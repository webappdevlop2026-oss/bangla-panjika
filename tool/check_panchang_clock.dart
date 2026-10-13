// Runs the actual calculation code without Flutter or copied model formulas.
// Usage: dart tool/check_panchang_clock.dart [path/to/main.dart]
import 'dart:io';

Future<void> main(List<String> args) async {
  final source = File(args.isEmpty ? 'lib/main.dart' : args.single)
      .readAsStringSync();
  final start = source.indexOf('class TithiInfo {');
  final end = source.indexOf('class CalendarEvent {', start);
  final helperStart = source.indexOf('DateTime panchangInstant(');
  final helperEnd = source.indexOf(';', helperStart) + 1;
  if (start < 0 || end < 0 || helperStart < 0 || helperEnd <= helperStart) {
    throw StateError(
      'Calculation source boundaries changed; update this check.',
    );
  }
  final temp = Directory.systemTemp.createTempSync('panchang-clock-');
  try {
    final probe = File('${temp.path}/probe.dart');
    probe.writeAsStringSync('''
import 'dart:math' as math;
class AppLocation { static double lat = 22.5726, lon = 88.3639; }
class AppSettings { static final instance = AppSettings(); bool isBangla = true; }
${source.substring(helperStart, helperEnd)}
${source.substring(start, end)}
$_checks
''');
    String? baseline;
    for (final zone in [
      'UTC',
      'Asia/Kolkata',
      'Asia/Dhaka',
      'America/New_York',
    ]) {
      final result = await Process.run(
        Platform.resolvedExecutable,
        [probe.path],
        environment: {'TZ': zone},
      );
      if (result.exitCode != 0) {
        stderr.write('$zone: ${result.stderr}${result.stdout}');
        exitCode = 1;
        return;
      }
      final output = result.stdout.toString();
      baseline ??= output;
      if (output != baseline)
        throw StateError('Results depend on device timezone: $zone');
      stdout.writeln(
        'PASS $zone: 76 date/location samples, tithi transitions, lunar horizon crossings, daily windows, instant conversion',
      );
    }
  } finally {
    temp.deleteSync(recursive: true);
  }
}

const _checks = r'''
void check(bool ok, String message) {
  if (!ok) throw StateError(message);
}
void main() {
  final dates = [
    for (final year in [2025, 2026, 2027])
      for (var month = 1; month <= 12; month++) DateTime.utc(year, month, 13, 12),
    DateTime.utc(2026, 10, 11, 12), DateTime.utc(2026, 12, 31, 12),
  ];
  for (final location in [(22.5726, 88.3639), (28.6139, 77.2090)]) {
    AppLocation.lat = location.$1; AppLocation.lon = location.$2;
    for (final day in dates) {
      final label = '$day $location';
      final sun = PanchangCalculator.sunTimes(day);
      check(sun.sunrise.isBefore(sun.sunset), 'Solar order $label');
      final timing = PanchangCalculator.tithiTiming(day);
      final idx = PanchangCalculator.tithiFor(day).index;
      check(timing.$1.isUtc && timing.$2.isUtc, 'Lost IST marker $label');
      check(timing.$1.isBefore(day) && timing.$2.isAfter(day), 'Tithi containment $label');
      check(PanchangCalculator.tithiFor(timing.$1.subtract(Duration(minutes: 1))).index != idx,
          'Tithi start is not a transition $label');
      check(PanchangCalculator.tithiFor(timing.$2.add(Duration(minutes: 1))).index != idx,
          'Tithi end is not a transition $label');
      final actual = day.subtract(Duration(hours: 5, minutes: 30));
      final local = actual.toLocal();
      check(PanchangCalculator.tithiFor(local).index == idx, 'Same instant disagrees $label');
      final localTiming = PanchangCalculator.tithiTiming(local);
      for (final pair in [(timing.$1, localTiming.$1), (timing.$2, localTiming.$2)]) {
        check(panchangInstant(pair.$1).difference(pair.$2).inSeconds.abs() <= 1,
            'Local/IST boundary disagreement $label');
      }
      check(panchangInstant(day).isAtSameMomentAs(actual), 'Wrong actual instant $label');
      check(panchangInstant(local).isAtSameMomentAs(actual), 'Changed local instant $label');
      final moon = PanchangCalculator.moonRiseSet(day);
      for (final entry in [(moon.$1, true), (moon.$2, false)]) {
        final t = entry.$1;
        if (t == null) continue; // Some civil days legitimately lack a crossing.
        check(t.isUtc, 'Moon lost IST marker $label');
        check(t.year == day.year && t.month == day.month && t.day == day.day,
            'Moon crossing outside civil day $label');
        double altitude(DateTime at) => PanchangCalculator.celestialAltAz('moon', at)['altitude']! - 0.125;
        final before = altitude(t.subtract(Duration(minutes: 1)));
        final after = altitude(t.add(Duration(minutes: 1)));
        check(entry.$2 ? before < 0 && after > 0 : before > 0 && after < 0,
            'Moon time is not a horizon crossing $label');
      }
      for (final window in [PanchangCalculator.rahuKalam(day), PanchangCalculator.yamagandaKalam(day), PanchangCalculator.gulikaKalam(day)]) {
        check(!window['start']!.isBefore(sun.sunrise) && !window['end']!.isAfter(sun.sunset),
            'Daylight window outside daylight $label');
        check(window['end']!.difference(window['start']!).inSeconds ==
            (sun.sunset.difference(sun.sunrise) ~/ 8).inSeconds, 'Wrong window duration $label');
      }
      final abhijit = PanchangCalculator.abhijitMuhurta(day);
      check((abhijit['end'] as DateTime).difference(abhijit['start'] as DateTime).inSeconds ==
          (sun.sunset.difference(sun.sunrise) ~/ 15).inSeconds, 'Abhijit duration $label');
      print('$label ${timing.$1} ${timing.$2} $moon');
    }
  }
}
''';
