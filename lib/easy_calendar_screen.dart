part of 'main.dart';

/// Traditional Bengali panjika inspired calendar with a clean mobile layout.
class EasyBengaliCalendarScreen extends StatefulWidget {
  const EasyBengaliCalendarScreen({super.key});

  @override
  State<EasyBengaliCalendarScreen> createState() =>
      _EasyBengaliCalendarScreenState();
}

class _EasyBengaliCalendarScreenState
    extends State<EasyBengaliCalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _anchor = DateTime.now();
  static const _weekdays = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];

  late final AnimationController _festivalPulseController;

  @override
  void initState() {
    super.initState();
    _festivalPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _festivalPulseController.dispose();
    super.dispose();
  }

  bool _isMajorFestival(List<CalendarEvent> events) {
    if (events.isEmpty) return false;
    const keywords = <String>[
      'দুর্গা',
      'মহালয়া',
      'মহালয়া',
      'কালী',
      'দীপাবলি',
      'লক্ষ্মী',
      'সরস্বতী',
      'জগদ্ধাত্রী',
      'বিশ্বকর্মা',
      'গণেশ',
      'শিবরাত্রি',
      'জন্মাষ্টমী',
      'রাম নবমী',
      'দোল',
      'হোলি',
      'রথযাত্রা',
      'রথ',
      'ভাইফোঁটা',
      'রাখী',
      'নববর্ষ',
      'পয়লা বৈশাখ',
      'পয়লা বৈশাখ',
      'ছট',
      'পূজা',
      'পুজো',
      'উৎসব',
    ];
    return events.any(
      (event) => keywords.any((keyword) => event.label.contains(keyword)),
    );
  }

  void _changeMonth(int direction) {
    final info = BengaliDateUtil.monthInfoFor(_anchor);
    setState(() {
      _anchor = direction < 0
          ? info.start.subtract(const Duration(days: 1))
          : info.end.add(const Duration(days: 1));
    });
  }

  void _goToday() => setState(() => _anchor = DateTime.now());

  @override
  Widget build(BuildContext context) {
    final info = BengaliDateUtil.monthInfoFor(_anchor);
    final totalDays = info.end.difference(info.start).inDays + 1;
    final leading = info.start.weekday % 7;
    final trailing = (7 - ((leading + totalDays) % 7)) % 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7D1010),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: const Color(0xFF7D1010),
        titleSpacing: 6,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'বাংলা পঞ্জিকা',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ),
            Text(
              'তিথি • উৎসব • শুভদিন',
              style: TextStyle(
                color: Color(0xFFFFDFA0),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _goToday,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFE8A6),
              ),
              icon: const Icon(Icons.today_rounded, size: 17),
              label: const Text(
                'আজ',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(3),
          child: SizedBox(
            height: 3,
            child: ColoredBox(color: Color(0xFFD6A33B)),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 28),
          children: [
            _buildMonthTitle(info),
            const SizedBox(height: 10),
            _buildMonthlyAuspiciousDays(info),
            const SizedBox(height: 10),
            _buildWeekHeader(),
            const SizedBox(height: 3),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: const Color(0xFFE4DDD3),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leading + totalDays + trailing,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                ),
                itemBuilder: (context, index) {
                  if (index < leading || index >= leading + totalDays) {
                    return Container(
                      color: const Color(0xFFF1E4D0),
                    );
                  }

                  final bengaliDay = index - leading + 1;
                  final greg =
                      info.start.add(Duration(days: bengaliDay - 1));
                  return _dayCell(greg, bengaliDay, info);
                },
              ),
            ),
            const SizedBox(height: 10),
            _buildLegend(),
            const SizedBox(height: 8),
            const Text(
              'যে কোনো তারিখে চাপলে তিথি, উৎসব ও বিশেষ দিনের বিস্তারিত দেখা যাবে',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6C5A47),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthTitle(dynamic info) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3D4C1), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            color: const Color(0xFF8B1515),
            child: const Text(
              'বাংলা মাসিক পঞ্জিকা',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFE6A7),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(4, 11, 4, 11),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFF5E6),
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'আগের মাস',
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded, size: 34),
                  color: const Color(0xFF8D1515),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${info.name} ${bnNum(info.year)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF8D1515),
                          fontSize: 31,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${bnNum(info.start.day)} ${gregMonthBn(info.start.month)} '
                        '- ${bnNum(info.end.day)} ${gregMonthBn(info.end.month)} '
                        '${bnNum(info.end.year)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6B4B2A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'পরের মাস',
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded, size: 34),
                  color: const Color(0xFF8D1515),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMonthlyAuspiciousDays(dynamic info) {
    const categories = <String, (String, String)>{
      'marriage': ('💍', 'বিবাহ'),
      'griha': ('🏠', 'গৃহপ্রবেশ'),
      'annaprashan': ('👶', 'অন্নপ্রাশন'),
      'byabosha': ('🪔', 'ব্যবসা শুরু'),
      'namakaran': ('📿', 'নামকরণ'),
      'jomi': ('🏞️', 'জমি কেনা'),
      'bari': ('🏡', 'বাড়ি কেনা'),
      'gari': ('🚗', 'গাড়ি কেনা'),
    };

    final items = <(String icon, String title, String dates)>[];

    for (final entry in categories.entries) {
      final dates = <DateTime>[];

      for (DateTime day = info.start;
          !day.isAfter(info.end);
          day = day.add(const Duration(days: 1))) {
        final hasCategory = BengaliCalendarData.eventsFor(day)
            .any((event) => event.category == entry.key);
        if (!hasCategory) continue;
        dates.add(day);
      }

      if (dates.isEmpty) continue;

      final dateText = dates.map((d) {
        final bDay = d.difference(info.start).inDays + 1;
        return bnNum(bDay);
      }).join(', ');

      items.add((entry.value.$1, entry.value.$2, dateText));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _MonthlyAuspiciousTicker(
      monthName: info.name,
      year: info.year,
      items: items,
    );
  }

  Widget _buildWeekHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        border: Border.all(color: const Color(0xFFC9C9C9)),
      ),
      child: Row(
        children: List.generate(_weekdays.length, (i) {
          return Expanded(
            child: Container(
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: i == 6
                    ? null
                    : const Border(
                        right: BorderSide(color: Color(0xFFCECECE)),
                      ),
              ),
              child: Text(
                _weekdays[i],
                style: TextStyle(
                  color: i == 0
                      ? const Color(0xFFD52B2B)
                      : const Color(0xFF0069A8),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLegend() {
    Widget chip(String label, Color bg, Color fg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: .2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        chip('আজ', const Color(0xFFFFE3A8), const Color(0xFF8A4D00)),
        chip('পূজা / উৎসব', const Color(0xFFFFDDD4), const Color(0xFFA61E14)),
        chip('একাদশী • পূর্ণিমা • অমাবস্যা', const Color(0xFFECE2F3), const Color(0xFF5B3374)),
      ],
    );
  }

  String _weekdayShort(DateTime date) {
    const names = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
    return names[date.weekday - 1];
  }

  String _shortCalendarLabel(
    dynamic tithi,
    List<CalendarEvent> events,
    List<CalendarEvent> filteredEvents,
  ) {
    final labels = events.map((e) => e.label).toList();

    for (final label in labels) {
      if (label.contains('মহাষষ্ঠী')) return 'মহাষষ্ঠী';
      if (label.contains('মহাসপ্তমী')) return 'মহাসপ্তমী';
      if (label.contains('মহাষ্টমী')) return 'মহাষ্টমী';
      if (label.contains('মহানবমী')) return 'মহানবমী';
      if (label.contains('বিজয়া দশমী') || label.contains('বিজয়া দশমী')) {
        return 'বিজয়া দশমী';
      }
      if (label.contains('দুর্গা')) return 'দুর্গাপূজা';
      if (label.contains('কালী')) return 'কালীপূজা';
      if (label.contains('লক্ষ্মী')) return 'লক্ষ্মীপূজা';
      if (label.contains('সরস্বতী')) return 'সরস্বতী পূজা';
      if (label.contains('জন্মাষ্টমী')) return 'জন্মাষ্টমী';
      if (label.contains('শিবরাত্রি')) return 'শিবরাত্রি';
      if (label.contains('একাদশী')) return 'একাদশী';
      if (label.contains('অমাবস্যা')) return 'অমাবস্যা';
      if (label.contains('পূর্ণিমা')) return 'পূর্ণিমা';
    }

    final name = tithi.name.toString();
    if (name.contains('অমাবস্যা')) return 'অমাবস্যা';
    if (name.contains('পূর্ণিমা')) return 'পূর্ণিমা';
    if (name.contains('একাদশী')) return 'একাদশী';
    if (name.contains('অষ্টমী')) return 'অষ্টমী';
    if (name.contains('নবমী')) return 'নবমী';
    if (name.contains('চতুর্দশী')) return 'চতুর্দশী';

    if (filteredEvents.isNotEmpty) {
      final label = filteredEvents.first.label;
      return label.length > 12 ? '${label.substring(0, 11)}…' : label;
    }
    return name;
  }

  String _majorFestivalIcon(List<CalendarEvent> events) {
    for (final e in events) {
      final label = e.label;
      if (label.contains('মহালয়া') || label.contains('মহালয়া')) return '👁️';
      if (label.contains('মহাষষ্ঠী') ||
          label.contains('মহাসপ্তমী') ||
          label.contains('মহাষ্টমী') ||
          label.contains('মহানবমী') ||
          label.contains('বিজয়া দশমী') ||
          label.contains('বিজয়া দশমী') ||
          label.contains('দুর্গা')) {
        return '🪔';
      }
      if (label.contains('লক্ষ্মী')) return '🪷';
      if (label.contains('কালী') || label.contains('দীপাবলি')) return '🪔';
      if (label.contains('সরস্বতী')) return '📖';
      if (label.contains('জন্মাষ্টমী')) return '🦚';
      if (label.contains('শিবরাত্রি')) return '🔱';
      if (label.contains('গণেশ')) return '🐘';
      if (label.contains('জগদ্ধাত্রী')) return '🦁';
      if (label.contains('রথ')) return '🛕';
      if (label.contains('ছট')) return '🌅';
      if (e.icon.trim().isNotEmpty) return e.icon;
    }
    return '🌺';
  }

  Widget _dayCell(DateTime greg, int bengaliDay, dynamic info) {
    final now = DateTime.now();
    final isToday = greg.year == now.year &&
        greg.month == now.month &&
        greg.day == now.day;
    final isSunday = greg.weekday == DateTime.sunday;
    final events = BengaliCalendarData.eventsFor(greg);
    final tithi = PanchangCalculator.tithiFor(greg);

    final filteredEvents = events;

    final shortLabel = _shortCalendarLabel(tithi, events, filteredEvents);
    final isMajorFestival = _isMajorFestival(events);

    final mainColor = isSunday
        ? const Color(0xFFD52B2B)
        : const Color(0xFF0069A8);

    return InkWell(
      onTap: () => _showDayDetails(greg, bengaliDay, info, tithi, events),
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFFFFF7D8)
              : const Color(0xFFF2F2F2),
          border: Border.all(
            color: isToday
                ? const Color(0xFF5D9CC7)
                : const Color(0xFFD0D0D0),
            width: isToday ? 1.6 : .7,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                bnNum(greg.day),
                style: TextStyle(
                  color: mainColor,
                  fontSize: 11.5,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    bnNum(bengaliDay),
                    maxLines: 1,
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 43,
                      height: .95,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            if (isMajorFestival || shortLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: SizedBox(
                  height: 18,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Text(
                      shortLabel,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isMajorFestival
                            ? const Color(0xFFD52B2B)
                            : const Color(0xFF0069A8),
                        fontSize: 10.5,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDayDetails(
    DateTime greg,
    int bengaliDay,
    dynamic info,
    dynamic tithi,
    List<CalendarEvent> events,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFCF7),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD3B88C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 105,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF3DF),
                        Color(0xFFFFE3D6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE6C9A8)),
                  ),
                  child: Center(
                    child: Text(
                      _majorFestivalIcon(events),
                      style: const TextStyle(fontSize: 58),
                    ),
                  ),
                ),
                Text(
                  '${bnNum(bengaliDay)} ${info.name} ${bnNum(info.year)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8D1515),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${PanchangCalculator.weekdayName(greg)} • '
                  '${bnNum(greg.day)} ${gregMonthBn(greg.month)} '
                  '${bnNum(greg.year)}',
                  style: const TextStyle(
                    color: Color(0xFF6C5A47),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Divider(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4E6D2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD9B77C)),
                  ),
                  child: Text(
                    'তিথি: ${tithi.name}',
                    style: const TextStyle(
                      color: Color(0xFF402B1D),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  events.isEmpty ? 'এই দিনে বিশেষ উৎসব নেই' : 'উৎসব ও বিশেষ দিন',
                  style: const TextStyle(
                    color: Color(0xFF4B2D1B),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (events.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...events.map(
                    (event) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEFE8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9C2B7)),
                      ),
                      child: Text(
                        '${event.icon}  ${event.label}',
                        style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// =====================================================================
// Home Screen — আলাদা একাদশী field
// =====================================================================

class _MonthlyAuspiciousTicker extends StatefulWidget {
  final String monthName;
  final int year;
  final List<(String icon, String title, String dates)> items;

  const _MonthlyAuspiciousTicker({
    required this.monthName,
    required this.year,
    required this.items,
  });

  @override
  State<_MonthlyAuspiciousTicker> createState() =>
      _MonthlyAuspiciousTickerState();
}

class _MonthlyAuspiciousTickerState extends State<_MonthlyAuspiciousTicker> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || widget.items.length <= 1) return;
      setState(() {
        _index = (_index + 1) % widget.items.length;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _MonthlyAuspiciousTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monthName != widget.monthName ||
        oldWidget.year != widget.year ||
        oldWidget.items.length != widget.items.length) {
      _index = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2D4C2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'এই মাসের শুভ দিন • ${widget.monthName} ${bnNum(widget.year)}',
                  style: const TextStyle(
                    color: Color(0xFF6C3A18),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0.18, 0),
                end: Offset.zero,
              ).animate(animation);
              return SlideTransition(
                position: offset,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Container(
              key: ValueKey('${item.$2}-$_index'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFE8DFD5)),
              ),
              child: Row(
                children: [
                  Text(item.$1, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        color: Color(0xFF2E2925),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    item.$3,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF9A1818),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.items.length > 1) ...[
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: i == _index ? 14 : 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == _index
                        ? const Color(0xFF9A1818)
                        : const Color(0xFFD6C9BC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveTithiData {
  final String title;
  final String icon;
  final DateTime day;
  final DateTime start;
  final DateTime end;
  final String subtitle;
  final CalendarEvent? event;
  final List<Color> colors;
  final String startLabel;
  final String endLabel;

  const _LiveTithiData({
    required this.title,
    required this.icon,
    required this.day,
    required this.start,
    required this.end,
    required this.subtitle,
    required this.event,
    required this.colors,
    this.startLabel = 'শুরু',
    this.endLabel = 'শেষ',
  });
}

class HomeEkadashiCard extends StatefulWidget {
  const HomeEkadashiCard({super.key});

  @override
  State<HomeEkadashiCard> createState() => _HomeEkadashiCardState();
}

class _HomeEkadashiCardState extends State<HomeEkadashiCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  _LiveTithiData? _ekadashi;
  _LiveTithiData? _ashtami;
  _LiveTithiData? _amavasya;
  _LiveTithiData? _purnima;
  _LiveTithiData? _upobash;

  @override
  void initState() {
    super.initState();
    LocationService.instance.addListener(_onLocationChanged);
    unawaited(LocationService.instance.refresh());
    _refreshData();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      final shouldRefresh = [
        _ekadashi,
        _ashtami,
        _amavasya,
        _purnima,
        _upobash,
      ].whereType<_LiveTithiData>().any(
            (item) => !item.end.isAfter(now),
          );

      setState(() => _now = now);
      if (shouldRefresh) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    LocationService.instance.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    _refreshData();
  }

  void _refreshData() {
    final now = DateTime.now();

    final ekadashi = _findTithi(
      'একাদশী',
      title: 'একাদশী',
      icon: '🙏',
      colors: const [
        Color(0xFF3C176A),
        Color(0xFF741B63),
        Color(0xFF9A5B16),
      ],
      now: now,
    );

    final ashtami = _findTithi(
      'অষ্টমী',
      title: 'অষ্টমী',
      icon: '🌺',
      colors: const [
        Color(0xFF8F1D1D),
        Color(0xFFC2412D),
        Color(0xFFB7791F),
      ],
      now: now,
    );

    final amavasya = _findTithi(
      'অমাবস্যা',
      title: 'অমাবস্যা',
      icon: '🌑',
      colors: const [
        Color(0xFF101828),
        Color(0xFF27324A),
        Color(0xFF3D2D62),
      ],
      now: now,
    );

    final purnima = _findTithi(
      'পূর্ণিমা',
      title: 'পূর্ণিমা',
      icon: '🌕',
      colors: const [
        Color(0xFF305B8C),
        Color(0xFF557FA8),
        Color(0xFF8B6E3C),
      ],
      now: now,
    );

    final upobash = _findUpobash(
      now: now,
      colors: const [
        Color(0xFF7A3E08),
        Color(0xFFA85B12),
        Color(0xFF8D6A19),
      ],
    );

    if (!mounted) return;
    setState(() {
      _now = now;
      _ekadashi = ekadashi;
      _ashtami = ashtami;
      _amavasya = amavasya;
      _purnima = purnima;
      _upobash = upobash;
    });
  }

  _LiveTithiData? _findTithi(
    String keyword, {
    required String title,
    required String icon,
    required List<Color> colors,
    required DateTime now,
  }) {
    final base = DateTime(now.year, now.month, now.day);

    for (int i = 0; i <= 60; i++) {
      final day = base.add(Duration(days: i));

      for (int h = 0; h < 24; h++) {
        final probe = DateTime(day.year, day.month, day.day, h, 30);
        final tithi = PanchangCalculator.tithiFor(probe);
        if (!tithi.name.contains(keyword)) continue;

        final timing = PanchangCalculator.tithiTiming(probe);
        final start = timing.$1;
        final end = timing.$2;
        if (!end.isAfter(now)) continue;

        CalendarEvent? event;
        for (final e in BengaliCalendarData.eventsFor(day)) {
          if (e.label.contains(keyword) ||
              (keyword == 'একাদশী' && e.category == 'ekadashi')) {
            event = e;
            break;
          }
        }

        final pakshaText = tithi.paksha.toString().trim();
        final subtitle = pakshaText.isEmpty
            ? title
            : '$pakshaText পক্ষের $title';

        return _LiveTithiData(
          title: title,
          icon: icon,
          day: day,
          start: start,
          end: end,
          subtitle: subtitle,
          event: event,
          colors: colors,
        );
      }
    }
    return null;
  }

  _LiveTithiData? _findUpobash({
    required DateTime now,
    required List<Color> colors,
  }) {
    final base = DateTime(now.year, now.month, now.day);

    const keywords = [
      'উপবাস',
      'ব্রত',
      'একাদশী',
      'শিবরাত্রি',
      'সংকষ্টি',
      'সঙ্কষ্টি',
    ];

    for (int i = 0; i <= 90; i++) {
      final day = base.add(Duration(days: i));
      final events = BengaliCalendarData.eventsFor(day);

      for (final event in events) {
        final matches =
            keywords.any((keyword) => event.label.contains(keyword));
        if (!matches) continue;

        final start = DateTime(day.year, day.month, day.day);
        final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
        if (!end.isAfter(now)) continue;

        return _LiveTithiData(
          title: 'উপবাস ও ব্রত',
          icon: '🪔',
          day: day,
          start: start,
          end: end,
          subtitle: event.label,
          event: event,
          colors: colors,
          startLabel: 'দিন শুরু',
          endLabel: 'দিন শেষ',
        );
      }
    }
    return null;
  }

  String _duration(Duration d) {
    if (d.isNegative) d = Duration.zero;

    final total = d.inSeconds;
    final days = total ~/ 86400;
    final hours = (total % 86400) ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;

    if (days > 0) {
      return '${bnNum(days)} দিন ${bnNum(hours)} ঘ '
          '${bnNum(minutes)} মি ${bnNum(seconds)} সে';
    }
    if (hours > 0) {
      return '${bnNum(hours)} ঘ ${bnNum(minutes)} মি '
          '${bnNum(seconds)} সে';
    }
    return '${bnNum(minutes)} মি ${bnNum(seconds)} সে';
  }

  String _statusText(_LiveTithiData data) {
    if (_now.isBefore(data.start)) {
      return 'শুরু হতে ${_duration(data.start.difference(_now))}';
    }
    if (_now.isBefore(data.end)) {
      return '🔴 LIVE • শেষ হতে ${_duration(data.end.difference(_now))}';
    }
    return 'শেষ হয়েছে';
  }

  Widget _buildLiveCard(_LiveTithiData data) {
    final active = !_now.isBefore(data.start) && _now.isBefore(data.end);
    final loc = LocationService.instance.hasGps
        ? 'GPS Live'
        : '${AppLocation.district} • জেলা';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PanchangOccasionDetailScreen(
            date: data.day,
            event: data.event,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: data.colors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? const Color(0x99FFF2A8)
                : const Color(0x55FFFFFF),
            width: active ? 1.6 : 1,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(data.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFE8A6),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0x3326FF96)
                        : const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? const Color(0x668CFFC1)
                          : const Color(0x33FFFFFF),
                    ),
                  ),
                  child: Text(
                    active ? 'LIVE' : 'NEXT',
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF8CFFC1)
                          : const Color(0xFFFFE8A6),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${PanchangCalculator.weekdayName(data.day)} • '
              '${bnNum(data.day.day)} ${gregMonthBn(data.day.month)} '
              '${bnNum(data.day.year)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HomeEkadashiTimeBox(
                    label: data.startLabel,
                    value:
                        '${bnNum(data.start.day)} ${gregMonthBn(data.start.month)} • '
                        '${bnTime12(data.start)}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HomeEkadashiTimeBox(
                    label: data.endLabel,
                    value:
                        '${bnNum(data.end.day)} ${gregMonthBn(data.end.month)} • '
                        '${bnTime12(data.end)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0x2D26FF96)
                    : const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: active
                    ? Border.all(color: const Color(0x448CFFC1))
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    active ? '⏱️' : '⏳',
                    style: const TextStyle(fontSize: 17),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _statusText(data),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '📍 $loc • প্রতি সেকেন্ডে লাইভ আপডেট',
              style: const TextStyle(
                color: Color(0xFFECE5F5),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ekadashi,
      _ashtami,
      _amavasya,
      _purnima,
      _upobash,
    ].whereType<_LiveTithiData>().toList();

    if (cards.isEmpty) return const SizedBox.shrink();

    _LiveTithiData? current;
    for (final item in cards) {
      final isLive = !_now.isBefore(item.start) && _now.isBefore(item.end);
      if (!isLive) continue;

      if (current == null || item.end.isBefore(current.end)) {
        current = item;
      }
    }

    if (current == null) {
      cards.sort((a, b) => a.start.compareTo(b.start));
      current = cards.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'তিথি ও উপবাস',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        _buildLiveCard(current),
      ],
    );
  }
}

class _HomeEkadashiTimeBox extends StatelessWidget {
  final String label;
  final String value;

  const _HomeEkadashiTimeBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFE8A6),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}



// =====================================================================
// Mahalaya -> Chhath seasonal Durga Puja LIVE field
// =====================================================================

class _DurgaSeasonEvent {
  final DateTime day;
  final CalendarEvent event;
  final DateTime start;
  final DateTime end;

  const _DurgaSeasonEvent({
    required this.day,
    required this.event,
    required this.start,
    required this.end,
  });
}

class DurgaFestivalSeason {
  const DurgaFestivalSeason._();

  static bool _isMahalaya(String label) =>
      label.contains('মহালয়া') || label.contains('মহালয়া');

  static bool _isChhath(String label) =>
      label.contains('ছট পূজা') || label.contains('ছটপূজা');

  static (DateTime start, DateTime end)? boundsFor(DateTime now) {
    final scanStart = DateTime(now.year, 8, 1);
    final scanEnd = DateTime(now.year, 12, 15);
    DateTime? start;
    DateTime? end;

    for (DateTime day = scanStart;
        !day.isAfter(scanEnd);
        day = day.add(const Duration(days: 1))) {
      final events = BengaliCalendarData.eventsFor(day);
      for (final event in events) {
        if (_isMahalaya(event.label)) {
          start = DateTime(day.year, day.month, day.day);
        }
        if (_isChhath(event.label)) {
          end = DateTime(day.year, day.month, day.day, 23, 59, 59);
        }
      }
    }

    if (start == null || end == null || end.isBefore(start)) return null;

    // দুর্গোৎসব LIVE field মহালয়ার একদিন আগে থেকেই দেখাবে,
    // যাতে ব্যবহারকারী আগের দিন থেকেই countdown দেখতে পান।
    final visibleFrom = start.subtract(const Duration(days: 1));
    return (visibleFrom, end);
  }

  static bool isActive(DateTime now) {
    final bounds = boundsFor(now);
    if (bounds == null) return false;
    return !now.isBefore(bounds.$1) && !now.isAfter(bounds.$2);
  }

  static List<_DurgaSeasonEvent> eventsFor(DateTime now) {
    final bounds = boundsFor(now);
    if (bounds == null) return const [];

    final result = <_DurgaSeasonEvent>[];
    for (DateTime day = bounds.$1;
        !day.isAfter(bounds.$2);
        day = day.add(const Duration(days: 1))) {
      final events = BengaliCalendarData.eventsFor(day);
      for (final event in events) {
        if (!_includeEvent(event.label)) continue;
        final timing = _timingFor(day, event);
        result.add(
          _DurgaSeasonEvent(
            day: day,
            event: event,
            start: timing.$1,
            end: timing.$2,
          ),
        );
      }
    }

    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  static bool _includeEvent(String label) {
    const keys = [
      'মহালয়া',
      'মহালয়া',
      'মহাচতুর্থী',
      'মহাপঞ্চমী',
      'মহাষষ্ঠী',
      'মহাসপ্তমী',
      'মহাষ্টমী',
      'মহানবমী',
      'বিজয়া দশমী',
      'বিজয়া দশমী',
      'কোজাগরী লক্ষ্মীপূজা',
      'ধনতেরাস',
      'ভূত চতুর্দশী',
      'কালীপূজা',
      'দীপাবলি',
      'ভাইফোঁটা',
      'ছট পূজা',
      'ছটপূজা',
    ];
    return keys.any(label.contains);
  }

  static (DateTime, DateTime) _timingFor(
    DateTime day,
    CalendarEvent event,
  ) {
    final label = event.label;

    // Chhath is primarily sunrise/sunset observance; keeping the final
    // seasonal card alive through the whole Chhath day is less confusing.
    if (_isChhath(label)) {
      return (
        DateTime(day.year, day.month, day.day),
        DateTime(day.year, day.month, day.day, 23, 59, 59),
      );
    }

    // For other Puja days use the actual tithi window around the day's
    // sunrise. This makes Mahashtami etc. show real start/end time.
    final sun = PanchangCalculator.sunTimes(
      day,
      lat: AppLocation.lat,
      lon: AppLocation.lon,
    );
    final timing = PanchangCalculator.tithiTiming(sun.sunrise);
    return (timing.$1, timing.$2);
  }

  static Future<void> playLaunchDhakIfActive() async {
    final now = DateTime.now();
    if (!isActive(now)) return;

    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player.setVolume(1.0);
      await player.play(AssetSource('audio/dhak_5sec.mp3'));
      await Future<void>.delayed(const Duration(seconds: 5));
      await player.stop();
    } catch (_) {
      // Audio failure must never block or crash app startup.
    } finally {
      try {
        await player?.dispose();
      } catch (_) {}
    }
  }

}

class DurgaFestivalLiveCard extends StatefulWidget {
  const DurgaFestivalLiveCard({super.key});

  @override
  State<DurgaFestivalLiveCard> createState() => _DurgaFestivalLiveCardState();
}

class _DurgaFestivalLiveCardState extends State<DurgaFestivalLiveCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  DateTime _now = DateTime.now();
  late final AnimationController _dhak;

  @override
  void initState() {
    super.initState();
    _dhak = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dhak.dispose();
    super.dispose();
  }

  String _countdown(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final total = d.inSeconds;
    final days = total ~/ 86400;
    final hours = (total % 86400) ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;

    if (days > 0) {
      return '${bnNum(days)} দিন ${bnNum(hours)} ঘ '
          '${bnNum(minutes)} মি ${bnNum(seconds)} সে';
    }
    return '${bnNum(hours).padLeft(2, '০')}:'
        '${bnNum(minutes).padLeft(2, '০')}:'
        '${bnNum(seconds).padLeft(2, '০')}';
  }

  _DurgaSeasonEvent? _currentOrNext() {
    final events = DurgaFestivalSeason.eventsFor(_now);
    if (events.isEmpty) return null;

    for (final item in events) {
      if (!_now.isBefore(item.start) && _now.isBefore(item.end)) {
        return item;
      }
    }
    for (final item in events) {
      if (_now.isBefore(item.start)) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!DurgaFestivalSeason.isActive(_now)) {
      return const SizedBox.shrink();
    }

    final item = _currentOrNext();
    if (item == null) return const SizedBox.shrink();

    final live = !_now.isBefore(item.start) && _now.isBefore(item.end);
    final status = live
        ? '🔴 LIVE • শেষ হতে ${_countdown(item.end.difference(_now))}'
        : '${item.event.label} শুরু হতে ${_countdown(item.start.difference(_now))}';

    Widget drum(bool left) {
      return AnimatedBuilder(
        animation: _dhak,
        builder: (_, __) {
          final turn = (_dhak.value - .5) * .045 * (left ? -1 : 1);
          final scale = .98 + (_dhak.value * .035);
          return Transform.rotate(
            angle: turn,
            child: Transform.scale(
              scale: scale,
              child: CustomPaint(
                size: const Size(58, 100),
                painter: _DhakiPersonPainter(mirrored: !left),
              ),
            ),
          );
        },
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E1111),
            Color(0xFFC23B20),
            Color(0xFFB47512),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD87A), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              drum(true),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      'দুর্গোৎসব লাইভ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFE8A6),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.event.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              drum(false),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${PanchangCalculator.weekdayName(item.day)} • '
            '${bnNum(item.day.day)} ${gregMonthBn(item.day.month)} '
            '${bnNum(item.day.year)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HomeEkadashiTimeBox(
                  label: 'লাগবে / শুরু',
                  value: '${bnNum(item.start.day)} '
                      '${gregMonthBn(item.start.month)} • '
                      '${bnTime12(item.start)}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HomeEkadashiTimeBox(
                  label: 'ছাড়বে / শেষ',
                  value: '${bnNum(item.end.day)} '
                      '${gregMonthBn(item.end.month)} • '
                      '${bnTime12(item.end)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
            decoration: BoxDecoration(
              color: live
                  ? const Color(0x2D26FF96)
                  : const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: live
                    ? const Color(0x668CFFC1)
                    : const Color(0x33FFFFFF),
              ),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'মহালয়া থেকে ছটপূজা পর্যন্ত • প্রতি সেকেন্ডে লাইভ সময়',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFFE7BD),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}




class _DhakiPersonPainter extends CustomPainter {
  final bool mirrored;

  const _DhakiPersonPainter({required this.mirrored});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirrored) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    double x(double v) => size.width * v;
    double y(double v) => size.height * v;

    final skin = Paint()..color = const Color(0xFFF2A07E);
    final white = Paint()..color = const Color(0xFFFFFBF1);
    final clothShade = Paint()..color = const Color(0xFFE6E2DD);
    final red = Paint()..color = const Color(0xFFCC1E16);
    final orange = Paint()..color = const Color(0xFFD86712);
    final orangeDark = Paint()..color = const Color(0xFF8D3E0B);
    final black = Paint()..color = const Color(0xFF0C0C0C);
    final feather = Paint()..color = const Color(0xFFF8F8F4);
    final featherDark = Paint()..color = const Color(0xFF3A2A20);
    final line = Paint()
      ..color = const Color(0xFF7A3214)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .022
      ..strokeCap = StrokeCap.round;
    final rope = Paint()
      ..color = const Color(0xFFF0C66A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .018;

    // White plume with dark base, like the supplied Bengali dhaki reference.
    final plume = Path()
      ..moveTo(x(.42), y(.06))
      ..quadraticBezierTo(x(.62), y(-.01), x(.77), y(.05))
      ..quadraticBezierTo(x(.86), y(.11), x(.78), y(.22))
      ..quadraticBezierTo(x(.66), y(.14), x(.54), y(.18))
      ..quadraticBezierTo(x(.48), y(.12), x(.42), y(.06))
      ..close();
    canvas.drawPath(plume, feather);
    final plumeBase = Path()
      ..moveTo(x(.40), y(.07))
      ..quadraticBezierTo(x(.34), y(.13), x(.50), y(.17))
      ..lineTo(x(.57), y(.12))
      ..quadraticBezierTo(x(.48), y(.06), x(.40), y(.07))
      ..close();
    canvas.drawPath(plumeBase, featherDark);

    // Dhak behind the performer.
    final drumBody = Path()
      ..moveTo(x(.58), y(.25))
      ..quadraticBezierTo(x(.86), y(.20), x(.93), y(.45))
      ..quadraticBezierTo(x(.96), y(.62), x(.74), y(.70))
      ..quadraticBezierTo(x(.60), y(.64), x(.56), y(.45))
      ..close();
    canvas.drawPath(drumBody, orange);
    canvas.drawPath(drumBody, Paint()
      ..color = orangeDark.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .025);
    for (int i = 0; i < 4; i++) {
      final xx = .64 + (i * .07);
      canvas.drawLine(Offset(x(xx), y(.29)), Offset(x(xx + .04), y(.62)), rope);
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x(.76), y(.66)),
        width: x(.34),
        height: y(.11),
      ),
      Paint()..color = const Color(0xFFF3E4C7),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x(.76), y(.66)),
        width: x(.34),
        height: y(.11),
      ),
      Paint()
        ..color = const Color(0xFF8F4A28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .022,
    );

    // Head and hair.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x(.33), y(.24)),
        width: x(.22),
        height: y(.16),
      ),
      skin,
    );
    final hair = Path()
      ..moveTo(x(.22), y(.22))
      ..quadraticBezierTo(x(.24), y(.13), x(.39), y(.15))
      ..quadraticBezierTo(x(.45), y(.18), x(.42), y(.23))
      ..lineTo(x(.31), y(.20))
      ..close();
    canvas.drawPath(hair, black);

    // Kurta.
    final torso = Path()
      ..moveTo(x(.22), y(.31))
      ..lineTo(x(.46), y(.30))
      ..quadraticBezierTo(x(.55), y(.48), x(.48), y(.64))
      ..lineTo(x(.22), y(.69))
      ..quadraticBezierTo(x(.11), y(.52), x(.18), y(.36))
      ..close();
    canvas.drawPath(torso, white);

    // Red shoulder strap to the dhak.
    canvas.drawPath(
      Path()
        ..moveTo(x(.39), y(.30))
        ..lineTo(x(.48), y(.31))
        ..lineTo(x(.66), y(.55))
        ..lineTo(x(.60), y(.58))
        ..close(),
      red,
    );

    // Dhoti.
    final dhoti = Path()
      ..moveTo(x(.24), y(.65))
      ..lineTo(x(.47), y(.64))
      ..lineTo(x(.51), y(.90))
      ..lineTo(x(.40), y(.95))
      ..lineTo(x(.34), y(.78))
      ..lineTo(x(.27), y(.95))
      ..lineTo(x(.17), y(.91))
      ..close();
    canvas.drawPath(dhoti, white);
    canvas.drawPath(
      Path()
        ..moveTo(x(.20), y(.88))
        ..lineTo(x(.28), y(.91))
        ..moveTo(x(.42), y(.90))
        ..lineTo(x(.49), y(.88)),
      Paint()
        ..color = red.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .025,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x(.31), y(.66))
        ..quadraticBezierTo(x(.36), y(.75), x(.39), y(.86)),
      Paint()
        ..color = clothShade.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .04,
    );

    // Arms and crossed drum sticks.
    canvas.drawLine(Offset(x(.20), y(.43)), Offset(x(.37), y(.57)), Paint()
      ..color = skin.color
      ..strokeWidth = size.width * .08
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(x(.46), y(.42)), Offset(x(.38), y(.57)), Paint()
      ..color = skin.color
      ..strokeWidth = size.width * .08
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(Offset(x(.30), y(.55)), Offset(x(.61), y(.67)), line);
    canvas.drawLine(Offset(x(.37), y(.57)), Offset(x(.63), y(.53)), line);

    // Feet.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x(.22), y(.965)),
        width: x(.13),
        height: y(.04),
      ),
      skin,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x(.43), y(.965)),
        width: x(.13),
        height: y(.04),
      ),
      skin,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DhakiPersonPainter oldDelegate) =>
      oldDelegate.mirrored != mirrored;
}

