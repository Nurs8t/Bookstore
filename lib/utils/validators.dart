import 'package:flutter/services.dart';

/// Тапсырыс формасының тексерулері. Әр функция `TextFormField.validator`-ға
/// тікелей беріледі: қате болса — мәтін, дұрыс болса — null.
class Validators {
  Validators._();

  static final RegExp _nameChars = RegExp(r"^[\p{L}\s'\-.]+$", unicode: true);

  /// Аты-жөні: кемінде 2 әріп, тек әріп, бос орын, дефис.
  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Аты-жөніңізді енгізіңіз';
    if (v.length < 2) return 'Тым қысқа';
    if (!_nameChars.hasMatch(v)) return 'Тек әріптер болуы керек';
    return null;
  }

  /// Қазақстан мобильді нөмірі: +7 7XX XXX XX XX (10 цифр, 7-ден басталады).
  /// Пайдаланушы «8 701…» немесе «+7 701…» деп енгізсе де қабылдаймыз.
  static String? phone(String? value) {
    final digits = phoneDigits(value ?? '');
    if (digits.isEmpty) return 'Телефон нөмірін енгізіңіз';
    if (digits.length != 10) return 'Нөмір 10 цифрдан тұруы керек';
    if (!digits.startsWith('7')) return 'Мобильді нөмір 7-ден басталады: 7XX…';
    return null;
  }

  /// Қала: міндетті, кемінде 2 әріп.
  static String? city(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Қаланы енгізіңіз';
    if (v.length < 2) return 'Тым қысқа';
    return null;
  }

  /// Мекенжай: кемінде 5 таңба және үй нөмірі (цифр) болуы керек.
  static String? address(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Мекенжайды енгізіңіз';
    if (v.length < 5) return 'Көше мен үй нөмірін толық жазыңыз';
    if (!RegExp(r'\d').hasMatch(v)) return 'Үй нөмірін қосыңыз';
    return null;
  }

  /// Пікір міндетті емес, бірақ 200 таңбадан аспауы керек.
  static String? comment(String? value) {
    if ((value?.length ?? 0) > 200) return '200 таңбадан аспауы керек';
    return null;
  }

  /// Мәтіннен абоненттің 10 цифрын алу (+7 / 8 префиксін алып тастап).
  static String phoneDigits(String text) {
    var d = text.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11 && (d.startsWith('7') || d.startsWith('8'))) d = d.substring(1);
    return d;
  }

  /// Сақтауға арналған пішін: `+77011234567`.
  static String normalizePhone(String text) => '+7${phoneDigits(text)}';
}

/// Телефон маскасы: терген сайын `(701) 123-45-67` пішініне келтіреді.
/// `+7` өрістің prefixText-інде тұрады, сондықтан мұнда тек 10 цифр.
class KzPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    // «8 701…» немесе «+7 701…» қойылса (paste) — ел кодын алып тастаймыз.
    final pastedWithCode = digits.length == 11 &&
        (digits.startsWith('8') || newValue.text.trimLeft().startsWith('+7'));
    if (pastedWithCode) digits = digits.substring(1);
    if (digits.length > 10) digits = digits.substring(0, 10);

    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) b.write('(');
      if (i == 3) b.write(') ');
      if (i == 6 || i == 8) b.write('-');
      b.write(digits[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
