# Staged payload for T1059 test #11 (download cradle via WebClient.DownloadString)
# Benign recon only — used to confirm the cradle actually reaches execution.
"$(Get-Date -Format o) | run.ps1 executed on $(hostname) as $(whoami)" | Out-File -Append C:\purpletest\evidence\cradle_run.log
whoami
hostname
