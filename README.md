# 📚 Қазақ әдебиеті дүкені — Kazakh Classic Book Shop

Қазақ классикалық әдебиетін сатып алуға арналған Flutter мобильді қолданбасы.
Narxoz University · Cross-Platform Mobile Development · **Capstone Project**

## 💡 Питч
**Мәселе:** Қазақ классикасын (Әуезов, Есенберлин, Мүсірепов, Нұршайықов…) онлайн тауып,
сипаттамасын оқып, бірден сатып алатын ыңғайлы қазақ тіліндегі қолданба аз.
**Қолданушы:** студенттер, мұғалімдер және қазақ әдебиетін оқығысы келетін кез келген оқырман.
**Шешім:** Қазақ тіліндегі кітап каталогы — санат, таңдаулылар, себет, тапсырыстар; интернетсіз де жұмыс істейді.

## ✨ Мүмкіндіктер

**🔐 Кіру (AuthCubit)**
- Кіру экраны: `BlocConsumer<AuthCubit, AuthState>` — `listener` қатеде қызыл SnackBar шығарады және сәтті кіргенде каталогқа өтеді, `builder` жүктелу кезінде батырманың орнына спиннер көрсетеді
- Күйлер (Equatable): `AuthInitial`, `AuthLoading`, `AuthSuccess(username, email)`, `AuthError(message)`
- Кіру экранынан тіркелуге болады; тіркелген email мен құпиясөз арқылы қайта кіру. Құпиясөздің өзі сақталмайды — тек тұзды SHA-256 хэші
- «Қонақ ретінде жалғастыру» мүмкіндігі бар
- Secure Vault: сессия токені `flutter_secure_storage`-те (Keychain / KeyStore) шифрланып сақталады — қолданбаны қайта ашқанда кіру экраны шықпайды

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
- 3 күй (`CatalogBloc`): `CatalogLoading` → `CatalogLoaded` (Pull-to-Refresh) → `CatalogError` және «Қайта қосылу»
- Кітапты басқанда `Hero` анимациясы, фото-карусель (1 / 3 санағыш, анимацияланған нүктелер)
- Бөлісу: Deep Link `narxoz://store/product/{id}` және көшіру батырмасы

**📴 Офлайн режим**
- API-дан келген кітаптар SQLite кэшіне жазылады
- Интернет жоқ болса, каталог кэштен көрсетіледі: «Офлайн режим · Соңғы жаңарту» белгісі және «Қайта қосылу»
- Кэш бос болса (бірінші ашылу) — қате экраны және «Қайта қосылу»

**🛍 Себет пен таңдаулылар**
- Глобал себет — `CartBloc`: `AddProductEvent`, `RemoveProductEvent`, `DecrementProductEvent`, `ClearCartEvent` → `CartState(items, totalPrice, count)`; барлық экранда бірден жаңарады
- Себет пен таңдаулылар SQLite-та сақталады — қолданбаны жауып ашқанда орнында
- AppBar мен төменгі мәзірдегі тірі badge — `BlocBuilder<CartBloc, CartState>`
- Санын −/+ өзгерту, жеке өшіру, жалпы сома, «Тазалау»
- «Рәсімдеу» тапсырысты сақтайды, «Профиль → Тапсырыстар тарихы» бөлімінде көрінеді
- Таңдаулы кітаптар тізімі

**👤 Профиль**
- Тіркелу формасы: аты-жөні, email, құпиясөз және растау, рөл таңдау, хабарлама, шарттарды қабылдау
- Әр өрісті тексеру (валидация) және сәтті тіркелу диалогы
- «Мені есте сақта»: профиль `shared_preferences`-те сақталады; «Шығу» оны өшіреді
- Тапсырыстар тарихы: күні, сомасы, ішіндегі кітаптар

**⚙️ Баптаулар мен оқу жазбалары (офлайн)**
- Қараңғы тақырып: `shared_preferences` (`app_theme_dark_mode`), `runApp()`-тан бұрын жүктеледі — ақ экран жыпылықтамайды
- Көрсетілетін ат (`user_display_name`), әдепкі мән — «Guest User»
- Оқу жазбалары: `NoteItem` → `toJson()` → `jsonEncode()` → бір кілт (`notes_list`); қосу, белгілеу, өшіру (+UNDO)
- Деректер қолданбаны толық жауып ашқанда (cold restart) бірден қалпына келеді

**🧭 Навигация**
- Төменгі мәзір: Кітаптар / Таңдаулылар / Себет / Профиль
- Деталь экранына толық объектіні беру, «артқа» батырмалары

