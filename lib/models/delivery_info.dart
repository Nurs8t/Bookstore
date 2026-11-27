/// Жеткізу тәсілі.
enum DeliveryMethod {
  courier('Курьер'),
  pickup('Өзім алып кетемін');

  const DeliveryMethod(this.label);

  final String label;
}

/// Төлем тәсілі (карта деректері қолданбада енгізілмейді — тек тәсіл таңдалады).
enum PaymentMethod {
  cardOnDelivery('Картамен (алған кезде)'),
  cash('Қолма-қол');

  const PaymentMethod(this.label);

  final String label;
}

/// Тапсырыс беру формасынан келетін жеткізу мәліметтері.
class DeliveryInfo {
  /// Өзі алып кететін нүкте.
  static const String pickupPoint = 'Алматы, Жандосов к-сі, 55 (Narxoz кітап дүкені)';

  /// Курьер ақысы және тегін жеткізу шегі (теңге).
  static const int courierFee = 1000;
  static const int freeDeliveryFrom = 10000;

  final String fullName;

  /// Қалыпқа келтірілген нөмір: `+77011234567`.
  final String phone;
  final DeliveryMethod method;
  final String city;
  final String address;
  final PaymentMethod payment;
  final String comment;

  const DeliveryInfo({
    required this.fullName,
    required this.phone,
    required this.method,
    this.city = '',
    this.address = '',
    required this.payment,
    this.comment = '',
  });

  /// Жеткізу ақысы: өзі алса — 0; курьер — 1 000 ₸, 10 000 ₸-ден бастап тегін.
  static int feeFor(DeliveryMethod method, int itemsTotal) {
    if (method == DeliveryMethod.pickup) return 0;
    return itemsTotal >= freeDeliveryFrom ? 0 : courierFee;
  }

  /// Экранда көрсетуге: курьер болса — қала мен мекенжай, әйтпесе — дүкен нүктесі.
  String get destination =>
      method == DeliveryMethod.courier ? '$city, $address' : pickupPoint;

  /// `+77011234567` → `+7 (701) 123-45-67`
  String get formattedPhone {
    final d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11) return phone;
    return '+7 (${d.substring(1, 4)}) ${d.substring(4, 7)}-${d.substring(7, 9)}-${d.substring(9)}';
  }

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'method': method.name,
        'city': city,
        'address': address,
        'payment': payment.name,
        'comment': comment,
      };

  factory DeliveryInfo.fromMap(Map<String, dynamic> map) => DeliveryInfo(
        fullName: map['fullName'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        method: DeliveryMethod.values.asNameMap()[map['method']] ?? DeliveryMethod.courier,
        city: map['city'] as String? ?? '',
        address: map['address'] as String? ?? '',
        payment: PaymentMethod.values.asNameMap()[map['payment']] ?? PaymentMethod.cash,
        comment: map['comment'] as String? ?? '',
      );
}
