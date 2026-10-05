$ErrorActionPreference = 'Stop'

$path = 'lib/main.dart'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$original = $text

# 1) Link the new screen as a Dart part, preserving the existing main.dart text.
if ($text -notmatch "part 'easy_calendar_screen\.dart';") {
  $importAnchor = "import 'package:url_launcher/url_launcher.dart';"
  $importIndex = $text.IndexOf($importAnchor)
  if ($importIndex -lt 0) {
    throw 'Could not find url_launcher import anchor in main.dart.'
  }
  $insertAt = $importIndex + $importAnchor.Length
  $text = $text.Insert($insertAt, "`n`npart 'easy_calendar_screen.dart';")
}

# 2) Add the Easy Calendar as the second visible option in the LIVE calendar tab bar.
$classAnchor = 'class _BengaliCalendarScreenState extends State<BengaliCalendarScreen>'
$classStart = $text.IndexOf($classAnchor)
if ($classStart -lt 0) {
  throw 'Could not find live Bengali calendar state class.'
}

$tabsStart = $text.IndexOf('static const _tabs = [', $classStart)
if ($tabsStart -lt 0) {
  throw 'Could not find live calendar tabs.'
}
$tabsEnd = $text.IndexOf('];', $tabsStart)
if ($tabsEnd -lt 0) {
  throw 'Could not find end of live calendar tabs.'
}
$tabsLength = ($tabsEnd + 2) - $tabsStart
$tabsBlock = $text.Substring($tabsStart, $tabsLength)

if ($tabsBlock -notmatch 'সহজ ক্যালেন্ডার') {
  $oldFirstTab = "'সম্পূর্ণ মাস',"
  $firstTabIndex = $tabsBlock.IndexOf($oldFirstTab)
  if ($firstTabIndex -lt 0) {
    throw 'Could not find সম্পূর্ণ মাস inside live calendar tabs.'
  }
  $afterFirstTab = $firstTabIndex + $oldFirstTab.Length
  $tabsBlock = $tabsBlock.Insert($afterFirstTab, "`n    'সহজ ক্যালেন্ডার',")
  $text = $text.Remove($tabsStart, $tabsLength).Insert($tabsStart, $tabsBlock)
}

# 3) Make that option open the elderly-friendly screen, while every old tab keeps working unchanged.
$classStart = $text.IndexOf($classAnchor)
$tapAnchor = 'onTap: () => setState(() => _tab = t),'
$tapIndex = $text.IndexOf($tapAnchor, $classStart)

if ($text.IndexOf('const EasyBengaliCalendarScreen()', $classStart) -lt 0) {
  if ($tapIndex -lt 0) {
    throw 'Could not find live calendar tab onTap handler.'
  }

  $replacement = @"
onTap: () {
                            if (t == 'সহজ ক্যালেন্ডার') {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const EasyBengaliCalendarScreen(),
                                ),
                              );
                              return;
                            }
                            setState(() => _tab = t);
                          },
"@

  $text = $text.Remove($tapIndex, $tapAnchor.Length).Insert($tapIndex, $replacement.TrimEnd("`r", "`n"))
}

if ($text -eq $original) {
  Write-Host 'Easy Calendar patch is already present; no changes needed.'
  exit 0
}

# Final safety checks before writing.
if ($text -notmatch "part 'easy_calendar_screen\.dart';") {
  throw 'Safety check failed: Dart part directive missing.'
}
if ($text -notmatch 'সহজ ক্যালেন্ডার') {
  throw 'Safety check failed: Easy Calendar label missing.'
}
if ($text -notmatch 'EasyBengaliCalendarScreen') {
  throw 'Safety check failed: Easy Calendar route missing.'
}

[System.IO.File]::WriteAllText($path, $text, $utf8)
Write-Host 'Easy Calendar entry patch applied safely to lib/main.dart.'
