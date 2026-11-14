import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

/// Желі қатесін UI-ға түсінікті хабармен жеткізетін ерекше жағдай.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// LAB 10: REST API-мен жұмыс істейтін сервис.
/// UI http, JSON немесе статус-кодтар туралы ештеңе білмейді —
/// тек `List<Product>` немесе `ApiException` алады.
class ProductApiService {
  /// Онлайн кітапхана API-ы: GitHub-тағы JSON файл (GET сұранысына JSON қайтарады).
  static const String _baseUrl =
      'https://raw.githubusercontent.com/Nurs8t/Bookstore/main/api';
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  ProductApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Product>> fetchProducts() async {
    final uri = Uri.parse('$_baseUrl/books.json');

    try {
      final response = await _client.get(uri).timeout(_timeout);

      switch (response.statusCode) {
        case 200:
          // utf8.decode — кириллица/арнайы таңбалар бұзылмауы үшін.
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is! List) {
            throw const ApiException('Сервер күтпеген форматта жауап берді.');
          }
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList();
        case 404:
          throw const ApiException('Кітаптар табылмады (404).', statusCode: 404);
        default:
          if (response.statusCode >= 500) {
            throw ApiException(
              'Сервер қатесі (${response.statusCode}). Кейінірек қайталап көріңіз.',
              statusCode: response.statusCode,
            );
          }
          throw ApiException(
            'Сұраныс сәтсіз аяқталды (${response.statusCode}).',
            statusCode: response.statusCode,
          );
      }
    } on TimeoutException {
      throw const ApiException(
        'Сервер 10 секунд ішінде жауап бермеді. Интернет байланысын тексеріңіз.',
      );
    } on http.ClientException {
      // Интернет жоқ (ұшақ режимі), DNS қатесі, байланыс үзілді.
      throw const ApiException(
        'Интернетке қосылу мүмкін емес. Wi-Fi немесе мобильді деректі тексеріңіз.',
      );
    } on FormatException {
      throw const ApiException('Сервер жауабын оқу мүмкін болмады (JSON қатесі).');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Белгісіз қате орын алды. Қайталап көріңіз.');
    }
  }

  void dispose() => _client.close();
}
