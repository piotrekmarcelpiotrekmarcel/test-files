# Source ID #43 — Inline C# Compile (Add-Type)
# Requires helper.cs already present at C:\purpletest\stage\helper.cs
powershell -c "&('Add-'+'Ty'+'pe') -Path C:\purpletest\stage\helper.cs; [Helper.Main]::Go()"
