# Staged payload for T1059 test #16 (download cradle, WebClient held in variable)
"$(Get-Date -Format o) | c.ps1 executed on $(hostname) as $(whoami)" | Out-File -Append C:\purpletest\evidence\cradle_c.log
whoami /all
