import 'package:flutter_test/flutter_test.dart';

import 'package:kazakh_book_shop/main.dart';

void main() {
  testWidgets('Каталог ашылады және кітаптар көрсетіледі', (tester) async {
    await tester.pumpWidget(const BookShopApp());
    await tester.pumpAndSettle();

    expect(find.text('Қазақ әдебиеті дүкені'), findsOneWidget);
    expect(find.text('Абай жолы (1-том)'), findsOneWidget);
  });
}
