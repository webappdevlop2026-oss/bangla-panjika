$ErrorActionPreference = 'Stop'
$path = 'lib/main.dart'
$text = Get-Content -Raw -Encoding UTF8 $path

$desktopAnchor = @"
      children: [
        _HeroDateCard(),
        const SizedBox(height: 14),
        const _HistoryBanner(),
"@
$desktopNew = @"
      children: [
        _HeroDateCard(),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const VillageHorizonScene(height: 300),
        ),
        const SizedBox(height: 14),
        const _HistoryBanner(),
"@

$mobileAnchor = @"
              const SizedBox(height: 16),
              _HeroDateCard(),
              const SizedBox(height: 12),
              const _HistoryBanner(),
"@
$mobileNew = @"
              const SizedBox(height: 16),
              _HeroDateCard(),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const VillageHorizonScene(),
              ),
              const SizedBox(height: 12),
              const _HistoryBanner(),
"@

$desktopOld = @"
        const SizedBox(height: 20),
        const _SectionTitle('জীবন্ত বাংলা গ্রাম • LIVE'),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: const VillageHorizonScene(height: 300),
        ),
        const SizedBox(height: 14),
        const AdBannerWidget(),
"@
$desktopOldNew = @"
        const SizedBox(height: 14),
        const AdBannerWidget(),
"@

$mobileOld = @"
              const SizedBox(height: 20),
              const _SectionTitle('জীবন্ত বাংলা গ্রাম • LIVE'),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const VillageHorizonScene(),
              ),
              const SizedBox(height: 14),
              const AdBannerWidget(),
"@
$mobileOldNew = @"
              const SizedBox(height: 14),
              const AdBannerWidget(),
"@

if (-not $text.Contains($desktopAnchor)) { throw 'Desktop hero anchor not found.' }
if (-not $text.Contains($mobileAnchor)) { throw 'Mobile hero anchor not found.' }
if (-not $text.Contains($desktopOld)) { throw 'Desktop old village block not found.' }
if (-not $text.Contains($mobileOld)) { throw 'Mobile old village block not found.' }

$text = $text.Replace($desktopAnchor, $desktopNew)
$text = $text.Replace($mobileAnchor, $mobileNew)
$text = $text.Replace($desktopOld, $desktopOldNew)
$text = $text.Replace($mobileOld, $mobileOldNew)

Set-Content -Path $path -Value $text -Encoding UTF8
Write-Host 'Village scene moved directly below the hero date card.'
