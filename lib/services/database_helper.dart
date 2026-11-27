import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/book.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

/// Жергілікті SQLite дерекқоры (Singleton).
///
/// Бүкіл қолданбада дерекқорға бір ғана қосылым болады:
///   final db = DatabaseHelper.instance;
///
/// Кестелер:
///   cart_items     — себет (кітап + саны)
///   favorites      — таңдаулы кітаптар
///   orders         — рәсімделген тапсырыстар тарихы
///   products_cache — API-дан соңғы жүктелген кітаптар (офлайн режим үшін)
class DatabaseHelper {
  // ---------- Singleton ----------
  DatabaseHelper._(); // жеке конструктор: сырттан `DatabaseHelper()` жасауға болмайды
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'bookstore.db';
  /// v1 — алғашқы 4 кесте.
  /// v2 — orders кестесіне жеткізу мәліметтері (delivery_json, delivery_fee).
  static const int _dbVersion = 2;

  // Кесте атаулары
  static const String tableCart = 'cart_items';
  static const String tableFavorites = 'favorites';
  static const String tableOrders = 'orders';
  static const String tableCache = 'products_cache';

  Future<Database>? _dbFuture;

  /// Тесттерде дерекқорды жадта (`inMemoryDatabasePath`) ашу үшін.
  /// Сонда параллель жүретін тест файлдары бір-бірін бұғаттамайды.
  @visibleForTesting
  String? databasePathOverride;

  /// Дерекқорға қосылым. Бірінші шақырғанда ашылады (lazy), кейін сол бір объект қайтарылады.
  /// Future сақталады: бірнеше сұраныс бір мезетте келсе де, файл тек бір рет ашылады.
  Future<Database> get database => _dbFuture ??= _open();

