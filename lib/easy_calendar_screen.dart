part of 'main.dart';

/// বড় লেখা, কম ভিড় এবং স্পষ্ট রঙে তৈরি সহজ মাসিক ক্যালেন্ডার।
/// মূল/আধুনিক ক্যালেন্ডার অপরিবর্তিত থাকে; সেখান থেকে এই স্ক্রিন খোলা হয়।
class EasyBengaliCalendarScreen extends StatefulWidget {
  const EasyBengaliCalendarScreen({super.key});

  @override
  State<EasyBengaliCalendarScreen> createState() =>
      _EasyBengaliCalendarScreenState();
}

class _EasyBengaliCalendarScreenState
    extends State<EasyBengaliCalendarScreen> {
  DateTime _anchor = DateTime.now();

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
      backgroundColor: const Color(0xFFFFFBF4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172554),
        elevation: 0.5,
        titleSpacing: 8,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'সহজ ক্যালেন্ডার',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Text(
              'বড় লেখা • সহজে দেখুন',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.auto_awesome_rounded, size: 17),
            label: const Text(
              'আধুনিক',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 24),
          children: [
            _monthHeader(info),
            const SizedBox(height: 10),
            _weekdayHeader(),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leading + totalDays + trailing,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.52,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                if (index < leading || index >= leading + totalDays) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F1EA),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  );
                }

                final bengaliDay = index - leading + 1;
                final greg = info.start.add(Duration(days: bengaliDay - 1));
                return _dayCell(greg, bengaliDay, info);
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E0D6)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'যে কোনো তারিখে চাপলে তিথি ও বিশেষ দিনের বিস্তারিত দেখা যাবে।',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthHeader(dynamic info) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4DDD2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'আগের মাস',
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 30),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      info.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${bnNum(info.year)} বঙ্গাব্দ',
                      style: const TextStyle(
                        color: Color(0xFF172554),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${info.start.day}/${info.start.month}/${info.start.year} – ${info.end.day}/${info.end.month}/${info.end.year}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'পরের মাস',
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: FilledButton.icon(
              onPressed: _goToday,
              icon: const Icon(Icons.today_rounded, size: 18),
              label: const Text(
                'আজকের মাসে ফিরুন',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekdayHeader() {
    const days = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(days.length, (i) {
          return Expanded(
            child: Text(
              days[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: i == 0
                    ? const Color(0xFFC62828)
                    : const Color(0xFF173B78),
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
    final firstEvent = events.isEmpty ? null : events.first;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showDayDetails(greg, bengaliDay, info, tithi, events),
      child: Container(
        padding: const EdgeInsets.fromLTRB(2, 3, 2, 3),
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFFFFF0B8)
              : isSunday
                  ? const Color(0xFFFFF2F2)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? const Color(0xFFE3A008)
                : const Color(0xFFE3DDD5),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${greg.day}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isToday)
                  const Text(
                    'আজ',
                    style: TextStyle(
                      fontSize: 8,
                      color: Color(0xFF9A6700),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              bnNum(bengaliDay),
              style: TextStyle(
                fontSize: 26,
                height: 1.0,
                fontWeight: FontWeight.w900,
                color: isSunday
                    ? const Color(0xFFC62828)
                    : const Color(0xFF173B78),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tithi.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8,
                height: 1.1,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w700,
              ),
            ),
            if (firstEvent != null) ...[
              const SizedBox(height: 2),
              Text(
                '${firstEvent.icon} ${firstEvent.label}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8,
                  height: 1.05,
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF173B78),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${greg.day}/${greg.month}/${greg.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
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
