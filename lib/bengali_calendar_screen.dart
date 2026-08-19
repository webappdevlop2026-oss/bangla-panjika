import 'package:flutter/material.dart';

class BengaliCalendarScreen extends StatefulWidget {
  const BengaliCalendarScreen({super.key});

  @override
  State<BengaliCalendarScreen> createState() => _BengaliCalendarScreenState();
}

class _BengaliCalendarScreenState extends State<BengaliCalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _filter = '\u09b8\u09ac \u09a6\u09bf\u09a8';

  final List<String> _filters = const [
    '\u09b8\u09ac \u09a6\u09bf\u09a8',
    '\u09b6\u09c1\u09ad \u09a6\u09bf\u09a8',
    '\u09ac\u09bf\u09ac\u09be\u09b9',
    '\u0985\u09ae\u09be\u09ac\u09b8\u09cd\u09af\u09be',
    '\u09aa\u09c2\u09b0\u09cd\u09a3\u09bf\u09ae\u09be',
    '\u0997\u09c3\u09b9\u09aa\u09cd\u09b0\u09ac\u09c7\u09b6',
    '\u098f\u0995\u09be\u09a6\u09b6\u09c0',
    '\u0989\u09ce\u09b8\u09ac',
  ];

  final List<String> _weekdays = const [
    '\u09b0\u09ac\u09bf',
    '\u09b8\u09cb\u09ae',
    '\u09ae\u0999\u09cd\u0997\u09b2',
    '\u09ac\u09c1\u09a7',
    '\u09ac\u09c3\u09b9\u09b8\u09cd\u09aa\u09a4\u09bf',
    '\u09b6\u09c1\u0995\u09cd\u09b0',
    '\u09b6\u09a8\u09bf',
  ];

  final List<String> _months = const [
    '\u099c\u09be\u09a8\u09c1\u09df\u09be\u09b0\u09bf',
    '\u09ab\u09c7\u09ac\u09cd\u09b0\u09c1\u09df\u09be\u09b0\u09bf',
    '\u09ae\u09be\u09b0\u09cd\u099a',
    '\u098f\u09aa\u09cd\u09b0\u09bf\u09b2',
    '\u09ae\u09c7',
    '\u099c\u09c1\u09a8',
    '\u099c\u09c1\u09b2\u09be\u0987',
    '\u0986\u0997\u09b8\u09cd\u099f',
    '\u09b8\u09c7\u09aa\u09cd\u099f\u09c7\u09ae\u09cd\u09ac\u09b0',
    '\u0985\u0995\u09cd\u099f\u09cb\u09ac\u09b0',
    '\u09a8\u09ad\u09c7\u09ae\u09cd\u09ac\u09b0',
    '\u09a1\u09bf\u09b8\u09c7\u09ae\u09cd\u09ac\u09b0',
  ];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final totalDays = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = firstDay.weekday % 7;
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F5),
        foregroundColor: const Color(0xFFC82335),
        elevation: 0,
        title: const Text(
          '\u09ac\u09be\u0982\u09b2\u09be \u0995\u09cd\u09af\u09be\u09b2\u09c7\u09a8\u09cd\u09a1\u09be\u09b0',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: _goToday,
            child: const Text(
              '\u0986\u099c',
              style: TextStyle(
                color: Color(0xFFC82335),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          _buildMonthHeader(),
          const SizedBox(height: 12),
          _buildFilters(),
          const SizedBox(height: 14),
          _buildCalendarHeader(),
          const SizedBox(height: 4),
          _buildCalendar(totalDays: totalDays, leading: leading, today: today),
          const SizedBox(height: 14),
          _buildInfoCard(today),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _month = DateTime(_month.year, _month.month - 1, 1);
                });
              },
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${_months[_month.month - 1]} ${_bn(_month.year)}',
                    style: const TextStyle(
                      color: Color(0xFFC82335),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    '\u09ae\u09be\u09b8\u09bf\u0995 \u0995\u09cd\u09af\u09be\u09b2\u09c7\u09a8\u09cd\u09a1\u09be\u09b0',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _month = DateTime(_month.year, _month.month + 1, 1);
                });
              },
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((item) {
          final selected = _filter == item;
          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChoiceChip(
              label: Text(item),
              selected: selected,
              onSelected: (_) => setState(() => _filter = item),
              selectedColor: const Color(0xFFC82335),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      children: List.generate(7, (index) {
        return Expanded(
          child: Center(
            child: Text(
              _weekdays[index],
              style: TextStyle(
                color: index == 0
                    ? const Color(0xFFC82335)
                    : const Color(0xFF1765A6),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalendar({
    required int totalDays,
    required int leading,
    required DateTime today,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: leading + totalDays,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.82,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        if (index < leading) {
          return const SizedBox.shrink();
        }

        final day = index - leading + 1;
        final date = DateTime(_month.year, _month.month, day);
        final isToday =
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSunday = date.weekday == DateTime.sunday;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showDay(date),
          child: Container(
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFFFE2E5) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday
                    ? const Color(0xFFC82335)
                    : const Color(0xFFE8DDE3),
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isToday)
                  const Text(
                    '\u0986\u099c',
                    style: TextStyle(
                      fontSize: 8,
                      color: Color(0xFFC82335),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                Text(
                  _bn(day),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isSunday
                        ? const Color(0xFFC82335)
                        : const Color(0xFF1765A6),
                  ),
                ),
                if (_filter != '\u09b8\u09ac \u09a6\u09bf\u09a8')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      _filter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 7,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(DateTime today) {
    final selectedMonth =
        _month.year == today.year && _month.month == today.month;

    return Card(
      elevation: 0,
      color: const Color(0xFFFFF8F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF0D5DA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFC82335),
              child: Icon(Icons.calendar_month, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedMonth
                    ? '\u0986\u099c\u0995\u09c7\u09b0 \u09a6\u09bf\u09a8\u099f\u09bf \u09a6\u09c7\u0996\u09a4\u09c7 \u0989\u09aa\u09b0\u09c7\u09b0 \u201c\u0986\u099c\u201d \u09ac\u09be\u09df\u09be\u09ae\u09c7\u09b0 \u09b8\u09be\u09a5\u09c7 \u09a6\u09bf\u09a8\u09c7 \u099f\u09cd\u09af\u09be\u09aa \u0995\u09b0\u09c1\u09a8\u0964'
                    : '\u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8 \u09ae\u09be\u09b8\u09c7 \u09ab\u09bf\u09b0\u09a4\u09c7 \u201c\u0986\u099c\u201d \u09ac\u09be\u09df\u09be\u09ae\u099f\u09bf \u09ac\u09cd\u09af\u09ac\u09b9\u09be\u09b0 \u0995\u09b0\u09c1\u09a8\u0964',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _month = DateTime(now.year, now.month, 1);
    });
  }

  void _showDay(DateTime date) {
    final weekday = _weekdays[date.weekday % 7];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_bn(date.day)} ${_months[date.month - 1]} ${_bn(date.year)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC82335),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\u09ac\u09be\u09b0: $weekday',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\u09ab\u09bf\u09b2\u09cd\u099f\u09be\u09b0: $_filter',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  '\u09aa\u099e\u09cd\u099c\u09bf\u0995\u09be \u09a4\u09a5\u09cd\u09af',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  '\u09a4\u09bf\u09a5\u09bf, \u09a8\u0995\u09cd\u09b7\u09a4\u09cd\u09b0, \u09b6\u09c1\u09ad \u09b8\u09ae\u09df \u098f\u09ac\u0982 \u0989\u09ce\u09b8\u09ac\u09c7\u09b0 \u09a1\u09be\u099f\u09be \u09af\u09c1\u0995\u09cd\u09a4 \u0995\u09b0\u09be\u09b0 \u09b8\u09c1\u09af\u09cb\u0997 \u098f\u0996\u09be\u09a8\u09c7 \u09a5\u09be\u0995\u09ac\u09c7\u0964',
                  style: TextStyle(color: Colors.black54, height: 1.45),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _bn(Object value) {
    return value
        .toString()
        .replaceAll('0', '\u09e6')
        .replaceAll('1', '\u09e7')
        .replaceAll('2', '\u09e8')
        .replaceAll('3', '\u09e9')
        .replaceAll('4', '\u09ea')
        .replaceAll('5', '\u09eb')
        .replaceAll('6', '\u09ec')
        .replaceAll('7', '\u09ed')
        .replaceAll('8', '\u09ee')
        .replaceAll('9', '\u09ef');
  }
}