class _DhakPainter extends CustomPainter {
  final bool mirrored;

  const _DhakPainter({required this.mirrored});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirrored) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final body = Paint()
      ..color = const Color(0xFFB86A22)
      ..style = PaintingStyle.fill;

    final dark = Paint()
      ..color = const Color(0xFF5B2A12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final rim = Paint()
      ..color = const Color(0xFFF4D27A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final rope = Paint()
      ..color = const Color(0xFFF2C45D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final stick = Paint()
      ..color = const Color(0xFF8A4B24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    // Traditional Bengali dhak body: tall, slightly tapered barrel.
    final bodyPath = Path()
      ..moveTo(size.width * .28, size.height * .18)
      ..quadraticBezierTo(
        size.width * .15,
        size.height * .50,
        size.width * .28,
        size.height * .82,
      )
      ..quadraticBezierTo(
        size.width * .50,
        size.height * .92,
        size.width * .72,
        size.height * .82,
      )
      ..quadraticBezierTo(
        size.width * .85,
        size.height * .50,
        size.width * .72,
        size.height * .18,
      )
      ..quadraticBezierTo(
        size.width * .50,
        size.height * .08,
        size.width * .28,
        size.height * .18,
      )
      ..close();

    canvas.drawPath(bodyPath, body);
    canvas.drawPath(bodyPath, dark);

    // Top and bottom drum heads.
    final topRect = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .18),
      width: size.width * .46,
      height: size.height * .16,
    );
    final bottomRect = Rect.fromCenter(
      center: Offset(size.width * .50, size.height * .82),
      width: size.width * .46,
      height: size.height * .16,
    );
    canvas.drawOval(topRect, rim);
    canvas.drawOval(bottomRect, rim);

    // Traditional lacing around the dhak body.
    for (int i = 0; i < 5; i++) {
      final x1 = size.width * (.31 + i * .095);
      final x2 = size.width * (.69 - i * .095);
      canvas.drawLine(
        Offset(x1, size.height * .22),
        Offset(x2, size.height * .78),
        rope,
      );
    }

    // Shoulder strap.
    final strap = Paint()
      ..color = const Color(0xFFD8B45E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final strapPath = Path()
      ..moveTo(size.width * .30, size.height * .22)
      ..quadraticBezierTo(
        size.width * .02,
        size.height * .08,
        size.width * .08,
        size.height * .66,
      );
    canvas.drawPath(strapPath, strap);

    // Curved dhak stick.
    final stickPath = Path()
      ..moveTo(size.width * .80, size.height * .12)
      ..quadraticBezierTo(
        size.width * .98,
        size.height * .28,
        size.width * .83,
        size.height * .47,
      );
    canvas.drawPath(stickPath, stick);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DhakPainter oldDelegate) =>
      oldDelegate.mirrored != mirrored;
}
