import 'dart:io';
import 'apply_panjika_refined.dart' as previous;
void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Expected candidate main.dart');
  final file = File(args.single);
  if (!file.readAsStringSync().contains('// Symbols have a dedicated row')) previous.main(args);
  var source = file.readAsStringSync();
  final a = source.indexOf('class _CalendarDayCellState extends State<_CalendarDayCell>');
  final b = source.indexOf('class ReminderItem {', a);
  if (a < 0 || b < a) throw StateError('Calendar cell missing');
  var cell = source.substring(a, b).replaceAll('\r\n', '\n');
  const old = 'final color = widget.isSunday || special ? red : ink;';
  if (!cell.contains(old)) throw StateError('Expected date color rule missing');
  cell = cell.replaceAll(old, """// Match the existing West Bengal holiday list, including Sundays.
    final holidays = HolidayCalendar.forMonth(widget.greg);
    final isHoliday = holidays.any((day) => day.date.day == widget.greg.day);
    final color = isHoliday ? red : ink;""");
  cell = cell.replaceAll('fontWeight: FontWeight.w600, color: Color(0xFF68594A)))',
    'fontWeight: FontWeight.w600, color: color))');
  cell = cell.replaceAll('style: const TextStyle(fontSize: 9,', 'style: TextStyle(fontSize: 9,');
  // Event text and decorations must not masquerade as holiday date markings.
  cell = cell.replaceAll('fontWeight: FontWeight.w600, color: red)),',
    'fontWeight: FontWeight.w600, color: ink)),');
  cell = cell.replaceAll('Icons.auto_awesome, size: 12, color: red',
    'Icons.auto_awesome, size: 12, color: Color(0xFF82612D)');
  cell = cell.replaceAll(': widget.isToday ? red :',
    ': widget.isToday ? const Color(0xFF99712B) :');
  cell = cell.replaceAll('fontWeight: FontWeight.bold, color: red)',
    'fontWeight: FontWeight.bold, color: Color(0xFF76551D))');
  source = source.replaceRange(a, b, cell.replaceAll('\n', '\r\n'));
  final pageStart = source.indexOf('class _BengaliCalendarScreenState');
  final pageEnd = source.indexOf('class _MonthlyPanjikaSlider', pageStart);
  var page = source.substring(pageStart, pageEnd).replaceAll('\r\n', '\n');
  final legendStart = page.indexOf('                  // ---- রং-কোডিংয়ের সংক্ষিপ্ত নির্দেশিকা ----');
  final legendEnd = page.indexOf('                  const SizedBox(height: 16),', legendStart);
  if (legendStart < 0 || legendEnd < legendStart) throw StateError('Calendar legend missing');
  page = page.replaceRange(legendStart, legendEnd, """                  const Text(
                    'লাল তারিখ: রবিবার ও পশ্চিমবঙ্গের তালিকাভুক্ত সরকারি ছুটি। অন্য তারিখ: কালো।',
                    style: TextStyle(color: Color(0xFF67564A), fontSize: 12, height: 1.5),
                  ),
                  if (!HolidayCalendar.hasPublishedList(info.start.year) ||
                      !HolidayCalendar.hasPublishedList(info.end.year))
                    const Text('এই বছরের সরকারি ছুটির তালিকা যোগ হয়নি; শুধু রবিবার লাল দেখানো হচ্ছে।',
                      style: TextStyle(color: Color(0xFF67564A), fontSize: 12)),
""");
  source = source.replaceRange(pageStart, pageEnd, page.replaceAll('\n', '\r\n'));
  file.writeAsStringSync(source);
  stdout.writeln('Only listed holidays and Sundays use red date numbers.');
}
