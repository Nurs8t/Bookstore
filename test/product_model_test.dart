import 'package:flutter_test/flutter_test.dart';

import 'package:kazakh_book_shop/models/product.dart';

void main() {
  group('Product.fromJson', () {
    test('API-дің толық жауабын дұрыс оқиды', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'Backpack',
        'price': 109.95,
        'description': 'Nice bag',
        'category': "men's clothing",
        'image': 'https://fakestoreapi.com/img/1.jpg',
        'rating': {'rate': 3.9, 'count': 120},
      });

      expect(product.id, 1);
      expect(product.price, 109.95);
      expect(product.rating, 3.9);
      expect(product.reviewCount, 120);
      expect(product.images.length, 3);
      expect(product.deepLink, 'narxoz://store/product/1');
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
      expect(product.title, 'Атауы жоқ тауар');
      expect(product.reviewCount, 0);
      expect(product.images, isEmpty);
    });
  });
}
