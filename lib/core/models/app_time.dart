class AppTime {
  final int hour;
  final int minute;

  const AppTime({required this.hour, required this.minute});

  factory AppTime.now() {
    final now = DateTime.now();
    return AppTime(hour: now.hour, minute: now.minute);
  }

  factory AppTime.fromDateTime(DateTime value) {
    return AppTime(hour: value.hour, minute: value.minute);
  }

  DateTime toDateTime({DateTime? baseDate}) {
    final base = baseDate ?? DateTime.now();
    return DateTime(base.year, base.month, base.day, hour, minute);
  }
}
