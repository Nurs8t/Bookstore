# 📚 Қазақ әдебиеті дүкені — Kazakh Classic Book Shop

Қазақ классикалық әдебиетін сатып алуға арналған Flutter мобильді қолданбасы.
Narxoz University · Cross-Platform Mobile Development · **Capstone Project — Milestone 1**

## 💡 Питч
**Мәселе:** Қазақ классикасын (Әуезов, Есенберлин, Мүсірепов, Нұршайықов…) онлайн тауып,
сипаттамасын оқып, бірден сатып алатын ыңғайлы қазақ тіліндегі қолданба аз.
**Қолданушы:** студенттер, мұғалімдер және қазақ әдебиетін оқығысы келетін кез келген оқырман.
**Шешім:** Қазақ тіліндегі кітап каталогы — іздеу/санат, таңдаулылар, себет, тіркелу.

## ✨ Мүмкіндіктер
| Мүмкіндік | Қай лаб |
|---|---|
| Каталог: тізім ↔ тор (2/3/4 баған, адаптивті) | LAB 8 |
| Pull-to-Refresh (1.5 с кідіріс, жаңа кітап index 0-ге) | LAB 8 |
| Swipe-to-Delete + UNDO (бастапқы индексіне қайтару) | LAB 8 |
| Бос каталог күйі + «Қалпына келтіру» батырмасы | LAB 8 |
| Санат бойынша сүзгі (ChoiceChip, `setState`) | Milestone 1 |
| Кітап детальдары: Stack мұқаба + Бестселлер баннері + bookmark белгісі, Row/Wrap тегтер, Expanded sticky «Себетке қосу» | LAB 5 |
| Bottom Navigation (Кітаптар / Таңдаулылар / Себет / Профиль), толық `Book` объектісін беру, AppBar + денедегі «артқа» батырмасы | LAB 7 |
| Тіркелу формасы: 4 TextFormField, Dropdown (рөл), Switch, Checkbox, GlobalKey<FormState>, AlertDialog | LAB 6 |
| Глобал себет `CartProvider` (ChangeNotifier), AppBar-дағы тірі badge, саны −/+, жалпы сома, «Тазалау» | LAB 9 |

## 🗂 Папка құрылымы
```
lib/
├── main.dart                  # MultiProvider + MaterialApp
├── data/books_data.dart       # бастапқы 6 кітап (seed data)
├── models/                    # Book, CartItem, UserProfile
├── providers/                 # CartProvider, FavoritesProvider, UserProvider
├── screens/                   # root, catalog, book_detail, favorites, cart, profile, registration
├── widgets/                   # BookListTile, BookGridCard, BookCover, TagChip, EmptyState, CartBadgeButton…
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
- REST API арқылы каталогты жүктеу
- Жергілікті дерекқор (себет пен таңдаулыларды сақтау)
- BLoC архитектурасына көшу
