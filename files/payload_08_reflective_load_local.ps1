# Source ID #42 — Reflective Assembly Load (local bytes, no network)
# Requires lib.dll already present at C:\purpletest\stage\lib.dll
# (download it manually first: see README)
powershell.exe -c "[System.Reflection.Assembly]::('Lo'+'ad').Invoke([IO.File]::ReadAllBytes('C:\purpletest\stage\lib.dll')) | Out-Null"
