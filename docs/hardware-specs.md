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

---

## Raspberry Pi 5

### Kernspezifikationen

| Komponente | Spezifikation |
|------------|---------------|
| **SoC** | Broadcom BCM2712 (16nm) |
| **CPU** | 4× Arm Cortex-A76 @ 2.4 GHz, 64-bit, mit Cryptographic Extension |
| **Cache** | 512 KB L2 pro Kern, 2 MB gemeinsamer L3 |
| **GPU** | VideoCore VII @ 800 MHz, OpenGL ES 3.1, Vulkan 1.2 |
| **Video** | Dual 4Kp60 HDMI mit HDR, 4Kp60 HEVC-Decoder |
| **RAM** | 1, 2, 4, 8 **oder 16 GB** LPDDR4X-4267 |
| **I/O-Controller** | RP1 (separater Chip, via chipinternem PCIe 2.0 **x4**) |
| **PCIe** | 1× PCIe **2.0** x1 (via FFC) – Gen 3 nur inoffiziell, siehe unten |
| **USB** | 2× USB 3.0 (gleichzeitig 5 Gbps), 2× USB 2.0 |
| **Kamera/Display** | 2× 4-Lane MIPI-Transceiver @ 1.5 Gbps/Lane, beliebige Kombination aus bis zu 2 Kameras oder Displays |
| **Speicherkarte** | microSD mit SDR104-Highspeed-Modus |
| **Netzwerk** | Gigabit Ethernet mit PoE+ (separater PoE+ HAT nötig), Dual-Band 802.11ac WLAN, Bluetooth 5.0/BLE |
| **Sonstiges** | Echtzeituhr (RTC, externe Batterie), Power-Button, 40-Pin-Header |
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
  (NICHT 16 mA wie auf Pi 4 - Pi-4-Anleitungen sind hier nicht uebertragbar)
- Voreinstellung: 4 mA
- Schmitt-Trigger am Eingang: per Reset aktiv
- Slew-Rate-Begrenzung: per Reset langsam
- Pull-Up / Pull-Down / Bus-Keeper / hochohmig waehlbar
- ESD: 4 kV HBM, 500 V CDM, 200 V MM
- 28 GPIO (0-27) in einer einzigen Bank (VDDIO0), Timings bei 3,3 V spezifiziert
- Ein Summenstrom pro Bank ist im Datenblatt NICHT angegeben
```

⚠️ **Der oft zitierte Wert «16 mA pro Pin» stammt vom Pi 4 und gilt auf dem Pi 5 nicht.**
Details, Latenz-Verhalten und die vollständige Peripherie-Übersicht: [`rp1-gpio.md`](rp1-gpio.md).

---

## Raspberry Pi 4

### Kernspezifikationen

| Komponente | Spezifikation |
|------------|---------------|
| **SoC** | Broadcom BCM2711 (28nm) |
| **CPU** | 4× Arm Cortex-A72 @ 1.8 GHz |
| **GPU** | VideoCore VI @ 500 MHz |
| **RAM** | 1GB, 2GB, 4GB oder 8GB LPDDR4-3200 |
| **USB** | 2× USB 3.0, 2× USB 2.0 |
| **Stromversorgung** | 5V/3A via USB-C |
| **TDP** | ~6.4W (Peak: ~15W mit Peripherie) |

### GPIO-Besonderheiten Pi 4

```
BCM2711 SoC Limitationen:
- Max. 16 mA pro Pin
- Pull-Up/Pull-Down: 50-65 kΩ
- Gesamt-Budget: ~50 mA pro Bank (GPIOs 0-27, 28-45)
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
- SPI1: GPIO 19 (MISO), GPIO 20 (MOSI), GPIO 21 (SCLK)

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
- **Idle:** 30–45°C (Raumtemperatur)
- **Load:** 60–80°C (ohne Kühlung)
- **Throttling Start:** 80°C (Soft Limit)
- **Throttling Aggressiv:** 85°C (Hard Limit)
- **Shutdown:** 95°C (Emergency)

**Kühlungs-Empfehlungen:**

| Szenario | Kühlung |
|----------|---------|
| Idle/Office | Passiv-Kühlkörper (optional) |
| Media Center | Passiv-Kühlkörper |
| **Edge AI / NPU** | **Active Cooler (obligatorisch!)** |
| Overclocking | Active Cooler + Case-Lüfter |

**Thermal Monitoring:**
```bash
# Temperatur überwachen
vcgencmd measure_temp

# Throttling-Status prüfen
vcgencmd get_throttled
# 0x0 = OK
# 0x50000 = Undervoltage detected
# 0x80000 = Soft temperature limit active
```

### Raspberry Pi 4

**Temperatur-Limits:**
- **Idle:** 35–50°C
- **Load:** 60–85°C (ohne Kühlung)
- **Throttling Start:** 80°C
- **Shutdown:** 85°C

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

## Modellwahl & Beschaffung

### RAM-Varianten Pi 5 (Listenpreise Product Brief, USD)

| Variante | Listenpreis | Sinnvoll für |
|----------|-------------|--------------|
| 1 GB | $45 | Headless-Sensorik, einzelne Dienste |
| 2 GB | $65 | Headless mit Kamera, klassische GPIO-Projekte |
| 4 GB | $110 | Desktop, Computer Vision mit Hailo-8L |
| 8 GB | $175 | Ollama bis ~4B, mehrere AI-Prozesse parallel |
| **16 GB** | $305 | Ollama mit 7B/8B-Modellen, Vision + LLM gleichzeitig |

Schweizer Endkundenpreise liegen darüber – siehe [`component-catalog.md`](component-catalog.md).

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
- Max. Treiberstrom pro Pin: **Pi 5 (RP1) 12 mA**, Pi 4 (BCM2711) 16 mA
- Bank-Summenstrom: Pi 4 ~50 mA; für Pi 5 **im Datenblatt nicht angegeben** → konservativ
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
