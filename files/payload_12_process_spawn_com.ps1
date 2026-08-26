# Source ID #57 — Process Spawn (COM / WScript.Shell)
powershell -c "(New-Object -ComObject ('WScript.'+'Shell')).Run(('cmd /c who'+'ami'),0,$false)"
