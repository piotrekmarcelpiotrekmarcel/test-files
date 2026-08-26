# Source ID #71 — Persistence (Scheduled Task)
# Remember to clean up afterwards: schtasks /delete /tn PurpleTest /f
powershell -c "&('sch'+'tasks') /create /tn ('Purple'+'Test') /tr ('powershell -'+'no'+'p -w hid'+'den -c who'+'ami') /sc once /st 23:59 /f"
