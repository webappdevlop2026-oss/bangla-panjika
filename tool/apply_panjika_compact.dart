import 'dart:io';
import 'apply_panjika_holiday_ink.dart' as previous;
void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Expected candidate main.dart');
  final file = File(args.single);
  if (!file.readAsStringSync().contains('final color = isHoliday ? red : ink;')) previous.main(args);
  var source = file.readAsStringSync();
  final a = source.indexOf('class _CalendarDayCellState extends State<_CalendarDayCell>');
  final b = source.indexOf('class ReminderItem {', a);
  if (a < 0 || b < a) throw StateError('Calendar cell missing');
  var cell = source.substring(a,b).replaceAll('\r\n', '\n');
  cell = cell.replaceAll('    final special = widget.events.isNotEmpty;\n', '');
  cell = cell.replaceAll('padding: const EdgeInsets.symmetric(vertical: 4),',
    'height: 18 * _tsFactor(context),\n                    alignment: Alignment.center,');
  final tithiStart = cell.indexOf('                  Padding(');
  final eventStart = cell.indexOf('                  SizedBox(\n                    height: 29', tithiStart);
  if (tithiStart < 0 || eventStart < tithiStart) throw StateError('Cell rows missing');
  cell = cell.replaceRange(tithiStart,eventStart, '''                  SizedBox(
                    height: 27 * _tsFactor(context),
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(widget.tithiName,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, height: 1.25,
                          fontWeight: FontWeight.w600, color: ink)),
                    ),
                  ),
''');
  cell = cell.replaceAll('height: 29 * _tsFactor(context)', 'height: 27 * _tsFactor(context)');
  source = source.replaceRange(a,b,cell.replaceAll('\n','\r\n'));
  final pageStart = source.indexOf('class _BengaliCalendarScreenState');
  final pageEnd = source.indexOf('class _MonthlyPanjikaSlider', pageStart);
  var page = source.substring(pageStart,pageEnd);
  if (!page.contains('mainAxisExtent: 148 * _tsFactor(context)')) throw StateError('Grid size missing');
  page = page.replaceAll('mainAxisExtent: 148 * _tsFactor(context)',
      'mainAxisExtent: 112 * _tsFactor(context)');
  page = page.replaceAll('color: const Color(0xFF9C9389),\r\n                                  fontSize: 14,',
      'color: const Color(0xFF9C9389),\r\n                                  fontSize: 25, height: 1.1, fontWeight: FontWeight.w900,');
  source = source.replaceRange(pageStart,pageEnd,page);
  file.writeAsStringSync(source);
  stdout.writeln('Compact equal-height calendar cells and aligned text rows applied.');
}
