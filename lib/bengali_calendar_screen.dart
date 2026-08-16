import 'package:flutter/material.dart';

class BengaliCalendarScreen extends StatefulWidget {
  const BengaliCalendarScreen({super.key});

  @override
  State<BengaliCalendarScreen> createState() => _BengaliCalendarScreenState();
}

class _BengaliCalendarScreenState extends State<BengaliCalendarScreen> {
  DateTime _month = DateTime.now();
  String _filter = 'সব দিন';

  final List<String> _filters = const [
    'সব দিন',
    'শুভ দিন',
    'বিবাহ',
    'অমাবস্যা',
    'পূর্ণিমা',
    'গৃহপ্রবেশ',
    'একাদশী',
    'উৎসব',
  ];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final totalDays = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = firstDay.weekday % 7;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2F5),
        foregroundColor: const Color(0xFFC82335),
        elevation: 0,
        title: const Text(
          'বাংলা ক্যালেন্ডার',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          Row(
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
                      '${_monthName(_month.month)} ${_bn(_month.year)}',
                      style: const TextStyle(
                        color: Color(0xFFC82335),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'বাংলা মাস',
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
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((item) {
                final selected = _filter == item;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = item),
                    selectedColor: const Color(0xFFC82335),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _Week('রবি', red: true),
              _Week('সোম'),
              _Week('মঙ্গল'),
              _Week('বুধ'),
              _Week('বৃহঃ'),
              _Week('শুক্র'),
              _Week('শনি'),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leading + totalDays,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.78,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemBuilder: (context, index) {
              if (index < leading) {
                return Container(color: const Color(0xFFF0EAEE));
              }

              final day = index - leading + 1;
              final date = DateTime(_month.year, _month.month, day);
              final sunday = date.weekday == DateTime.sunday;

              return InkWell(
                onTap: () => _showDay(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE8DDE3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _bn(day),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: sunday
                              ? const Color(0xFFC82335)
                              : const Color(0xFF1765A6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _filter == 'সব দিন' ? '' : _filter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 7,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDay(DateTime date) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_bn(date.day)} ${_monthName(date.month)} ${_bn(date.year)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text('Filter: $_filter'),
              const SizedBox(height: 10),
              const Text(
                'পরের ধাপে এখানে সঠিক তিথি, নক্ষত্র, শুভ দিন, বিবাহ, পূর্ণিমা, অমাবস্যা ও উৎসবের তথ্য যুক্ত হবে।',
              ),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int m) {
    return const [
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ][m - 1];
  }

  String _bn(Object value) {
    return value
        .toString()
        .replaceAll('0', '০')
        .replaceAll('1', '১')
        .replaceAll('2', '২')
        .replaceAll('3', '৩')
        .replaceAll('4', '৪')
        .replaceAll('5', '৫')
        .replaceAll('6', '৬')
        .replaceAll('7', '৭')
        .replaceAll('8', '৮')
        .replaceAll('9', '৯');
  }
}

class _Week extends StatelessWidget {
  final String text;
  final bool red;
  const _Week(this.text, {this.red = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: red ? const Color(0xFFC82335) : const Color(0xFF1765A6),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
