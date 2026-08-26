whoami /all
hostname
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
systeminfo | findstr /i "domain"
[Environment]::UserDomainName
[Environment]::Is64BitProcess
(Get-WmiObject Win32_ComputerSystem).Domain
ipconfig /all
net localgroup administrators
Get-MpComputerStatus | Select AMServiceEnabled, RealTimeProtectionEnabled
Get-Service | Where-Object {$_.DisplayName -match "CrowdStrike|SentinelOne|Defender|Carbon Black|Cortex"}
