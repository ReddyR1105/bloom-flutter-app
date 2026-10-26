param(
    [Parameter(Mandatory=$true)][string]$Serial,
    [string]$Adb = 'D:\Map\platform-tools\adb.exe',
    [string]$Apk = 'build\app\outputs\flutter-apk\app-release.apk',
    [string]$EvidenceRoot = 'docs\device_evidence'
)
$ErrorActionPreference = 'Stop'
$deviceRoot = Join-Path $EvidenceRoot $Serial
New-Item -ItemType Directory -Path $deviceRoot -Force | Out-Null
$logPath = Join-Path $deviceRoot 'release_checks.txt'
function Record([string]$Message) {
    Write-Output $Message
    Add-Content -LiteralPath $logPath -Value $Message -Encoding UTF8
}
function Invoke-Adb([string[]]$Arguments) {
    # adb pull prints successful progress to stderr. PowerShell 5 turns it into
    # ErrorRecord objects, so use the native exit code rather than stream type.
    $priorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $result = & $Adb -s $Serial @Arguments 2>&1
        $nativeExit = $LASTEXITCODE
    } finally { $ErrorActionPreference = $priorPreference }
    if ($nativeExit -ne 0) { throw "adb failed: $($Arguments -join ' '): $result" }
    return ($result -join "`n")
}
function Snapshot([string]$Name) {
    Invoke-Adb @('shell','uiautomator','dump','/sdcard/bloom_window.xml') | Out-Null
    $xmlText = Invoke-Adb @('exec-out','cat','/sdcard/bloom_window.xml')
    [System.IO.File]::WriteAllText((Join-Path (Resolve-Path $deviceRoot) "$Name.xml"), $xmlText)
    Invoke-Adb @('shell','screencap','-p','/sdcard/bloom_screen.png') | Out-Null
    Invoke-Adb @('pull','/sdcard/bloom_screen.png',(Join-Path $deviceRoot "$Name.png")) | Out-Null
    return [xml]$xmlText
}
function Tap-Label([xml]$Tree, [string]$Label) {
    $node = $null
    for ($attempt = 0; $attempt -lt 12; $attempt++) {
        $node = @($Tree.SelectNodes('//node') | Where-Object {
            $_.text -eq $Label -or $_.'content-desc' -eq $Label -or
            $_.'content-desc'.StartsWith($Label + "`n")
        } | Sort-Object { if ($_.clickable -eq 'true') { 0 } else { 1 } }) | Select-Object -First 1
        if ($null -ne $node) { break }
        $screen = [regex]::Match($Tree.SelectSingleNode('//hierarchy/node').bounds, '\[0,0\]\[(\d+),(\d+)\]')
        if (!$screen.Success) { throw 'Cannot determine actual rotated viewport.' }
        $width = [int]$screen.Groups[1].Value
        $height = [int]$screen.Groups[2].Value
        # At large text in phone landscape, bottom navigation begins well above
        # 75% of the viewport. Start in the body, not on the navigation bar.
        Invoke-Adb @('shell','input','swipe',"$([int]($width*.5))","$([int]($height*.60))","$([int]($width*.5))","$([int]($height*.30))",'350') | Out-Null
        Invoke-Adb @('shell','uiautomator','dump','/sdcard/bloom_window.xml') | Out-Null
        $Tree = [xml](Invoke-Adb @('exec-out','cat','/sdcard/bloom_window.xml'))
    }
    if ($null -eq $node) { throw "Visible label not found: $Label" }
    $bounds = [regex]::Match($node.bounds, '\[(\d+),(\d+)\]\[(\d+),(\d+)\]')
    if (!$bounds.Success) { throw "No usable bounds for: $Label" }
    $x = [int](([int]$bounds.Groups[1].Value + [int]$bounds.Groups[3].Value) / 2)
    $y = [int](([int]$bounds.Groups[2].Value + [int]$bounds.Groups[4].Value) / 2)
    Invoke-Adb @('shell','input','tap',"$x","$y") | Out-Null
}
function Require-Text([xml]$Tree, [string]$Text) {
    if (!$Tree.OuterXml.Contains($Text)) { throw "Expected screen text not present: $Text" }
    Record "PASS visible assertion: $Text"
}

