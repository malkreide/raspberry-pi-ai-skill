# Hardware-Spezifikationen – Raspberry Pi 4 & 5

Quelle der Pi-5-Werte: **Raspberry Pi 5 Product Brief, RP-008348-DS (April 2026)**.
Mechanische Masse, Bohrbild und Gehäusethemen: siehe [`mechanical.md`](mechanical.md).

## Inhaltsverzeichnis
1. [Raspberry Pi 5](#raspberry-pi-5)
2. [Raspberry Pi 4](#raspberry-pi-4)
3. [GPIO-Pinout](#gpio-pinout)
4. [Strombudgets](#strombudgets)
5. [Thermisches Management](#thermisches-management)
6. [Schnittstellen](#schnittstellen)
7. [Modellwahl & Beschaffung](#modellwahl--beschaffung)

PCIe-Stecker, FFC-Anforderungen und M.2 HAT+: [`pcie.md`](pcie.md).
RP1-Pads, Latenzverhalten und Alternativfunktionen: [`rp1-gpio.md`](rp1-gpio.md).
Boot-Medium, Netzteilwahl, Headless-Setup und erster Start: [`setup-provisioning.md`](setup-provisioning.md).

---

## Raspberry Pi 5

### Kernspezifikationen

| Komponente | Spezifikation |
|------------|---------------|
| **SoC** | Broadcom BCM2712 (16nm) |
| **CPU** | 4× Arm Cortex-A76 @ 2.4 GHz, 64-bit, mit Cryptographic Extension |
| **Cache** | 512 KB L2 pro Kern, 2 MB gemeinsamer L3 |
| **GPU** | VideoCore VII, **12 Kerne**, 3D-Einheit @ **960 MHz**, OpenGL ES 3.1, **Vulkan 1.3** |
| **Video** | Dual 4Kp60 HDMI mit HDR, 4Kp60 HEVC-Decoder |
| **RAM** | 1, 2, 4, 8 **oder 16 GB** LPDDR4X-4267 |
| **I/O-Controller** | RP1 (separater Chip, via chipinternem PCIe 2.0 **x4**) |
| **PCIe** | 1× PCIe **2.0** x1 (via FFC) – Gen 3 nur inoffiziell, siehe unten |
| **USB** | 2× USB 3.0 (gleichzeitig 5 Gbps), 2× USB 2.0 |
| **Kamera/Display** | 2× 4-Lane MIPI-Transceiver @ 1.5 Gbps/Lane, beliebige Kombination aus bis zu 2 Kameras oder Displays |
| **Speicherkarte** | microSD mit SDR104-Highspeed-Modus |
| **Netzwerk** | Gigabit Ethernet mit PoE+ (separater PoE+ HAT nötig), Dual-Band 802.11ac WLAN, Bluetooth 5.0/BLE |
| **Sonstiges** | Echtzeituhr (RTC, externe Batterie), Power-Button, 40-Pin-Header |

> ℹ️ **Die GPU hat mehr als einen Takt** – daher kursieren drei verschiedene Zahlen:
>
> | Block | Takt | Parameter |
> |---|---|---|
> | **3D-Einheit (V3D)** | **960 MHz** | `v3d_freq` |
> | Core, ISP, HEVC | 910 MHz | `core_freq`, `isp_freq`, `hevc_freq` |
>
> Für den Leistungsvergleich zählt die **3D-Einheit: 960 MHz gegen 500 MHz** beim Pi 4 –
> zusammen mit der breiteren Hardware ergibt das rund **2- bis 2,5-fache Grafikleistung**.
> Die für Pi 500/500+ genannten «910 MHz» sind der Core-Takt, nicht die 3D-Einheit. Der
> ebenfalls kursierende Wert **800 MHz entspricht keiner dokumentierten Voreinstellung**.

> ℹ️ **Verfügbarkeit als Planungsgrösse:** Raspberry Pi hat die Produktion des Pi 5 und der
> KI-Erweiterungen **bis mindestens Januar 2030** zugesagt. Für Projekte mit langer
> Laufzeit oder Nachbeschaffung ist das ein belastbarer Anker – anders als bei den meisten
> Einplatinenrechnern.
>
> Ebenfalls vertraglich abgesichert: Die kommerzielle Raspberry Pi Ltd. ist gegenüber der
> Foundation verpflichtet, weiterhin Low-Cost-Computer anzubieten – seit Februar 2024 mit
> einer festgeschriebenen Obergrenze von **45 USD** für das Basismodell.
| **Stromversorgung** | 5V/5A via USB-C mit Power Delivery |
| **TDP** | ~12W (Peak: ~27W mit Peripherie) |
| **Betriebstemperatur** | **0 °C bis 70 °C** (Umgebung) |
| **MTBF** | 93 800 h (Ground Benign) |
| **Produktionszusage** | mindestens bis Januar 2036 |

**Abmessungen:** 85 × 56 mm, Bohrbild 58 × 49 mm (Ø 2,7 mm).
Buchsen ragen 3 mm über die 85-mm-Kante → realer Platzbedarf 88 mm.
Details, Steckerpositionen und Gehäuse-Checkliste: [`mechanical.md`](mechanical.md).

### Kritische Unterschiede zu Pi 4

**RP1 I/O-Controller:**
- Separater Chip für alle Peripherie (GPIO, I2C, SPI, UART, PWM, USB, MIPI, Ethernet)
- Angebunden über chipinternes **PCIe 2.0 x4** – nicht zu verwechseln mit dem externen
  PCIe-Stecker (x1) für M.2 HAT+
- Erfordert Kernel 6.6+ und angepasste Treiber
- `RPi.GPIO` ist **inkompatibel** → Verwende `gpiozero` mit lgpio
- **Jeder GPIO-Zugriff läuft über PCIe (~1 µs Latenz).** Software-getaktete Protokolle
  (Bit-Banging) verhalten sich deshalb anders als auf dem Pi 4 → [`rp1-gpio.md`](rp1-gpio.md)

**Mini-CSI-Anschlüsse:**
- 22-Pin-Stecker (schmal), nicht 15-Pin wie Pi 4
- Kamera Module 1/2 benötigen Adapter-Kabel
- Camera Module 3 hat natives Mini-CSI-Kabel
- Beide Anschlüsse sind **kombinierte MIPI-Transceiver**: jeder kann eine Kamera *oder*
  ein Display bedienen (max. 2 Geräte insgesamt) – auf Pi 4 waren CSI und DSI getrennt

**PCIe:**
- Offiziell spezifiziert ist **PCIe 2.0 x1** (5 GT/s) – so steht es im Product Brief
- Gen 3 (8 GT/s) ist ein **Opt-in ausserhalb der Spezifikation**: `dtparam=pciex1_gen=3`
  in `config.txt`. Raspberry Pi gibt dafür keine Signalintegritäts-Garantie.
- Praxis: Hailo-8L und NVMe SSDs profitieren spürbar, laufen aber auch auf Gen 2.
- ➜ **Regel:** Bei instabilem PCIe-Gerät immer zuerst auf Gen 2 zurückstellen, bevor
  Treiber oder Hardware verdächtigt werden.

**USB-Bandbreite:**
- Pi 5: Beide USB-3.0-Ports können **gleichzeitig** mit 5 Gbps arbeiten
- Pi 4: Die USB-3.0-Ports teilen sich die Bandbreite
- ➜ Zwei schnelle USB-Geräte (UAS-SSD + Kamera) sind erst auf Pi 5 sinnvoll

**Stromversorgung:**
- USB-C **mit Power Delivery** erforderlich (nicht nur USB-C)
- 27W offizielles Netzteil empfohlen
- Unterspannungserkennung strenger (mehr false positives)

**Neu gegenüber Pi 4:**
- **Echtzeituhr (RTC)** mit Anschluss für eine externe Batterie – Zeitstempel bleiben ohne
  Netz und ohne NTP korrekt (relevant für Datenlogger und Feldprojekte)
- **Power-Button** für sauberes Herunter- und Hochfahren
- **PoE+** (nicht nur PoE) über separaten PoE+ HAT
- microSD im **SDR104**-Modus (doppelte Spitzenrate gegenüber Pi 4)

### GPIO-Besonderheiten Pi 5

```
RP1-Pad-Grenzwerte (Quelle: RP1 Peripherals, RP-008370-DS-1):
- Treiberstrom: 2 / 4 / 8 / 12 mA wählbar -> Maximum 12 mA
  (der Pi 4 schafft nur 8 mA, Pi 1/2/3/Zero dagegen 16 mA)
- Voreinstellung: 4 mA
- Schmitt-Trigger am Eingang: per Reset aktiv
- Slew-Rate-Begrenzung: per Reset langsam
- Pull-Up / Pull-Down / Bus-Keeper / hochohmig waehlbar
- ESD: 4 kV HBM, 500 V CDM, 200 V MM
- 28 GPIO (0-27) in einer einzigen Bank (VDDIO0), Timings bei 3,3 V spezifiziert
- Ein Summenstrom pro Bank ist im Datenblatt NICHT angegeben
```

⚠️ **Der oft zitierte Wert «16 mA pro Pin» stammt vom Pi 3 und älter – nicht vom Pi 4.**
Der Pi 4 liefert maximal 8 mA, der Pi 5 also **mehr** als der Pi 4, nicht weniger.
Vollständige Tabelle über alle Generationen, Spannungspegel, Latenz-Verhalten und
Peripherie-Übersicht: [`rp1-gpio.md`](rp1-gpio.md).

---

## Raspberry Pi 4

### Kernspezifikationen

| Komponente | Spezifikation |
|------------|---------------|
| **SoC** | Broadcom BCM2711 (28nm) |
| **CPU** | 4× Arm Cortex-A72 @ **1,5 GHz** (1,8 GHz ab Rev. 1.4 mit `arm_boost=1`) |
| **Cache** | 32 kB Daten + 48 kB Instruktionen L1 je Kern, **1 MB gemeinsamer L2** |
| **GPU** | VideoCore VI @ 500 MHz |
| **RAM** | 1, 2, 4 oder 8 GB LPDDR4-3200¹ |
| **Video** | H.265 4Kp60 dekodieren, H.264 1080p60 dekodieren / 1080p30 kodieren |
| **USB** | 2× USB 3.0, 2× USB 2.0 |
| **Kamera/Display** | SoC bietet **je 2× CSI und DSI – am Pi 4B ist je einer herausgeführt** |
| **Stromversorgung** | 5V/3A via USB-C |
| **TDP** | ~6.4W (Peak: ~15W mit Peripherie) |

¹ Das Prozessordatenblatt des BCM2711 nennt **LPDDR4-2400**, die Voreinstellung
`sdram_freq` auf dem Pi 4B steht auf **3200** (siehe `config-txt.md`). Ab dem Pi 4 lässt
sich der SDRAM ohnehin nicht mehr übertakten – für die Praxis ist der Wert also keine
Stellgrösse.

> ⚠️ **Die 1,8 GHz sind nicht der Grundtakt.** Der BCM2711 ist für **bis zu 1,5 GHz**
> spezifiziert; die 1,8 GHz erreichen erst Boards ab Revision 1.4 mit `arm_boost=1`.
> **CM4 und CM4S bleiben bei 1,5 GHz** (siehe `compute-module.md`) – wer Laufzeiten
> zwischen Pi 4B und CM4 überträgt, liegt um rund 17 % daneben.

### GPIO-Besonderheiten Pi 4

```
BCM2711 SoC Limitationen:
- Max. 8 mA pro Pin (Voreinstellung 4 mA)
  Der BCM2711 halbiert alle Stufen des DRIVE-Feldes: was das Register
  als 16 mA beschriftet, liefert real 8 mA.
- Pull-Up/Pull-Down: 33-73 kOhm (nicht 50-65 wie beim Pi 3)
- Eingangspegel: High erst ab 2,0 V (Pi 3: ab 1,6 V)
- Gesamt-Budget: ~50 mA ueber alle Pins zusammen
```

---

## GPIO-Pinout

### 40-Pin-Header (identisch Pi 4 & 5)

```
     3.3V  1 ●  ● 2   5V
   GPIO 2  3 ●  ● 4   5V
   GPIO 3  5 ●  ● 6   GND
   GPIO 4  7 ●  ● 8   GPIO 14 (UART TX)
      GND  9 ●  ● 10  GPIO 15 (UART RX)
  GPIO 17 11 ●  ● 12  GPIO 18 (PWM0)
  GPIO 27 13 ●  ● 14  GND
  GPIO 22 15 ●  ● 16  GPIO 23
     3.3V 17 ●  ● 18  GPIO 24
  GPIO 10 19 ●  ● 20  GND
   GPIO 9 21 ●  ● 22  GPIO 25
  GPIO 11 23 ●  ● 24  GPIO 8 (SPI CE0)
      GND 25 ●  ● 26  GPIO 7 (SPI CE1)
   GPIO 0 27 ●  ● 28  GPIO 1
   GPIO 5 29 ●  ● 30  GND
   GPIO 6 31 ●  ● 32  GPIO 12 (PWM0)
  GPIO 13 33 ●  ● 34  GND
  GPIO 19 35 ●  ● 36  GPIO 16
  GPIO 26 37 ●  ● 38  GPIO 20 (PWM1)
      GND 39 ●  ● 40  GPIO 21 (PWM1)
```

### Spezialfunktionen

Die folgenden Zuordnungen sind die **Standardbelegung**. Der Pi 5 bietet über die
Alternativfunktionen des RP1 deutlich mehr Instanzen, als hier aufgeführt sind:

| Funktion | Pi 4 (üblich genutzt) | **Pi 5 / RP1 am Header verfügbar** |
|----------|----------------------|-------------------------------------|
| UART | 2 | **5** |
| SPI | 2 | **6** |
| I2C | 2 | **4** |
| I2S | 1 | **2** |
| PWM | 2 Kanäle | **4 Kanäle** |
| PIO | – | **vorhanden** (wie RP2040) |

➜ Bei I2C-Adresskonflikten oder zu wenigen Chip-Selects lohnt auf dem Pi 5 der Blick in
die Alternativfunktionen statt der Griff zum Multiplexer. Tabelle und Regeln:
[`rp1-gpio.md`](rp1-gpio.md).

**I2C:**
- I2C1: GPIO 2 (SDA), GPIO 3 (SCL) – Standard für HATs
- I2C0: GPIO 0 (SDA), GPIO 1 (SCL) – Reserviert für EEPROM

**SPI:**
- SPI0: GPIO 9 (MISO), GPIO 10 (MOSI), GPIO 11 (SCLK), GPIO 8 (CE0), GPIO 7 (CE1)
- SPI1: GPIO 19 (MISO), GPIO 20 (MOSI), GPIO 21 (SCLK), GPIO 18/17/16 (CE0–CE2)
- Pi 4 zusätzlich **SPI3–SPI6** über Alternativfunktionen – Pinbelegung und
  Überschneidungen in [`interfaces.md`](interfaces.md#spi)

**UART:**
- UART0: GPIO 14 (TX), GPIO 15 (RX) – Standard Serial Console
- UART1: GPIO 14 (TX alt), GPIO 15 (RX alt) – via ALT5

**PWM (Hardware):**
- PWM0: GPIO 12, GPIO 18 (Channel A)
- PWM1: GPIO 13, GPIO 19 (Channel B)
- PWM0: GPIO 32, GPIO 52 (Channel A, nur Pi 5)
- PWM1: GPIO 33, GPIO 53 (Channel B, nur Pi 5)

---

## Strombudgets

### Raspberry Pi 5

**Netzteil-Anforderungen:**
- Offiziell: 27W USB-C PD (5.1V/5A)
- Minimum: 15W (für Idle-Betrieb ohne Peripherie)
- Empfohlen: 27W für alle Szenarien

⚠️ **Am Pi 5 mit 5 V / 3 A wird die Peripherieversorgung auf 600 mA begrenzt.**
Das Board läuft, aber USB-SSDs, Kameras und Hubs fallen aus, ohne dass Unterspannung
gemeldet wird. Ein 15-W-Netzteil vom Pi 4 ist damit kein vollwertiger Ersatz.

⚠️ **Die Spannungsangaben gelten am Stecker, nicht am Netzteil.** Spannungsabfall im
Kabel einrechnen – ein dünnes oder langes USB-C-Kabel ist eine häufige Fehlerquelle.

Netzteiltabelle für alle Modelle: [`setup-provisioning.md`](setup-provisioning.md).

**Leistungsaufnahme (typisch):**

| Szenario | Leistung |
|----------|----------|
| Idle (Desktop) | 3.7W |
| 4K60 Video | 5.0W |
| CPU Sysbench (1 Thread) | 6.5W |
| CPU Sysbench (4 Threads) | 9.0W |
| **Mit Hailo-8L NPU** | +6W (Total: ~15W) |
| **Mit NVMe SSD** | +2.5W |
| **Mit Active Cooler** | +0.6W |

**Peripherie-Budget:**
- USB (gesamt): Max. 1.6A @ 5V (aufgeteilt auf 4 Ports)
- GPIO 3.3V Pin: Max. 500mA (shared mit SoC)
- GPIO 5V Pin: Direkt vom Netzteil (aber PSU-Limit beachten!)

### Raspberry Pi 4

**Netzteil-Anforderungen:**
- Offiziell: 15W USB-C (5V/3A)
- Minimum: 2.5A für stabile Operation

**Leistungsaufnahme (typisch):**

| Szenario | Leistung |
|----------|----------|
| Idle (Desktop) | 2.7W |
| 4K60 Video | 3.4W |
| CPU Stress | 6.4W |

**Peripherie-Budget:**
- USB (gesamt): Max. 1.2A @ 5V
- GPIO 3.3V Pin: Max. 500mA
- GPIO 5V Pin: Max. PSU-Capacity - Pi-Consumption

### Strombudget-Rechnung (Beispiel)

**Projekt:** Pi 5 + Hailo NPU + Camera Module 3 + USB-Mikrofon

```
Komponente              | Leistung
------------------------|----------
Raspberry Pi 5 (Idle)   | 3.7W
Hailo-8L (Inference)    | 6.0W
Camera Module 3         | 0.8W
USB-Mikrofon            | 0.5W
Active Cooler           | 0.6W
------------------------|----------
TOTAL                   | 11.6W
------------------------|----------
PSU Required (80% Rule) | 14.5W minimum
Empfehlung              | 27W USB-C PD
```

---

## Thermisches Management

### Raspberry Pi 5

**Zulässige Umgebungstemperatur (Product Brief): 0 °C bis 70 °C**

⚠️ Nicht verwechseln: Die folgenden Werte sind **SoC-Temperaturen** (`vcgencmd measure_temp`),
die 0–70 °C oben sind die **Umgebungstemperatur**. Beide Grenzen gelten gleichzeitig.
Ein Gehäuse in der Sonne oder ein Schaltschrank ohne Belüftung kann die Umgebungsgrenze
verletzen, lange bevor der SoC auffällig wird.

**Temperatur-Limits (SoC):**

| Bereich | Verhalten |
|---------|-----------|
| Idle | 30–45 °C (Richtwert bei Raumtemperatur) |
| Last ohne Kühlung | 60–80 °C (Richtwert) |
| **80–85 °C** | **Die Arm-Kerne werden gedrosselt** |
| **> 85 °C** | **Arm-Kerne *und* GPU werden gedrosselt** |

⚠️ **Eine Abschalttemperatur nennt die offizielle Dokumentation nicht.** Sie beschreibt
ausschliesslich die beiden Drosselschwellen 80 °C und 85 °C. Kursierende Werte wie
«95 °C Emergency Shutdown» sind nicht belegt – für die Auslegung zählen die 80/85 °C, und
das Erreichen dieser Grenze **schadet dem SoC nicht**, es kostet Leistung.

➜ Wie viel Leistung, steht in `edge-ai.md`: gemessene **19 % Einbruch** nach etwa
120 Sekunden CPU-Volllast.

> 🔴 **`0x50000` heisst nicht «Unterspannung jetzt».** Es sind die Bits 16 und 18 – also
> *aufgetreten seit dem Booten*: Unterspannung **und** Drosselung. Im Moment der Messung
> ist alles in Ordnung. Wer nur auf die oberen Bits schaut, jagt einem Fehler nach, der
> gerade nicht vorliegt; wer nur auf die unteren schaut, übersieht ihn ganz.
> Vollständige Bit-Tabelle in `os-and-software.md`.

**Kühlungs-Empfehlungen:**

| Szenario | Kühlung |
|----------|---------|
| Idle/Office | Passiv-Kühlkörper (optional) |
| Media Center | Passiv-Kühlkörper |
| **Edge AI / NPU** | **Active Cooler (obligatorisch!)** |
| Overclocking | Active Cooler + Case-Lüfter |

**Lüfterkurve des Pi 5** (Firmware-gesteuert, gilt für alle offiziellen Lüfter):

| Temperatur | Drehzahl |
|------------|----------|
| < 50 °C | **0 %** – der Lüfter steht still |
| ab 50 °C | 30 % |
| ab 60 °C | 50 % |
| ab 67,5 °C | 70 % |
| ab 75 °C | **100 %** |

Beim Abkühlen gelten dieselben Schwellen mit **5 °C Hysterese** – der Lüfter fällt erst
5 °C unterhalb der jeweiligen Schwelle wieder zurück. Das verhindert Pumpen um einen
Schwellwert herum.

➜ **Ein stillstehender Lüfter unter 50 °C ist kein Defekt**, sondern die Voreinstellung.
Wer prüfen will, ob der Lüfter überhaupt läuft, muss das Board erst über 50 °C bringen.
Die Schwellen sind über `dtparam=fan_temp0=55000` (Wert in Milligrad) und die
Parameter `fan_tempN_hyst` / `fan_tempN_speed` verschiebbar.

**Lüfteranschluss (JST-SH, 1 mm Raster, 4-polig)** – zwischen GPIO-Leiste und USB-2.0-Ports:

| Pin | Funktion | Aderfarbe |
|-----|----------|-----------|
| 1 | +5 V | rot |
| 2 | PWM | blau |
| 3 | GND | schwarz |
| 4 | Tacho | gelb |

⚠️ **Der Lüfteranschluss zieht aus demselben Budget wie die USB-Peripherie.** An einem
3-A-Netzteil teilt sich der Lüfter also die 600 mA mit allem, was an USB hängt. Beim Booten
prüft die Firmware über den Tacho-Eingang, ob sich der Lüfter dreht, und aktiviert nur dann
das `cooling_fan`-Overlay – ein Lüfter ohne Tacho-Leitung wird deshalb nicht geregelt.

**Thermal Monitoring:**
```bash
# Temperatur überwachen
vcgencmd measure_temp

# Throttling-Status prüfen
vcgencmd get_throttled
# 0x0 = OK
# Untere 4 Bits = Zustand JETZT, obere 4 Bits (ab 0x10000) = seit dem Booten aufgetreten
#   0x1 Unterspannung jetzt      | 0x10000 Unterspannung aufgetreten
#   0x2 Frequenz jetzt begrenzt  | 0x20000 Begrenzung aufgetreten
#   0x4 jetzt gedrosselt         | 0x40000 Drosselung aufgetreten
#   0x8 Soft-Temp jetzt aktiv    | 0x80000 Soft-Temp war aktiv
```

### Raspberry Pi 4

**Temperatur-Limits:** dieselben Drosselschwellen wie beim Pi 5 – **80 °C** (Arm-Kerne),
**> 85 °C** (Arm-Kerne und GPU). Idle 35–50 °C, unter Last ohne Kühlung 60–85 °C.

> ℹ️ Beim **Pi 3A+ und 3B+** kommt eine zusätzliche weiche Grenze dazu: ab **60 °C**
> (einstellbar über `temp_soft_limit`, max. 70) wird von 1400 auf 1200 MHz zurückgetaktet,
> um die Zeit bis zur harten Grenze zu verlängern (siehe `config-txt.md`).

**Kühlungs-Empfehlungen:**
- Passiv-Kühlkörper für meiste Anwendungen ausreichend
- Active Cooler bei sustained CPU-Load (24/7 Server)

---

## Schnittstellen

### Kamera

**Pi 5:**
- 2× Mini-CSI/DSI (22-Pin, schmal), je 4 Lanes @ 1.5 Gbps
- Jeder Anschluss ist Kamera **oder** Display → bis zu 2 Kameras, 2 Displays oder je eines
- Gesamtbandbreite gegenüber Pi 4 verdreifacht
- Kompatibel: Camera Module 3, HQ Camera (mit Adapter)

**Pi 4:**
- 1× Standard-CSI (15-Pin, breit)
- Kompatibel: Camera Module 1, 2, HQ Camera

**Test:**
```bash
rpicam-hello --list-cameras
rpicam-still -o test.jpg
```

### USB

**Pi 5:**
- 2× USB 3.0 (5 Gbps)
- 2× USB 2.0 (480 Mbps)
- Max. 1.6A gesamt

**Pi 4:**
- 2× USB 3.0 (5 Gbps)
- 2× USB 2.0 (480 Mbps)
- Max. 1.2A gesamt

### HDMI

**Pi 5:**
- 2× Micro-HDMI 2.0
- Dual 4K@60 oder Single 4K@120

**Pi 4:**
- 2× Micro-HDMI 2.0
- Dual 4K@60

### Ethernet

**Beide:**
- Gigabit Ethernet (1000 Mbps)
- PoE-fähig (mit PoE HAT)

### PCIe (nur Pi 5)

- **Spezifiziert:** 1× PCIe 2.0 x1 (5 GT/s) via 16-Pin-FFC (0,5 mm Raster) und M.2 HAT+
- **Inoffiziell:** Gen 3 (8 GT/s) per Opt-in in `config.txt`. Das Steckerdokument sagt
  dazu wörtlich: *«Signals can be run at Gen 3 speeds, but this is not officially supported.»*
- **5 V am Stecker:** Pins 1 und 2, je 500 mA – zusammen **1 A (5 W)**
- **FFC:** max. **50 mm**, 90 Ω ± 10 % impedanzkontrolliert, Typ **opposite-sides-contact**

⚠️ Ein FFC mit gleichseitigen Kontakten ist nicht umkehrbar und **kurzschliesst falsch
herum eingesteckt den Pi und/oder die Zusatzplatine**. Pinout, Sideband-Signale,
Power States und M.2 HAT+: [`pcie.md`](pcie.md).

**Aktivierung Gen 3 (auf eigenes Risiko):**
```bash
# /boot/firmware/config.txt
dtparam=pciex1_gen=3
```

**Rollback bei Instabilität** (Link-Fehler, Gerät verschwindet, `dmesg`-AER-Meldungen):
Zeile auskommentieren oder entfernen, neu starten – das Gerät läuft dann mit Gen 2.

---

## Die Prozessoren im Überblick

Welcher SoC in welchem Modell steckt – nützlich, wenn eine Anleitung oder ein Datenblatt
nur den Chip nennt.

| SoC | Modelle | CPU | GPU | Status |
|-----|---------|-----|-----|--------|
| **BCM2712** | Pi 5, 500, 500+, CM5 | 4× A76 @ 2,4 GHz | VideoCore VII, V3D 960 MHz | aktuell |
| **BCM2711** | Pi 4B, 400, CM4, CM4S | 4× A72 @ 1,5 GHz | VideoCore VI @ 500 MHz | aktuell |
| **RP3A0** | **Pi Zero 2 W** | 4× A53 @ **1 GHz** | VideoCore IV @ 400 MHz | aktuell |
| BCM2837B0 | Pi 3A+, 3B+, spätere 3B und 2B, CM3+ | 4× A53 @ bis 1,4 GHz | VideoCore IV @ 400 MHz | aktuell |
| BCM2837 | frühe 3B, manche 2B, CM3 | 4× A53 @ 1,2 GHz | VideoCore IV @ 400 MHz | 🔴 abgekündigt |
| BCM2836 | frühe Pi 2B | 4× Cortex-A7 | VideoCore IV | 🔴 abgekündigt |
| BCM2835 | Pi 1 (alle), Zero, Zero W, CM1 | 1× ARM1176JZF-S @ 700 MHz | VideoCore IV | aktuell |

**Was die Generationen praktisch unterscheidet:**

- **BCM2837B0 gegen BCM2837:** identische Kern-Hardware, nur höher eingestuft – 1,4 statt
  1,2 GHz, rund **17 % schneller**. Der sichtbare Unterschied ist der **Wärmeverteiler
  auf dem Gehäuse**, der die höheren Takte und eine genauere Temperaturmessung erst
  ermöglicht.
- **BCM2711 gegen BCM2837B0:** rund **50 % schneller**, dazu erstmals PCIe (daran hängen
  USB 3.0 und Ethernet), mehr adressierbarer Speicher und ein deutlich stärkerer Grafikteil.
- **BCM2712 gegen BCM2711:** in Summe **2- bis 3-fache Leistung** bei CPU- und
  E/A-lastigen Aufgaben, Grafik 2- bis 2,5-fach.

> ℹ️ **Der RP3A0 im Zero 2 W ist ein System-in-Package:** der nackte BCM2710A1-Die – also
> dasselbe Silizium wie im BCM2837 des Pi 3 – zusammen mit **512 MB DRAM** in einem
> Gehäuse. Er läuft mit **1 GHz**; mit Kühlkörper sind bis zu 1,2 GHz erreichbar.
>
> Der **ursprüngliche Zero** ist anders aufgebaut: Dort sitzt der DRAM als
> Package-on-Package direkt **auf** dem BCM2835.

### Videobeschleunigung: was der Pi 5 nicht mehr in Hardware kann

| Codec | Pi 4 (BCM2711) | **Pi 5 (BCM2712)** |
|-------|----------------|--------------------|
| H.265 / HEVC dekodieren | 4Kp60 | **4Kp60** |
| H.264 dekodieren | 1080p60 | 🔴 **nur Software** |
| H.264 kodieren | 1080p30 | 🔴 **nur Software** |

🔴 **Der Pi 5 hat keinen H.264-Hardware-Codec mehr.** Was das kostet:

| Aufgabe | CPU-Last |
|---------|----------|
| H.264 1080p24 dekodieren | ~10–20 % |
| H.264 1080p60 dekodieren | **~50–60 %** |
| H.264 1080p30 kodieren (aus dem ISP) | ~30–40 % |

➜ **Für Kameraprojekte ist das die wichtigste Einzelinformation dieses Abschnitts.** Ein
Pi 5, der einen H.264-Stream mit 1080p60 aufnimmt oder wiedergibt, verbraucht dafür
**gut die Hälfte einer CPU** – Leistung, die dann für Inferenz fehlt. Wo möglich **HEVC
verwenden** (bleibt in Hardware) oder auf 1080p30 heruntergehen. Der Pi 4 erledigt
H.264 nebenbei, der Pi 5 nicht.

### Bekannte Sicherheitslücken

Der Cortex-A76 des BCM2712 ist von Spectre- und verwandten Lücken betroffen; unter
Raspberry Pi OS sind **alle Gegenmassnahmen aktiv**. Prüfen lässt sich das so:

```bash
lscpu | grep Vulnerability | grep -v "Not affected"
```

Was übrig bleibt, ist die Liste der Lücken, für die eine Massnahme greift – typischerweise
Spec store bypass, Spectre v1 und Spectre v2.

> ⚠️ **Bei Fremdbetriebssystemen selbst nachsehen.** Die Arm-Kerne von Raspberry Pi
> verwenden **keinen Microcode** – sämtliche Gegenmassnahmen stecken im Kernel. Ein
> Drittanbieter-Image mit altem Kernel ist damit tatsächlich ungeschützt, und `lscpu` gibt
> nur wieder, was der **laufende Kernel** erkennt, nicht den wahren Zustand der Hardware.

---

## Keyboard-Computer: Pi 400, 500 und 500+

Vollständige Rechner im Tastaturgehäuse, mit demselben SoC wie die entsprechenden
Einplatinenrechner. Für Klassensätze und Arbeitsplätze relevant, weil Gehäuse, Kühlung und
Tastatur wegfallen.

| | **Pi 400** | **Pi 500** | **Pi 500+** |
|---|---|---|---|
| Basis | Pi 4 (4 GB) | Pi 5 (8 GB) | Pi 5 (16 GB) |
| Erschienen | 2020 | 2024 | 2025 |
| SoC | BCM2711 | BCM2712 + RP1 | BCM2712 + RP1 |
| CPU | A72 @ 1,8 GHz | A76 @ 2,4 GHz | A76 @ 2,4 GHz |
| GPU | VideoCore VI @ 500 MHz | VideoCore VII @ 910 MHz | VideoCore VII @ 910 MHz |
| RAM | 4 GB | 8 GB | **16 GB** |
| HDR über HDMI | ❌ | ✅ | ✅ |
| Speicher | microSD | microSD | microSD **+ 256 GB M.2 SSD** |
| Tasten | 78/79/83 Folientasten | 78/79/83 Folientasten | **84/85/88 mechanische Tasten** |
| Beleuchtung | – | – | **RGB je Taste** |
| Ein/Aus | **Fn + F10** | eigene Taste | eigene Taste |
| Netzteil | 5 V / 3 A (15 W) | 5 V / 5 A (25 W) | 5 V / 5 A (25 W) |
| Masse | 286 × 122 × 23 mm | 286 × 122 × 23 mm | **312 × 123 × 35 mm** |

**Was für alle drei gilt:**

- **Nur drei USB-Ports** – 2× USB 3.0 und 1× USB 2.0. Ein Einplatinenrechner hat vier.
  Die Maus gehört an den weissen USB-2.0-Port, damit die schnellen Ports frei bleiben.
- **Waagerechte 40-Pin-Leiste**, Gigabit-Ethernet, Dual-Band-WLAN und BLE
- **Passiver Alu-Kühlkörper**, kein Lüfter
- **Kein Composite-Ausgang** (siehe `config-txt.md`)

> 🔴 **Der Pi 400 hat keine Ein-/Aus-Taste.** Er wird über **Fn + F10** ein- und
> ausgeschaltet. Wer danach am Gehäuse sucht, sucht vergeblich.

### Der M.2-Steckplatz des Pi 500+ ist grosszügiger als der M.2 HAT+

| | M.2 HAT+ am Pi 5 | **Pi 500+ intern** |
|---|---|---|
| Formfaktoren | 2230, 2242 | **2230, 2242, 2260, 2280** |

➜ **Im Pi 500+ passen auch die langen 2280-Module** – also die gängigste und preislich
günstigste Bauform. Am Pi 5 mit M.2 HAT+ ist bei 2242 Schluss. Der Steckplatz nimmt zudem
andere PCIe-Peripherie auf, nicht nur SSDs.

Der Tausch ist vorgesehen: Fünf Kreuzschrauben am Boden, Gehäuse mit dem beiliegenden
Spudger an der Vorderkante auftrennen, Oberteil **umklappen statt abheben** (Flachbandkabel!),
Schraube rechts neben dem Modul lösen – die SSD springt hoch. Das neue Modul passt nur in
einer Ausrichtung.

### Kompatibilität der Tastenkappen (Pi 500+)

Gateron KS-33 mit **Cherry-MX-kompatiblem Kreuzstamm** – die meisten Fremdhersteller-Sets
passen also mechanisch. Vier Einschränkungen:

- **DSA oder Cherry** wählen. **XDA, OEM und SA sind zu hoch**, machen mehr Lärm und können
  am Rahmen anstossen.
- Die LEDs beleuchten die **obere Hälfte** der Kappe – **vollständig opake Kappen
  schlucken das Licht**.
- Das Layout ist ein **modifiziertes 75 %**: Power-Taste, SysRq, Ins sowie die Beschriftungen
  auf F4/F5/F6 und F10/F11/F12 sind nicht standardisiert und fehlen in üblichen Sets.
- Die **Cmd-Taste** heisst in Fremdsets `Win`, das Raspberry-Pi-Logo gibt es dort nicht.

---

## Modell zuverlässig erkennen

Für Skripte, die sich je nach Board anders verhalten müssen, gibt es zwei Wege – einen
robusten und einen, der regelmässig bricht.

### Der robuste Weg: Device Tree

```bash
cat /proc/device-tree/compatible | tr '\0' '\n'
# raspberrypi,5-model-b
# brcm,bcm2712
```

Funktioniert auf **jeder** Linux-Distribution, nicht nur unter Raspberry Pi OS, und liefert
Hersteller und Modell getrennt. Auswahl der Werte:

| Gerät | Modell-String | SoC |
|-------|---------------|-----|
| Raspberry Pi 5 | `5-model-b` | `bcm2712` |
| Raspberry Pi 500 / 500+ | `500` | `bcm2712` |
| Compute Module 5 | `5-compute-module` | `bcm2712` |
| Raspberry Pi 4B | `4-model-b` | `bcm2711` |
| Raspberry Pi 400 | `400` | `bcm2711` |
| Raspberry Pi Zero 2 W | `model-zero-2-w` | `bcm2837` |
| Raspberry Pi 3B+ | `3-model-b-plus` | `bcm2837` |

### Der Revisionscode

```bash
cat /proc/cpuinfo | grep Revision
# Revision : c03111
```

🔴 **`/proc/cpuinfo` meldet bei *jedem* Pi `Hardware: BCM2835`** – auch auf BCM2711 und
BCM2712. Dieses Feld ist zur SoC-Erkennung unbrauchbar.

Der Code ist ein Bitfeld, kein fortlaufender Zähler. Die drei praktisch wichtigen Felder:

| Bits | Feld | Bedeutung |
|------|------|-----------|
| 0–3 | Revision | 0, 1, 2 … |
| 4–11 | **Modelltyp** | `0x11` = 4B, `0x17` = 5, `0x13` = 400, `0x19` = 500/500+, `0x12` = Zero 2 W |
| 12–15 | Prozessor | 0 = BCM2835, 1 = 2836, 2 = 2837, 3 = **2711**, 4 = **2712** |
| 20–22 | **RAM** | 0 = 256 MB, 1 = 512 MB, 2 = 1 GB, 3 = 2 GB, 4 = 4 GB, 5 = 8 GB, 6 = 16 GB |
| 23 | Neues Format | muss **1** sein, bevor die anderen Felder gelten |
| 25 | Garantie-Bit | durch Übertakten gesetzt (am Pi 4 nie gesetzt) |

```python
import subprocess
code = int(subprocess.check_output(
    "awk '/Revision/ {print $3}' /proc/cpuinfo", shell=True), 16)

neu   = (code >> 23) & 0x1      # zuerst prüfen!
modell= (code >> 4)  & 0xff
ram   = (code >> 20) & 0x7

if neu and modell == 0x17 and ram >= 4:
    print("Pi 5 mit mindestens 4 GB")
```

> 🔴 **Nie gegen eine Liste bekannter Revisionscodes prüfen.** Genau das ist der häufigste
> Fehler: Sobald eine neue Board-Revision erscheint oder die Fertigung den Standort
> wechselt, entsteht ein neuer Code – und das Skript lehnt ein Board ab, das voll
> kompatibel ist. Jede neue Revision erzwingt dann ein Update der Liste.
>
> Stattdessen **nach Modelltyp oder RAM-Grösse filtern** («Pi 5 mit ≥ 4 GB»), wie im
> Beispiel oben. Und immer zuerst Bit 23 prüfen: Bei einem alten Code (Pi 1, Codes `0002`
> bis `0015`) haben die übrigen Felder eine völlig andere Bedeutung.

---

## Modellwahl & Beschaffung

### RAM-Varianten Pi 5 (offizielle Listenpreise, USD)

| Variante | Listenpreis | Sinnvoll für |
|----------|-------------|--------------|
| 1 GB | k. A. | existiert (Rev. 1.1, Code `a04171`), im Handel praktisch nicht erhältlich |
| 2 GB | $50 | Headless-Sensorik, einzelne Dienste, klassische GPIO-Projekte |
| 4 GB | $60 | Desktop, Computer Vision mit Hailo-8L |
| 8 GB | $80 | Ollama bis ~4B, mehrere AI-Prozesse parallel |
| **16 GB** | $120 | Ollama mit 7B/8B-Modellen, Vision + LLM gleichzeitig |

Die 1-GB-Variante ist eine Industrie-Variante und im Handel kaum zu bekommen; praktisch
beginnt die Auswahl bei 2 GB, darunter ist der Pi Zero 2 W ($15) die realistische Klasse.
Schweizer Endkundenpreise liegen über den USD-Listenpreisen (MwSt., Zoll, Marge) – siehe
[`component-catalog.md`](component-catalog.md).

**Faustregeln:**
- **Hailo-8L / Computer Vision:** 4 GB genügen, das Modell liegt auf der NPU.
- **Ollama:** 8 GB ist das praktikable Minimum, 16 GB öffnet die 7B/8B-Klasse.
- **Vision + LLM gleichzeitig:** 16 GB, sonst wird geswappt und die Latenz bricht ein.
- **Bildung / Klassensatz:** 2 GB oder 4 GB – günstiger und für Lehrprojekte ausreichend.

### Langlebigkeit

| Kennzahl | Wert | Bedeutung für Projekte |
|----------|------|------------------------|
| MTBF (Ground Benign) | 93 800 h ≈ 10,7 Jahre | Dauerbetrieb ist plausibel, Backup-Strategie trotzdem nötig |
| Produktionszusage | mindestens bis Januar 2036 | Ersatzteil- und Nachbeschaffungssicherheit für Schulen und Verwaltung |

**Konformität:** Alle lokalen und regionalen Produktzulassungen sind unter
[pip.raspberrypi.com](https://pip.raspberrypi.com) dokumentiert – relevant für Beschaffungen
und für Projekte, die den Pi in ein eigenes Produkt integrieren.

---

## Wichtige Sicherheitshinweise

### Elektrische Grenzen

⚠️ **Kritisch:**
- GPIO sind **nicht 5V-tolerant**
- Max. Treiberstrom pro Pin: **Pi 1/2/3/Zero 16 mA**, **Pi 5 (RP1) 12 mA**,
  **Pi 4 (BCM2711) nur 8 mA** – der Pi 5 ist hier stärker als der Pi 4
- Summenstrom: **~50 mA über alle Pins**, Auslegung der 3,3-V-Schiene ~3 mA pro Pin
  im Dauerbetrieb; für den Pi 5 nennt das Datenblatt keinen Bankwert → konservativ
  rechnen und Lasten nicht aus GPIO speisen
- Induktive Lasten **immer** via Transistor/Relais

### Unterspannung

⚠️ **Lightning Bolt = PSU Problem:**
- Führt zu SD-Karten-Korruption
- Instabiles Verhalten (Crashes, Freezes)
- Lösung: Besseres Netzteil (27W für Pi 5)

### Überhitzung

⚠️ **Thermometer-Symbol = Throttling:**
- CPU-Takt wird reduziert
- Performance drastisch schlechter
- Lösung: Active Cooler montieren

### Offizielle Betriebs- und Handhabungshinweise

Aus dem Product Brief – gelten unabhängig vom Projekt:

- Betrieb nur in **gut belüfteter Umgebung**; ein verwendetes Gehäuse darf **nicht
  abgedeckt** werden.
- Im Betrieb sicher befestigen oder auf eine **stabile, ebene, nicht leitfähige**
  Unterlage legen.
- Keine Feuchtigkeit, keine externe Wärmequelle, kühl und trocken lagern.
- Platine im Betrieb nicht berühren bzw. nur an den Kanten anfassen (**ESD**).
- Inkompatible Peripherie kann Konformität und Garantie kosten; Peripherie muss den
  Normen des Einsatzlandes entsprechen.

➜ Vollständig samt mechanischer Konsequenzen in [`mechanical.md`](mechanical.md).

---

## Weitere Ressourcen

- [Raspberry Pi 5 Product Brief](https://datasheets.raspberrypi.com/rpi5/raspberry-pi-5-product-brief.pdf)
- [Raspberry Pi 5 Mechanical Drawing](https://datasheets.raspberrypi.com/rpi5/raspberry-pi-5-mechanical-drawing.pdf)
- [Raspberry Pi 4 Datasheet](https://datasheets.raspberrypi.com/rpi4/raspberry-pi-4-datasheet.pdf)
- [Produktzulassungen (PIP)](https://pip.raspberrypi.com)
- [GPIO Pinout (interaktiv)](https://pinout.xyz/)
- [Official Documentation](https://www.raspberrypi.com/documentation/)
