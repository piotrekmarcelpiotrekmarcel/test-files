# Source ID #55 — Process Spawn (WMI Win32_Process.Create)
powershell -c "&('Inv'+'oke-Wmi'+'Method') -Class ('Win32_'+'Process') -Name Create -ArgumentList 'calc.exe'"
