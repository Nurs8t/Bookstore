import 'package:flutter_test/flutter_test.dart';

import 'package:kazakh_book_shop/main.dart';

void main() {
  testWidgets('Қолданба ашылады және каталог экраны көрсетіледі', (tester) async {
    await tester.pumpWidget(const BookShopApp());
    // Тестте желі жоқ: сұраныс аяқталып, 10 с timeout таймері біткенше күтеміз.
    await tester.pump(const Duration(seconds: 11));

    expect(find.text('Қазақ әдебиеті дүкені'), findsOneWidget);
  });
}
