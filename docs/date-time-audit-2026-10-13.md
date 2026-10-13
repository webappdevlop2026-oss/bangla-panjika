# Date/time audit — 13 October 2026

Scope: GitHub main bf73e33 plus the monthly-holiday branch. This is a source and calculation audit, not a certification of every screen or the client's installed APK. The client's uncommitted PC changes and installed build were not available. No Flutter SDK or attached Android device was available here.

## Corrected in this change

1. `PanchangCalculator.tithiTiming`: bisection discarded the UTC marker used by the app to encode IST wall-clock values. Midpoints and search bounds consequently represented different time domains. Preserve the input marker.
2. `PanchangCalculator.moonRiseSet`: the same loss occurred during horizon-crossing refinement. Preserve the bounds' marker.
3. `panchangInstant`: constructing device-local clock fields from IST values shifted the actual instant on non-IST devices. Subtract the IST offset before converting to device local time, and leave already-local inputs unchanged. This brings the shared helper into agreement with the existing `_actual` helpers.

Example, Kolkata on 13 October 2026, noon IST input:

| Calculation | Before | After clock fixes | Published comparison |
|---|---|---|---|
| Tritiya ends | 18:00 | 23:01 | 23:27 |
| Moonrise | 13:10 | 07:48 | 07:51 |
| Moonset | 00:10 next day | 18:47 | 18:43 |
| Sunrise | 05:33 | 05:33 | 05:32 |
| Sunset | 17:14 | 17:14 | 17:13 |
| Bengali civil date | 25 Ashwin 1433 | unchanged | 26 Ashwin 1433 |

Times in this table are IST; seconds are omitted. Before-values are from the actual calculation source running with device timezone Asia/Kolkata. Published comparison: [Drik Panchang, Kolkata, Bisuddhasiddhanta, 13 October 2026](https://www.drikpanchang.com/bengali/bengali-month-panjika.html?geoname-id=1275004), retrieved 13 October. The linked monthly page changes with the current date. Differences demonstrate that clock repair alone does not establish astronomical or calendar accuracy.

## Outstanding findings

- **Astronomical precision:** the existing truncated lunar model still differs from the comparison by about 26 minutes for this tithi transition. The alternative accuracy branch gives approximately 23:29 in a standalone calculation, but has not been integrated or Flutter-tested. Do not present this patch as a full ephemeris correction.
- **Bengali month baseline:** `_monthStart` explicitly adds an extra day for Bhadra and Ashwin in 2026, producing the one-day discrepancy above. Its comments say it was requested to match a different published calendar. Resolve the intended calendar tradition/reference before removing this override; changing it also affects festival rules and Bengali dates across screens.
- **Location consistency:** `AppLocation.lat/lon` always prefer available GPS, while `select` changes only the district name. Several headings still display that selected district. Consequently the displayed district and coordinates used for calculations can disagree. Location selection and GPS priority need one explicit product rule.
- **Nighttime festival reference:** the live panel's `_festivalTithiTiming` constructs 23:59 using device-local `DateTime`, while festival generation uses the IST marker. These can choose different reference instants outside IST. Review all civil-day/reference-time construction together; this patch does not claim that all screens work internationally.
- **Branch regression risk:** replacing main wholesale with `calendar-accuracy-fix-205` removes timezone initialization and mandatory-update changes, broadens the 2026 month override to other years, and reintroduces fixed-length Abhijit calculation in one path. Selective integration is required.
- **Notifications and live UI:** real alarm delivery, midnight rollover, background/resume, countdown rendering, manual district/GPS changes and the client's installed version still need device verification. Their behavior is not covered by standalone arithmetic tests.

## Verification

`dart tool/check_panchang_clock.dart` extracts the real calculation classes from `lib/main.dart` into a temporary dependency-free probe. No copied astronomical implementation is used. It tests 38 dates spanning all months of 2025–2027 at Kolkata and Delhi coordinates, under UTC, Asia/Kolkata, Asia/Dhaka and America/New_York on Linux: 304 date/location/timezone combinations.

Checks: tithi containment and crossings on both sides, equivalence of local and IST representations, actual-instant conversion, lunar horizon crossings and civil-day containment, daytime interval containment/length, Abhijit daylight/15 duration, and identical marked calculation results across timezones. These are consistency tests, not independent accuracy fixtures.

The previous source fails with `Lost IST marker`; the corrected source passes all four timezone runs. Analyzer reports no issues in the two standalone tools; full Flutter analysis/build was not run. The patch installer was tested against the previous source and tested a second time for idempotence. It validates all replacements before writing and saves a timestamped backup. Unknown source variants stop without modifying the app.

Holiday data tests remain separate: `dart tool/check_holidays.dart`. The holiday screen is limited to its published 2026 list; later years do not silently reuse that year's holidays.
