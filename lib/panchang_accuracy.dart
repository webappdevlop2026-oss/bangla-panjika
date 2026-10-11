import 'dart:math' as math;

import 'package:astronomia/astronomia.dart' as astro;
import 'package:astronomia/coord.dart' as astro_coord;
import 'package:astronomia/moonposition.dart' as astro_moon;
import 'package:astronomia/rise.dart' as astro_rise;
import 'package:astronomia/sidereal.dart' as astro_sid;
import 'package:astronomia/solar.dart' as astro_solar;
import 'package:astronomia/sunrise.dart' as astro_sunrise;

/// High-accuracy astronomical calculations used by the Panchang layer.
///
/// The existing app represents Panchang clock values as UTC-tagged DateTimes
/// whose *wall clock fields* are IST. These helpers intentionally preserve that
/// convention so existing UI (bnTime12, panchangInstant, etc.) keeps working
/// without a large risky refactor.
class AccurateSunTimes {
  final DateTime sunrise;
  final DateTime sunset;
  const AccurateSunTimes(this.sunrise, this.sunset);
}

class AccurateMoonTimes {
  final DateTime? moonrise;
  final DateTime? moonset;
  const AccurateMoonTimes(this.moonrise, this.moonset);
}

class PanchangAccuracy {
  PanchangAccuracy._();

  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  static double _norm360(double x) {
    var v = x % 360.0;
    if (v < 0) v += 360.0;
    return v;
  }

  /// Apparent geocentric solar longitude (Meeus), including nutation
  /// and aberration; used for tithi, yoga and solar-month boundaries.
  static double sunLongitudeDegrees(double jd) =>
      _norm360(astro.toDeg(astro_solar.apparentLongitude(astro.j2000Century(jd))));

  /// Full Meeus lunar position instead of the old heavily truncated series.
  static double moonLongitudeDegrees(double jd) =>
      _norm360(astro.toDeg(astro_moon.position(jd).lon));

  static double moonLatitudeDegrees(double jd) =>
      astro.toDeg(astro_moon.position(jd).lat);

  static DateTime _jdToIstMarked(double jd) {
    final millis = ((jd - 2440587.5) * 86400000).round();
    final utc = DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    return utc.add(_istOffset);
  }

  /// Accurate sunrise/sunset using Astronomia's sampled/refined solar altitude
  /// algorithm. Longitude passed by the app is positive-east, while the
  /// library expects positive-west.
  static AccurateSunTimes sunTimes(
    DateTime localDate, {
    required double lat,
    required double lon,
  }) {
    final jd0 = astro.calendarGregorianToJD(
      localDate.year,
      localDate.month,
      localDate.day.toDouble(),
    );
    final result = astro_sunrise.sunriseSunset(
      jd0,
      astro.toRad(lat),
      astro.toRad(-lon),
    );

    // India is never in polar day/night; keep a defensive fallback so the app
    // cannot crash if impossible coordinates somehow reach this method.
    if (result.rise == null || result.set == null) {
      throw StateError('Sunrise/sunset unavailable for this location/date');
    }

    return AccurateSunTimes(
      _jdToIstMarked(result.rise!),
      _jdToIstMarked(result.set!),
    );
  }

  static bool _sameYmd(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime _utcSecondsToIstMarked(DateTime utcDay, double seconds) {
    final utc = utcDay.add(
      Duration(milliseconds: (seconds * 1000).round()),
    );
    return utc.add(_istOffset);
  }

  /// Topocentric moonrise/moonset with lunar parallax correction (Meeus Ch.15).
  ///
  /// A local IST civil day overlaps two UT dates, so we calculate neighboring
  /// UT days and retain only events whose IST wall date equals [localDate].
  static AccurateMoonTimes moonTimes(
    DateTime localDate, {
    required double lat,
    required double lon,
  }) {
    final target = DateTime.utc(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    DateTime? riseFound;
    DateTime? setFound;

    for (final offset in const [-1, 0, 1]) {
      final utcDay = target.add(Duration(days: offset));
      final jd0 = astro.calendarGregorianToJD(
        utcDay.year,
        utcDay.month,
        utcDay.day.toDouble(),
      );
      final th0 = astro_sid.apparent0UT(jd0);

      final result = astro_rise.moonTimes(
        jd0,
        astro.toRad(lat),
        astro.toRad(-lon),
        69.0,
        th0,
        (jde) {
          final pos = astro_moon.position(jde);
          // True obliquity changes very slowly; this value is amply precise
          // for rise/set and follows the package's documented example.
          final eps = astro.toRad(23.44);
          final eq = astro_coord.eclToEq(
            pos.lon,
            pos.lat,
            math.sin(eps),
            math.cos(eps),
          );
          return (
            ra: eq.ra,
            dec: eq.dec,
            parallax: astro_moon.parallax(pos.delta),
          );
        },
      );

      if (result == null) continue;

      final rise = _utcSecondsToIstMarked(utcDay, result.rise);
      final set = _utcSecondsToIstMarked(utcDay, result.set);

      if (riseFound == null && _sameYmd(rise, target)) {
        riseFound = rise;
      }
      if (setFound == null && _sameYmd(set, target)) {
        setFound = set;
      }
    }

    return AccurateMoonTimes(riseFound, setFound);
  }
}
