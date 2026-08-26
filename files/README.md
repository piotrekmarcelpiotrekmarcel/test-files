# Stage folder — pliki wspierające do T1059_Payload_Test_Plan.md

## Hostuj przez HTTP/HTTPS (idą do serwera pod 10.10.10.50)

| Plik | Dla payloadu | Uwaga |
|---|---|---|
| `run.ps1` | #11 | zwykły tekst, gotowy do hostowania |
| `c.ps1` | #16 | zwykły tekst, gotowy do hostowania |
| `s.ps1` | #27 | hostuj przez **HTTPS** (self-signed cert wystarczy — payload sam wyłącza walidację) |
| `mod.dll` | #25 | **musisz skompilować** z `PurpleTestModule.cs` — patrz niżej |
| `poc.hta` | #60 | zwykły tekst, gotowy do hostowania |
| `scrobj.dll` | #63 | to XML/.sct pod zmienioną nazwą — zwykły tekst, gotowy do hostowania |
| `cert.dat` | #64 | dowolna treść — gotowy do hostowania |

## Kopiuj bezpośrednio na hosta testowego, do C:\purpletest\stage\

| Plik | Dla payloadu | Uwaga |
|---|---|---|
| `lib.dll` | #42 | **musisz skompilować** z `PurpleTestModule.cs` — patrz niżej (ten sam plik co mod.dll, inna nazwa) |
| `helper.cs` | #43 | zostaw jako .cs — Add-Type kompiluje go dopiero w trakcie testu |

## Kompilacja mod.dll / lib.dll

`PurpleTestModule.cs` to gotowe źródło C#. Na hoście Windows z .NET
Framework (jest domyślnie w Windows), skompiluj:

```powershell
$csc = (Get-ChildItem "C:\Windows\Microsoft.NET\Framework64" -Recurse -Filter csc.exe | Select-Object -First 1).FullName
& $csc /target:library /out:mod.dll PurpleTestModule.cs
Copy-Item mod.dll lib.dll
```

`mod.dll` wrzuć na serwer hostujący (do pobrania przez sieć w #25).
`lib.dll` skopiuj bezpośrednio do `C:\purpletest\stage\` na hoście
testowym (payload #42 nic nie pobiera, czyta lokalny plik).

## Ewidencja

Wszystkie staged pliki logują wykonanie do `C:\purpletest\evidence\*.log`
na hoście testowym — po każdym teście sprawdź czy odpowiedni log powstał,
to Twój dowód, że payload faktycznie doszedł do wykonania (niezależnie od
tego czy EDR go złapał).

## Sprzątanie po testach

Payloady #71 (scheduled task) i #74 (registry run key) tworzą trwałe
mechanizmy — usuń je ręcznie po zakończeniu testu:

```powershell
schtasks /delete /tn PurpleTest /f
Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name PurpleTest
```
