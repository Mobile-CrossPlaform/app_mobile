/// Utilitaires pour le formatage des dates
library;

/// Classe utilitaire pour formater les dates
class DateFormatter {
  DateFormatter._();

  /// Formate une date au format "dd/MM/yyyy"
  static String formatDate(DateTime date) {
    return '${_pad(date.day)}/${_pad(date.month)}/${date.year}';
  }

  /// Formate une date avec l'heure au format "dd/MM/yyyy à HH:mm"
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} à ${_pad(date.hour)}:${_pad(date.minute)}';
  }

  /// Formate une date relative (il y a X minutes/heures/jours)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return formatDate(date);
    }
  }

  /// Ajoute un zéro devant les nombres < 10
  static String _pad(int number) {
    return number.toString().padLeft(2, '0');
  }
}
