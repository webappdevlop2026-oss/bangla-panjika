import '../lib/holiday_calendar.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  final october = HolidayCalendar.forMonth(DateTime(2026, 10));
  final octoberDays = october.map((h) => h.date.day).toList();
  const expected = [
    2,
    4,
    10,
    11,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
  ];
  check(
    octoberDays.join(',') == expected.join(','),
    'October official + Sunday dates',
  );
  final november = HolidayCalendar.forMonth(DateTime(2026, 11));
  check(
    november.map((h) => h.date.day).join(',') ==
        '1,8,9,10,11,12,15,16,22,24,29',
    'November public, state and Sunday dates',
  );
  for (var m = 1; m <= 12; m++) {
    final days = HolidayCalendar.forMonth(DateTime(2026, m));
    check(
      days.map((h) => h.date).toSet().length == days.length,
      'No duplicate holiday dates',
    );
    check(
      days.every((h) => h.date.year == 2026 && h.date.month == m),
      'Month isolation',
    );
    check(
      days.every((h) => !RegExp('কেনার|শুভ দিন|নক্ষত্র|তিথি').hasMatch(h.name)),
      'No auspicious activities or astronomy in holidays',
    );
  }
  final may = HolidayCalendar.forMonth(DateTime(2026, 5));
  check(may.any((h) => h.date.day == 28), 'Amended Bakrid date');
  check(
    !may.any((h) => h.date.day == 26 || h.date.day == 27),
    'Cancelled dates omitted',
  );
  final september = HolidayCalendar.forMonth(DateTime(2026, 9));
  check(
    september.any((h) => h.date.day == 18) &&
        !september.any((h) => h.date.day == 17),
    'Amended Viswakarma holiday',
  );
  final january = HolidayCalendar.forMonth(DateTime(2026, 13));
  check(!HolidayCalendar.hasPublishedList(2027), 'Unpublished year explicit');
  check(
    january.every(
      (h) =>
          h.date.year == 2027 &&
          h.date.month == 1 &&
          h.date.weekday == DateTime.sunday,
    ),
    'Year rollover must not invent festival dates',
  );
  print(
    'PASS: October/November dates, all-month isolation, duplicates, exclusions, amendments, year rollover',
  );
}
