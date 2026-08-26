whoami /all
hostname
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
systeminfo | findstr /i "domain"
[Environment]::UserDomainName
[Environment]::Is64BitProcess
(Get-WmiObject Win32_ComputerSystem).Domain
ipconfig /all
