/// Holiday data is separate from astrological events: never use eventsFor here.
/// West Bengal Finance Department 4188-F(P2), Lists I and II and Sunday notes.
/// https://wb.gov.in/pdf/Holiday-2026.pdf
/// Amendments: 1814-F(P2), 22 May; 3446-F(P2), 14 September 2026.
class HolidayCalendar {
  static const sourceUrl = 'https://wb.gov.in/pdf/Holiday-2026.pdf';
  static const _public2026 = <String, String>{
    '01-01': 'ইংরেজি নববর্ষ',
    '01-12': 'স্বামী বিবেকানন্দ জন্মদিন',
    '01-23': 'নেতাজি জন্মজয়ন্তী ও সরস্বতী পূজা',
    '01-26': 'প্রজাতন্ত্র দিবস',
    '03-03': 'দোলযাত্রা',
    '03-21': 'ঈদ-উল-ফিতর',
    '03-26': 'রাম নবমী',
    '03-31': 'মহাবীর জয়ন্তী',
    '04-03': 'গুড ফ্রাইডে',
    '04-14': 'ড. বি. আর. আম্বেদকর জন্মদিন',
    '04-15': 'বাংলা নববর্ষ',
    '05-01': 'শ্রমিক দিবস ও বুদ্ধ পূর্ণিমা',
    '05-09': 'রবীন্দ্রনাথ ঠাকুর জন্মদিন',
    '05-28': 'ঈদ-উদ্-জোহা (বকরি ঈদ)',
    '06-26': 'মহরম',
    '08-15': 'স্বাধীনতা দিবস',
    '09-04': 'জন্মাষ্টমী',
    '10-02': 'গান্ধী জয়ন্তী',
    '10-10': 'মহালয়া',
    '10-19': 'দুর্গাপূজা — মহাষ্টমী',
    '10-20': 'দুর্গাপূজা — মহানবমী',
    '10-21': 'দুর্গাপূজা — বিজয়া দশমী',
    '11-11': 'ভাইফোঁটা',
    '11-24': 'গুরু নানক জন্মদিন',
    '12-25': 'বড়দিন',
  };
  static const _state2026 = <String, String>{
    '01-22': 'সরস্বতী পূজার আগের দিন',
    '02-04': 'শবেবরাত',
    '02-14': 'ঠাকুর পঞ্চানন বর্মা জন্মদিন',
    '03-04': 'হোলি',
    '03-17': 'শ্রীশ্রী হরিচাঁদ ঠাকুর জন্মদিন',
    '03-20': 'ঈদ-উল-ফিতরের আগের দিন',
    '07-16': 'রথযাত্রা',
    '08-26': 'ফতেহা-দোয়াজ-দাহাম',
    '08-28': 'রাখিবন্ধন',
    '09-18': 'বিশ্বকর্মা পূজা',
    '10-15': 'দুর্গাপূজা — মহাচতুর্থী',
    '10-16': 'দুর্গাপূজা — মহাপঞ্চমী',
    '10-17': 'দুর্গাপূজা — মহাষষ্ঠী',
    '10-22': 'দুর্গাপূজার অতিরিক্ত ছুটি',
    '10-23': 'দুর্গাপূজার অতিরিক্ত ছুটি',
    '10-24': 'দুর্গাপূজার অতিরিক্ত ছুটি',
    '10-26': 'লক্ষ্মীপূজার অতিরিক্ত ছুটি',
    '11-09': 'কালীপূজার অতিরিক্ত ছুটি',
    '11-10': 'কালীপূজার অতিরিক্ত ছুটি',
    '11-12': 'ভাইফোঁটার পরের দিন',
    '11-16': 'ছট পূজার অতিরিক্ত ছুটি',
  };
  static const _sundayNames2026 = <String, String>{
    '02-15': 'মহাশিবরাত্রি',
    '10-18': 'দুর্গাপূজা — মহাসপ্তমী',
    '10-25': 'কোজাগরী লক্ষ্মীপূজা',
    '11-08': 'কালীপূজা',
    '11-15': 'ছট পূজা ও বিরসা মুন্ডা জন্মদিন',
  };

  static bool hasPublishedList(int year) => year == 2026;

  static List<HolidayDay> forMonth(DateTime month) {
    final result = <HolidayDay>[];
    final last = DateTime(month.year, month.month + 1, 0).day;
    for (var day = 1; day <= last; day++) {
      final date = DateTime(month.year, month.month, day);
      final key =
          '${date.month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}';
      final known = hasPublishedList(date.year);
      final publicName = known ? _public2026[key] : null;
      final stateName = known ? _state2026[key] : null;
      final sunday = date.weekday == DateTime.sunday;
      final sundayName = known ? _sundayNames2026[key] : null;
      if (publicName == null && stateName == null && !sunday) continue;
      result.add(
        HolidayDay(
          date,
          publicName ?? stateName ?? sundayName ?? 'রবিবার',
          publicName != null
              ? 'সরকারি ঘোষিত ছুটি'
              : stateName != null
              ? 'রাজ্য সরকারি দপ্তরের ছুটি'
              : 'সাপ্তাহিক ছুটি — রবিবার',
        ),
      );
    }
    return result;
  }
}

class HolidayDay {
  final DateTime date;
  final String name;
  final String kind;
  const HolidayDay(this.date, this.name, this.kind);
}
