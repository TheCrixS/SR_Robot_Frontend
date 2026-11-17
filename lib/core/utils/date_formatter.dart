import 'package:intl/intl.dart';

/// Fechas: se reciben en UTC ISO-8601 y se muestran en la zona del dispositivo.
class DateFormatter {
  DateFormatter._();

  static DateTime? parse(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso)?.toLocal();

  static String shortDate(DateTime d, String locale) =>
      DateFormat('d MMM yyyy', locale).format(d);

  static String dayMonth(DateTime d, String locale) =>
      DateFormat('d MMM', locale).format(d);

  static String weekdayShort(DateTime d, String locale) =>
      DateFormat('EEE', locale).format(d);

  static String time(DateTime d, String locale) =>
      DateFormat('HH:mm', locale).format(d);

  /// `YYYY-MM-DD` para la API.
  static String apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Hora relativa compacta para listas de chat/notificaciones.
  static String relative(DateTime d, String locale) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays == 0 && now.day == d.day) return time(d, locale);
    if (diff.inDays < 7) return weekdayShort(d, locale);
    return dayMonth(d, locale);
  }
}
