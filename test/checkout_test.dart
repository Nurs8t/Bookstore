import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kazakh_book_shop/models/book.dart';
import 'package:kazakh_book_shop/models/cart_item.dart';
import 'package:kazakh_book_shop/models/delivery_info.dart';
import 'package:kazakh_book_shop/models/order.dart';
import 'package:kazakh_book_shop/services/database_helper.dart';
import 'package:kazakh_book_shop/utils/validators.dart';

/// Тапсырыс беру формасы: валидация, телефон маскасы, жеткізу ақысы,
/// SQLite-қа сақтау және v1 → v2 миграциясы.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Validators', () {
    test('Аты-жөні', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('  '), isNotNull);
      expect(Validators.fullName('А'), isNotNull);
      expect(Validators.fullName('Нұрсейіт123'), 'Тек әріптер болуы керек');
      expect(Validators.fullName('Арыстанбек Нұрсейіт'), isNull);
      expect(Validators.fullName('Anna-Maria'), isNull);
    });

    test('Телефон: 10 цифр, 7-ден басталады, +7 / 8 префиксі қабылданады', () {
      expect(Validators.phone(''), 'Телефон нөмірін енгізіңіз');
      expect(Validators.phone('(701) 123-45'), 'Нөмір 10 цифрдан тұруы керек');
      expect(Validators.phone('(501) 123-45-67'), isNotNull);
      expect(Validators.phone('(701) 123-45-67'), isNull);
      expect(Validators.phone('+7 701 123 45 67'), isNull);
      expect(Validators.phone('87011234567'), isNull);
      expect(Validators.normalizePhone('(701) 123-45-67'), '+77011234567');
      expect(Validators.normalizePhone('8 701 123 45 67'), '+77011234567');
    });

    test('Мекенжай: міндетті, үй нөмірі болуы керек', () {
      expect(Validators.address(''), isNotNull);
      expect(Validators.address('Абай'), isNotNull);
      expect(Validators.address('Абай даңғылы'), 'Үй нөмірін қосыңыз');
      expect(Validators.address('Абай даңғылы, 10'), isNull);
    });

    test('Қала және пікір', () {
      expect(Validators.city(''), isNotNull);
      expect(Validators.city('Алматы'), isNull);
      expect(Validators.comment(null), isNull);
      expect(Validators.comment('x' * 201), isNotNull);
    });
  });

  group('KzPhoneInputFormatter', () {
    final f = KzPhoneInputFormatter();
    String type(String text) =>
        f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text)).text;

    test('Терген сайын маска қойылады', () {
      expect(type('7'), '(7');
      expect(type('7011'), '(701) 1');
      expect(type('7011234567'), '(701) 123-45-67');
    });

    test('Әріптер алынып тасталады, 10 цифрдан артық кірмейді', () {
      expect(type('70a1b'), '(701');
      expect(type('701123456789'), '(701) 123-45-67');
    });

    test('«8 701…» қойылса (paste) — 8 алынып тасталады', () {
      expect(type('8 701 123 45 67'), '(701) 123-45-67');
    });
  });

  group('Жеткізу ақысы', () {
    test('Өзі алса — тегін; курьер — 1 000 ₸, 10 000 ₸-ден бастап тегін', () {
      expect(DeliveryInfo.feeFor(DeliveryMethod.pickup, 500), 0);
      expect(DeliveryInfo.feeFor(DeliveryMethod.courier, 9999), 1000);
      expect(DeliveryInfo.feeFor(DeliveryMethod.courier, 10000), 0);
    });

    test('OrderRecord.fromCart сомаға жеткізуді қосады', () {
      final order = OrderRecord.fromCart([const CartItem(book: _abai, quantity: 2)], delivery: _courier);
      expect(order.deliveryFee, 1000);
      expect(order.itemsTotal, 7000);
      expect(order.total, 8000);
    });

    test('Телефон экранда әдемі пішінде', () {
      expect(_courier.formattedPhone, '+7 (701) 123-45-67');
    });
  });

  group('SQLite', () {
    late Directory dir;
    late String path;
    final db = DatabaseHelper.instance;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('bookstore_test_');
      path = p.join(dir.path, 'bookstore.db');
      db.databasePathOverride = path;
    });

    tearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });

    test('Жеткізу мәліметтері сақталып, қайта оқылады', () async {
      final order = OrderRecord.fromCart([const CartItem(book: _abai)], delivery: _courier);
      await db.insertOrder(order);
      await db.close(); // «қолданбаны жабу»

      final saved = (await db.getOrders()).single;
      expect(saved.total, 3500 + 1000);
      expect(saved.deliveryFee, 1000);
      expect(saved.delivery!.fullName, 'Нұрсейіт');
      expect(saved.delivery!.phone, '+77011234567');
      expect(saved.delivery!.method, DeliveryMethod.courier);
      expect(saved.delivery!.destination, 'Алматы, Абай даңғылы, 10');
      expect(saved.delivery!.payment, PaymentMethod.cash);
    });

    test('Миграция v1 → v2: ескі тапсырыстар өшпейді, жаңа бағандар қосылады', () async {
      // Ескі нұсқадағы (v1) дерекқорды қолмен жасаймыз — delivery бағандарынсыз.
      final old = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (d, _) async {
            await d.execute('CREATE TABLE cart_items (book_id TEXT PRIMARY KEY, book_json TEXT NOT NULL, '
                'quantity INTEGER NOT NULL DEFAULT 1, updated_at INTEGER NOT NULL)');
            await d.execute('CREATE TABLE favorites (book_id TEXT PRIMARY KEY, book_json TEXT NOT NULL, '
                'added_at INTEGER NOT NULL)');
            await d.execute('CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, created_at INTEGER NOT NULL, '
                'total INTEGER NOT NULL, item_count INTEGER NOT NULL, items_json TEXT NOT NULL)');
            await d.execute('CREATE TABLE products_cache (book_id TEXT PRIMARY KEY, book_json TEXT NOT NULL, '
                'position INTEGER NOT NULL, cached_at INTEGER NOT NULL)');
          },
        ),
      );
      await old.insert('orders', {
        'created_at': 0,
        'total': 3500,
        'item_count': 1,
        'items_json': '[{"bookId":"2","title":"Абай жолы (1-том)","price":3500,"quantity":1}]',
      });
      await old.close();

      // Жаңа нұсқа ашады → onUpgrade(1, 2)
      final orders = await db.getOrders();
      expect(orders.single.total, 3500);
      expect(orders.single.delivery, isNull);
      expect(orders.single.deliveryFee, 0);

      await db.insertOrder(OrderRecord.fromCart([const CartItem(book: _abai)], delivery: _courier));
      expect((await db.getOrders()).length, 2);
      expect((await (await db.database).getVersion()), 2);
    });
  });
}

const _abai = Book(
  id: '2',
  title: 'Абай жолы (1-том)',
  author: 'Мұхтар Әуезов',
  price: 3500,
  rating: 5.0,
  reviewsCount: 1,
  imagePath: '',
  synopsis: '',
  category: 'Роман-эпопея',
  tags: [],
);

const _courier = DeliveryInfo(
  fullName: 'Нұрсейіт',
  phone: '+77011234567',
  method: DeliveryMethod.courier,
  city: 'Алматы',
  address: 'Абай даңғылы, 10',
  payment: PaymentMethod.cash,
);
