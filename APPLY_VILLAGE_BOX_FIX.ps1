$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainFile = Join-Path $projectRoot 'lib\main.dart'
$backupFile = Join-Path $projectRoot 'lib\main.dart.village_box_backup'

if (-not (Test-Path $mainFile)) {
  throw "lib\main.dart not found. Run this script from the bangla-panjika project folder."
}

$content = [System.IO.File]::ReadAllText($mainFile)

$old = @"
    String festival = '';
    try {
      final events = BengaliCalendarData.eventsFor(now);
      if (events.isNotEmpty) {
        festival = events.take(2).map((e) => e.label).join(' • ');
      }
    } catch (_) {}
"@

$new = @"
    String festival = '';
    try {
      final events = BengaliCalendarData.eventsFor(now);
      final festivalEvents = events
          .where((e) => e.category == 'general')
          .toList();
      if (festivalEvents.isNotEmpty) {
        festival = festivalEvents.take(2).map((e) => e.label).join(' • ');
      }
    } catch (_) {}
"@

$matchCount = ([regex]::Matches($content, [regex]::Escape($old))).Count
if ($matchCount -lt 1) {
  throw 'Target village festival block was not found. No file was changed.'
}

Copy-Item $mainFile $backupFile -Force
$updated = $content.Replace($old, $new)
[System.IO.File]::WriteAllText($mainFile, $updated, [System.Text.UTF8Encoding]::new($false))

Write-Host "Village box fix applied successfully. Updated block count: $matchCount" -ForegroundColor Green
Write-Host "Backup: lib\main.dart.village_box_backup"
Write-Host "Now run: flutter run"
