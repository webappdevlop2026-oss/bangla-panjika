import 'package:flutter_test/flutter_test.dart';
import 'package:bangla_panjika_native/main.dart';

int _minutesOfDay(DateTime value) => value.hour * 60 + value.minute;

void main() {
  group('Panchang regression - Kolkata 11 Oct 2026', () {
    final sample = DateTime.utc(2026, 10, 11, 12);
    const lat = 22.5726;
    const lon = 88.3639;

    test('sunrise, sunset and lunar events stay close to published Panchang', () {
      final sun = PanchangCalculator.sunTimes(sample, lat: lat, lon: lon);
      final moon = PanchangCalculator.moonTimes(sample, lat: lat, lon: lon);

      expect((_minutesOfDay(sun.sunrise) - (5 * 60 + 31)).abs(), lessThanOrEqualTo(5));
      expect((_minutesOfDay(sun.sunset) - (17 * 60 + 15)).abs(), lessThanOrEqualTo(5));

      final rise = moon['rise'];
      final set = moon['set'];
      expect(rise, isNotNull);
      expect(set, isNotNull);
      expect((_minutesOfDay(rise!) - (5 * 60 + 58)).abs(), lessThanOrEqualTo(10));
      expect((_minutesOfDay(set!) - (17 * 60 + 25)).abs(), lessThanOrEqualTo(10));
    });

    test('tithi boundary preserves IST wall-clock domain', () {
      final tithi = PanchangCalculator.tithiFor(sample);
      expect(tithi.paksha, 'শুক্ল');
      expect(tithi.name, 'প্রতিপদ');

      final timing = PanchangCalculator.tithiTiming(sample);
      final expectedEnd = DateTime.utc(2026, 10, 11, 21, 30);
      expect(
        timing.$2.difference(expectedEnd).inMinutes.abs(),
        lessThanOrEqualTo(10),
      );
    });

    test('nakshatra and yoga use nirayana positions', () {
      final nak = PanchangCalculator
          .nakshatraNames[PanchangCalculator.nakshatraIndexFor(sample)];
      final yoga = PanchangCalculator
          .yogaNames[PanchangCalculator.yogaIndexFor(sample)];

      expect(nak, 'চিত্রা');
      expect(yoga, 'বৈধৃতি');
    });

    test('Rahu, Gulika and Yamaganda agree with daylight eighths', () {
      final rahu = PanchangCalculator.rahuKalam(sample, lat: lat, lon: lon);
      final gulika = PanchangCalculator.gulikaKalam(sample, lat: lat, lon: lon);
      final yama = PanchangCalculator.yamagandaKalam(sample, lat: lat, lon: lon);

      expect((_minutesOfDay(rahu['start']!) - (15 * 60 + 47)).abs(), lessThanOrEqualTo(5));
      expect((_minutesOfDay(rahu['end']!) - (17 * 60 + 15)).abs(), lessThanOrEqualTo(5));
      expect((_minutesOfDay(gulika['start']!) - (14 * 60 + 19)).abs(), lessThanOrEqualTo(5));
      expect((_minutesOfDay(yama['start']!) - (11 * 60 + 23)).abs(), lessThanOrEqualTo(5));
    });

    test('Abhijit is the eighth of fifteen daylight muhurtas', () {
      final abhijit = PanchangCalculator.abhijitMuhurta(sample, lat: lat, lon: lon);
      expect(abhijit['applicable'], true);
      final start = abhijit['start'] as DateTime;
      final end = abhijit['end'] as DateTime;
      expect((_minutesOfDay(start) - (11 * 60)).abs(), lessThanOrEqualTo(5));
      expect((_minutesOfDay(end) - (11 * 60 + 47)).abs(), lessThanOrEqualTo(5));
    });
  });
}
