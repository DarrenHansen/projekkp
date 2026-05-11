import 'package:intl/intl.dart';

/// Helper class untuk formatting
class Helpers {
  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  static final DateFormat _dateFormatterFull = DateFormat('dd MMMM yyyy');
  static final DateFormat _dateTimeFormatter = DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat _dbDateFormatter = DateFormat('yyyy-MM-dd');

  /// Format mata uang Rupiah
  static String formatCurrency(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format tanggal singkat
  static String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return _dateFormatter.format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format tanggal lengkap
  static String formatDateFull(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return _dateFormatterFull.format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format tanggal dan waktu
  static String formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return _dateTimeFormatter.format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Format tanggal untuk disimpan ke database
  static String dateToDb(DateTime date) {
    return _dbDateFormatter.format(date);
  }

  /// Format tanggal dari ISO string
  static String formatIsoDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return _dateFormatter.format(date);
    } catch (_) {
      return isoDate;
    }
  }

  /// Hitung hari tersisa sebelum jatuh tempo
  static int daysUntilDue(String dueDate) {
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      final difference = due.difference(now).inDays;
      return difference;
    } catch (_) {
      return 0;
    }
  }

  /// Mendapatkan greeting berdasarkan waktu
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 17) {
      return 'Selamat Siang';
    } else {
      return 'Selamat Malam';
    }
  }

  /// Truncate string dengan ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
