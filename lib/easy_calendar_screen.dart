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
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 4,
        title: const Text(
          'সহজ ক্যালেন্ডার',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _goToday,
            child: const Text(
              'আজ',
              style: TextStyle(
                color: Color(0xFFC62828),
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
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 20),
          children: [
            _buildMonthTitle(info),
            const SizedBox(height: 8),
            _buildModeBar(),
            const SizedBox(height: 10),
            _buildWeekHeader(),
            const SizedBox(height: 2),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E2E2)),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leading + totalDays + trailing,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 1.5,
                  mainAxisSpacing: 1.5,
                ),
                clipBehavior: Clip.none,
                itemBuilder: (context, index) {
                  if (index < leading || index >= leading + totalDays) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F7F7),
                        border: Border(
                          right: BorderSide(color: Color(0xFFE7E7E7)),
                          bottom: BorderSide(color: Color(0xFFE7E7E7)),
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
      child: Row(
        children: [
          IconButton(
            tooltip: 'আগের মাস',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded, size: 32),
            color: const Color(0xFF444444),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${info.name} ${bnNum(info.year)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 27,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${info.start.day}/${info.start.month}/${info.start.year} - ${info.end.day}/${info.end.month}/${info.end.year}',
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'পরের মাস',
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded, size: 32),
            color: const Color(0xFF444444),
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
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFC62828) : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFC62828)
                        : const Color(0xFFD7D7D7),
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
      color: const Color(0xFFF0F0F0),
      child: Row(
        children: List.generate(_weekdays.length, (i) {
          return Expanded(
            child: Container(
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFFDDDDDD)),
                ),
              ),
              child: Text(
                _weekdays[i],
                style: TextStyle(
                  color: i == 0
                      ? const Color(0xFFC62828)
                      : const Color(0xFF194F90),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        }),
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

    final isMajorFestival = _isMajorFestival(events);
    final isDurgaFestival = _isDurgaFestival(events);

    final dayTile = InkWell(
      onTap: () => _showDayDetails(greg, bengaliDay, info, tithi, events),
      child: Container(
        padding: const EdgeInsets.fromLTRB(1.5, 1.5, 1.5, 1.5),
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFFEAF4FF)
              : isDurgaFestival
                  ? const Color(0xFFFFF3E0)
                  : Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isToday
                ? const Color(0xFF1565C0)
                : isDurgaFestival
                    ? const Color(0xFFE65100)
                    : isMajorFestival
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFE0E0E0),
            width: isToday
                ? 2.6
                : (isDurgaFestival || isMajorFestival)
                    ? 1.7
                    : 1,
          ),
          boxShadow: isToday
              ? const [
                  BoxShadow(
                    color: Color(0x551565C0),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${greg.day}',
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 7.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'আজ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else if (isMajorFestival)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isDurgaFestival
                          ? const Color(0xFFE65100)
                          : const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      isDurgaFestival ? 'পূজা' : 'উৎসব',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            SizedBox(
              height: 25,
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
                          ? const Color(0xFF0D47A1)
                          : isSunday
                              ? const Color(0xFFC62828)
                              : const Color(0xFF194F90),
                      fontSize: isToday ? 27 : 25,
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
                    SizedBox(
                      height: 9,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          showMoon
                              ? (tithi.name.contains('পূর্ণিমা')
                                  ? '🌕 ${tithi.name}'
                                  : tithi.name.contains('অমাবস্যা')
                                      ? '🌑 ${tithi.name}'
                                      : '◐ ${tithi.name}')
                              : tithi.name,
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: showMoon
                                ? const Color(0xFF555555)
                                : const Color(0xFF666666),
                            fontSize: 8,
                            height: 1.0,
                            fontWeight:
                                showMoon ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (firstEvent != null)
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 48),
                              child: Text(
                                '${firstEvent.icon} ${firstEvent.label}',
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isDurgaFestival
                                      ? const Color(0xFFB71C1C)
                                      : const Color(0xFFC62828),
                                  fontSize: isMajorFestival ? 7.5 : 7.0,
                                  height: 1.0,
                                  fontWeight: isMajorFestival
                                      ? FontWeight.w900
                                      : FontWeight.w800,
                                ),
                              ),
                            ),
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
    );

    if (!isMajorFestival) return dayTile;

    return AnimatedBuilder(
      animation: _festivalPulseController,
      child: dayTile,
      builder: (context, child) {
        final pulse = _festivalPulseController.value;
        final scale = isDurgaFestival
            ? 0.99 + (0.035 * pulse)
            : 1.0 + (0.02 * pulse);
        final moveY = isDurgaFestival ? -1.2 + (2.4 * pulse) : 0.0;
        final rotate = isDurgaFestival ? -0.012 + (0.024 * pulse) : 0.0;

        return Transform.translate(
          offset: Offset(0, moveY),
          child: Transform.rotate(
            angle: rotate,
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
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
                      blurRadius:
                          isDurgaFestival ? 8 + (10 * pulse) : 5 + (6 * pulse),
                      spreadRadius:
                          isDurgaFestival ? 1 + (2 * pulse) : 0.5 + pulse,
                    ),
                  ],
                ),
                child: child,
              ),
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
