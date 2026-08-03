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
9. [Der ADC – und die 12 Bit, die keine sind](#der-adc--und-die-12-bit-die-keine-sind)
10. [GPIO-Pads am Mikrocontroller](#gpio-pads-am-mikrocontroller)
11. [Errata, die man als Fehler im eigenen Code sucht](#errata-die-man-als-fehler-im-eigenen-code-sucht)
12. [Flash zur Laufzeit beschreiben](#flash-zur-laufzeit-beschreiben)
13. [Stromsparen – und warum der Debugger es verhindert](#stromsparen--und-warum-der-debugger-es-verhindert)
14. [Der Pico W als Funkknoten am Pi](#der-pico-w-als-funkknoten-am-pi)
15. [Probleme, die das SDK bereits gelöst hat](#probleme-die-das-sdk-bereits-gelöst-hat)

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
| 🔴 **DMA-Transferzähler ist schmaler** | RP2040: volle **32 Bit**. RP2350: nur die unteren **28 Bit** sind die Anzahl, die oberen 4 kodieren Optionen. Eine Zahl > 2²⁸−1 wird **still** falsch interpretiert |
| **Andere Kernarchitektur** | M0+ → M33: anderer Befehlssatz, andere Assembler-Fragmente, andere Interrupt-Prioritätsstufen (2 signifikante Bits beim M0+, 4 beim M33, **auf RISC-V gar keine**) |
| **Mehr PIO, aber neu zu verteilen** | 3 Blöcke statt 2; fest verdrahtete Blocknummern in Beispielcode passen nicht mehr |
| **PIO sieht auf dem RP2350B nur 32 der 48 Pins** | Jede PIO-Instanz adressiert **entweder 0–31 oder 16–47**. Ein Entwurf, der Pins aus 0–15 *und* 32–47 in derselben Instanz braucht, ist nicht umsetzbar |
| **`in_count` ist auf dem RP2040 zwingend 32** | Der RP2040 kann ungenutzte Eingangspins nicht ausmaskieren; RP2350-Code mit kleinerem Wert läuft dort anders |
| 🔴 **Die RTC gibt es nur auf dem RP2040** | Der RP2350 ersetzt sie durch **powman** mit AON-Timer – andere API, anderes Konzept (siehe unten) |
| **Watchdog-Höchstdauer** | RP2040 **8388 ms** (~8,3 s, Errata RP2040-E1), RP2350 **16777 ms** (~16,7 s) |
| **Anderes Spannungskonzept** | SMPS statt LDO – Beschaltung, Entstörung und Ruhestromverhalten unterscheiden sich |
| **BOOTSEL-Datenträger heisst anders** | `RPI-RP2` beim Pico, **`RP2350`** beim Pico 2. Skripte, die auf den Datenträgernamen prüfen, brechen |
| **Eigene UF2-Dateien** | Firmware ist **nicht** zwischen den Generationen austauschbar – z.B. `debugprobe_on_pico.uf2` gegen `debugprobe_on_pico2.uf2` |

> ℹ️ **Zum Dividierer die Entwarnung:** Gewöhnliches `/` und `%` in C laufen über die
> `pico_divider`-Bibliothek und funktionieren auf beiden Generationen unverändert. Betroffen
> ist nur Code, der die Divider-Register **direkt** anspricht oder die inlined
> `hw_divider_*`-Funktionen benutzt – typischerweise handoptimierte Fragmente aus fremden
> Beispielen.

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

Der Grund steckt in der Umrechnungsformel selbst:

```
T = 27 − (ADC_Spannung − 0,706) / 0,001721
```

Der Nenner ist die Steilheit: **1,721 mV pro °C**. Umgestellt heisst das
**0,58 °C Fehler pro Millivolt Abweichung der Referenzspannung** – und der RP2040 hat
**keine interne feste Spannungsreferenz**. VREF muss deshalb entweder extern gemessen
werden (und ändert sich über die Zeit) oder von einer externen Präzisionsreferenz kommen.

> 🔴 **Zehn Millivolt daneben sind knapp sechs Grad daneben.** Das ist die ganze Geschichte
> hinter «unkalibriert ist unwahrscheinlich genau» – und der Grund, warum ein aus 3,3 V
> abgeleitetes VREF für Temperaturmessung nicht taugt: Die Versorgungsspannung schwankt
> mit Last und USB-Kabel um deutlich mehr als 10 mV.

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

### Drei Wege, die beiden zu verbinden

| Weg | Wie es sich am Pi darstellt | Wofür |
|-----|-----------------------------|-------|
| **UART** | `/dev/serial0` bzw. der Debug-Header | Einfachster Fall; GPIO 14/15 am Pi, GP0/GP1 am Pico, **gekreuzt** |
| **USB** | `/dev/ttyACM*` (CDC-Gerät) | Strom und Daten über ein Kabel; der Pico hängt nicht an der GPIO-Leiste |
| **I²C – der Pico als Slave** | ein **Busteilnehmer wie jeder Sensor** | Der elegante Weg, wenn am Pi schon ein I²C-Bus liegt |

➜ **Der I²C-Slave-Weg ist der architektonisch sauberste und wird am seltensten gesehen.**
Der Pico meldet sich unter einer eigenen 7-Bit-Adresse und verhält sich für den Pi wie ein
gewöhnliches Peripheriegerät – auslesbar mit `i2cdetect`, ansprechbar aus `smbus2`, ohne
eigenes Protokoll über eine serielle Leitung. Der Pi bleibt Master und braucht keine
Kenntnis davon, dass hinter der Adresse ein zweiter Rechner steckt.

> 🔴 **Der Slave-Handler läuft im Interrupt und muss in unter 25 µs zurückkehren**
> (bei 400 kbit/s). Rechnen, Blockieren oder Loggen gehört nicht hinein – der Handler
> nimmt Bytes an oder gibt Bytes heraus, alles andere macht die Hauptschleife. Grosse
> Übertragungen werden über mehrere Aufrufe verteilt.

> ⚠️ **Zwei Systeme, zwei Netzteile, eine Masse.** Für jede dieser Verbindungen gilt
> dieselbe Regel wie für den Debug Probe: **gemeinsame Masse zuerst.** Und der Pi spricht
> 3,3 V – ein 5-V-Seriellkabel beschädigt den Anschluss (`rp1-gpio.md`). Beim I²C-Weg
> zusätzlich: **die Pull-ups gehören genau einmal in den Bus**, nicht auf beide Seiten
> (`interfaces.md`).

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

## Der ADC – und die 12 Bit, die keine sind

Der ADC ist die Baugruppe, die am häufigsten überschätzt wird, weil auf dem Datenblatt
«12 Bit» steht.

| Angabe | RP2040 | RP2350 |
|--------|--------|--------|
| Nennauflösung | 12 Bit | 12 Bit |
| **Effektive Auflösung (ENOB)** | **8,7 Bit** | **9,2 Bit** |
| Abtastrate | 500 kS/s | 500 kS/s |
| Nutzbare Eingänge | 4 | 4 (QFN-60) bzw. **8** (QFN-80) |
| Empfangs-FIFO | 8 Einträge | 8 Einträge |

> 🔴 **8,7 effektive Bit sind rund ein Achtel der nominellen 4096 Stufen.** Wer eine Messung
> auf 12 Bit auslegt, plant mit Auflösung, die nicht da ist. Für alles, was Genauigkeit
> braucht – Wägezellen, Präzisionsthermometrie, Strommessung – gehört ein **externer ADC**
> an SPI oder I²C.

➜ **Das ist dasselbe Muster wie bei den MB/s auf der SD-Kartenverpackung
(`component-catalog.md`): Die beworbene Zahl beschreibt die Schnittstelle, nicht das
Ergebnis.** Die Frage im Entwurf lautet nicht «wie viele Bit hat der Wandler», sondern
«wie viele davon sind Signal».

### Die Kanalzuordnung wechselt mit dem Gehäuse

| Chip | Nutzereingänge | Temperatursensor |
|------|----------------|------------------|
| RP2040, RP2350A (QFN-60) | Eingang 0–3 = **GPIO 26–29** | Eingang **4** |
| RP2350B (QFN-80) | Eingang 0–7 = **GPIO 40–47** | Eingang **8** |

⚠️ Code, der den Temperatursensor fest auf Eingang 4 legt, misst auf einem RP2350B einen
Analogeingang. Kein Fehler, nur ein falscher Wert.

Zwei Dinge, die dabei leicht untergehen: `adc_gpio_init()` muss den Pin **hochohmig**
machen (Pull-ups aus), und der Temperatursensor braucht ein ausdrückliches
`adc_set_temp_sensor_enabled(true)` – ohne das liefert er nichts Sinnvolles.

---

## GPIO-Pads am Mikrocontroller

Die Treiberstärken sind dieselbe Leiter wie beim RP1 des Pi 5 (`rp1-gpio.md`):

| Stufe | 2 mA | 4 mA | 8 mA | 12 mA |
|-------|------|------|------|-------|

➜ **Der RP2040, der RP2350 und der RP1 teilen sich diese Staffelung** – sichtbarer Beleg
der gemeinsamen Herkunft. Zur Einordnung gegenüber den älteren SoCs: Pi 1/2/3 gehen bis
16 mA, der **Pi 4 nur bis 8 mA** (`hardware-specs.md`).

Drei Eigenheiten, die im Entwurf zählen:

| Merkmal | Wirkung |
|---------|---------|
| 🔴 **Beide Pulls gleichzeitig** | Auf dem RP2040 ist das **kein** stärkerer Pull, sondern **«bus keep»**: ein schwaches Halten des *aktuellen* Pegels. Wer beides setzt in der Annahme, es addiere sich, bekommt etwas völlig anderes |
| **Schmitt-Trigger** | Auf allen GPIOs **voreingestellt an**. Abschalten verkürzt die Eingangsverzögerung minimal, macht Messwerte bei langsamen Flanken aber unzuverlässig |
| **Flankensteilheit** | Begrenzbar (`slow`/`fast`). Die langsame Stufe senkt die Störabstrahlung – relevant, sobald ein Funkmodul oder ein GPS-Empfänger im selben Gehäuse sitzt (`camera.md`) |

---

## Errata, die man als Fehler im eigenen Code sucht

Diese Hardwarefehler äussern sich als plausible Software-Symptome. Wer sie nicht kennt,
sucht sehr lange an der falschen Stelle.

| Errata | Symptom | Umgang |
|--------|---------|--------|
| 🔴 **RP2040-E13** | Nach dem Abbruch eines DMA-Kanals kommt ein **Abschluss-Interrupt, obwohl nichts abgeschlossen wurde** | IRQ für den Kanal vor dem Abbruch abschalten, danach quittieren und wieder einschalten |
| **RP2350-E5** | Ein abgebrochener DMA-Kanal **löst sich selbst erneut aus** | Vor dem Abbruch die Enable-Bits des Kanals **und aller verketteten Kanäle** löschen |
| 🔴 **RP2040-E1** | `watchdog_get_time_remaining_*` liefert **den zuletzt gesetzten Wert statt der Restzeit** | Auf dem RP2040 nicht zur Laufzeitüberwachung verwenden; ausserdem Höchstdauer 8388 ms |
| **RP2350-E2** | Schreibzugriffe auf SIO-Register oberhalb +0x180 **überlagern die Spinlocks** und geben sie unbeabsichtigt frei | Das SDK weicht auf atomare Speicherzugriffe aus – bei eigenem Registerzugriff selbst bedenken |
| **RP2350-E11** | `xip_cache_clean_all()` **verwirft nebenbei den gesamten Cache**; der nächste Zugriff auf jede Zeile geht ins externe Medium | `xip_cache_clean_range()` verwenden, wenn der Cache warm bleiben soll |
| **RP2040-E10** | Das BADWRITE-Flag des Ringoszillators ist **unzuverlässig** | Nicht als Erfolgsprüfung eines ROSC-Schreibzugriffs auswerten |

➜ **Die gemeinsame Lehre: Ein Symptom, das «unmöglich» aussieht, ist auf einem
Mikrocontroller häufiger ein bekanntes Errata als ein eigener Denkfehler.** Der erste Griff
bei unerklärlichem Verhalten gehört ins Errata-Kapitel des jeweiligen Datenblatts – nicht in
den nächsten Debug-Durchlauf.

---

## Flash zur Laufzeit beschreiben

Ein Pico führt seinen Code **aus dem Flash heraus** aus (XIP, Execute In Place). Daraus
folgt die zentrale Regel:

> 🔴 **Wer Flash löscht oder programmiert, sägt an dem Ast, auf dem der Code sitzt.**
> Während der Operation ist der Flash für Befehlsabrufe nicht verfügbar. Läuft in dieser
> Zeit ein Interrupt-Handler aus dem Flash oder führt der zweite Kern Flash-Code aus,
> stürzt das Gerät ab.

**Die drei Vorkehrungen:**

1. **`flash_safe_execute()`** benutzen – es schaltet Interrupts ab und stimmt sich mit dem
   zweiten Kern ab.
2. Bei eigener Absicherung: **Interrupts aus**, wenn Handler oder Vektortabelle im Flash
   liegen.
3. Den anderen Kern anhalten oder in RAM-Code parken.

**Die Geometrie ist nicht verhandelbar:**

| Operation | Ausrichtung und Vielfaches |
|-----------|----------------------------|
| Löschen | **4096 Byte** (ein Sektor) |
| Programmieren | **256 Byte** (eine Seite) |

> ⚠️ **Programmieren setzt Bits nur von 1 auf 0.** Der Weg zurück führt ausschliesslich
> über das Löschen des **ganzen Sektors**. Wer einen Zähler oder ein Konfigurationsfeld
> «einfach überschreibt», bekommt das UND aus altem und neuem Wert – ein Fehlerbild, das
> wie ein Speicherfehler aussieht und keiner ist.

### Wenn Flash und PSRAM zusammenkommen

Der XIP-Cache weiss nichts von seriellen Flash-Operationen. Die verlässliche Reihenfolge:

```
1. Cache vollständig zurückschreiben   (xip_cache_clean_all)
2. Flash löschen und programmieren
3. Cache vollständig verwerfen          (xip_cache_invalidate_all)
```

➜ **Das Zurückschreiben vor dem Verwerfen ist der Schritt, den man auslässt und dann
bereut:** Ohne ihn gehen noch nicht geschriebene PSRAM-Daten beim Verwerfen verloren. Auf
dem RP2040 entfällt er – dessen XIP-Cache ist reiner Lesecache.

### Seriennummer ohne eigene Verwaltung

`flash_get_unique_id()` liest die 64-Bit-Kennung des Flash-Bausteins. Da Chip und
Mikrocontroller fest zusammengehören, ist das **eine eindeutige Kennung der Platine** –
das Gegenstück zur Seriennummer aus dem OTP auf der Linux-Seite
(`setup-provisioning.md`).

---

## Stromsparen – und warum der Debugger es verhindert

Es gibt **drei** Stufen, nicht zwei – und die gemessenen Werte widersprechen der Intuition
an einer entscheidenden Stelle.

| Stufe | Was passiert |
|-------|--------------|
| **Sleep** | Ausgewählte Takte laufen weiter. Aufwachen durch **jeden** Interrupt, dessen Takt aktiv bleibt |
| **Dormant** | XOSC und ROSC stehen. Aufwachen **nur** über AON-Timer oder GPIO-Interrupt; USB wird ab- und danach wieder angeschaltet |
| **Pstate** (nur RP2350) | Ganze Leistungsbereiche sind stromlos. Aufwachen **nur** über AON-Timer oder GPIO |

### 🔴 Die gemessenen Werte – und die Überraschung

Offizielle Messwerte an Pico-Boards, einmal aus **VSYS** (5,2 V) und einmal direkt aus
**3V3** gespeist:

| Modus | Pico (VSYS) | Pico 2 (VSYS) | Pico (3V3) | Pico 2 (3V3) |
|-------|-------------|---------------|------------|--------------|
| Sleep | 7,3 mA | 5,9 mA | 8,7 mA | 6,9 mA |
| **Dormant** | **0,95 mA** | 🔴 **3,3 mA** | **1,2 mA** | 🔴 **3,7 mA** |
| Pstate (SRAM0 an) | – | 0,25 mA | – | 0,14 mA |
| Pstate (XIP-SRAM an) | – | 0,22 mA | – | 0,10 mA |
| **Pstate (alles aus)** | – | **0,18 mA** | – | **0,08 mA** |

> 🔴 **Im Dormant-Modus zieht der Pico 2 rund das Dreifache des Pico 1.** Der Grund ist
> kein Defekt: Der RP2350 lässt `clk_ref` aus dem LPOSC weiterlaufen, damit der Timer
> weiterzählt, während der RP2040 nur `clk_rtc` aus dem XOSC betreibt.
>
> ➜ **Wer einen Pico-1-Entwurf auf den Pico 2 überträgt und beim Dormant-Modus bleibt,
> verschlechtert die Laufzeit um Faktor drei.** Der Gewinn liegt ausschliesslich im
> **Pstate** – dort ist der Pico 2 gegenüber dem besten Wert des Pico 1 um mehr als
> **Faktor zehn** besser. Die Generationsverbesserung ist also kein Automatismus, sondern
> hängt daran, dass man die neue Stufe auch benutzt.

Das korrigiert die Faustregel weiter oben: Der RP2350 beantwortet das 180-µA-Problem –
**aber nur über Pstate**, nicht über den Schlafmodus, den man aus dem RP2040-Code
mitbringt.

### ⚠️ Wie gespeist wird, kostet mehr als was schläft

Bei den kleinen Strömen dreht sich das Verhältnis um: **Pstate aus 3V3 zieht 0,40 mW,
aus VSYS 1,10 mW.** Der Aufwärtsregler auf dem Board hat seinen eigenen Ruheverbrauch, der
im Tiefschlaf plötzlich den grösseren Anteil ausmacht.

➜ **Für ein batteriebetriebenes Produkt ist die Speisungsarchitektur damit wichtiger als
die letzte Sparstufe der Firmware.** Wer aus zwei Zellen über den VSYS-Eingang speist,
verschenkt den grössten Teil dessen, was Pstate einbringt. Auf einer eigenen Platine
(`Minimal Viable Board`, siehe oben) speist man 3,3 V direkt.

### Was im Pstate abgeschaltet wird

| Abschaltbarer Bereich | Inhalt |
|-----------------------|--------|
| Switched Core | Prozessoren, Busfabric, Peripherie |
| XIP-Cache | 2 × 8 kB |
| SRAM Bank 0 | untere 256 kB |
| SRAM Bank 1 | obere 256 kB plus Scratch X/Y |

### 🔴 Pstate ist kein Schlaf – es ist ein Neustart

> 🔴 **Beim Aufwachen aus dem Pstate läuft das Programm wieder von vorn.** `crt0`
> überschreibt sämtliche nicht-persistenten Daten; ein `resume_func` wird während der
> Laufzeitinitialisierung aufgerufen und bekommt den benutzten Pstate übergeben.

Das ist ein anderes mentales Modell als «schlafen und weitermachen». Wer Zustand über den
Tiefschlaf retten will, markiert ihn ausdrücklich:

```c
__persistent_data static uint32_t messwertzaehler;
```

Der Ablageort wird über die CMake-Funktion `pico_set_persistent_data_loc` gewählt –
**XIP-SRAM oder Haupt-SRAM**. Die Messwerte oben zeigen, was das kostet: XIP-SRAM
anzulassen ist mit 0,10 mA billiger als SRAM Bank 0 mit 0,14 mA.

⚠️ Die **letzten beiden powman-Scratch-Register** werden von den Pstate-Funktionen
überschrieben; die übrigen bleiben für eigene persistente Daten nutzbar.

### Zwei Dinge, die den gemessenen Wert verderben

| Punkt | Wirkung |
|-------|---------|
| 🔴 **Pins lecken** | Ungenutzte GPIOs mit aktiven Pulls oder Eingangspuffern ziehen messbar Strom. `low_power_set_pins_low_leakage_exclude_mask()` schaltet Pulls und Eingänge ab und setzt alles auf Eingang – ohne diesen Schritt sind die Tabellenwerte oben nicht erreichbar |
| 🔴 **RP2040: zeitgesteuertes Dormant braucht einen externen Takt** | Für Dormant mit AON-Timer muss auf dem RP2040 eine **externe Taktquelle** an einem GPIO anliegen (`low_power_set_external_clock_source`). Ohne sie schlägt der Aufruf fehl. Nur der Weg über `DORMANT_CLOCK_SOURCE_RTC` kommt ohne aus – dann bleibt aber der XOSC an |

➜ **Für reines GPIO-Aufwachen ist `DORMANT_CLOCK_SOURCE_ROSC` die sparsamste Wahl** – ein
GPIO-Interrupt braucht überhaupt keinen Takt.

### 🔴 Die Falle, die jede Messung ruiniert

> 🔴 **Mit angeschlossenem Debugger schläft powman nie ein.** Ein angehängter Debugger setzt
> das Signal `pwrupreq` – und OpenOCD löscht es beim Beenden **nicht** wieder. Ab dem ersten
> Anstecken bleibt der Chip wach, auch nachdem das Debug-Werkzeug längst zu ist.

Der Ausweg ist `powman_set_debug_power_request_ignored(true)`. Zwei Konsequenzen:

- **Strommessungen sind mit angeschlossenem Debug Probe wertlos**, solange das nicht gesetzt
  ist. Wer den Ruhestrom eines Aufbaus beurteilen will, misst ohne Debugger – oder
  wundert sich über Werte, die um Grössenordnungen danebenliegen.
- Wird der Switched Core mit angeschlossenem Debugger abgeschaltet, **bricht der Debugger
  ab** – die Prozessoren sind dann stromlos. Das ist kein Defekt.

### Zeitquellen des AON-Timers

| Quelle | Wofür |
|--------|-------|
| **LPOSC** (~32 kHz) | Standard; Kalibrierwert kommt aus dem OTP |
| **XOSC** | genauer, aber teurer im Verbrauch |
| **GPIO, 1 kHz** | externer Takt (nur GPIO 12, 14, 20, 22) |
| **GPIO, 1 Hz** | **Sekundenimpuls z.B. eines GPS-Empfängers** (nur GPIO 12, 14, 20, 22) |

➜ **Der 1-Hz-Eingang ist der Weg zu einer Uhr, die ohne Netz genau bleibt.** Die
Millisekunden kommen weiter aus LPOSC oder XOSC, die Sekunden vom GPS-PPS. Für
Feldmesstechnik mit Zeitstempeln ist das die saubere Lösung – dort allerdings mit dem
Störungshinweis aus `camera.md` im Hinterkopf, falls im selben Aufbau eine Kamera läuft.

---

## Der Pico W als Funkknoten am Pi

Die naheliegendste Rolle eines Pico W in einem Pi-Projekt ist der **drahtlose Aussenposten**:
Sensorik dort, wo kein Kabel hinkommt, Daten per WLAN oder BLE zum Pi. Vier Entscheidungen
fallen dabei früh.

### 1. Die Nebenläufigkeitsarchitektur – die erste und folgenreichste Wahl

| Variante | Verhalten | Wofür |
|----------|-----------|-------|
| **`poll`** | 🔴 **nicht** multicore-/threadsicher; `cyw43_arch_poll()` muss regelmässig aus der Hauptschleife kommen | Einfache Einzelkernprogramme |
| **`threadsafe_background`** | Multicore- und threadsicher; Treiber und Netzwerkstapel laufen **in einem niederpriorisierten IRQ** | Der übliche Fall |
| **`freertos`** | Multicore-/tasksicher; eigener FreeRTOS-Task, blockierende Socket-API (`NO_SYS=0`) | Wenn ohnehin ein RTOS läuft |

> 🔴 **lwIP ist nicht threadsicher.** Aufrufe in den Stapel müssen mit
> `cyw43_arch_lwip_begin()` und `cyw43_arch_lwip_end()` geklammert werden – **ausser** sie
> kommen aus einem lwIP-Callback heraus. Wer die Klammerung vergisst, bekommt keinen
> Compilerfehler, sondern sporadische Abstürze unter Last.

> ⚠️ **lwIP-Callbacks laufen im IRQ-Kontext** (niedrige Priorität, ähnlich einem
> Alarm-Callback). Was dort passiert, unterliegt denselben Regeln wie jeder ISR: kurz
> bleiben, nicht blockieren, keine RTOS-Aufrufe, die im IRQ verboten sind.

➜ **Die Wahl `poll` ist verlockend und meist die falsche.** Sie spart Komplexität nur so
lange, wie das Programm einkernig und ohne Interrupts bleibt. Sobald ein zweiter Kern die
Sensorik übernimmt – der übliche Grund, überhaupt einen Pico zu nehmen – ist
`threadsafe_background` die richtige Grundlage.

### 2. 🔴 Der Ländercode, den fast niemand setzt

`cyw43_arch_init()` initialisiert mit **`CYW43_COUNTRY_WORLDWIDE`**, und die Dokumentation
sagt dazu unmissverständlich: *«Worldwide settings may not give the best performance.»*

```c
cyw43_arch_init_with_country(CYW43_COUNTRY_SWITZERLAND);   // oder _GERMANY, _UK, …
```

Alternativ dauerhaft über `PICO_CYW43_ARCH_DEFAULT_COUNTRY_CODE`.

➜ **Das ist zugleich eine Leistungs- und eine Regulierungsfrage.** Der Weltweit-Code wählt
den kleinsten gemeinsamen Nenner an Kanälen und Sendeleistung. Für ein Produkt gehört der
Zielmarkt gesetzt – dieselbe Logik wie beim Funkzulassungsabschnitt zu RM2 oben und wie
beim `wpa_country` auf der Linux-Seite (`setup-provisioning.md`).

### 3. Die Sendeleistungsverwaltung ist ein eigener Regler

Getrennt von den Schlafmodi weiter oben hat der Funkchip seine eigene Stufe:

| Modus | Bedeutung |
|-------|-----------|
| `CYW43_NONE_PM` | keine Sparfunktion |
| `CYW43_PERFORMANCE_PM` (**Vorgabe**) | PM2 – spart, wenn eine Weile nichts läuft, bei hohem Durchsatz |
| `CYW43_AGGRESSIVE_PM` | PM1 – spart stärker, **senkt den Durchsatz** |

⚠️ Muss **nach** `cyw43_wifi_set_up()` gesetzt werden.

➜ **Für einen Sensorknoten, der alle paar Minuten ein paar Bytes schickt, ist
`CYW43_AGGRESSIVE_PM` fast immer richtig** – der Durchsatzverlust ist irrelevant, die
Ersparnis nicht. Für einen Kamerastrom ist er falsch.

### 4. 🔴 Die Verbindungsleiter – vier Zustände, nicht zwei

«Verbunden» ist beim WLAN kein einzelner Zustand. `cyw43_tcpip_link_status()` liefert:

| Wert | Bedeutung | Was zu tun ist |
|------|-----------|----------------|
| `CYW43_LINK_DOWN` | kein Funk | Verbindung starten |
| `CYW43_LINK_JOIN` | **mit dem AP verbunden – aber noch ohne IP** | warten; DHCP läuft |
| `CYW43_LINK_NOIP` | verbunden, **DHCP hat nichts geliefert** | DHCP-Server, Adressbereich prüfen |
| `CYW43_LINK_UP` | verbunden **mit** IP-Adresse | betriebsbereit |
| `CYW43_LINK_FAIL` | Verbindung fehlgeschlagen | allgemeiner Fehler |
| `CYW43_LINK_NONET` | **kein passendes SSID gefunden** | ausser Reichweite, AP aus, oder Tippfehler |
| `CYW43_LINK_BADAUTH` | **Authentifizierung fehlgeschlagen** | falsches Passwort oder falscher Auth-Typ |

> ➜ **Die Unterscheidung `JOIN` gegen `UP` ist der häufigste Grund für «es verbindet sich,
> aber nichts geht».** Wer nach dem erfolgreichen Verbinden sofort einen Socket öffnet,
> arbeitet ohne IP-Adresse. Der Zustand muss bis `CYW43_LINK_UP` abgewartet werden.

⚠️ `cyw43_wifi_link_status()` kennt nur die Funkseite und meldet `JOIN` bereits als Erfolg;
`cyw43_tcpip_link_status()` ist die Obermenge inklusive IP-Zustand. **Für die Frage «kann
ich jetzt senden» ist die zweite die richtige.**

➜ Diese Leiter ist das Gegenstück zur Diagnosekette auf der Linux-Seite
(`remote-access.md`): erst Funk, dann Adresse, dann Dienst. Dieselbe Reihenfolge, nur mit
anderen Werkzeugnamen.

### Verschlüsselte Verbindungen zum Pi

`pico_mbedtls` bindet mbedTLS ein und nutzt dabei die Hardware, sofern vorhanden:

| Beschleunigung | RP2040 | RP2350 |
|----------------|--------|--------|
| Entropiequelle aus `get_rand_64()` | ✅ | ✅ |
| **SHA-256 in Hardware** | 🔴 nein | ✅ (`MBEDTLS_SHA256_ALT`) |

➜ **TLS auf einem RP2040 ist Softwarearbeit.** Wer einen Knoten baut, der regelmässig
verschlüsselt zum Pi spricht, hat auf dem RP2350 einen spürbaren Vorteil – zusätzlich zu
den Sicherheitsfunktionen aus dem Vergleich weiter oben.

⚠️ **Zufallszahlen: `pico_rand` ist ein PRNG**, gespeist aus mehreren Entropiequellen
(Ringoszillator, Zeitgeber, Bus-Zähler, RAM-Inhalt beim Start) – **kein echter
Zufallsgenerator**. Einen TRNG in Hardware hat erst der RP2350. Für kryptografische
Schlüssel ist der Unterschied erheblich.

> ⚠️ Der Ringoszillator als Entropiequelle **darf nicht genutzt werden, wenn der Prozessor
> selbst aus dem ROSC getaktet wird** – dann ist die «zufällige» Quelle mit dem Verbraucher
> korreliert.

---

## Probleme, die das SDK bereits gelöst hat

Mehrere der Fallen aus dieser Referenz haben eine fertige Antwort in einer
SDK-Bibliothek. Wer sie kennt, schreibt den Workaround nicht selbst.

| Problem | Antwort |
|---------|---------|
| 🔴 **LED an GP25 oder WL_GPIO0?** (siehe oben) | **`pico_status_led`** – `status_led_init()` und `status_led_set_state()` finden die richtige LED selbst, egal ob einfarbig, am Funkchip oder als WS2812. Damit läuft derselbe Quelltext auf Pico, Pico W und Pico 2 W |
| **Seriennummer der Platine** | **`pico_unique_id`** liest sie **vor `main()`** und legt sie sicher ab – ohne die Flash-Klippen aus dem Abschnitt oben. Quelle ist der **Flash-Baustein (RP2040)** bzw. das **OTP (RP2350)** |
| **BOOTSEL-Taste unerreichbar im Gehäuse** | **`pico_bootsel_via_double_reset`** – zweimaliges schnelles Zurücksetzen führt in den BOOTSEL-Modus |
| **Neu flashen ohne Anfassen** | **`pico_usb_reset`** – Rücksetzen über die USB-Schnittstelle; bei `pico_stdio_usb` ohnehin enthalten |
| **Daten zwischen den Kernen** | **`queue`** aus `pico_util` – multicore- und interruptsicher, **nicht** die FIFOs (siehe unten) |
| 🔴 **Die ersten `printf` über USB fehlen** | Der Host verbindet sich erst nach dem Programmstart; alles davor geht verloren. **`PICO_STDIO_USB_CONNECT_WAIT_TIMEOUT_MS`** lässt `stdio_init_all()` auf die Verbindung warten. Zur Laufzeit prüft `stdio_usb_connected()` |

⚠️ **`pico_stdio_usb` beansprucht die USB-Schnittstelle vollständig** – eigene
Device- oder Host-Anwendungen sind damit ausgeschlossen. Wird `tinyusb_device` oder
`tinyusb_host` dazugelinkt, zieht sich die Bibliothek automatisch zurück.

### 🔴 Die Inter-Core-FIFOs gehören nicht dir

> 🔴 **Die beiden FIFOs zwischen den Kernen sind eine knappe, vom SDK selbst belegte
> Ressource.** Sie werden für den Start von Kern 1 und für die Lockout-Funktionen gebraucht,
> und ein RTOS wie FreeRTOS SMP beansprucht sie exklusiv. Wer eigene Daten darüber schickt,
> kollidiert früher oder später mit einem dieser Nutzer.

Dazu ein Portierungsdetail: Die FIFOs sind **8 Einträge tief auf dem RP2040, aber nur 4 auf
dem RP2350**. Code, der sich auf die Tiefe verlässt, blockiert auf dem Pico 2 früher.

➜ **Für den Datenaustausch zwischen den Kernen ist `queue` die richtige Wahl** – sie deckt
praktisch alle Fälle ab und kollidiert mit nichts.

### Zwei Kerne und Flash gleichzeitig

Der Abschnitt zum Flash-Schreiben oben nennt `flash_safe_execute()`. Was dort nicht steht:
**Die Absicherung funktioniert nicht in jeder Umgebung.**

| Situation | Sicher? |
|-----------|---------|
| Ein Kern, Interrupts aus | ✅ |
| `pico_multicore` **mit** `flash_safe_execute_core_init()` auf dem anderen Kern | ✅ |
| `pico_multicore` **ohne** diesen Aufruf | 🔴 nein – das SDK weiss nicht, was der andere Kern tut |
| FreeRTOS SMP mit `configNUM_CORES=1` | 🔴 nein |
| FreeRTOS ohne SMP, aber mit `pico_multicore` | 🔴 nein |

Für die unsicheren Fälle gibt es die ausdrückliche Zusicherung
`PICO_FLASH_ASSUME_CORE0_SAFE=1` bzw. `..._CORE1_SAFE=1` – eine Aussage des Entwicklers,
dass der betreffende Kern nie aus dem Flash arbeitet.

⚠️ Der Mechanismus dahinter (`multicore_lockout`) **belegt die Inter-Core-FIFOs**. Wer
`multicore_lockout_victim_init()` aufruft, kann sie danach für nichts anderes mehr nutzen –
siehe oben.

### Der Speicherfresser im Zeitcode

Der AON-Timer bietet zwei Sorten von Funktionen: mit **Kalenderdatum** (`struct tm`) und mit
**linearer Zeit** (`struct timespec`). Welche billiger ist, hängt vom Chip ab:

| Chip | Sparsame Variante | Weil |
|------|-------------------|------|
| **RP2040** | die `_calendar()`-Funktionen | intern liegt eine Kalenderuhr (RTC); die lineare Variante zieht `localtime_r` aus der C-Bibliothek nach |
| **RP2350** | die Funktionen **ohne** `_calendar` | intern liegt ein linearer Zähler; die Kalendervariante zieht `mktime` nach |

> ⚠️ **`localtime_r` und `mktime` vergrössern das Binary erheblich.** Auf einem Chip mit
> 2 MB Flash fällt das nicht auf, auf einem Entwurf mit knappem Speicher sehr wohl. Beide
> sind als schwache Symbole deklariert und können durch eine schlankere eigene
> Implementierung ersetzt werden.

➜ **Die Regel: die Zeitdarstellung nehmen, die der Chip ohnehin führt.** Das ist eine der
wenigen Stellen, an denen dieselbe API auf beiden Generationen unterschiedlich teuer ist.

### 🔴 Bluetooth belegt das Ende des Flash

Nutzt ein Projekt BTstack, legt dessen Speicherabstraktion die Bindungsschlüssel in
**zwei Flash-Sektoren am Ende des Bausteins** ab (auf dem RP2350 A2 drei Sektoren vom Ende
entfernt, wegen Errata RP2350-E10).

> 🔴 **Das kollidiert mit jedem eigenen Konfigurations- oder Messwertspeicher, der «ganz
> hinten im Flash» abgelegt wird** – eine sehr verbreitete Wahl, weil dort nie Programmcode
> liegt. Das Fehlerbild: Nach dem ersten Bluetooth-Pairing sind die eigenen Daten weg, oder
> die Kopplung überlebt einen Neustart nicht. Steuerbar über
> `PICO_FLASH_BANK_STORAGE_OFFSET`.

### Gleitkomma – und was die RISC-V-Umschaltung kostet

Die Implementierung ist wählbar (`none`, `compiler`, `pico`), voreingestellt ist `pico`
mit handoptimierten Routinen aus Bootrom und SDK. Auf dem RP2350 nutzt `pico_double` die
**DCP-Befehle** des Doppel-Koprozessors.

> 🔴 **Auf RISC-V gibt es keine dieser Optimierungen für doppelte Genauigkeit** –
> `pico_double pico` ist dort gleichbedeutend mit `compiler`.
>
> ➜ Das ist die versteckte Rechnung hinter der Architekturumschaltung aus dem Abschnitt
> ganz oben: Der Wechsel auf Hazard3 kostet nicht nur einzelne Sicherheitsfunktionen,
> sondern auch die beschleunigte `double`-Arithmetik. Für Regelungstechnik oder
> Signalverarbeitung mit `double` ist das der entscheidende Punkt.

`none` ist die dritte Wahl und unterschätzt: Damit lösen Gleitkommaoperationen einen Panic
aus – **eine wirksame Prüfung, dass sich in eine Echtzeitschleife keine `float`-Arithmetik
eingeschlichen hat.**

### Wo Code und Daten liegen

Weil das Programm normalerweise **aus dem Flash** läuft (XIP), unterliegt jeder Aufruf der
Latenz des externen Bausteins. Für zeitkritische Teile gibt es Platzierungsmakros:

| Makro | Wirkung |
|-------|---------|
| `__time_critical_func(name)` | Funktion ins RAM – gegen XIP-Latenz |
| `__not_in_flash_func(name)` | dasselbe, semantisch «darf nicht im Flash liegen» (z.B. Code, der Flash beschreibt) |
| `__in_scratch_x` / `__in_scratch_y` | in eine der beiden separaten SRAM-Bänke |
| `__uninitialized_ram(name)` | **überlebt einen Reset** (wird nicht genullt) |

➜ **`__in_scratch_x`/`_y` sind der Trick gegen Buskonflikte:** Greift nur ein Kern auf eine
Bank zu, kann es dort keine Wartezyklen durch den anderen geben. Für die zeitkritische
Schleife eines Kerns ist das die passende Ablage – und die Ergänzung zu den PIO- und
DMA-Mitteln, mit denen man die CPU aus dem Zeitverhalten heraushält.

---

## Weitere Ressourcen

- [Microcontrollers – offizielle Dokumentation](https://www.raspberrypi.com/documentation/microcontrollers/)
- [Raspberry Pi Pico C/C++ SDK – API-Dokumentation](https://www.raspberrypi.com/documentation/pico-sdk/) – die Funktionsreferenz selbst; hier stehen nur die Entwurfsfolgen
- [Debug Probe](https://www.raspberrypi.com/documentation/microcontrollers/debug-probe.html)
- [Raspberry Pi 3-pin Debug Connector Specification](https://datasheets.raspberrypi.com/debug/debug-connector-specification.pdf)
- [`debugprobe`](https://github.com/raspberrypi/debugprobe) – Firmware, auch für einen Pico als Probe
- [`pico-examples`](https://github.com/raspberrypi/pico-examples) – u.a. die UF2 zum Leeren des Flash
- `setup-provisioning.md` – die Gattungsentscheidung Pico oder Pi, Modelltabelle, USB-PIDs
- `rp1-gpio.md` – PIO auf dem Pi 5, GPIO-Timing, 3,3-V-Pegel am Debug-Header