## 🏗 Архитектура
```
UI (screens, widgets)
   │ BlocBuilder / BlocConsumer / context.read<…>().add(Event)
   │ context.watch / context.read (Provider)
   ▼
BLoC: Auth, Cart, Catalog, Favorites, Orders  +  Providers ─┐
   │                                     │
   ▼                                     ▼
BookRepository                     DatabaseHelper (SQLite)   SharedPreferences
   ├─▶ BookApiService ──▶ REST API         ▲                        ▲
   └─▶ SQLite кэш ─────────────────────────┘                        │
                                   Cart / Favorites / Orders   Settings / Notes / User
```
- **UI** деректің қайдан келетінін білмейді: тек провайдерден оқиды және әрекет жібереді.
- **Repository** API мен кэшті біріктіреді: интернет бар — API, жоқ — SQLite.
- **BLoC / Cubit** (кіру, себет, каталог, таңдаулылар, тапсырыстар): UI тек оқиға жібереді, күйді BLoC өзгертеді; күйлер өзгермейтін (immutable) және Equatable.
- **Clean Architecture**: UI → `CatalogBloc` → `BookRepository` → API / SQLite.
- **Provider** (баптаулар, жазбалар, профиль): shared_preferences-тегі қарапайым мәндер үшін.
- **Optimistic update**: себет пен таңдаулылар жадта бірден өзгереді, дерекқорға фонда жазылады.

## 💾 Деректерді сақтау
| Не | Қайда | Кесте / кілт |
|---|---|---|
| Себет | SQLite | `cart_items` |
| Таңдаулылар | SQLite | `favorites` |
| Тапсырыстар | SQLite | `orders` |
| Кітаптар кэші (офлайн) | SQLite | `products_cache` |
| Қараңғы тақырып | SharedPreferences | `app_theme_dark_mode` |
| Көрсетілетін ат | SharedPreferences | `user_display_name` |
| Оқу жазбалары (JSON) | SharedPreferences | `notes_list` |
| Тіркелген қолданушы (JSON) | SharedPreferences | `user_profile` |
| Аккаунттар (тұзды хэш) | SharedPreferences | `accounts` |
| Кіру сессиясының токені | **Keychain / KeyStore** (шифрланған) | `auth_session` |

Құпиясөздің өзі ешқайда сақталмайды — тек тұзды SHA-256 хэші. Сессия токені сияқты құпия деректер шифрланбаған SharedPreferences-те емес, Keychain / KeyStore-да (`flutter_secure_storage`).

## 🗂 Папка құрылымы
```
api/books.json                 # кітаптар API-ы (JSON)
lib/
├── main.dart                  # SharedPreferences алдын ала жүктеу → MultiBlocProvider + MultiProvider → MaterialApp
├── blocs/                     # auth/, cart/, catalog/, favorites/, orders/
├── models/                    # Book, Product, CartItem, OrderRecord, NoteItem, UserProfile
├── providers/                 # User, Settings, Notes
├── repositories/              # BookRepository (API + офлайн кэш)
├── services/                  # BookApiService (http + JSON), DatabaseHelper (SQLite)
├── screens/                   # login, root, catalog, book_detail, favorites, cart, orders, profile, registration, settings
├── widgets/                   # BookListTile, BookGridCard, BookCover, TagChip, EmptyState, ErrorState, ShareLinkSheet, CartBadgeButton…
└── utils/                     # AppTheme (жарық/қараңғы), formatPrice
test/                          # модельдер, API, SQLite, BLoC (bloc_test), провайдерлер
```

## 🛠 Технологиялар
Flutter · Dart 3 · `flutter_bloc` + `equatable` · `provider` · `http` · `sqflite` · `shared_preferences` · `flutter_secure_storage` · `crypto` · `flutter_test` + `bloc_test` + `sqflite_common_ffi`

## ▶️ Іске қосу
```bash
flutter pub get
flutter run
flutter test        # барлық тесттер
```
Кітап мұқабалары API арқылы GitHub-тан жүктеледі. Сурет жоқ немесе интернет болмаса, қолданба құламайды — placeholder көрсетіледі.

## ✅ Қолмен тексеру
**Cold restart:** себетке кітап қосу, ♡ басу, тіркелу («Мені есте сақта»), қараңғы тақырыпты қосу, жазба қосу → қолданбаны толық жабу → қайта ашу: барлығы орнында, қолданба бірден қараңғы ашылады.

**Ұшақ режимі:** интернетпен бір рет ашу → Wi-Fi өшіріп қайта ашу: каталог «Офлайн режим» белгісімен кэштен көрсетіледі → Wi-Fi қосып «Қайта қосылу»: тізім серверден жаңарады.

## 🛣 Жоспар
- [x] UI, навигация, себет (Provider)
- [x] REST API, 3 UI күйі, Hero, карусель, Deep Link
- [x] SQLite, офлайн кэш, тапсырыстар тарихы, SharedPreferences
- [x] BLoC: AuthCubit (кіру), CartBloc (себет)
- [x] Каталог CatalogBloc-та: Fetch / Refresh / FilterCategory / Remove / Restore
- [ ] Іздеу, тапсырыс беру формасы
