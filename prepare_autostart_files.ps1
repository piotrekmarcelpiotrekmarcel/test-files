<#
    Skrypt przygotowawczy - Purple Team Scenario 6 (T1547.001)
    Tworzy katalog C:\purpletest\stage oraz nieszkodliwe pliki placeholder
    wymagane przez payloady ze scenariusza Persistence - Registry Run Keys.

    Uruchom jako Administrator (niektore payloady docelowe wymagaja HKLM).
#>

$stageDir = "C:\purpletest\autostart"

Write-Host "=== Tworzenie katalogu $stageDir ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null

# Sciezka do neutralnego pliku EXE uzywanego jako "silnik" placeholderow (notepad.exe)
$sourceExe = "$env:WINDIR\System32\notepad.exe"

# Lista plikow EXE do utworzenia (kopie notepad.exe pod inna nazwa - nieszkodliwe)
$exeFiles = @(
    "pt_persist.exe",
    "pt32.exe",
    "pt_setup.exe",
    "pt_init.exe",
    "pt_active.exe",
    "pt_dotnet.exe",
    "pt_wmi.exe",
    "pt_sync.exe",
    "pt_av.exe",
    "pt_update.exe",
    "pt_stage.exe",
    "pt2.exe",
    "pt_teams.exe",
    "pt_cert.exe",
    "pt_bits.exe",
    "pt_dl.exe",
    "pt_dl2.exe",
    "pt_move.exe",
    "pt_curl.exe",
    "pt_onedrive.exe",
    "pt_sec.exe",
    "pt_cim.exe",
    "pt_wmi_hklm.exe",
    "pt_chain.exe"
)

Write-Host "=== Kopiowanie placeholderow EXE (kopia notepad.exe) ===" -ForegroundColor Cyan
foreach ($f in $exeFiles) {
    $dest = Join-Path $stageDir $f
    Copy-Item -Path $sourceExe -Destination $dest -Force
    Write-Host "  Utworzono: $dest"
}

# Pliki DLL - puste/neutralne (nie beda faktycznie ladowane jako prawdziwe DLL bez exportow,
# ale wystarcza do wygenerowania zdarzenia rejestru/procesu w teście)
Write-Host "=== Tworzenie placeholderow DLL ===" -ForegroundColor Cyan
$dllFiles = @("pt_loader.dll")
foreach ($f in $dllFiles) {
    $dest = Join-Path $stageDir $f
    [byte[]]$dummyBytes = 0x4D,0x5A  # naglowek MZ - minimalny placeholder
    [System.IO.File]::WriteAllBytes($dest, $dummyBytes)
    Write-Host "  Utworzono: $dest"
}

# Pliki skryptowe - neutralna zawartosc (echo/komentarz), zeby dzialaly z interpreterami
Write-Host "=== Tworzenie placeholderow skryptowych (.vbs/.js/.ps1/.cfg/.xml) ===" -ForegroundColor Cyan

$scriptFiles = @{
    "pt_agent.vbs"    = "' Purple Team placeholder script - no-op`r`nWScript.Echo ""placeholder"""
    "pt_agent.js"     = "// Purple Team placeholder script - no-op`r`nWScript.Echo('placeholder');"
    "pt_launch.vbs"   = "' Purple Team placeholder script - no-op"
    "pt_finalize.ps1" = "# Purple Team placeholder script - no-op`r`nWrite-Host 'placeholder'"
    "pt_active.ps1"   = "# Purple Team placeholder script - no-op`r`nWrite-Host 'placeholder'"
    "pt_policy.ps1"   = "# Purple Team placeholder script - no-op`r`nWrite-Host 'placeholder'"
    "pt_loop.ps1"     = "# Purple Team placeholder script - no-op`r`nWrite-Host 'placeholder'"
    "pt.cfg"          = "# Purple Team placeholder config file"
    "pt_task.xml"     = "<Project></Project>"
    "pt_launch.bat"   = "@echo off`r`necho placeholder"
}

foreach ($entry in $scriptFiles.GetEnumerator()) {
    $dest = Join-Path $stageDir $entry.Key
    Set-Content -Path $dest -Value $entry.Value -Encoding ASCII
    Write-Host "  Utworzono: $dest"
}

Write-Host "`n=== Gotowe. Zawartosc katalogu: ===" -ForegroundColor Green
Get-ChildItem $stageDir | Format-Table Name, Length -AutoSize

Write-Host "`nUWAGA: Payloady scenariusza 6 odwoluja sie rowniez do:" -ForegroundColor Yellow
Write-Host "  - C:\Users\pt_user1\NTUSER.DAT (offline hive) - musi istniec osobno, np. skopiowany profil testowy."
Write-Host "  - Adresu http://10.10.10.50/payload/... - to zewnetrzny serwer C2 testowy, nie tworzony przez ten skrypt."
