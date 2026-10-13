import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length != 1) throw ArgumentError('Expected candidate main.dart');
  final file = File(args.single);
  var source = file.readAsStringSync();
  if (!source.contains('class CalendarChoiceScreen extends StatelessWidget')) {
    source = source.replaceAll('const BengaliCalendarScreen()', 'const CalendarChoiceScreen()');
    source = source.replaceAll('class BengaliCalendarScreen extends StatefulWidget {',
      utf8.decode(base64Decode('Ly8gQ2hvb3NlIGEgY2FsZW5kYXIgYmVmb3JlIG9wZW5pbmcgZWl0aGVyIGV4aXN0aW5nIGNhbGVuZGFyIHNjcmVlbi4NCmNsYXNzIENhbGVuZGFyQ2hvaWNlU2NyZWVuIGV4dGVuZHMgU3RhdGVsZXNzV2lkZ2V0IHsNCiAgY29uc3QgQ2FsZW5kYXJDaG9pY2VTY3JlZW4oe3N1cGVyLmtleX0pOw0KDQogIEBvdmVycmlkZQ0KICBXaWRnZXQgYnVpbGQoQnVpbGRDb250ZXh0IGNvbnRleHQpIHsNCiAgICBmaW5hbCBjb2xvcnMgPSBUaGVtZS5vZihjb250ZXh0KS5jb2xvclNjaGVtZTsNCiAgICBXaWRnZXQgb3B0aW9uKFN0cmluZyB0aXRsZSwgU3RyaW5nIGRlc2NyaXB0aW9uLCBJY29uRGF0YSBpY29uLCBXaWRnZXQgcGFnZSkgew0KICAgICAgcmV0dXJuIENhcmQoDQogICAgICAgIGNsaXBCZWhhdmlvcjogQ2xpcC5hbnRpQWxpYXMsDQogICAgICAgIGNoaWxkOiBJbmtXZWxsKA0KICAgICAgICAgIG9uVGFwOiAoKSA9PiBOYXZpZ2F0b3Iub2YoY29udGV4dCkucHVzaCgNCiAgICAgICAgICAgIE1hdGVyaWFsUGFnZVJvdXRlPHZvaWQ+KGJ1aWxkZXI6IChfKSA9PiBwYWdlKSwNCiAgICAgICAgICApLA0KICAgICAgICAgIGNoaWxkOiBQYWRkaW5nKA0KICAgICAgICAgICAgcGFkZGluZzogY29uc3QgRWRnZUluc2V0cy5hbGwoMjApLA0KICAgICAgICAgICAgY2hpbGQ6IFJvdygNCiAgICAgICAgICAgICAgY2hpbGRyZW46IFsNCiAgICAgICAgICAgICAgICBJY29uKGljb24sIHNpemU6IDMyLCBjb2xvcjogY29sb3JzLnByaW1hcnkpLA0KICAgICAgICAgICAgICAgIGNvbnN0IFNpemVkQm94KHdpZHRoOiAxNiksDQogICAgICAgICAgICAgICAgRXhwYW5kZWQoDQogICAgICAgICAgICAgICAgICBjaGlsZDogQ29sdW1uKA0KICAgICAgICAgICAgICAgICAgICBjcm9zc0F4aXNBbGlnbm1lbnQ6IENyb3NzQXhpc0FsaWdubWVudC5zdGFydCwNCiAgICAgICAgICAgICAgICAgICAgY2hpbGRyZW46IFsNCiAgICAgICAgICAgICAgICAgICAgICBUZXh0KHRpdGxlLCBzdHlsZTogY29uc3QgVGV4dFN0eWxlKA0KICAgICAgICAgICAgICAgICAgICAgICAgZm9udFNpemU6IDIwLCBmb250V2VpZ2h0OiBGb250V2VpZ2h0LmJvbGQsDQogICAgICAgICAgICAgICAgICAgICAgKSksDQogICAgICAgICAgICAgICAgICAgICAgY29uc3QgU2l6ZWRCb3goaGVpZ2h0OiA2KSwNCiAgICAgICAgICAgICAgICAgICAgICBUZXh0KGRlc2NyaXB0aW9uKSwNCiAgICAgICAgICAgICAgICAgICAgXSwNCiAgICAgICAgICAgICAgICAgICksDQogICAgICAgICAgICAgICAgKSwNCiAgICAgICAgICAgICAgICBjb25zdCBTaXplZEJveCh3aWR0aDogOCksDQogICAgICAgICAgICAgICAgY29uc3QgSWNvbihJY29ucy5jaGV2cm9uX3JpZ2h0X3JvdW5kZWQpLA0KICAgICAgICAgICAgICBdLA0KICAgICAgICAgICAgKSwNCiAgICAgICAgICApLA0KICAgICAgICApLA0KICAgICAgKTsNCiAgICB9DQoNCiAgICByZXR1cm4gU2NhZmZvbGQoDQogICAgICBhcHBCYXI6IEFwcEJhcih0aXRsZTogY29uc3QgVGV4dCgn4KaV4KeN4Kav4Ka+4Kay4KeH4Kao4KeN4Kah4Ka+4KawJykpLA0KICAgICAgYm9keTogU2FmZUFyZWEoDQogICAgICAgIGNoaWxkOiBMaXN0VmlldygNCiAgICAgICAgICBwYWRkaW5nOiBjb25zdCBFZGdlSW5zZXRzLmFsbCgyMCksDQogICAgICAgICAgY2hpbGRyZW46IFsNCiAgICAgICAgICAgIGNvbnN0IFRleHQoJ+CmhuCmquCmqOCmvuCmsCDgppXgp43gpq/gpr7gprLgp4fgpqjgp43gpqHgpr7gprAg4Kas4KeH4Kab4KeHIOCmqOCmv+CmqCcsDQogICAgICAgICAgICAgIHN0eWxlOiBUZXh0U3R5bGUoZm9udFNpemU6IDI0LCBmb250V2VpZ2h0OiBGb250V2VpZ2h0LmJvbGQpKSwNCiAgICAgICAgICAgIGNvbnN0IFNpemVkQm94KGhlaWdodDogOCksDQogICAgICAgICAgICBjb25zdCBUZXh0KCfgpq/gp4cg4KaV4KeN4Kav4Ka+4Kay4KeH4Kao4KeN4Kah4Ka+4KawIOCmpuCnh+CmluCmpOCnhyDgpprgpr7gpqgsIOCmqOCmv+CmmuCnh+CmsCDgpqzgpr7gpp/gpqjgp4cg4Kaa4Ka+4Kaq4KeB4Kao4KWkJyksDQogICAgICAgICAgICBjb25zdCBTaXplZEJveChoZWlnaHQ6IDI0KSwNCiAgICAgICAgICAgIG9wdGlvbign4Ka44Ka54KacIOCmleCnjeCmr+CmvuCmsuCnh+CmqOCnjeCmoeCmvuCmsCcsICfgprjgprngppzgpq3gpr7gpqzgp4cg4Kau4Ka+4Ka44KeH4KawIOCmpuCmv+CmqCDgppMg4KaJ4KeO4Ka44KasIOCmpuCnh+CmluCngeCmqCcsDQogICAgICAgICAgICAgIEljb25zLmNhbGVuZGFyX3ZpZXdfbW9udGhfcm91bmRlZCwNCiAgICAgICAgICAgICAgY29uc3QgRWFzeUJlbmdhbGlDYWxlbmRhclNjcmVlbigpKSwNCiAgICAgICAgICAgIGNvbnN0IFNpemVkQm94KGhlaWdodDogMTIpLA0KICAgICAgICAgICAgb3B0aW9uKCfgpqrgpp7gp43gppzgpr/gppXgpr4g4KaV4KeN4Kav4Ka+4Kay4KeH4Kao4KeN4Kah4Ka+4KawJywgJ+CmrOCmv+CmuOCnjeCmpOCmvuCmsOCmv+CmpCDgpqzgpr7gpoLgprLgpr4g4Kaq4Kae4KeN4Kac4Ka/4KaV4Ka+IOCmpuCnh+CmluCngeCmqCcsDQogICAgICAgICAgICAgIEljb25zLmRhdGVfcmFuZ2Vfcm91bmRlZCwgY29uc3QgQmVuZ2FsaUNhbGVuZGFyU2NyZWVuKCkpLA0KICAgICAgICAgIF0sDQogICAgICAgICksDQogICAgICApLA0KICAgICk7DQogIH0NCn0NCg0K')) + 'class BengaliCalendarScreen extends StatefulWidget {');
  }
  const start = 'class _BengaliCalendarScreenState';
  const end = 'class ReminderItem {';
  final a = source.indexOf(start), b = source.indexOf(end);
  if (a < 0 || b < a) throw StateError('Calendar section missing');
  var s = source.substring(a, b).replaceAll('\r\n', '\n');
  void replace(String old, String value) {
    if (!s.contains(old)) throw StateError('Expected calendar fragment missing: $old');
    s = s.replaceAll(old, value);
  }
  replace('return CosmicBackground(\n      child: Material(',
      'return SafeArea(\n      child: Material(');
  replace('color: Colors.transparent,\n        child: Column(',
      'color: const Color(0xFFFFF9ED),\n        child: Column(');
  replace("'বাংলা ক্যালেন্ডার \${info.start.year}'", "'বাংলা পঞ্জিকা'");
  final buttonStart = s.indexOf('                                    SizedBox(');
  final buttonEnd = s.indexOf('                  // ---- ট্যাব বার (ফিল্টার) ----', buttonStart);
  if (buttonStart < 0 || buttonEnd < buttonStart) throw StateError('Calendar switch button missing');
  s = s.replaceRange(buttonStart, buttonEnd, '');
  replace('                  _sidebarPanel(context, info),\n                  const SizedBox(height: 12),', '');
  replace('                  _MonthlyPanjikaSlider(info: info),',
      '                  const SizedBox(height: 16),\n                  _sidebarPanel(context, info),\n                  const SizedBox(height: 12),\n                  _MonthlyPanjikaSlider(info: info),');
  // The almanac panel must describe the selected day, or the displayed month.
  replace('final now = DateTime.now();\n    final sun = PanchangCalculator.sunTimes(',
      'final now = _selectedKey == null ? _anchor : DateTime.parse(_selectedKey!);\n    final sun = PanchangCalculator.sunTimes(');
  replace("'শকাব্দ \${bnNum(shaka)}'", "'\${bnNum(now.day)} \${gregMonthBn(now.month)} • শকাব্দ \${bnNum(shaka)}'");
  // Printed paper palette, restricted to this calendar and its own cells.
  s = s.replaceAllMapped(RegExp(r'Colors\.white(70|60|54|24)?\b'), (m) =>
      m[1] == '24' ? 'const Color(0xFF9C9389)' :
      m[1] == null ? 'const Color(0xFF2B211B)' : 'const Color(0xFF67564A)');
  for (final color in ['0xFFFFD36E', '0xFFFFD467', '0xFFFF8A80', '0xFFE0384A']) {
    s = s.replaceAll(color, '0xFFA52222');
  }
  for (final color in ['0xFF07182E', '0xFF06152B', '0xFF2B0E45', '0xFF071428']) {
    s = s.replaceAll(color, '0xFFFFF2DC');
  }
  s = s.replaceAll('0xFF6A2D72', '0xFFE9CFA5');
  // Replace the date-cell palette separately, with explicit today/selection borders.
  replace('borderRadius: BorderRadius.circular(9),', 'borderRadius: BorderRadius.circular(2),');
  replace('color: widget.isSelected\n                  ? const Color(0xFFA52222)',
      'color: widget.isSelected\n                  ? const Color(0xFF1565C0)');
  replace('mainAxisSpacing: 4,\n                          crossAxisSpacing: 4,',
      'mainAxisSpacing: 1,\n                          crossAxisSpacing: 1,');
  replace('childAspectRatio: 1 / (1.30 * _tsFactor(context)),',
      'mainAxisExtent: 112 * _tsFactor(context),');
  final tithiStart = s.indexOf('                      // ঘরে তিথির সংখ্যা');
  final tithiEnd = s.indexOf('                      SizedBox(', tithiStart);
  if (tithiStart < 0 || tithiEnd < tithiStart) throw StateError('Tithi insertion missing');
  s = s.replaceRange(tithiStart, tithiEnd, '''                      Text(
                        widget.tithiName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, height: 1.2,
                          color: Color(0xFF67564A)),
                      ),
                      const SizedBox(height: 3),
''');
  // Keep the information stable, like a printed almanac.
  replace('height: (widget.isToday || hasEventLabel) ? 17 : 0,',
      'height: hasEventLabel ? 28 : 0,');
  final animationStart = s.indexOf('child: widget.isToday\n                            ? AnimatedSwitcher(');
  final animationEnd = s.indexOf('                            : Center(', animationStart);
  if (animationStart < 0 || animationEnd < animationStart) throw StateError('Cell animation missing');
  s = s.replaceRange(animationStart, animationEnd + '                            : '.length, 'child: ');
  // The active filter uses red ink on a pale paper fill.
  replace('? const Color(0xFFA52222)\n                                  :',
      '? const Color(0xFFF1D5B5)\n                                  :');
  replace('? const Color(0xFFFFF2DC)\n                                    :',
      '? const Color(0xFFA52222)\n                                    :');
  source = source.replaceRange(a, b, s.replaceAll('\n', '\r\n'));
  file.writeAsStringSync(source);
  stdout.writeln('Printed Bengali panjika layout applied.');
}
