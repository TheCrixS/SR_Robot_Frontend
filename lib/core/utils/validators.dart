/// Validadores puros: devuelven `true` si el valor es válido.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phoneDigits = RegExp(r'^\d{7,15}$');

  static bool isEmail(String v) => _email.hasMatch(v.trim());

  static bool isPhone(String v) =>
      _phoneDigits.hasMatch(v.trim().replaceAll(RegExp(r'[\s\-+]'), ''));

  static bool isOtp(String v) => RegExp(r'^\d{6}$').hasMatch(v);

  static bool isPassword(String v) => v.length >= 8;
}
