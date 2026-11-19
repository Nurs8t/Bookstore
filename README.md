# 📚 Қазақ әдебиеті дүкені — Kazakh Classic Book Shop

Қазақ классикалық әдебиетін сатып алуға арналған Flutter мобильді қолданбасы.
Narxoz University · Cross-Platform Mobile Development · **Capstone Project — Milestone 1**

## 💡 Питч
**Мәселе:** Қазақ классикасын (Әуезов, Есенберлин, Мүсірепов, Нұршайықов…) онлайн тауып,
сипаттамасын оқып, бірден сатып алатын ыңғайлы қазақ тіліндегі қолданба аз.
**Қолданушы:** студенттер, мұғалімдер және қазақ әдебиетін оқығысы келетін кез келген оқырман.
**Шешім:** Қазақ тіліндегі кітап каталогы — іздеу/санат, таңдаулылар, себет, тіркелу.

## ✨ Мүмкіндіктер

**📖 Кітап каталогы**
- Тізім ↔ тор көрінісі (телефонда 2, планшетте 3, ПК-да 4 баған)
- Санат бойынша сүзгі
- Pull-to-Refresh — каталог серверден қайта жүктеледі
- Swipe-to-Delete және «UNDO» арқылы кітапты орнына қайтару
- Каталог бос болса — «Қалпына келтіру» батырмасы серверден қайта жүктейді

**📘 Кітап мәліметтері**
- Мұқаба, «Бестселлер» баннері және бетбелгі
- Рейтинг, санат пен тақырып белгілері, толық сипаттама
- Төменде тұрақты «Себетке қосу» батырмасы

**☁️ REST API**
- Каталог кітаптарды өз API-ымыздан жүктейді: [`api/books.json`](api/books.json) (`http.get`, 10 с timeout, 200/404/500 өңдеу)
- Type-safe `Product.fromJson`: null-safe fallback, `(json['price'] as num).toDouble()`; int, double, String бағалар
- 3 күй: жүктелу → кітаптар тізімі (Pull-to-Refresh) → офлайн қате және «Қайта қосылу»
- Кітапты басқанда `Hero` анимациясы, фото-карусель (1 / 3 санағыш, анимацияланған нүктелер)
- Бөлісу: Deep Link `narxoz://store/product/{id}` және көшіру батырмасы

**🛍 Себет пен таңдаулылар**
- Глобал себет (`Provider` + `ChangeNotifier`) — барлық экранда бірден жаңарады
- AppBar мен төменгі мәзірдегі тірі badge
- Санын −/+ өзгерту, жеке өшіру, жалпы сома, «Тазалау»
- «Рәсімдеу» тапсырысты сақтайды, «Профиль → Тапсырыстар тарихы» бөлімінде көрінеді
- Таңдаулы кітаптар тізімі

**👤 Профиль**
- Тіркелу формасы: аты-жөні, email, құпиясөз және растау, рөл таңдау, хабарлама, шарттарды қабылдау
- Әр өрісті тексеру (валидация) және сәтті тіркелу диалогы

**⚙️ Баптаулар мен оқу жазбалары (офлайн)**
- Қараңғы тақырып: `shared_preferences` (`app_theme_dark_mode`), `runApp()`-тан бұрын жүктеледі — ақ экран жыпылықтамайды
- Көрсетілетін ат (`user_display_name`), әдепкі мән — «Guest User»
- Оқу жазбалары: `NoteItem` → `toJson()` → `jsonEncode()` → бір кілт (`notes_list`); қосу, белгілеу, өшіру (+UNDO)
- Деректер қолданбаны толық жауып ашқанда (cold restart) бірден қалпына келеді

**🧭 Навигация**
- Төменгі мәзір: Кітаптар / Таңдаулылар / Себет / Профиль
- Деталь экранына толық объектіні беру, «артқа» батырмалары

## 🗂 Папка құрылымы
```
api/books.json               # кітаптар API-ы (JSON)
lib/
├── main.dart                  # MultiProvider + MaterialApp
├── models/                    # Book, CartItem, UserProfile, Product, OrderRecord
├── providers/                 # CartProvider, FavoritesProvider, UserProvider
├── repositories/              # BookRepository (API + офлайн кэш)
├── services/                  # BookApiService (http + JSON), DatabaseHelper (SQLite)
├── screens/                   # root, catalog, book_detail, favorites, cart, profile, registration
├── widgets/                   # BookListTile, BookGridCard, BookCover, TagChip, EmptyState, ErrorState, ShareLinkSheet, CartBadgeButton…
└── utils/                     # AppTheme, formatPrice
```

## ▶️ Іске қосу
```bash
flutter pub get
flutter run
```
Мұқабалар `assets/` папкасында: `my_book.jpeg`, `my_book1.jpeg` … `my_book5.jpeg`, профиль суреті `123.jpeg`.
Сурет жоқ болса, қолданба құламайды — әдемі placeholder көрсетіледі.

## 🛣 Жоспар (келесі milestone-дар)
- Жергілікті дерекқор (себет пен таңдаулыларды сақтау)
- BLoC архитектурасына көшу
