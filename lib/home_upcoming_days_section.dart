part of 'main.dart';

class _UpcomingImportantDay {
  final DateTime date;
  final CalendarEvent event;
  const _UpcomingImportantDay(this.date, this.event);
}

class UpcomingImportantDaysSection extends StatefulWidget {
  const UpcomingImportantDaysSection({super.key});

  @override
  State<UpcomingImportantDaysSection> createState() =>
      _UpcomingImportantDaysSectionState();
}

class _UpcomingImportantDaysSectionState
    extends State<UpcomingImportantDaysSection> {
  final AudioPlayer _dhakPlayer = AudioPlayer();

  @override
  void dispose() {
    _dhakPlayer.dispose();
    super.dispose();
  }

  Future<void> _playDhak() async {
    try {
      await _dhakPlayer.stop();
      await _dhakPlayer.play(AssetSource('audio/dhak_click.ogg'));
    } catch (_) {
      // Sound must never block the card action.
    }
  }

  static const _majorKeywords = <String>[
    'দুর্গা',
    'মহালয়া',
    'মহালয়া',
    'ষষ্ঠী',
    'সপ্তমী',
    'অষ্টমী',
    'নবমী',
    'দশমী',
    'লক্ষ্মী',
    'কালী',
    'দীপাবলি',
    'সরস্বতী',
    'জগদ্ধাত্রী',
    'বিশ্বকর্মা',
    'গণেশ',
    'শিবরাত্রি',
    'জন্মাষ্টমী',
    'রাম নবমী',
    'দোল',
    'হোলি',
    'রথ',
    'ভাইফোঁটা',
    'রাখী',
    'নববর্ষ',
    'পয়লা বৈশাখ',
    'পয়লা বৈশাখ',
    'ছট',
    'পূর্ণিমা',
    'অমাবস্যা',
    'একাদশী',
    'পূজা',
    'পুজো',
    'উৎসব',
  ];

  bool _important(CalendarEvent e) =>
      _majorKeywords.any((keyword) => e.label.contains(keyword));

  List<_UpcomingImportantDay> _days() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final result = <_UpcomingImportantDay>[];
    final seen = <String>{};

    for (var i = 0; i < 120 && result.length < 10; i++) {
      final day = start.add(Duration(days: i));
      final events = BengaliCalendarData.eventsFor(day);
      for (final event in events) {
        if (!_important(event)) continue;
        final key = '${day.year}-${day.month}-${day.day}-${event.label}';
        if (!seen.add(key)) continue;
        result.add(_UpcomingImportantDay(day, event));
        if (result.length >= 10) break;
      }
    }
    return result;
  }

  String _weekday(DateTime d) {
    const names = [
      'সোমবার',
      'মঙ্গলবার',
      'বুধবার',
      'বৃহস্পতিবার',
      'শুক্রবার',
      'শনিবার',
      'রবিবার',
    ];
    return names[d.weekday - 1];
  }

  String _daysLeft(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = d.difference(today).inDays;
    if (diff <= 0) return 'আজ';
    if (diff == 1) return 'আগামীকাল';
    return '${bnNum(diff)} দিন বাকি';
  }

  Color _accentFor(String label) {
    if (label.contains('দুর্গা') ||
        label.contains('অষ্টমী') ||
        label.contains('নবমী') ||
        label.contains('দশমী')) {
      return const Color(0xFFC62828);
    }
    if (label.contains('কালী') || label.contains('অমাবস্যা')) {
      return const Color(0xFF172554);
    }
    if (label.contains('লক্ষ্মী') || label.contains('পূর্ণিমা')) {
      return const Color(0xFFD97706);
    }
    return const Color(0xFFB91C1C);
  }

  IconData _iconFor(String label) {
    if (label.contains('কালী') || label.contains('অমাবস্যা')) {
      return Icons.nightlight_round;
    }
    if (label.contains('লক্ষ্মী')) return Icons.local_florist_rounded;
    if (label.contains('ছট')) return Icons.wb_sunny_rounded;
    if (label.contains('ভাইফোঁটা')) return Icons.favorite_rounded;
    return Icons.temple_hindu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final items = _days();
    if (items.isEmpty) return const SizedBox.shrink();

    final wide = MediaQuery.sizeOf(context).width >= 900;
    final cardWidth = wide ? 235.0 : 168.0;
    final cardHeight = wide ? 238.0 : 214.0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        wide ? 20 : 14,
        wide ? 18 : 14,
        wide ? 20 : 14,
        wide ? 18 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E2D4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFC81018),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'আসন্ন গুরুত্বপূর্ণ দিনগুলো',
                      style: TextStyle(
                        color: Color(0xFF8E1010),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'পূজা, উৎসব, তিথি ও বিশেষ দিনের তারিখ এক নজরে',
                      style: TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BengaliCalendarScreen(),
                  ),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text(
                  'সব দেখুন',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9D1515),
                  backgroundColor: const Color(0xFFFFE1DE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final label = item.event.label;
                final accent = _accentFor(label);
                return SizedBox(
                  width: cardWidth,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await _playDhak();
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BengaliCalendarScreen(),
                        ),
                      );
                    },
                    child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE8E1DA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: wide ? 104 : 82,
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/durga_puja_home.webp',
                                fit: BoxFit.cover,
                                alignment: Alignment.center,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      accent.withValues(alpha: 0.30),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.42),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.volume_up_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'ঢাক',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
                            child: Column(
                              children: [
                                Text(
                                  '${item.event.icon} $label',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: wide ? 16 : 14,
                                    height: 1.05,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${bnNum(item.date.day)} ${gregMonthBn(item.date.month)} ${bnNum(item.date.year)}',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    color: Color(0xFF3F4858),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _weekday(item.date),
                                  style: const TextStyle(
                                    color: Color(0xFF667085),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _daysLeft(item.date),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              },
            ),
          ),
        ],
      ),
    );
  }
}
