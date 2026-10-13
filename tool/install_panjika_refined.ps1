param([string]$ProjectRoot = 'D:\bangla_panjika_native')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$target = Join-Path $ProjectRoot 'lib\main.dart'
$installed = $false
$backupFile = $null
$expected = @{
    '8604BA13057255EB3E41A46C4B21012BCE06C97375D0170FC10161F508403443' = '4FCC619976BB65D20CA79F8020628B744299DFB636CF684E9B17ED4FA2025910'
    '3C481ED6C559288444AE2B2868001007A94533AF115A3B90F06D47B33BC73C9E' = 'A03C0BF1A21C3E4CC8D8A947E62AC6563ED6629561F52BFB39B2DF3C628ADB61'
    '5DE3BD72427B1AC72A0EBD69A9919942D0455F52DD15A747043910E192D3913E' = '4FCC619976BB65D20CA79F8020628B744299DFB636CF684E9B17ED4FA2025910'
    'EEC837AE9C1EB69CF45546F178DDF80870B5B333D03FAEEE79808582B14469D0' = 'A03C0BF1A21C3E4CC8D8A947E62AC6563ED6629561F52BFB39B2DF3C628ADB61'
    '02F5F42006AB8FC0C6B4733AE40603D77D5E0C0D100548BEE3E31CA780BA402F' = '4FCC619976BB65D20CA79F8020628B744299DFB636CF684E9B17ED4FA2025910'
    '5AC50664A4030FDA9273A1BDC0264ADCCF667E2A3D5F414B401D1A19D8635EE3' = 'A03C0BF1A21C3E4CC8D8A947E62AC6563ED6629561F52BFB39B2DF3C628ADB61'
}
try {
    $beforeHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    if ($expected.ContainsValue($beforeHash)) { Write-Host 'Panjika layout already installed.'; exit 0 }
    if (!$expected.ContainsKey($beforeHash)) { throw 'Source has changed. Nothing replaced. Send this output and your latest source ZIP.' }
    $dart = Get-Command dart -ErrorAction Stop
    $null = Get-Command flutter -ErrorAction Stop
    $work = Join-Path $env:TEMP ('PanjikaPrint_' + [guid]::NewGuid())
    $null = New-Item -ItemType Directory -Path $work
    $candidate = Join-Path $work 'main.dart'
    Copy-Item -LiteralPath $target -Destination $candidate
    & $dart.Source (Join-Path $PSScriptRoot 'apply_panjika_refined.dart') $candidate
    if ($LASTEXITCODE -ne 0) { throw 'Layout patch failed. Nothing replaced.' }
    if ((Get-FileHash $candidate -Algorithm SHA256).Hash -ne $expected[$beforeHash]) { throw 'Patch verification failed. Nothing replaced.' }
    & $dart.Source format --output=none $candidate
    if ($LASTEXITCODE -ne 0) { throw 'Syntax check failed. Nothing replaced.' }
    $backupDir = Join-Path (Split-Path $ProjectRoot -Parent) ('PanjikaPrintBackup_' + [guid]::NewGuid())
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
    Write-Host "Panjika layout installed. Backup: $backupFile" -ForegroundColor Green
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
