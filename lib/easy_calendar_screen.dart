part of 'main.dart';

/// বয়স্কদের জন্য পরিষ্কার, বড় লেখা এবং কম ভিড়ের মাসিক বাংলা ক্যালেন্ডার।
/// মূল/আধুনিক ক্যালেন্ডার অপরিবর্তিত থাকে।
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
  String _mode = 'সম্পূর্ণ মাস';

  static const _modes = ['সম্পূর্ণ মাস', 'বিশেষ দিন', 'বিবাহ'];
  static const _weekdays = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];

  late final AnimationController _festivalPulseController;

  @override
  void initState() {
    super.initState();
    _festivalPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

  bool _isDurgaFestival(List<CalendarEvent> events) {
    return events.any(
      (event) =>
          event.label.contains('দুর্গা') ||
          event.label.contains('ষষ্ঠী') ||
          event.label.contains('সপ্তমী') ||
          event.label.contains('অষ্টমী') ||
          event.label.contains('নবমী') ||
          event.label.contains('দশমী') ||
          event.label.contains('মহাষষ্ঠী') ||
          event.label.contains('মহাসপ্তমী') ||
          event.label.contains('মহাষ্টমী') ||
          event.label.contains('মহানবমী') ||
          event.label.contains('বিজয়া দশমী') ||
          event.label.contains('বিজয়া দশমী'),
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
      backgroundColor: const Color(0xFFF3E9D7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E1111),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: const Color(0xFF8E1111),
        titleSpacing: 4,
        title: const Text(
          'সহজ ক্যালেন্ডার',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: .2),
        ),
        actions: [
          TextButton(
            onPressed: _goToday,
            child: const Text(
              'আজ',
              style: TextStyle(
                color: Color(0xFFFFE5A6),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
          children: [
            _buildMonthTitle(info),
            const SizedBox(height: 8),
            _buildModeBar(),
            const SizedBox(height: 10),
            _buildWeekHeader(),
            const SizedBox(height: 2),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF8EEDC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFB77A2C), width: 1.4),
                boxShadow: const [
                  BoxShadow(color: Color(0x24000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leading + totalDays + trailing,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                clipBehavior: Clip.hardEdge,
                itemBuilder: (context, index) {
                  if (index < leading || index >= leading + totalDays) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1E4D0),
                        border: Border(
                          right: BorderSide(color: Color(0xFFD9C3A4)),
                          bottom: BorderSide(color: Color(0xFFD9C3A4)),
                        ),
                      ),
                    );
                  }

                  final bengaliDay = index - leading + 1;
                  final greg = info.start.add(Duration(days: bengaliDay - 1));
                  return _dayCell(greg, bengaliDay, info);
                },
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'তারিখে চাপলে তিথি ও বিশেষ দিনের বিস্তারিত দেখা যাবে',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthTitle(dynamic info) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF7DE), Color(0xFFF4D7A1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB56A17), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'আগের মাস',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded, size: 34),
            color: const Color(0xFF8E1111),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'বাংলা পঞ্জিকা',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF7A4A12),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${info.name} ${bnNum(info.year)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8E1111),
                    fontSize: 29,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${info.start.day}/${info.start.month}/${info.start.year} - ${info.end.day}/${info.end.month}/${info.end.year}',
                  style: const TextStyle(
                    color: Color(0xFF6B4B2A),
                    fontSize: 11.5,
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
            color: const Color(0xFF8E1111),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBar() {
    return Row(
      children: _modes.map((mode) {
        final selected = _mode == mode;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => setState(() => _mode = mode),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF8E1111) : const Color(0xFFFFFAEF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF8E1111)
                        : const Color(0xFFD5B58A),
                  ),
                ),
                child: Text(
                  mode,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF333333),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4D9A4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB77A2C), width: 1.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
        children: List.generate(_weekdays.length, (i) {
          return Expanded(
            child: Container(
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFD4B17B)),
                ),
              ),
              child: Text(
                _weekdays[i],
                style: TextStyle(
                  color: i == 0
                      ? const Color(0xFFB00000)
                      : const Color(0xFF4B2E16),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }),
        ),
      ),
    );
  }

  Widget _dayCell(DateTime greg, int bengaliDay, dynamic info) {
    final now = DateTime.now();
    final isToday = greg.year == now.year &&
        greg.month == now.month &&
        greg.day == now.day;
    final isSunday = greg.weekday == DateTime.sunday;
    final events = BengaliCalendarData.eventsFor(greg);
    final tithi = PanchangCalculator.tithiFor(greg);

    final filteredEvents = _mode == 'সম্পূর্ণ মাস'
        ? events
        : _mode == 'বিবাহ'
            ? events
                .where((e) => e.label.contains('বিবাহ') || e.label.contains('শুভ'))
                .toList()
            : events;

    final firstEvent = filteredEvents.isEmpty ? null : filteredEvents.first;
    final showMoon = tithi.name.contains('পূর্ণিমা') ||
        tithi.name.contains('অমাবস্যা') ||
        tithi.name.contains('একাদশী');

    final isSpecialTithi = tithi.name.contains('অমাবস্যা') ||
        tithi.name.contains('পূর্ণিমা') ||
        tithi.name.contains('একাদশী') ||
        tithi.name.contains('অষ্টমী') ||
        tithi.name.contains('নবমী') ||
        tithi.name.contains('চতুর্দশী') ||
        tithi.name.contains('সংক্রান্তি');

    final isMajorFestival = _isMajorFestival(events);
    final isDurgaFestival = _isDurgaFestival(events);
    final majorFestivalEvent = isMajorFestival
        ? events.firstWhere((event) => _isMajorFestival([event]))
        : null;
    final majorFestivalLabel = majorFestivalEvent?.label;

    final dayTile = InkWell(
      onTap: () => _showDayDetails(greg, bengaliDay, info, tithi, events),
      child: Container(
        padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFFFFF1B8)
              : isDurgaFestival
                  ? const Color(0xFFFFE7CC)
                  : const Color(0xFFFFFCF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday
                ? const Color(0xFFC58A10)
                : isDurgaFestival
                    ? const Color(0xFFE65100)
                    : isMajorFestival
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFE7DDD3),
            width: isToday
                ? 2.6
                : (isDurgaFestival || isMajorFestival)
                    ? 1.7
                    : 1,
          ),
          boxShadow: isToday
              ? const [
                  BoxShadow(
                    color: Color(0x33B77A2C),
                    blurRadius: 7,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: 0,
                    top: 2,
                    child: Text(
                      '${greg.day}',
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF7A6A59),
                        fontSize: 9.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (isToday)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E1111),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'আজ',
                          maxLines: 1,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            SizedBox(
              height: 34,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    bnNum(bengaliDay),
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isToday
                          ? const Color(0xFF8E1111)
                          : isSunday
                              ? const Color(0xFFC40000)
                              : const Color(0xFF342315),
                      fontSize: isToday ? 30 : 28,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 1,
                        vertical: isSpecialTithi ? 2 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: isSpecialTithi
                            ? const Color(0xFFFBE5B8)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        showMoon
                            ? (tithi.name.contains('পূর্ণিমা')
                                ? '🌕 ${tithi.name}'
                                : tithi.name.contains('অমাবস্যা')
                                    ? '🌑 ${tithi.name}'
                                    : '◐ ${tithi.name}')
                            : tithi.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSpecialTithi
                              ? const Color(0xFF9B1111)
                              : const Color(0xFF5B3A22),
                          fontSize: isSpecialTithi ? 9.3 : 8.4,
                          height: 1.0,
                          fontWeight: isSpecialTithi
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (majorFestivalLabel != null) ...[
                      const SizedBox(height: 2),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                            decoration: BoxDecoration(
                              color: isDurgaFestival
                                  ? const Color(0xFFFFD5B8)
                                  : const Color(0xFFFFEDC1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${majorFestivalEvent!.icon} $majorFestivalLabel',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDurgaFestival
                                    ? const Color(0xFFB71C1C)
                                    : const Color(0xFFB45309),
                                fontSize: isDurgaFestival ? 9.2 : 8.7,
                                height: 1.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else if (firstEvent != null) ...[
                      const SizedBox(height: 2),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${firstEvent.icon} ${firstEvent.label}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFC62828),
                              fontSize: 8.4,
                              height: 1.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!isMajorFestival) return dayTile;

    return AnimatedBuilder(
      animation: _festivalPulseController,
      child: dayTile,
      builder: (context, child) {
        final pulse = _festivalPulseController.value;
        final scale = 1.0;
        final moveY = 0.0;

        return Transform.translate(
          offset: Offset(0, moveY),
          child: Transform.scale(
            scale: scale,
            child: Container(
                decoration: BoxDecoration(
                  color: Color.lerp(
                    isDurgaFestival
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFFFFBEB),
                    isDurgaFestival
                        ? const Color(0xFFFFCC80)
                        : const Color(0xFFFFE8A3),
                    pulse,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDurgaFestival
                        ? const Color(0xFFE65100)
                        : const Color(0xFFF59E0B),
                    width: 1.4 + (0.8 * pulse),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.lerp(
                        isDurgaFestival
                            ? const Color(0x55FF6F00)
                            : const Color(0x33F59E0B),
                        isDurgaFestival
                            ? const Color(0xCCFF9800)
                            : const Color(0x88FFB300),
                        pulse,
                      )!,
                      blurRadius: isDurgaFestival ? 7 : 5,
                      spreadRadius: isDurgaFestival ? 0.8 : 0.4,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
      },
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
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bnNum(bengaliDay)} ${info.name} ${bnNum(info.year)}',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF194F90),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${greg.day}/${greg.month}/${greg.year}',
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 24),
                Text(
                  'তিথি: ${tithi.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  events.isEmpty ? 'বিশেষ দিন নেই' : 'উৎসব ও বিশেষ দিন',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (events.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${event.icon} ${event.label}',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
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

class HomeEkadashiCard extends StatefulWidget {
  const HomeEkadashiCard({super.key});

  @override
  State<HomeEkadashiCard> createState() => _HomeEkadashiCardState();
}

class _HomeEkadashiCardState extends State<HomeEkadashiCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    LocationService.instance.addListener(_onLocationChanged);
    unawaited(LocationService.instance.refresh());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    LocationService.instance.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  (DateTime day, String paksha, DateTime start, DateTime end)? _next() {
    final base = DateTime(_now.year, _now.month, _now.day);

    for (int i = 0; i <= 45; i++) {
      final day = base.add(Duration(days: i));
      final sunrise = PanchangCalculator.sunTimes(
        day,
        lat: AppLocation.lat,
        lon: AppLocation.lon,
      ).sunrise;

      final atSunrise = PanchangCalculator.tithiFor(sunrise);
      final hasEvent = BengaliCalendarData.eventsFor(
        day,
      ).any((e) => e.category == 'ekadashi');

      if (atSunrise.name != 'একাদশী' && !hasEvent) continue;

      for (int h = 0; h < 24; h++) {
        final probe = DateTime(day.year, day.month, day.day, h, 30);
        final t = PanchangCalculator.tithiFor(probe);
        if (t.name != 'একাদশী') continue;

        final timing = PanchangCalculator.tithiTiming(probe);
        if (!timing.$2.isAfter(_now)) continue;
        return (day, t.paksha, timing.$1, timing.$2);
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
      return '${bnNum(days)} দিন ${bnNum(hours)} ঘ ${bnNum(minutes)} মি';
    }
    if (hours > 0) {
      return '${bnNum(hours)} ঘ ${bnNum(minutes)} মি ${bnNum(seconds)} সে';
    }
    return '${bnNum(minutes)} মি ${bnNum(seconds)} সে';
  }

  @override
  Widget build(BuildContext context) {
    final data = _next();
    if (data == null) return const SizedBox.shrink();

    final day = data.$1;
    final paksha = data.$2;
    final start = data.$3;
    final end = data.$4;
    final active = !_now.isBefore(start) && _now.isBefore(end);

    final countdown = _now.isBefore(start)
        ? 'শুরু হতে ${_duration(start.difference(_now))}'
        : 'একাদশী চলছে • শেষ হতে ${_duration(end.difference(_now))}';

    final loc = LocationService.instance.hasGps
        ? 'GPS Live'
        : '${AppLocation.district} • জেলা';

    CalendarEvent? event;
    for (final e in BengaliCalendarData.eventsFor(day)) {
      if (e.category == 'ekadashi') {
        event = e;
        break;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PanchangOccasionDetailScreen(
            date: day,
            event: event,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3C176A),
              Color(0xFF741B63),
              Color(0xFF9A5B16),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x66FFD98A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🙏', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'আগামী একাদশী',
                        style: TextStyle(
                          color: Color(0xFFFFE8A6),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$paksha পক্ষের একাদশী',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  active ? 'LIVE' : 'NEXT',
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF8CFFC1)
                        : const Color(0xFFFFE8A6),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${PanchangCalculator.weekdayName(day)} • '
              '${bnNum(day.day)} ${gregMonthBn(day.month)} ${bnNum(day.year)}',
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
                    label: 'লাগবে',
                    value:
                        '${bnNum(start.day)} ${gregMonthBn(start.month)} • ${bnTime12(start)}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HomeEkadashiTimeBox(
                    label: 'ছাড়বে',
                    value:
                        '${bnNum(end.day)} ${gregMonthBn(end.month)} • ${bnTime12(end)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⏳ $countdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '📍 $loc • live timing',
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
