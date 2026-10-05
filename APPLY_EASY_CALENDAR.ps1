$ErrorActionPreference = 'Stop'

$path = 'lib/main.dart'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$original = $text

# Keep the separate Easy Calendar screen linked to main.dart.
if ($text -notmatch "part 'easy_calendar_screen\.dart';") {
  $importAnchor = "import 'package:url_launcher/url_launcher.dart';"
  $importIndex = $text.IndexOf($importAnchor)
  if ($importIndex -lt 0) { throw 'Could not find import anchor.' }
  $insertAt = $importIndex + $importAnchor.Length
  $text = $text.Insert($insertAt, "`n`npart 'easy_calendar_screen.dart';")
}

$classAnchor = 'class _BengaliCalendarScreenState extends State<BengaliCalendarScreen>'
$classStart = $text.IndexOf($classAnchor)
if ($classStart -lt 0) { throw 'Could not find live Bengali calendar state class.' }

# Remove Easy Calendar from the horizontal filter/tab list.
$tabsStart = $text.IndexOf('static const _tabs = [', $classStart)
if ($tabsStart -lt 0) { throw 'Could not find live calendar tabs.' }
$tabsEnd = $text.IndexOf('];', $tabsStart)
if ($tabsEnd -lt 0) { throw 'Could not find end of live calendar tabs.' }
$tabsLength = ($tabsEnd + 2) - $tabsStart
$tabsBlock = $text.Substring($tabsStart, $tabsLength)
$tabsBlock = $tabsBlock.Replace("    'সহজ ক্যালেন্ডার',`r`n", '')
$tabsBlock = $tabsBlock.Replace("    'সহজ ক্যালেন্ডার',`n", '')
$text = $text.Remove($tabsStart, $tabsLength).Insert($tabsStart, $tabsBlock)

# Restore normal tap behavior for the remaining filter tabs if an older patch is present.
$classStart = $text.IndexOf($classAnchor)
$handlerPattern = "onTap:\s*\(\)\s*\{\s*if \(t == 'সহজ ক্যালেন্ডার'\)\s*\{.*?setState\(\(\) => _tab = t\);\s*\},"
$handlerRegex = [regex]::new($handlerPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$afterClass = $text.Substring($classStart)
if ($handlerRegex.IsMatch($afterClass)) {
  $afterClass = $handlerRegex.Replace($afterClass, 'onTap: () => setState(() => _tab = t),', 1)
  $text = $text.Substring(0, $classStart) + $afterClass
}

# Repair the previous build-breaking FilledButton.icon tooltip argument.
$text = $text.Replace("                      tooltip: 'বয়স্কদের জন্য সহজ ক্যালেন্ডার',`r`n", "                      // EASY_CALENDAR_STANDALONE_BUTTON`r`n")
$text = $text.Replace("                      tooltip: 'বয়স্কদের জন্য সহজ ক্যালেন্ডার',`n", "                      // EASY_CALENDAR_STANDALONE_BUTTON`n")

# Add ONE large standalone button immediately above the filter tabs if it is missing.
$classStart = $text.IndexOf($classAnchor)
$tabComment = '// ---- ট্যাব বার (ফিল্টার) ----'
$commentIndex = $text.IndexOf($tabComment, $classStart)
if ($commentIndex -lt 0) { throw 'Could not find filter-tab insertion point.' }

$standaloneMarker = '// EASY_CALENDAR_STANDALONE_BUTTON'
if ($text.IndexOf($standaloneMarker, $classStart) -lt 0) {
  $button = @"
                  // EASY_CALENDAR_STANDALONE_BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52 * _tsFactor(context),
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EasyBengaliCalendarScreen(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1765A6),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.calendar_view_month_rounded,
                        size: 22,
                      ),
                      label: const Text(
                        'সহজ ক্যালেন্ডার',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
"@
  $text = $text.Insert($commentIndex, $button)
}

# Safety checks.
$classStart = $text.IndexOf($classAnchor)
$tabsStart = $text.IndexOf('static const _tabs = [', $classStart)
$tabsEnd = $text.IndexOf('];', $tabsStart)
$tabsBlock = $text.Substring($tabsStart, ($tabsEnd + 2) - $tabsStart)
if ($tabsBlock -match 'সহজ ক্যালেন্ডার') {
  throw 'Safety check failed: Easy Calendar is still inside filter tabs.'
}
if ($text.IndexOf($standaloneMarker, $classStart) -lt 0) {
  throw 'Safety check failed: standalone Easy Calendar button missing.'
}
if ($text.IndexOf('const EasyBengaliCalendarScreen()', $classStart) -lt 0) {
  throw 'Safety check failed: Easy Calendar route missing.'
}
if ($text -match "tooltip:\s*'বয়স্কদের জন্য সহজ ক্যালেন্ডার'") {
  throw 'Safety check failed: invalid FilledButton.icon tooltip still present.'
}

if ($text -eq $original) {
  Write-Host 'Standalone Easy Calendar button is already build-safe.'
  exit 0
}

[System.IO.File]::WriteAllText($path, $text, $utf8)
Write-Host 'Standalone Easy Calendar build fix applied successfully.'
