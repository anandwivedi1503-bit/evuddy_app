/// Rental end time + 1-hour-before reminder for in-app / local alerts.
class BookingEndSchedule {
  const BookingEndSchedule._();

  static int defaultUnits(String duration) => 1;

  static int maxUnits(String duration) {
    switch (duration) {
      case 'Hourly':
        return 12;
      case 'Daily':
        return 14;
      case 'Weekly':
        return 4;
      case 'Monthly':
        return 6;
      default:
        return 1;
    }
  }

  static String unitLabel(String duration) {
    switch (duration) {
      case 'Hourly':
        return 'hours';
      case 'Daily':
        return 'days';
      case 'Weekly':
        return 'weeks';
      case 'Monthly':
        return 'months';
      default:
        return 'units';
    }
  }

  static DateTime? rentalEndsAt({
    required String duration,
    required int units,
    DateTime? from,
  }) {
    final u = units.clamp(1, maxUnits(duration));
    final start = from ?? DateTime.now();
    switch (duration) {
      case 'Hourly':
        return start.add(Duration(hours: u));
      case 'Daily':
        return start.add(Duration(days: u));
      case 'Weekly':
        return start.add(Duration(days: 7 * u));
      case 'Monthly':
        return start.add(Duration(days: 30 * u));
      default:
        return null;
    }
  }

  static DateTime? reminderOneHourBefore(DateTime end) {
    final at = end.subtract(const Duration(hours: 1));
    if (!at.isAfter(DateTime.now())) return null;
    return at;
  }

  static String humanEnd(String duration, int units, DateTime end) {
    final u = units.clamp(1, maxUnits(duration));
    final label = unitLabel(duration);
    final when = _formatLocal(end);
    return 'Your $duration plan ($u $label) ends around $when.';
  }

  static String _formatLocal(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year} · $h:$m $ap';
  }
}
