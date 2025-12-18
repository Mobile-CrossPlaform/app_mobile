import 'package:intl/intl.dart';

/// Utilitaire pour le formatage des dates
class DateFormatter {
  static final DateFormat _fullFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateOnly = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeOnly = DateFormat('HH:mm');
  static final DateFormat _relative = DateFormat('dd MMM yyyy', 'fr_FR');

  /// Format complet : 25/12/2024 14:30
  static String full(DateTime date) {
    return _fullFormat.format(date);
  }

  /// Date uniquement : 25/12/2024
  static String dateOnly(DateTime date) {
    return _dateOnly.format(date);
  }

  /// Heure uniquement : 14:30
  static String timeOnly(DateTime date) {
    return _timeOnly.format(date);
  }

  /// Format relatif lisible : 25 déc 2024
  static String readable(DateTime date) {
    return _relative.format(date);
  }

  /// Format relatif intelligent (aujourd'hui, hier, ou date)
  static String smart(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateDay).inDays;

    if (difference == 0) {
      return 'Aujourd\'hui à ${timeOnly(date)}';
    } else if (difference == 1) {
      return 'Hier à ${timeOnly(date)}';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return readable(date);
    }
  }
}