  Future<Database> _open() async {
    final path = databasePathOverride ?? join(await getDatabasesPath(), _dbName);
    debugPrint('SQLite: $path');

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Дерекқор алғаш жасалғанда кестелерді құру (DDL).
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE $tableCart (
        book_id    TEXT PRIMARY KEY,
        book_json  TEXT    NOT NULL,
        quantity   INTEGER NOT NULL DEFAULT 1,
        updated_at INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableFavorites (
        book_id   TEXT PRIMARY KEY,
        book_json TEXT    NOT NULL,
        added_at  INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableOrders (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at INTEGER NOT NULL,
        total      INTEGER NOT NULL,
        item_count INTEGER NOT NULL,
        items_json TEXT    NOT NULL,
        delivery_json TEXT,
        delivery_fee  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableCache (
        book_id   TEXT PRIMARY KEY,
        book_json TEXT    NOT NULL,
        position  INTEGER NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  /// Миграция: ескі нұсқадағы пайдаланушының деректері (себет, тапсырыстар)
  /// өшпейді — тек жетіспейтін бағандар қосылады.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableOrders ADD COLUMN delivery_json TEXT');
      await db.execute(
          'ALTER TABLE $tableOrders ADD COLUMN delivery_fee INTEGER NOT NULL DEFAULT 0');
    }
  }

  static int get _now => DateTime.now().millisecondsSinceEpoch;

  // =====================================================================
  // CART — CRUD
  // =====================================================================

  /// READ: себеттегі барлық позициялар (қосылған ретімен).
  Future<List<CartItem>> getCartItems() async {
    final db = await database;
    final rows = await db.query(tableCart, orderBy: 'updated_at ASC');
    return rows
        .map((r) => CartItem(
              book: Book.fromMap(jsonDecode(r['book_json'] as String)),
              quantity: r['quantity'] as int,
            ))
        .toList();
  }

  /// CREATE / UPDATE: кітапты берілген санмен сақтау (бар болса — жаңарту).
  Future<void> upsertCartItem(Book book, int quantity) async {
    final db = await database;
    await db.insert(
      tableCart,
      {
        'book_id': book.id,
        'book_json': jsonEncode(book.toMap()),
        'quantity': quantity,
        'updated_at': _now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// UPDATE: тек санын өзгерту.
  Future<int> updateCartQuantity(String bookId, int quantity) async {
    final db = await database;
    return db.update(
      tableCart,
      {'quantity': quantity},
      where: 'book_id = ?', // `?` — SQL injection-нан қорғайды
      whereArgs: [bookId],
    );
  }

  /// DELETE: бір кітапты себеттен өшіру.
  Future<int> deleteCartItem(String bookId) async {
    final db = await database;
    return db.delete(tableCart, where: 'book_id = ?', whereArgs: [bookId]);
  }

  /// DELETE: себетті толық тазалау.
  Future<int> clearCart() async {
    final db = await database;
    return db.delete(tableCart);
  }

  // =====================================================================
  // FAVORITES — CRUD
  // =====================================================================

  Future<List<Book>> getFavorites() async {
    final db = await database;
    final rows = await db.query(tableFavorites, orderBy: 'added_at ASC');
    return rows.map((r) => Book.fromMap(jsonDecode(r['book_json'] as String))).toList();
  }

  Future<void> insertFavorite(Book book) async {
    final db = await database;
    await db.insert(
      tableFavorites,
      {'book_id': book.id, 'book_json': jsonEncode(book.toMap()), 'added_at': _now},
      conflictAlgorithm: ConflictAlgorithm.ignore, // бұрыннан бар болса — ештеңе істемейді
    );
  }

  Future<int> deleteFavorite(String bookId) async {
    final db = await database;
    return db.delete(tableFavorites, where: 'book_id = ?', whereArgs: [bookId]);
  }

  // =====================================================================
  // ORDERS — CRUD
  // =====================================================================

  /// CREATE: жаңа тапсырыс. Қайтаратыны — дерекқор берген id.
  Future<int> insertOrder(OrderRecord order) async {
    final db = await database;
    return db.insert(tableOrders, order.toRow());
  }

  /// READ: барлық тапсырыстар, ең жаңасы бірінші.
  Future<List<OrderRecord>> getOrders() async {
    final db = await database;
    final rows = await db.query(tableOrders, orderBy: 'created_at DESC');
    return rows.map(OrderRecord.fromRow).toList();
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return db.delete(tableOrders, where: 'id = ?', whereArgs: [id]);
  }

  /// DELETE: бүкіл тарихты тазалау (баптаулардан). Қайтаратыны — өшірілген жолдар саны.
  Future<int> clearOrders() async {
    final db = await database;
    return db.delete(tableOrders);
  }

  // =====================================================================
  // PRODUCTS CACHE — офлайн режим
  // =====================================================================

  /// API-дан келген тізімді кэшке толық ауыстырып жазу.
  /// Transaction: не бәрі сақталады, не ештеңе (жартылай жазылып қалмайды).
  Future<void> replaceBooksCache(List<Book> books) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableCache);
      final batch = txn.batch();
      for (var i = 0; i < books.length; i++) {
        batch.insert(tableCache, {
          'book_id': books[i].id,
          'book_json': jsonEncode(books[i].toMap()),
          'position': i,
          'cached_at': _now,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  /// Офлайн кэшті тазалау. Келесі жолы каталог тек интернетпен ашылады.
  Future<int> clearBooksCache() async {
    final db = await database;
    return db.delete(tableCache);
  }

  /// Кэштегі кітаптар (API-дағы ретімен). Кэш бос болса — бос тізім.
  Future<List<Book>> getCachedBooks() async {
    final db = await database;
    final rows = await db.query(tableCache, orderBy: 'position ASC');
    return rows.map((r) => Book.fromMap(jsonDecode(r['book_json'] as String))).toList();
  }

  /// Кэш соңғы рет қашан жаңартылды (кэш бос болса — null).
  Future<DateTime?> lastCacheTime() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT MAX(cached_at) AS t FROM $tableCache');
    final millis = Sqflite.firstIntValue(rows);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  // =====================================================================
  // Қызметтік әдістер
  // =====================================================================

  /// Әр кестедегі жолдар саны (debug / қорғауда көрсету үшін).
  Future<Map<String, int>> tableCounts() async {
    final db = await database;
    final result = <String, int>{};
    for (final table in [tableCart, tableFavorites, tableOrders, tableCache]) {
      final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
      result[table] = Sqflite.firstIntValue(rows) ?? 0;
    }
    return result;
  }

  /// Қосылымды жабу (тесттерде қолданылады).
  Future<void> close() async {
    final future = _dbFuture;
    _dbFuture = null;
    if (future != null) await (await future).close();
  }

  /// Дерекқор файлын толық өшіру (тесттерде таза бастау үшін).
  @visibleForTesting
  Future<void> deleteDatabaseFile() async {
    await close();
    // Жадтағы дерекқор жабылғанда өзі жойылады; файл болса — өшіреміз.
    if (databasePathOverride == null) {
      await deleteDatabase(join(await getDatabasesPath(), _dbName));
    }
  }
}
