# Mikrocontroller – RP2040, RP2350, Pico und der Debug Probe

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «Microcontrollers»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/microcontrollers/)).

> ℹ️ **Was diese Referenz ist – und was nicht.**
> Dieser Skill entwickelt für **Linux auf dem Raspberry Pi**. Diese Referenz ist die
> **Grenzbeschreibung**: Sie beantwortet, *wann* ein Projekt einen Mikrocontroller braucht,
> *welchen*, und *wie* er an einen Pi angebunden und debuggt wird. Sie ersetzt weder das
> C/C++-SDK-Handbuch noch die MicroPython-Dokumentation – für die eigentliche
> Firmware-Entwicklung gehört man in die offiziellen Pico-Bücher.
>
> Die Gattungsentscheidung **Pico oder Pi** steht in `setup-provisioning.md`; hier steht,
> was danach kommt.

## Inhaltsverzeichnis
1. [Die Namenssystematik – RP-Nummern lesen](#die-namenssystematik--rp-nummern-lesen)
2. [RP2040 gegen RP2350](#rp2040-gegen-rp2350)
3. [🔴 Fallen beim Umstieg RP2040 → RP2350](#-fallen-beim-umstieg-rp2040--rp2350)
4. [Zwei Angaben, die Projekte falsch dimensionieren](#zwei-angaben-die-projekte-falsch-dimensionieren)
5. [Die Funkvarianten – und was sie kosten](#die-funkvarianten--und-was-sie-kosten)
6. [Radio Module 2 (RM2) und die Zulassungsfrage](#radio-module-2-rm2-und-die-zulassungsfrage)
7. [Debug Probe – SWD, UART und RTT](#debug-probe--swd-uart-und-rtt)
8. [Pi und Pico zusammen betreiben](#pi-und-pico-zusammen-betreiben)

---

## Die Namenssystematik – RP-Nummern lesen

Raspberry-Pi-Silizium folgt einem festen Schema. Wer es kennt, liest die Ausstattung aus
dem Namen ab, statt sie nachzuschlagen:

```
R P   2      0            4          0
│ │   │      │            │          └─ Flash, log. Faktor: 0 = keiner, 4 = 2 MB gestapelt
│ │   │      │            └──────────── RAM, logarithmischer Faktor: 4 = 264 kB, 5 = 520 kB
│ │   │      └───────────────────────── Kerntyp: 0 = Cortex-M0+, 3 = Cortex-M33
│ │   └──────────────────────────────── Anzahl Prozessorkerne
└─┴──────────────────────────────────── «Raspberry Pi»-Silizium
```

Beim RP2350 kommt ein **Buchstabe für die Gehäusegrösse** dazu:

| Variante | Gehäuse | Grösse | Internes Flash | GPIO | Analogeingänge | PWM |
|----------|---------|--------|----------------|------|----------------|-----|
| **RP2350A** | QFN-60 | 7 × 7 mm | – | 30 | 4 | 16 |
| **RP2350B** | QFN-80 | 10 × 10 mm | – | **48** | **8** | **24** |
| **RP2354A** | QFN-60 | 7 × 7 mm | **2 MB gestapelt** | 30 | 4 | 16 |
| **RP2354B** | QFN-80 | 10 × 10 mm | **2 MB gestapelt** | **48** | **8** | **24** |

➜ **Für eigene Platinen ist das die eigentliche Auswahltabelle.** Der RP2354 spart den
externen Flash-Baustein samt QSPI-Leiterbahnen – bei kleinen Serien oft die günstigere und
robustere Lösung. Der B-Typ ist die Antwort, wenn 30 GPIO nicht reichen; kein Pico-Board
trägt ihn, man braucht also ein eigenes Layout.

> ℹ️ Dasselbe Schema erklärt auch die Chips auf der Linux-Seite: **RP1** ist der
> I/O-Controller des Pi 5 (`rp1-gpio.md`), **RP3A0** das SiP des Zero 2 W
> (`hardware-specs.md`).

---

## RP2040 gegen RP2350

| Merkmal | RP2040 | RP2350 |
|---------|--------|--------|
| Kerne | 2 × Arm Cortex-M0+ | 2 × Arm **Cortex-M33** **oder** 2 × **Hazard3 (RISC-V)** |
| Takt | bis 133 MHz | bis 150 MHz |
| SRAM | 264 kB in 6 Bänken | **520 kB in 10 Bänken** |
| Externes Flash | bis 16 MB (QSPI/XIP) | bis **32 MB**; je nach Variante 2 MB intern |
| **PSRAM** | ❌ nicht unterstützt | ✅ über QMI am QSPI/XIP-Bus |
| GPIO | 30 (4 analog) | 30 oder **48** (4 oder **8** analog) |
| **PIO** | 2 Blöcke, **8** State Machines | **3 Blöcke, 12** State Machines |
| DMA | 12 Kanäle | **16 Kanäle** |
| Hardware-Dividierer | separat, speichermapped | **entfällt** – die CPU dividiert selbst |
| Kernspannung | LDO | **Abwärtswandler (SMPS)** + optionaler LDO für Schlafzustände |
| Sicherheit | – | **Arm TrustZone**, Signed Boot, 8 kB Antifuse-OTP, SHA-256, TRNG |
| Zusatzperipherie | – | **HSTX** (Hochgeschwindigkeits-Digitalausgang, z.B. Video) |
| Boards | Pico, Pico H/W/WH | Pico 2, Pico 2 W (± Header) |

Gleich geblieben sind: zwei UART, zwei SPI, zwei I²C, USB-1.1-Controller **mit Host- und
Device-Rolle**, zwei PLLs, die beiden Interpolatoren und der UF2-Bootloader im ROM.

### Architekturumschaltung

Der RP2350 trägt **beide** Kernsätze: Arm Cortex-M33 und die quelloffenen
Hazard3-RISC-V-Kerne. Das Boot-ROM erkennt an der zweiten Stufe des Binaries, für welche
Architektur übersetzt wurde, und startet den Chip entsprechend neu.

➜ **Praktisch heisst das: Die Architekturwahl ist eine Build-Option, keine
Beschaffungsentscheidung.** Bis auf einen Teil der Sicherheitsfunktionen und den
Beschleuniger für doppelte Gleitkommagenauigkeit steht im RISC-V-Modus derselbe
Funktionsumfang zur Verfügung.

---

## 🔴 Fallen beim Umstieg RP2040 → RP2350

Der Skill warnt an anderer Stelle, dass der Pico 2 «keine reine Aufwertung» ist. Das sind
die konkreten Gründe:

| Falle | Was passiert |
|-------|--------------|
| 🔴 **Der Hardware-Dividierer ist weg** | Code, der die speichermappten Divider-Register des RP2040 direkt beschreibt, findet sie nicht mehr. Der RP2350 dividiert in der CPU – schneller, aber an anderer Stelle |
| **Andere Kernarchitektur** | M0+ → M33: anderer Befehlssatz, andere Assembler-Fragmente, andere Interrupt-Prioritätsstufen |
| **Mehr PIO, aber neu zu verteilen** | 3 Blöcke statt 2; fest verdrahtete Blocknummern in Beispielcode passen nicht mehr |
| **Anderes Spannungskonzept** | SMPS statt LDO – Beschaltung, Entstörung und Ruhestromverhalten unterscheiden sich |
| **BOOTSEL-Datenträger heisst anders** | `RPI-RP2` beim Pico, **`RP2350`** beim Pico 2. Skripte, die auf den Datenträgernamen prüfen, brechen |
| **Eigene UF2-Dateien** | Firmware ist **nicht** zwischen den Generationen austauschbar – z.B. `debugprobe_on_pico.uf2` gegen `debugprobe_on_pico2.uf2` |

➜ **Der Reflex bei «die Anleitung funktioniert auf dem Pico 2 nicht» ist deshalb nicht
Fehlersuche im eigenen Code, sondern die Frage, für welche Generation die Anleitung
geschrieben wurde.** Das ist derselbe Alterstest wie bei Pi-Anleitungen (`SKILL.md`) –
nur eine Ebene tiefer.

---

## Zwei Angaben, die Projekte falsch dimensionieren

### 🔴 «Batteriebetrieb über Wochen» – nicht durch Schlafmodus allein

Der RP2040 zieht **typisch ~180 µA, auch im Dormant-Modus**. Der Wert hängt von PVT ab:

| Faktor | Verhalten |
|--------|-----------|
| **P**rocess | streut zwischen einzelnen Chips |
| **V**oltage | Strom steigt **linear** mit der Spannung |
| **T**emperature | Strom steigt **nichtlinear** mit der Temperatur |

➜ **Die offizielle Empfehlung für minimalen Ruhestrom lautet nicht «tiefer schlafen»,
sondern das System oder den RP2040-Teil davon vollständig abzuschalten** – über einen
Lastschalter, der von einem externen RTC- oder Sensorereignis wieder eingeschaltet wird.

Das relativiert die Faustregel «Pico für Batteriebetrieb» aus `setup-provisioning.md`: Der
Pico ist gegenüber einem Pi um Grössenordnungen sparsamer, **aber 180 µA sind an einer
CR2032 (~220 mAh) rechnerisch rund sieben Wochen – ohne jede Nutzlast**. Wer Monate oder
Jahre braucht, plant die Abschaltung von Anfang an in die Schaltung ein und nicht in die
Firmware.

### 🔴 Der interne Temperatursensor ist unkalibriert

Der Temperatursensor im RP2040 ist **niedrig aufgelöst und benutzerseitig zu
kalibrieren**. Ohne Kalibrierung ist er unwahrscheinlich genau.

Der Grund liegt in der Referenzspannung: Die Umrechnungsformel reagiert **sehr empfindlich
auf VREF**, und der RP2040 hat **keine interne feste Spannungsreferenz**. VREF muss
deshalb entweder extern gemessen (und es ändert sich über die Zeit) oder von einer externen
Präzisionsreferenz geliefert werden.

> ℹ️ Die Sensorspannung **fällt**, wenn die Temperatur steigt – wer das Vorzeichen
> vertauscht, misst plausible, aber gespiegelte Werte.

➜ **Dieselbe Lehre wie beim Sense HAT (`accessories.md`): Ein eingebauter Temperatursensor
misst den Chip, nicht die Umgebung – und hier zusätzlich gegen eine unbekannte Referenz.**
Für eine Messgrösse, die im Projekt eine Rolle spielt, gehört ein externer, kalibrierter
Sensor an den Bus.

---

## Die Funkvarianten – und was sie kosten

Alle Funk-Picos (Pico W, Pico WH, Pico 2 W, Pico 2 W with headers) nutzen den
**Infineon CYW43439**, angebunden über SPI mit bis zu 33 MHz, mit einer von ABRACON
lizenzierten Antenne auf der Platine.

### 🔴 Der Funkteil belegt Pins doppelt

| Geteilte Ressource | Konsequenz |
|--------------------|------------|
| **SPI-Takt (CLK)** ↔ VSYS-Spannungsüberwachung | Der ADC kann **VSYS nur lesen, wenn gerade keine SPI-Übertragung läuft** |
| **CYW43439 DIN/OUT** ↔ IRQ | Interrupt-Anfragen sind **nur zwischen SPI-Übertragungen** prüfbar |
| **Die Onboard-LED** | Hängt beim Pico/Pico 2 an **GP25**, bei den W-Modellen am Funkchip über **WL_GPIO0** |

> 🔴 **Die LED ist die häufigste Ursache dafür, dass ein Blink-Beispiel auf einem Pico W
> nichts tut.** Der Code schaltet GP25 – dort ist auf dem W-Modell nichts angeschlossen.
> Kein Fehler, keine Meldung, nur eine dunkle LED. Dasselbe gilt für den Pico 2 W.

**Antennenfreiraum:** Metall in der Nähe oder unter der Antenne senkt Verstärkung und
Bandbreite deutlich. Geerdetes Metall **seitlich neben** der Antenne kann die Bandbreite
dagegen verbessern. Für Gehäusebau ist das dieselbe Disziplin wie die Freihaltung der
Antenne beim Pi (`mechanical.md`).

### Auf welchem Board läuft das eigentlich?

Aus MicroPython heraus gibt es keinen direkten Hardwaretest – man prüft indirekt:

```python
import network
if hasattr(network, "WLAN"):
    ...   # Firmware mit Funkunterstützung
```

```python
>>> import sys
>>> sys.implementation._machine
'Raspberry Pi Pico W with RP2040'
```

Beim C/C++-SDK ist es **keine Laufzeitfrage, sondern eine Build-Option**:

```bash
cmake -DPICO_BOARD=pico_w ..        # ohne das: falsche Pin-Vorgaben, kein Funk
```

> ⚠️ **Wer `-DPICO_BOARD` vergisst, baut gegen die Vorgaben des Standard-Pico.** Die
> Wireless-Bibliotheken werden gar nicht erst eingebunden, Standard-Pins für UART und
> andere Peripherie können abweichen. Der Fehler äussert sich als fehlende Funktion, nicht
> als Übersetzungsfehler.

### Lizenz – der Punkt für kommerzielle Projekte

`libcyw43` und **BTstack** sind für nichtkommerzielle Projekte frei. Raspberry Pi hat
darüber hinaus eine **kostenlose kommerzielle Lizenz** ausgehandelt – aber nur für:

- Funk-Picos (Pico W, Pico WH, Pico 2 W, Pico 2 W with headers), **oder**
- eigene Hardware aus **RP2040 + CYW43439** bzw. **RP2350 + CYW43439**.

➜ **Die Lizenzfreiheit hängt an der Chipkombination, nicht am Projekt.** Wer für ein
Produkt ein anderes Funkmodul wählt, verliert sie – das gehört in die Beschaffungs- und
nicht in die Implementierungsphase.

---

## Radio Module 2 (RM2) und die Zulassungsfrage

Raspberry Pi hat zwei Funkmodule; nur eines ist einzeln zu kaufen:

| Modul | Wo | Einzeln erhältlich |
|-------|----|--------------------|
| **RM1** | eingebaut in Pi 4, Pi 5, CM4, CM5 | ❌ nein |
| **RM2** | Zusatzmodul für eigene Mikrocontroller-Platinen | ✅ ja |

**RM2** ist ein kompaktes WLAN-/Bluetooth-Modul auf Basis desselben CYW43439:
Wi-Fi 4 (802.11b/g/n, nur 2,4 GHz), Bluetooth 5.2 (Classic und BLE), gemeinsame Antenne
für beides (SISO), gSPI-Hostanbindung mit wenigen Pins, dazu **drei hostgesteuerte GPIOs
als kleiner Portexpander**. Etwa 14,5 × 16,5 × 2,55 mm, FR4, **21 castellated Pins** im
1,5-mm-Raster. Betriebsbereich **−30 °C bis +70 °C**. Softwareseitig voll kompatibel zum
Pico-W- und Pico-2-W-SDK.

Stromaufnahme, die für Batterieauslegung zählt:

| Zustand | Strom |
|---------|-------|
| IEEE Power Save (PM1, DTIM1) | **1,19 mA** |
| Empfang aktiv (MCS7, −50 dBm) | 43 mA |
| Senden aktiv (MCS7, 16 dBm) | **271 mA** |

> 🔴 **271 mA im Sendebetrieb sind die Zahl, nach der das Netzteil und der Stützkondensator
> ausgelegt werden** – nicht der Ruhestrom. Sendespitzen sind kurz, aber sie brechen eine
> unterdimensionierte Versorgung ein, und der Ausfall sieht dann aus wie ein Funkproblem.

### Die Zulassung ist regional unterschiedlich stark

RM2 ist von Raspberry Pi vollständig getestet und abgestimmt; eine eigene HF-Abstimmung
oder Modulprogrammierung in der Fertigung entfällt.

| Region | Status |
|--------|--------|
| **EU, UK, USA, Kanada** | **Full Modular Approval** – das Hostgerät erbt die Zulassung, nur minimale Zusatzprüfung |
| **Indien, Malaysia** | 🔴 **Keine modulare Zulassung** – die Zertifizierung gilt nur dem Modul; **jedes Hostgerät braucht eine eigene Zulassung** |

➜ **Für ein Produkt, das nach Indien oder Malaysia geht, ist RM2 kein Abkürzungspfad durch
die Zulassung.** Das ist ein Kosten- und Terminfaktor in der Projektplanung, kein
technisches Detail. Prüfberichte und Zertifikate liegen im
[Product Information Portal](https://pip.raspberrypi.com/); für andere Regionen ist
`gma@raspberrypi.com` die Anlaufstelle.

---

## Debug Probe – SWD, UART und RTT

Der **Raspberry Pi Debug Probe** ist ein USB-Gerät, das gleichzeitig einen **UART-Adapter**
und eine **Arm-SWD-Schnittstelle** bereitstellt. Er spricht CMSIS-DAP und arbeitet damit mit
OpenOCD und allem, was den Standard unterstützt. I/O-Pegel: **3,3 V nominal**.

> ➜ **Wer einen Raspberry Pi als Entwicklungsrechner hat, braucht ihn nicht zwingend** –
> der Pi kann über seine GPIO-Leiste direkt SWD und UART bedienen. Der Debug Probe ist die
> Antwort für Windows-, macOS- und Linux-Rechner **ohne** GPIO-Header. Ein zweiter Pico tut
> es übrigens auch: mit der `debugprobe`-Firmware wird er zum USB-zu-SWD-Wandler.

### 🔴 Zuerst Masse, dann Signale

> 🔴 **Wird das Zielgerät aus einer anderen Quelle versorgt als der Debug Probe, muss vor
> den Signalleitungen eine gemeinsame Masse hergestellt werden.** Entweder das Ziel
> stromlos machen **oder** zuerst GND verbinden; RX, TX, SC und SD kommen danach.
> **Potenzialdifferenzen zwischen den beiden Systemen können den Probe zerstören.**

Das ist derselbe Fehlermechanismus wie bei jeder anderen Verbindung zweier getrennt
gespeister Systeme – nur dass hier ein Gerät kaputtgeht und nicht bloss die Übertragung
scheitert.

### Verkabelung

Am Debug Probe sind die 0,1-Zoll-Adapterkabel farbcodiert:

| Farbe | Signal | Richtung |
|-------|--------|----------|
| **Orange** | TX / SC | Ausgang des Probe |
| **Schwarz** | GND | – |
| **Gelb** | RX / SD | Eingang des Probe bzw. bidirektional |

Für UART wird **gekreuzt** verbunden: Probe-RX an Ziel-TX, Probe-TX an Ziel-RX, GND an GND.

> ⚠️ **Der SWD-Stecker führt keine Versorgung.** Er trägt ausschliesslich SWDIO, GND und
> SWCLK. Das Zielgerät braucht seine eigene Versorgung über USB oder VSYS – der Probe
> speist es nicht mit.

**Wo der Debug-Anschluss sitzt**, hängt von der Variante ab – das ist beim Kauf von Kabeln
und beim Gehäuseentwurf relevant:

| Board | Ort | Typ |
|-------|-----|-----|
| Pico, Pico 2 | Unterkante | drei castellated Lötpads |
| Pico H, Pico 2 with headers | Unterkante | **gekeyter 3-Pin-Stecker (JST-Bauart)** |
| Pico W, Pico 2 W | mittig, unter dem Chip | drei Durchkontaktierungen |
| Pico WH, Pico 2 W with headers | mittig, unter dem Chip | **gekeyter 3-Pin-Stecker** |

➜ Nur die Header-Varianten passen **ohne Nacharbeit** an den Debug Probe. Bei den anderen
ist eine Stiftleiste anzulöten.

### Firmware-Stand prüfen

```bash
lsusb -v -d 2e8a:000c | grep bcdDevice     # bcdDevice 2.31  =  Firmware 2.3.1
```

> ⚠️ **Die Zeile `CMSIS-DAP: FW Version = 2.0.0` aus OpenOCD ist nicht die
> Firmware-Version des Probe**, sondern die Protokollstufe von CMSIS-DAP. Die beiden
> werden regelmässig verwechselt.

### Programmieren und Debuggen ohne BOOTSEL-Taste

Der eigentliche Gewinn: Über SWD lässt sich ein Binary aufspielen, **ohne bei jedem
Durchlauf den BOOTSEL-Knopf zu drücken und neu einzustecken**.

```bash
sudo openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg \
     -c "adapter speed 5000" -c "program blink.elf verify reset exit"
```

> 🔴 **Über SWD wird die `.elf`-Datei geladen, nicht die `.uf2`.** Die UF2-Datei ist das
> Format für Drag-and-Drop im BOOTSEL-Modus. Wer die UF2 an OpenOCD übergibt, bekommt eine
> Fehlermeldung, die nicht sofort auf die Ursache zeigt.

Und für eine Sitzung mit Haltepunkten muss **als Debug-Build übersetzt** werden:

```bash
cmake -DCMAKE_BUILD_TYPE=Debug ..
```

```bash
sudo openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg -c "adapter speed 5000"
# zweites Fenster:
gdb blink.elf
(gdb) target remote localhost:3333
(gdb) monitor reset init
(gdb) continue
```

> ℹ️ Auf Nicht-Pi-Rechnern braucht es ein GDB, das Arm-Prozessoren kann: unter Linux
> `gdb-multiarch`, unter macOS und Windows `arm-none-eabi-gdb` aus der Arm-Toolchain.

### RTT – Konsolenausgabe ohne UART-Pins

**Segger Real-Time Transport (RTT)** schickt die Ausgabe des Programms über dieselbe
SWD-Verbindung. Damit entfallen die beiden UART-Leitungen komplett.

```cmake
target_link_libraries(mein_programm pico_stdio_rtt)
```

Nach `stdio_init_all()` geht jedes `printf()` über RTT. In einer eigenständigen Sitzung:

```
(gdb) monitor rtt setup 0x20000000 2048 "SEGGER RTT"
(gdb) monitor rtt start
(gdb) monitor rtt server start 60000 0
(gdb) continue
```

```bash
nc localhost 60000
```

➜ **Für Aufbauten, in denen jeder Pin gebraucht wird, ist RTT der entscheidende Trick:**
Debug-Ausgabe ohne einen einzigen zusätzlichen GPIO. Voraussetzung ist auch hier ein
Debug-Build.

### Warum sich ein Pico nicht per Software zerstören lässt

Der **BOOTSEL-Modus liegt im ROM des Mikrocontrollers** und ist nicht überschreibbar. Wer
beim Einstecken BOOTSEL hält, bekommt **immer** einen USB-Massenspeicher – unabhängig
davon, was im Flash steht.

➜ **Ein Pico ist per Software nicht dauerhaft unbrauchbar zu machen.** Zum Leeren des
externen Flash gibt es eine eigene UF2-Datei in `pico-examples`. Das ist ein
bemerkenswerter Unterschied zum Pi, wo ein misslungenes EEPROM-Update
(`os-and-software.md`) sehr wohl ein totes Gerät hinterlassen kann.

---

## Pi und Pico zusammen betreiben

Die Kombination ist für anspruchsvolle Projekte oft die richtige Antwort, und die
Aufgabenteilung folgt aus den Grenzen beider Seiten:

| Aufgabe | Wohin | Warum |
|---------|-------|-------|
| Inferenz, Kamera, Netz, Speicherung | **Pi** | NPU, Linux, Dateisystem (`edge-ai.md`) |
| Regelung im festen Takt, Motoren, Schrittketten | **Pico** | deterministisches Timing ohne Scheduler |
| Bitgenaue Protokolle, viele parallele Kanäle | **Pico** (PIO) | 8 bzw. 12 State Machines |
| Sensorik ausserhalb 0–70 °C | **Pico** | die Umgebungsgrenze des Pi (`mechanical.md`) |
| Weiterlaufen bei abruptem Stromverlust | **Pico** | kein Dateisystem, das korrumpieren kann |

**Verbindung:** UART (GPIO 14/15 am Pi, GP0/GP1 am Pico – gekreuzt, GND gemeinsam) oder
USB. Beim USB-Weg meldet sich der Pico als CDC-Gerät; unter Linux erscheint er als
`/dev/ttyACM*`.

> ⚠️ **Zwei Systeme, zwei Netzteile, eine Masse.** Für die UART-Verbindung zwischen Pi und
> Pico gilt dieselbe Regel wie für den Debug Probe: **gemeinsame Masse zuerst.** Und der Pi
> spricht 3,3 V – ein 5-V-Seriellkabel beschädigt den Anschluss (`rp1-gpio.md`).

➜ **Der Pi 5 verwischt die Grenze ein Stück:** Sein RP1 bringt einen **PIO-Block mit vier
State Machines** mit – denselben programmierbaren I/O-Baustein wie der RP2040. Zeitkritische
Protokolle lassen sich damit auf dem Pi selbst in Hardware abbilden (`rp1-gpio.md`), ohne
einen zweiten Rechner. Was der Pi 5 damit **nicht** löst, sind die anderen Zeilen der
Tabelle: Bootzeit, Temperaturbereich, Verhalten bei Stromverlust und Ruhestrom.

### Eigene Platine statt Pico

Wer aus einem Prototyp ein Produkt macht, findet bei Raspberry Pi offene Entwurfsdateien:

| Entwurf | Format | Wofür |
|---------|--------|-------|
| Pico / Pico W | Cadence Allegro | Referenzlayout der Boards |
| **Minimal Viable Board** (RP2040) | KiCad | kleinstmögliche RP2040-Platine |
| **RP2350A / RP2350B Minimal Viable Board** | KiCad | dasselbe für den RP2350 |
| VGA Carrier Board | KiCad | Multimedia-Trägerplatine (RP2040 und RP2350) |

Die Entwürfe sind ohne Einschränkung nutzbar, kopierbar und veränderbar – aber
ausdrücklich **«as-is» ohne jede Gewährleistung**.

➜ Für eigene Platinen zusätzlich relevant: die **USB-Produkt-ID** unter der Vendor-ID
`0x2E8A` (`setup-provisioning.md`) – und die Gegenfrage, ob wirklich eine eigene PID nötig
ist. Ohne Windows-Treiber und ohne den Anspruch, als eigenes Produkt erkannt zu werden,
genügen die Textfelder `iManufacturer`, `iProduct` und `iSerial`.

---

## Weitere Ressourcen

- [Microcontrollers – offizielle Dokumentation](https://www.raspberrypi.com/documentation/microcontrollers/)
- [Debug Probe](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html)
- [Raspberry Pi 3-pin Debug Connector Specification](https://datasheets.raspberrypi.com/debug/debug-connector-specification.pdf)
- [`debugprobe`](https://github.com/raspberrypi/debugprobe) – Firmware, auch für einen Pico als Probe
- [`pico-examples`](https://github.com/raspberrypi/pico-examples) – u.a. die UF2 zum Leeren des Flash
- `setup-provisioning.md` – die Gattungsentscheidung Pico oder Pi, Modelltabelle, USB-PIDs
- `rp1-gpio.md` – PIO auf dem Pi 5, GPIO-Timing, 3,3-V-Pegel am Debug-Header