Record "Release acceptance on $Serial; test fixtures are explicitly labeled [TEST]."
Record (Invoke-Adb @('shell','getprop','ro.build.fingerprint'))
Record (Invoke-Adb @('shell','wm','size'))
Record (Invoke-Adb @('shell','wm','density'))
$airplane = (Invoke-Adb @('shell','settings','get','global','airplane_mode_on')).Trim()
$font = (Invoke-Adb @('shell','settings','get','system','font_scale')).Trim()
$rotation = (Invoke-Adb @('shell','settings','get','system','user_rotation')).Trim()
$autoRotation = (Invoke-Adb @('shell','settings','get','system','accelerometer_rotation')).Trim()
try {
    Record (Invoke-Adb @('install','-r',$Apk))
    Invoke-Adb @('shell','cmd','connectivity','airplane-mode','enable') | Out-Null
    Record ('Airplane mode actual value: ' + (Invoke-Adb @('shell','settings','get','global','airplane_mode_on')))
    if ((Invoke-Adb @('shell','settings','get','global','airplane_mode_on')).Trim() -ne '1') {
        throw 'Airplane mode was not enabled.'
    }
    Invoke-Adb @('shell','am','force-stop','edu.gsu.bloom.bloom') | Out-Null
    Record (Invoke-Adb @('shell','am','start','-W','-n','edu.gsu.bloom.bloom/.MainActivity'))
    $today = Snapshot '01_today_offline_after_process_restart'
    Require-Text $today '[TEST] Restart proof'
    Require-Text $today '10 / 10 pages'
    Record 'PASS SQLite habit/check-in completion survives Android force-stop/relaunch in airplane mode.'

    Tap-Label $today 'Settings'
    $settings = Snapshot '05_settings_restored'
    Require-Text $settings 'Default daily target: 27'
    Require-Text $settings 'Sunday'
    $reduced = @($settings.SelectNodes('//node') | Where-Object {
        $_.'content-desc'.Contains('Reduced motion') -and $_.checked -eq 'true'
    })
    if ($reduced.Count -eq 0) { throw 'Reduced motion switch is not restored as checked.' }
    Record 'PASS actual SharedPreferences target/week-start/reduced-motion restored after process restart.'

    Tap-Label $settings 'Today'
    $today = Snapshot 'today_navigation'
    Tap-Label $today '[TEST] Restart proof'
    $detail = Snapshot '03_habit_detail'
    Require-Text $detail '10 / 10 pages saved'
    Tap-Label $detail 'Edit habit'
    $form = Snapshot '02_edit_habit'
    Require-Text $form 'Habit name'
    Invoke-Adb @('shell','input','keyevent','4') | Out-Null
    Invoke-Adb @('shell','input','keyevent','4') | Out-Null
    $bloomHomeTree = Snapshot 'home_after_back'
    Tap-Label $bloomHomeTree 'Insights'
    $history = Snapshot '04_history'
    Require-Text $history '[TEST] Restart proof'

    Invoke-Adb @('shell','settings','put','system','accelerometer_rotation','0') | Out-Null
    Invoke-Adb @('shell','settings','put','system','user_rotation','1') | Out-Null
    Invoke-Adb @('shell','settings','put','system','font_scale','1.5') | Out-Null
    $large = Snapshot '06_rotated_large_text'
    # The saved entry may be below the fold after rotation/text scaling.
    # Scroll it into view; tapping this noninteractive title makes no change.
    Tap-Label $large '[TEST] Restart proof'
    $large = Snapshot '06_rotated_large_text'
    Require-Text $large '[TEST] Restart proof'
    $viewport = [regex]::Match($large.SelectSingleNode('//hierarchy/node').bounds, '\[0,0\]\[(\d+),(\d+)\]')
    $orientation = if ([int]$viewport.Groups[1].Value -gt [int]$viewport.Groups[2].Value) { 'landscape' } else { 'portrait' }
    Record "PASS history remains accessible in rotated $orientation at 1.5x system text scale; inspect authentic screenshot for visual quality."
    Record 'All scripted release checks passed. No peer feedback or human contribution evidence is implied.'
} finally {
    if ($airplane -eq '1') { Invoke-Adb @('shell','cmd','connectivity','airplane-mode','enable') | Out-Null }
    else { Invoke-Adb @('shell','cmd','connectivity','airplane-mode','disable') | Out-Null }
    if ($font -match '^\d+(\.\d+)?$') { Invoke-Adb @('shell','settings','put','system','font_scale',$font) | Out-Null }
    if ($rotation -match '^\d+$') { Invoke-Adb @('shell','settings','put','system','user_rotation',$rotation) | Out-Null }
    if ($autoRotation -match '^\d+$') { Invoke-Adb @('shell','settings','put','system','accelerometer_rotation',$autoRotation) | Out-Null }
}
