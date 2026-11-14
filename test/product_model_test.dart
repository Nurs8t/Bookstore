import 'package:flutter_test/flutter_test.dart';

import 'package:kazakh_book_shop/models/product.dart';

void main() {
  group('Product.fromJson', () {
    test('API-дің толық жауабын дұрыс оқиды', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Абай жолы',
        'author': 'Мұхтар Әуезов',
        'price': 3500.5,
        'description': 'Роман-эпопея',
        'category': 'Роман-эпопея',
        'image': 'https://example.com/abai.jpg',
        'rating': {'rate': 3.9, 'count': 120},
      });

      expect(product.id, 1);
      expect(product.price, 3500.5);
      expect(product.author, 'Мұхтар Әуезов');
      expect(product.rating, 3.9);
      expect(product.reviewCount, 120);
      expect(product.images.length, 3);
      expect(product.deepLink, 'narxoz://store/product/1');
    });

    test('String бағаны да оқиды', () {
      final product = Product.fromJson({'id': 8, 'price': '2600'});
      expect(product.price, 2600.0);
    });

    test('int бағаны double-ға қатесіз айналдырады', () {
      final product = Product.fromJson({
        'id': 2,
        'price': 22, // int!
        'rating': {'rate': 4, 'count': 10}, // int!
      });

      expect(product.price, 22.0);
      expect(product.price, isA<double>());
      expect(product.rating, 4.0);
    });

    test('өрістер жоқ немесе null болса, құламайды', () {
      final product = Product.fromJson({'id': null, 'price': null, 'rating': null});

      expect(product.id, 0);
      expect(product.price, 0.0);
      expect(product.title, 'Атауы жоқ кітап');
      expect(product.author, 'Автор белгісіз');
      expect(product.reviewCount, 0);
    });
  });
}
