import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // replace events
  content = content.replaceAll(
    "CalendarEvent('à¦…à¦®à¦¾à¦¬à¦¸à§ à¦¯à¦¾', 'general', icon: 'ðŸŒ‘')",
    "CalendarEvent('à¦…à¦®à¦¾à¦¬à¦¸à§ à¦¯à¦¾', 'amabasya', icon: 'ðŸŒ‘')"
  );
  content = content.replaceAll(
    "CalendarEvent('à¦ à¦•à¦¾à¦¦à¦¶à§€', 'general', icon: 'ðŸŒ‘')",
    "CalendarEvent('à¦ à¦•à¦¾à¦¦à¦¶à§€', 'ekadashi', icon: 'ðŸŒ‘')"
  );
  content = content.replaceAll(
    "CalendarEvent('à¦ªà§‚à¦°à§ à¦£à¦¿à¦®à¦¾', 'general', icon: 'ðŸŒ•')",
    "CalendarEvent('à¦ªà§‚à¦°à§ à¦£à¦¿à¦®à¦¾', 'purnima', icon: 'ðŸŒ•')"
  );
  
  // specific multiline strings
  content = content.replaceAll('''        'à¦¬à§ˆà¦¶à¦¾à¦– à¦ªà§‚à¦°à§ à¦£à¦¿à¦®à¦¾',
        'general',
        icon: 'ðŸŒ•',''', '''        'à¦¬à§ˆà¦¶à¦¾à¦– à¦ªà§‚à¦°à§ à¦£à¦¿à¦®à¦¾',
        'purnima',
        icon: 'ðŸŒ•',''');
        
  content = content.replaceAll('''        'à¦—à§ à¦°à§  à¦ªà§‚à¦°à§ à¦£à¦¿à¦®à¦¾',
        'general',
        icon: 'ðŸŒ•',''', '''        'à¦—à§ à¦°à§  à¦ªà§‚à¦°à§ à¦£à¦¿à¦®à¦¾',
        'purnima',
        icon: 'ðŸŒ•',''');
        
  content = content.replaceAll('''        'à¦•à¦¾à¦°à§ à¦¤à¦¿à¦• à¦ªà§‚à¦°à§ à¦£à¦¿à¦®à¦¾',
        'general',
        icon: 'ðŸŒ•',''', '''        'à¦•à¦¾à¦°à§ à¦¤à¦¿à¦• à¦ªà§‚à¦°à§ à¦£à¦¿à¦®à¦¾',
        'purnima',
        icon: 'ðŸŒ•',''');

  // Fix the duplicate à¦ªà§ à¦°à¦œà¦¾à¦¤à¦¨à§ à¦¤à§ à¦° à¦¦à¦¿à¦¬à¦¸ that was accidentally added earlier
  content = content.replaceAll('''      CalendarEvent(
        'à¦ªà§ à¦°à¦œà¦¾à¦¤à¦¨à§ à¦¤à§ à¦° à¦¦à¦¿à¦¬à¦¸',
        'à¦ªà§ à¦°à¦œà¦¾à¦¤à¦¨à§ à¦¤à§ à¦° à¦¦à¦¿à¦¬à¦¸',
        'general',
        icon: 'ðŸ‡®ðŸ‡³',
      ),''', '''      CalendarEvent(
        'à¦ªà§ à¦°à¦œà¦¾à¦¤à¦¨à§ à¦¤à§ à¦° à¦¦à¦¿à¦¬à¦¸',
        'general',
        icon: 'ðŸ‡®ðŸ‡³',
      ),''');

  // Also fix the duplicate à¦…à¦—à§ à¦°à¦¹à¦¾à¦¯à¦¼à¦£ that was accidentally added
  content = content.replaceAll('''      {
        'name': 'à¦…à¦—à§ à¦°à¦¹à¦¾à¦¯à¦¼à¦£',
        'date': DateTime(g, 11, 17),
        'bYear': by,
      },
      {'name': 'à¦…à¦—à§ à¦°à¦¹à¦¾à¦¯à¦¼à¦£', 'date': DateTime(g, 11, 17), 'bYear': by},''', '''      {
        'name': 'à¦…à¦—à§ à¦°à¦¹à¦¾à¦¯à¦¼à¦£',
        'date': DateTime(g, 11, 17),
        'bYear': by,
      },''');

  file.writeAsStringSync(content);
  print('Done!');
}
