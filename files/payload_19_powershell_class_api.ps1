# Source ID #87 — PowerShell Class API (in-process, no new process)
powershell -c "$ps=[PowerShell]::Create().AddScript(('who'+'ami')); $ps.Invoke()"
