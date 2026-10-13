part of 'main.dart';

class HolidayScreen extends StatefulWidget {
  const HolidayScreen({super.key});
  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen>
    with WidgetsBindingObserver {
  late DateTime _month;
  late DateTime _observedMonth;
  bool _followCurrentMonth = true;
  Timer? _clock;
  final _scroll = ScrollController();

  DateTime _currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  @override
  void initState() {
    super.initState();
    _month = _observedMonth = _currentMonth();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => _refreshMonth());
  }

  void _refreshMonth() {
    final current = _currentMonth();
    if (!mounted || current == _observedMonth) return;
    setState(() {
      _observedMonth = current;
      if (_followCurrentMonth) _month = current;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshMonth();
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  void _selectMonth(DateTime month) {
    setState(() {
      _month = month;
      _observedMonth = _currentMonth();
      _followCurrentMonth = _month == _observedMonth;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  String get _title => '${gregMonthBn(_month.month)} ${bnNum(_month.year)}';

  String _dateLabel(HolidayDay day) =>
      '${bnNum(day.date.day)} ${gregMonthBn(day.date.month)}'
      ' • ${PanchangCalculator.weekdayName(day.date)}';

  void _share(List<HolidayDay> days) {
    final text = StringBuffer('ছুটির দিন — $_title\nপশ্চিমবঙ্গ\n');
    if (!HolidayCalendar.hasPublishedList(_month.year)) {
      text.writeln('সরকারি তালিকা এখনও যোগ হয়নি; শুধু রবিবার দেখানো হচ্ছে।');
    }
    for (final day in days) {
      text.writeln('${_dateLabel(day)} — ${day.name} (${day.kind})');
    }
    text.writeln(
      '\nস্কুল, ব্যাংক ও বেসরকারি প্রতিষ্ঠানের ছুটি আলাদা হতে পারে।',
    );
    text.writeln(HolidayCalendar.sourceUrl);
    shareFromApp(text.toString(), subject: '$_title — ছুটির তালিকা');
  }

  Future<void> _remind(HolidayDay day) async {
    final when = DateTime(day.date.year, day.date.month, day.date.day, 9);
    if (!when.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই রিমাইন্ডারের সময় পেরিয়ে গেছে')),
      );
      return;
    }
    await ReminderStore.instance.load();
    await ReminderStore.instance.add(ReminderItem(day.name, when));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('সকাল ৯টার রিমাইন্ডার রাখা হয়েছে')),
    );
  }

  void _detail(HolidayDay day) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A1A31),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${_dateLabel(day)} ${bnNum(day.date.year)}',
                style: const TextStyle(color: Colors.white, fontSize: 17),
              ),
              const SizedBox(height: 8),
              Text(day.kind, style: const TextStyle(color: Color(0xFFFFD36E))),
              const SizedBox(height: 16),
              const Text(
                'পশ্চিমবঙ্গের ছুটির তালিকা। প্রতিষ্ঠান অনুযায়ী ছুটি আলাদা হতে পারে।',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _remind(day);
                    },
                    icon: const Icon(Icons.alarm_add),
                    label: const Text('মনে করিয়ে দাও'),
                  ),
                  TextButton.icon(
                    onPressed: () => shareFromApp(
                      '${day.name}\n${_dateLabel(day)} ${bnNum(day.date.year)}\n'
                      '${day.kind}\nপশ্চিমবঙ্গ',
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('শেয়ার'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = HolidayCalendar.forMonth(_month);
    final published = HolidayCalendar.hasPublishedList(_month.year);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return CosmicBackground(
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Expanded(
                  child: Text(
                    'ছুটির দিন',
                    style: TextStyle(
                      color: Color(0xFFFFD36E),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _share(days),
                  tooltip: 'এই মাসের তালিকা শেয়ার করুন',
                  icon: const Icon(Icons.share, color: Color(0xFFFFD36E)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'আগের মাস',
                    onPressed: () =>
                        _selectMonth(DateTime(_month.year, _month.month - 1)),
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      _title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'পরের মাস',
                    onPressed: () =>
                        _selectMonth(DateTime(_month.year, _month.month + 1)),
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _selectMonth(_currentMonth()),
              child: Text(_followCurrentMonth ? 'চলতি মাস' : 'চলতি মাসে ফিরুন'),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                children: [
                  Text(
                    'পশ্চিমবঙ্গ • এই মাসে ${bnNum(days.length)} দিন ছুটি',
                    style: const TextStyle(
                      color: Color(0xFFFFD36E),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    published
                        ? 'ঘোষিত ছুটি ও রবিবার। স্কুল, ব্যাংক এবং বেসরকারি প্রতিষ্ঠানের তালিকা আলাদা হতে পারে।'
                        : 'এই বছরের সরকারি ছুটির তালিকা এখনও যোগ হয়নি। নিচে শুধু রবিবার দেখানো হচ্ছে।',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  for (final day in days)
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: day.date == today
                              ? const Color(0xFFFFD36E)
                              : Colors.white12,
                        ),
                      ),
                      color: const Color(0xFF10233D),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        onTap: () => _detail(day),
                        leading: Container(
                          width: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD36E)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FittedBox(
                            child: Text(
                              bnNum(day.date.day),
                              style: const TextStyle(
                                color: Color(0xFFFFD36E),
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          day.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${PanchangCalculator.weekdayName(day.date)} • ${day.kind}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(HolidayCalendar.sourceUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('সরকারি ছুটির তালিকা'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
