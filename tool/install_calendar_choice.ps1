param([string]$ProjectRoot = 'D:\bangla_panjika_native')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$target = Join-Path $ProjectRoot 'lib\main.dart'
$installed = $false
$backupFile = $null
$expected = @{
    '8604BA13057255EB3E41A46C4B21012BCE06C97375D0170FC10161F508403443' = '5DE3BD72427B1AC72A0EBD69A9919942D0455F52DD15A747043910E192D3913E'
    '3C481ED6C559288444AE2B2868001007A94533AF115A3B90F06D47B33BC73C9E' = 'EEC837AE9C1EB69CF45546F178DDF80870B5B333D03FAEEE79808582B14469D0'
}
try {
    $beforeHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    if ($expected.ContainsValue($beforeHash)) { Write-Host 'Calendar choice already installed.'; exit 0 }
    if (!$expected.ContainsKey($beforeHash)) { throw 'Source has changed. Nothing replaced. Send this output and your latest source ZIP.' }
    $dart = Get-Command dart -ErrorAction Stop
    $null = Get-Command flutter -ErrorAction Stop
    $source = [IO.File]::ReadAllText($target, [Text.Encoding]::UTF8)
    $snippet = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('Ly8gQ2hvb3NlIGEgY2FsZW5kYXIgYmVmb3JlIG9wZW5pbmcgZWl0aGVyIGV4aXN0aW5nIGNhbGVuZGFyIHNjcmVlbi4NCmNsYXNzIENhbGVuZGFyQ2hvaWNlU2NyZWVuIGV4dGVuZHMgU3RhdGVsZXNzV2lkZ2V0IHsNCiAgY29uc3QgQ2FsZW5kYXJDaG9pY2VTY3JlZW4oe3N1cGVyLmtleX0pOw0KDQogIEBvdmVycmlkZQ0KICBXaWRnZXQgYnVpbGQoQnVpbGRDb250ZXh0IGNvbnRleHQpIHsNCiAgICBmaW5hbCBjb2xvcnMgPSBUaGVtZS5vZihjb250ZXh0KS5jb2xvclNjaGVtZTsNCiAgICBXaWRnZXQgb3B0aW9uKFN0cmluZyB0aXRsZSwgU3RyaW5nIGRlc2NyaXB0aW9uLCBJY29uRGF0YSBpY29uLCBXaWRnZXQgcGFnZSkgew0KICAgICAgcmV0dXJuIENhcmQoDQogICAgICAgIGNsaXBCZWhhdmlvcjogQ2xpcC5hbnRpQWxpYXMsDQogICAgICAgIGNoaWxkOiBJbmtXZWxsKA0KICAgICAgICAgIG9uVGFwOiAoKSA9PiBOYXZpZ2F0b3Iub2YoY29udGV4dCkucHVzaCgNCiAgICAgICAgICAgIE1hdGVyaWFsUGFnZVJvdXRlPHZvaWQ+KGJ1aWxkZXI6IChfKSA9PiBwYWdlKSwNCiAgICAgICAgICApLA0KICAgICAgICAgIGNoaWxkOiBQYWRkaW5nKA0KICAgICAgICAgICAgcGFkZGluZzogY29uc3QgRWRnZUluc2V0cy5hbGwoMjApLA0KICAgICAgICAgICAgY2hpbGQ6IFJvdygNCiAgICAgICAgICAgICAgY2hpbGRyZW46IFsNCiAgICAgICAgICAgICAgICBJY29uKGljb24sIHNpemU6IDMyLCBjb2xvcjogY29sb3JzLnByaW1hcnkpLA0KICAgICAgICAgICAgICAgIGNvbnN0IFNpemVkQm94KHdpZHRoOiAxNiksDQogICAgICAgICAgICAgICAgRXhwYW5kZWQoDQogICAgICAgICAgICAgICAgICBjaGlsZDogQ29sdW1uKA0KICAgICAgICAgICAgICAgICAgICBjcm9zc0F4aXNBbGlnbm1lbnQ6IENyb3NzQXhpc0FsaWdubWVudC5zdGFydCwNCiAgICAgICAgICAgICAgICAgICAgY2hpbGRyZW46IFsNCiAgICAgICAgICAgICAgICAgICAgICBUZXh0KHRpdGxlLCBzdHlsZTogY29uc3QgVGV4dFN0eWxlKA0KICAgICAgICAgICAgICAgICAgICAgICAgZm9udFNpemU6IDIwLCBmb250V2VpZ2h0OiBGb250V2VpZ2h0LmJvbGQsDQogICAgICAgICAgICAgICAgICAgICAgKSksDQogICAgICAgICAgICAgICAgICAgICAgY29uc3QgU2l6ZWRCb3goaGVpZ2h0OiA2KSwNCiAgICAgICAgICAgICAgICAgICAgICBUZXh0KGRlc2NyaXB0aW9uKSwNCiAgICAgICAgICAgICAgICAgICAgXSwNCiAgICAgICAgICAgICAgICAgICksDQogICAgICAgICAgICAgICAgKSwNCiAgICAgICAgICAgICAgICBjb25zdCBTaXplZEJveCh3aWR0aDogOCksDQogICAgICAgICAgICAgICAgY29uc3QgSWNvbihJY29ucy5jaGV2cm9uX3JpZ2h0X3JvdW5kZWQpLA0KICAgICAgICAgICAgICBdLA0KICAgICAgICAgICAgKSwNCiAgICAgICAgICApLA0KICAgICAgICApLA0KICAgICAgKTsNCiAgICB9DQoNCiAgICByZXR1cm4gU2NhZmZvbGQoDQogICAgICBhcHBCYXI6IEFwcEJhcih0aXRsZTogY29uc3QgVGV4dCgn4KaV4KeN4Kav4Ka+4Kay4KeH4Kao4KeN4Kah4Ka+4KawJykpLA0KICAgICAgYm9keTogU2FmZUFyZWEoDQogICAgICAgIGNoaWxkOiBMaXN0VmlldygNCiAgICAgICAgICBwYWRkaW5nOiBjb25zdCBFZGdlSW5zZXRzLmFsbCgyMCksDQogICAgICAgICAgY2hpbGRyZW46IFsNCiAgICAgICAgICAgIGNvbnN0IFRleHQoJ+CmhuCmquCmqOCmvuCmsCDgppXgp43gpq/gpr7gprLgp4fgpqjgp43gpqHgpr7gprAg4Kas4KeH4Kab4KeHIOCmqOCmv+CmqCcsDQogICAgICAgICAgICAgIHN0eWxlOiBUZXh0U3R5bGUoZm9udFNpemU6IDI0LCBmb250V2VpZ2h0OiBGb250V2VpZ2h0LmJvbGQpKSwNCiAgICAgICAgICAgIGNvbnN0IFNpemVkQm94KGhlaWdodDogOCksDQogICAgICAgICAgICBjb25zdCBUZXh0KCfgpq/gp4cg4KaV4KeN4Kav4Ka+4Kay4KeH4Kao4KeN4Kah4Ka+4KawIOCmpuCnh+CmluCmpOCnhyDgpprgpr7gpqgsIOCmqOCmv+CmmuCnh+CmsCDgpqzgpr7gpp/gpqjgp4cg4Kaa4Ka+4Kaq4KeB4Kao4KWkJyksDQogICAgICAgICAgICBjb25zdCBTaXplZEJveChoZWlnaHQ6IDI0KSwNCiAgICAgICAgICAgIG9wdGlvbign4Ka44Ka54KacIOCmleCnjeCmr+CmvuCmsuCnh+CmqOCnjeCmoeCmvuCmsCcsICfgprjgprngppzgpq3gpr7gpqzgp4cg4Kau4Ka+4Ka44KeH4KawIOCmpuCmv+CmqCDgppMg4KaJ4KeO4Ka44KasIOCmpuCnh+CmluCngeCmqCcsDQogICAgICAgICAgICAgIEljb25zLmNhbGVuZGFyX3ZpZXdfbW9udGhfcm91bmRlZCwNCiAgICAgICAgICAgICAgY29uc3QgRWFzeUJlbmdhbGlDYWxlbmRhclNjcmVlbigpKSwNCiAgICAgICAgICAgIGNvbnN0IFNpemVkQm94KGhlaWdodDogMTIpLA0KICAgICAgICAgICAgb3B0aW9uKCfgpqrgpp7gp43gppzgpr/gppXgpr4g4KaV4KeN4Kav4Ka+4Kay4KeH4Kao4KeN4Kah4Ka+4KawJywgJ+CmrOCmv+CmuOCnjeCmpOCmvuCmsOCmv+CmpCDgpqzgpr7gpoLgprLgpr4g4Kaq4Kae4KeN4Kac4Ka/4KaV4Ka+IOCmpuCnh+CmluCngeCmqCcsDQogICAgICAgICAgICAgIEljb25zLmRhdGVfcmFuZ2Vfcm91bmRlZCwgY29uc3QgQmVuZ2FsaUNhbGVuZGFyU2NyZWVuKCkpLA0KICAgICAgICAgIF0sDQogICAgICAgICksDQogICAgICApLA0KICAgICk7DQogIH0NCn0NCg0K'))
    $source = $source.Replace('const BengaliCalendarScreen()', 'const CalendarChoiceScreen()')
    $source = $source.Replace('class BengaliCalendarScreen extends StatefulWidget {', $snippet + 'class BengaliCalendarScreen extends StatefulWidget {')
    $work = Join-Path $env:TEMP ('CalendarChoice_' + [guid]::NewGuid())
    $null = New-Item -ItemType Directory -Path $work
    $candidate = Join-Path $work 'main.dart'
    [IO.File]::WriteAllText($candidate, $source, (New-Object Text.UTF8Encoding($false)))
    if ((Get-FileHash $candidate -Algorithm SHA256).Hash -ne $expected[$beforeHash]) { throw 'Patch verification failed. Nothing replaced.' }
    & $dart.Source format --output=none $candidate
    if ($LASTEXITCODE -ne 0) { throw 'Syntax check failed. Nothing replaced.' }
    $backupDir = Join-Path (Split-Path $ProjectRoot -Parent) ('CalendarChoiceBackup_' + [guid]::NewGuid())
    $null = New-Item -ItemType Directory -Path $backupDir
    $backupFile = Join-Path $backupDir 'main.dart'
    Copy-Item -LiteralPath $target -Destination $backupFile
    if ((Get-FileHash $backupFile -Algorithm SHA256).Hash -ne $beforeHash) { throw 'Backup check failed.' }
    if ((Get-FileHash $target -Algorithm SHA256).Hash -ne $beforeHash) { throw 'Source changed during checks.' }
    $installed = $true
    Copy-Item -LiteralPath $candidate -Destination $target -Force
    Push-Location $ProjectRoot
    try {
        flutter build apk --debug --no-pub -t lib/main.dart
        if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
    } finally { Pop-Location }
    Write-Host "Calendar choice installed. Backup: $backupFile" -ForegroundColor Green
} catch {
    $problem = $_.Exception.Message
    if ($installed -and $backupFile) {
        Copy-Item -LiteralPath $backupFile -Destination $target -Force
        if ((Get-FileHash $target -Algorithm SHA256).Hash -ne $beforeHash) { Write-Host "Restore failed. Backup: $backupFile"; exit 2 }
        Write-Host 'Previous main.dart restored.' -ForegroundColor Yellow
    }
    Write-Host $problem -ForegroundColor Red
    exit 1
}
