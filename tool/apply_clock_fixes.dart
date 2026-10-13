// Apply only the three audited clock fixes, preserving unrelated local edits.
// Usage: dart apply_clock_fixes.dart [path/to/lib/main.dart]
import 'dart:io';

void main(List<String> args) {
  final file = File(args.isEmpty ? 'lib/main.dart' : args.single);
  final original = file.readAsStringSync();
  final newline = original.contains('\r\n') ? '\r\n' : '\n';
  var updated = original.replaceAll('\r\n', '\n');
  for (final change in changes) {
    if (updated.contains(change.$2)) continue;
    final count = change.$1.allMatches(updated).length;
    if (count != 1) {
      throw StateError('Unrecognized source (${change.$3}). No files changed.');
    }
    updated = updated.replaceFirst(change.$1, change.$2);
  }
  updated = updated.replaceAll('\n', newline);
  if (updated == original) {
    stdout.writeln('Clock fixes already installed.');
    return;
  }
  final backup =
      '${file.path}.before_clock_fix_${DateTime.now().microsecondsSinceEpoch}';
  file.copySync(backup);
  file.writeAsStringSync(updated, flush: true);
  stdout.writeln('Applied 3 clock fixes. Backup: $backup');
}

const changes = <(String, String, String)>[
  (
    '''DateTime panchangInstant(DateTime t) =>
    DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);''',
    '''DateTime panchangInstant(DateTime t) => t.isUtc
    ? t.subtract(const Duration(hours: 5, minutes: 30)).toLocal()
    : t;''',
    'IST instant conversion',
  ),
  (
    '''(known.millisecondsSinceEpoch + unknown.millisecondsSinceEpoch) ~/ 2,
        );''',
    '''(known.millisecondsSinceEpoch + unknown.millisecondsSinceEpoch) ~/ 2,
          isUtc: moment.isUtc,
        );''',
    'tithi transition search',
  ),
  (
    '''(loT.millisecondsSinceEpoch + hiT.millisecondsSinceEpoch) ~/ 2,
        );''',
    '''(loT.millisecondsSinceEpoch + hiT.millisecondsSinceEpoch) ~/ 2,
          isUtc: loT.isUtc,
        );''',
    'moonrise/moonset search',
  ),
];
