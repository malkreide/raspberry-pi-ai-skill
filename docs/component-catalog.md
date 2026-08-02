# Komponenten-Katalog

Empfohlene Komponenten für Raspberry Pi Projekte mit Bezugsquellen (Schweiz/Europa).

## Inhaltsverzeichnis
1. [Grundausstattung](#grundausstattung)
2. [Sensoren](#sensoren)
3. [Aktoren](#aktoren)
4. [Kameras](#kameras)
5. [Audio](#audio)
6. [Edge AI Hardware](#edge-ai-hardware)
7. [Stromversorgung](#stromversorgung)
8. [Werkzeug & Zubehör](#werkzeug--zubehör)
9. [Projekt-spezifische Kits](#projekt-spezifische-kits)
10. [Mechanik & Gehäusebau](#mechanik--gehäusebau)

---

## Grundausstattung

### Raspberry Pi

| Komponente | Spezifikation | Listenpreis (USD) | Preis (CHF) | Bezugsquelle |
|------------|---------------|-------------------|-------------|--------------|
| **Raspberry Pi 5 (16 GB)** | BCM2712, 4× A76 @ 2.4 GHz | $305 | ~250 | [pi-shop.ch](https://www.pi-shop.ch/), [pi3g.com](https://pi3g.com/) |
| **Raspberry Pi 5 (8 GB)** | BCM2712, 4× A76 @ 2.4 GHz | $175 | ~120 | [pi-shop.ch](https://www.pi-shop.ch/), [pi3g.com](https://pi3g.com/) |
| **Raspberry Pi 5 (4 GB)** | BCM2712, 4× A76 @ 2.4 GHz | $110 | ~90 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Raspberry Pi 5 (2 GB) | BCM2712, 4× A76 @ 2.4 GHz | $65 | ~55 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Raspberry Pi 5 (1 GB) | BCM2712, 4× A76 @ 2.4 GHz | $45 | ~40 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Raspberry Pi 4 (8 GB) | BCM2711, 4× A72 @ 1.8 GHz | – | ~100 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Raspberry Pi 4 (4 GB) | BCM2711, 4× A72 @ 1.8 GHz | – | ~70 | [pi-shop.ch](https://www.pi-shop.ch/) |

Listenpreise aus dem Raspberry Pi 5 Product Brief (RP-008348-DS, April 2026); CHF-Werte
sind Richtwerte für den Schweizer Endkundenhandel.

**Empfehlung:**
- **Edge AI / Computer Vision:** Pi 5 4GB oder 8GB + Hailo-8L (das Modell liegt auf der NPU)
- **Ollama / LLM:** Pi 5 8GB als Minimum, **16GB für 7B/8B-Modelle**
- **Vision + LLM gleichzeitig:** Pi 5 16GB
- **Allgemein / Prototyping:** Pi 5 4GB oder Pi 4 4GB
- **Klassensatz / Bildung:** Pi 5 2GB – deutlich günstiger, für Lehrprojekte ausreichend

**Beschaffungsargumente (aus dem Product Brief):**
- Produktion zugesichert **bis mindestens Januar 2036**
- MTBF 93 800 h (Ground Benign)
- Zulassungen dokumentiert unter [pip.raspberrypi.com](https://pip.raspberrypi.com)

### Gehäuse & Kühlung

| Komponente | Spezifikation | Preis (CHF) | Bezugsquelle |
|------------|---------------|-------------|--------------|
| **Official Active Cooler (Pi 5)** | PWM-Lüfter, ~0.6W | ~8 | [pi-shop.ch](https://www.pi-shop.ch/) |
| **Official Raspberry Pi Case (Pi 5)** | 98.5 × 70.3 × 33 mm, Aktivlüfter 8000 U/min, ABS/PC | ~12 | [pi-shop.ch](https://www.pi-shop.ch/) |
| **Official Pi 5 Bumper** | Aufsteckbare Schutzhülle, 89.6 × 60.6 × 10 mm ($3 Listenpreis) | ~5 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Argon NEO 5 Case | Passiv-Kühlung, Alu | ~30 | [argon40.com](https://argon40.com/) |
| Pimoroni Heatsink Case | Passiv-Kühlung, Low-Profile | ~25 | [pimoroni.com](https://shop.pimoroni.com/) |
| Flirc Raspberry Pi 5 Case | Passiv-Kühlung, Alu | ~35 | [flirc.tv](https://flirc.tv/) |

**Empfehlung:**
- **Hailo-8L / sustained loads:** Official Active Cooler (obligatorisch)
- **Idle / Media Center:** Flirc Case oder Argon NEO 5
- **Offene Aufbauten / Unterricht:** Bumper – isoliert die Lötseite gegen leitfähige
  Tischoberflächen (offizielle Sicherheitsanforderung)
- **Geschlossener Aufbau mit Kühlung:** Official Case – bringt Kühlkörper (12 × 17 × 4 mm)
  und temperaturgeregelten Lüfter mit, Deckel abnehmbar für GPIO-Kabel, stapelbar

⚠️ **Official Case und HATs:** HATs lassen sich nur mit **Abstandshaltern und
GPIO-Header-Verlängerungen** montieren – beides ist **nicht im Lieferumfang**. Für M.2 auf
das offizielle Gehäuse ist der **M.2 HAT+ Compact** vorgesehen (nur 2230).

⚠️ **Bumper und Kühlgehäuse schliessen sich aus.** Der Bumper vergrössert den Fussabdruck
auf **89,6 × 60,6 mm** bei **10 mm** Nennhöhe. Alu-Kühlgehäuse setzen dagegen auf der
nackten Platine auf. Die Befestigungsbohrungen bleiben unter dem Bumper zugänglich, die
Stapelhöhe ändert sich aber. Masse, Materialfrage und CAD-Daten:
[`mechanical.md`](mechanical.md).

ℹ️ **Vor dem Einsetzen die SD-Karte entfernen** (offizielle Warnung im Product Brief).

### Zubehör Stromversorgung & Zeit

| Komponente | Spezifikation | Preis (CHF) | Bezugsquelle |
|------------|---------------|-------------|--------------|
| **RTC-Batterie (Pi 5)** | Lithium-Zelle mit 2-Pin-Stecker | ~7 | [pi-shop.ch](https://www.pi-shop.ch/) |
| PoE+ HAT (Pi 5) | 802.3at, mit Lüfter | ~25 | [pi-shop.ch](https://www.pi-shop.ch/) |

**Wann sinnvoll:**
- **RTC-Batterie:** Datenlogger und Feldprojekte ohne Netzwerk – ohne sie sind alle
  Zeitstempel nach einem Stromausfall falsch, bis NTP erreichbar ist.
- **PoE+ HAT:** Ein Kabel für Strom und Daten. Der Pi 5 verlangt **PoE+** (802.3at),
  ein reiner PoE-Injektor (802.3af) reicht nicht.

### Speicher

| Komponente | Spezifikation | Preis (CHF) | Bezugsquelle |
|------------|---------------|-------------|--------------|
| **SanDisk Extreme 64 GB** | UHS-I, A2, 160 MB/s | ~15 | [digitec.ch](https://www.digitec.ch/), [galaxus.ch](https://www.galaxus.ch/) |
| Samsung EVO Plus 128 GB | UHS-I, U3, 130 MB/s | ~20 | [digitec.ch](https://www.digitec.ch/) |
| Kingston Canvas Go! Plus 64 GB | UHS-I, V30, 170 MB/s | ~12 | [digitec.ch](https://www.digitec.ch/) |
| **NVMe SSD (Pi 5 nur)** | M.2 2230/2242 via HAT+ | ~50-100 | [digitec.ch](https://www.digitec.ch/) |

**Empfehlung:**
- **Minimum:** SanDisk Extreme 64 GB (A2-Rating wichtig!)
- **Ollama / grosse Modelle:** 128 GB oder NVMe SSD
- **Vermeiden:** No-Name SD-Karten (Korruptions-Risiko)

**Offizielle Mindestgrössen nach OS-Variante:**

| OS | Minimum |
|----|---------|
| Raspberry Pi OS (Desktop) | 32 GB |
| Raspberry Pi OS Full | 32 GB |
| **Raspberry Pi OS Lite** (Headless) | **8 GB** |

Für Edge AI grosszügiger rechnen – Ollama-Modelle und HEF-Dateien füllen 32 GB schnell.

⚠️ **Karten über 2 TB werden nicht unterstützt** (Beschränkung des Master Boot Record).
Ältere Geräte (Pi Zero, erster Flagship-Pi, frühe Pi 2 mit BCM2836) booten nur von einer
Boot-Partition ≤ 256 GB. Details: [`setup-provisioning.md`](setup-provisioning.md).

---

## Sensoren

### Temperatur & Luftfeuchtigkeit

| Komponente | Schnittstelle | Messbereich | Preis (CHF) | Bezugsquelle |
|------------|---------------|-------------|-------------|--------------|
| **DHT22 (AM2302)** | 1-Wire | -40 bis +80°C, 0-100% RH | ~8 | [pi-shop.ch](https://www.pi-shop.ch/), [reichelt.com](https://www.reichelt.com/) |
| BME280 | I2C/SPI | -40 bis +85°C, 0-100% RH, Druck | ~15 | [adafruit.com](https://www.adafruit.com/), [pimoroni.com](https://shop.pimoroni.com/) |
| SHT31 | I2C | -40 bis +125°C, 0-100% RH | ~12 | [adafruit.com](https://www.adafruit.com/) |
| DS18B20 | 1-Wire | -55 bis +125°C (wasserdicht) | ~5 | [pi-shop.ch](https://www.pi-shop.ch/) |

**Empfehlung:**
- **Basis-Projekte:** DHT22 (günstig, einfach)
- **Präzision:** BME280 (zusätzlich Luftdruck)
- **Wasserdicht:** DS18B20

**Beispiel-Code (BME280):**
```python
from smbus2 import SMBus
from bme280 import BME280

bus = SMBus(1)
bme280 = BME280(i2c_dev=bus)

temp = bme280.get_temperature()
humidity = bme280.get_humidity()
pressure = bme280.get_pressure()
```

### Distanz & Bewegung

| Komponente | Typ | Reichweite | Preis (CHF) | Bezugsquelle |
|------------|-----|------------|-------------|--------------|
| **HC-SR04** | Ultraschall | 2 cm – 4 m | ~3 | [pi-shop.ch](https://www.pi-shop.ch/), [reichelt.com](https://www.reichelt.com/) |
| VL53L0X | Time-of-Flight | 30 mm – 2 m | ~15 | [adafruit.com](https://www.adafruit.com/), [pololu.com](https://www.pololu.com/) |
| PIR HC-SR501 | Passiv-Infrarot | 3-7 m | ~5 | [pi-shop.ch](https://www.pi-shop.ch/) |
| MPU6050 | IMU (6-Achsen) | Accel + Gyro | ~8 | [adafruit.com](https://www.adafruit.com/) |

**Empfehlung:**
- **Robotik:** HC-SR04 (günstig, robust)
- **Präzision:** VL53L0X (ToF, besser in hellem Licht)
- **Bewegungsmelder:** PIR HC-SR501

### Licht & Farbe

| Komponente | Typ | Auflösung | Preis (CHF) | Bezugsquelle |
|------------|-----|-----------|-------------|--------------|
| **BH1750** | Lux-Sensor | 1-65535 lux | ~5 | [adafruit.com](https://www.adafruit.com/) |
| TSL2561 | Lux-Sensor | 0.1-40000 lux | ~8 | [adafruit.com](https://www.adafruit.com/) |
| TCS34725 | RGB-Farb-Sensor | I2C | ~10 | [adafruit.com](https://www.adafruit.com/) |

---

## Aktoren

### Motoren & Servos

| Komponente | Typ | Spezifikation | Preis (CHF) | Bezugsquelle |
|------------|-----|---------------|-------------|--------------|
| **SG90 Micro Servo** | Servo | 0-180°, 1.2 kg·cm | ~5 | [pi-shop.ch](https://www.pi-shop.ch/), [reichelt.com](https://www.reichelt.com/) |
| MG996R Servo | Servo | 0-180°, 11 kg·cm | ~12 | [pi-shop.ch](https://www.pi-shop.ch/) |
| 28BYJ-48 Stepper | Schrittmotor | 5V, ULN2003 Driver | ~8 | [pi-shop.ch](https://www.pi-shop.ch/) |
| **L298N Motor Driver** | DC-Motor H-Bridge | 2× Motoren, bis 2A | ~10 | [pi-shop.ch](https://www.pi-shop.ch/) |
| DRV8833 | DC-Motor H-Bridge | 2× Motoren, bis 1.5A | ~8 | [adafruit.com](https://www.adafruit.com/) |

**Wichtig:**
- ⚠️ **Niemals Motoren direkt an GPIO anschliessen** (Strom-Limit!)
- Verwende H-Bridge oder Transistor
- Freilaufdioden bei induktiven Lasten

**Beispiel (SG90 Servo):**
```python
from gpiozero import Servo
from time import sleep

servo = Servo(17)

servo.min()   # 0°
sleep(1)
servo.mid()   # 90°
sleep(1)
servo.max()   # 180°
```

### LEDs & Displays

| Komponente | Typ | Spezifikation | Preis (CHF) | Bezugsquelle |
|------------|-----|---------------|-------------|--------------|
| **WS2812B LED Strip** | Adressierbar | 30/60/144 LEDs/m, 5V | ~15-30/m | [adafruit.com](https://www.adafruit.com/), [pimoroni.com](https://shop.pimoroni.com/) |
| SSD1306 OLED | Display | 128×64, I2C | ~12 | [adafruit.com](https://www.adafruit.com/) |
| LCD 16×2 | Zeichen-Display | I2C-Backpack | ~10 | [pi-shop.ch](https://www.pi-shop.ch/) |
| 7-Segment Display | TM1637 | 4-stellig, I2C | ~5 | [reichelt.com](https://www.reichelt.com/) |

### Relais & Schalter

| Komponente | Typ | Spezifikation | Preis (CHF) | Bezugsquelle |
|------------|-----|---------------|-------------|--------------|
| **5V Relais-Modul** | 1-4 Kanal | 10A @ 250V AC | ~5-15 | [pi-shop.ch](https://www.pi-shop.ch/), [reichelt.com](https://www.reichelt.com/) |
| SSR-25 DA | Solid State Relay | 25A @ 240V AC | ~10 | [reichelt.com](https://www.reichelt.com/) |
| Taster-Kit | Buttons | Verschiedene Farben | ~5 | [pi-shop.ch](https://www.pi-shop.ch/) |

---

## Kameras

### Raspberry Pi Kameras

| Komponente | Sensor | Auflösung | FOV | Preis (CHF) | Bezugsquelle |
|------------|--------|-----------|-----|-------------|--------------|
| **Camera Module 3** | Sony IMX708 | 12 MP, 1080p60 | 75° | ~40 | [pi-shop.ch](https://www.pi-shop.ch/), [pimoroni.com](https://shop.pimoroni.com/) |
| Camera Module 3 Wide | Sony IMX708 | 12 MP, 1080p60 | 120° | ~50 | [pi-shop.ch](https://www.pi-shop.ch/) |
| HQ Camera | Sony IMX477 | 12.3 MP, C/CS-Mount | var. | ~70 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Camera Module 2 | Sony IMX219 | 8 MP, 1080p30 | 62° | ~30 | [pi-shop.ch](https://www.pi-shop.ch/) |

**Pi 5 Wichtig:**
- ✅ Camera Module 3: Natives Mini-CSI-Kabel (22-Pin)
- ⚠️ Camera Module 1/2: Benötigen Adapter-Kabel (15-Pin → 22-Pin)

**Empfehlung:**
- **Allgemein:** Camera Module 3 (beste Preis/Leistung)
- **Weitwinkel:** Camera Module 3 Wide (Robotik, Überwachung)
- **Wechselobjektive:** HQ Camera + C-Mount Objektive

### USB-Kameras

| Komponente | Auflösung | Framerate | Preis (CHF) | Bezugsquelle |
|------------|-----------|-----------|-------------|--------------|
| Logitech C270 | 720p | 30 fps | ~30 | [digitec.ch](https://www.digitec.ch/) |
| **Logitech C920** | 1080p | 30 fps | ~80 | [digitec.ch](https://www.digitec.ch/) |
| Arducam B0196 (IMX219) | 8 MP | 1080p30 | ~40 | [arducam.com](https://www.arducam.com/) |

**Empfehlung:**
- USB-Kameras nur wenn CSI nicht möglich (z.B. mehrere Kameras auf Pi 4)
- Verbrauchen mehr USB-Bandbreite und Strom

---

## Audio

### Mikrofone

| Komponente | Typ | Schnittstelle | Preis (CHF) | Bezugsquelle |
|------------|-----|---------------|-------------|--------------|
| **USB Mikrofon (Lavalier)** | Klinke → USB | USB 2.0 | ~20 | [digitec.ch](https://www.digitec.ch/) |
| Adafruit I2S MEMS Mic | SPH0645LM4H | I2S | ~10 | [adafruit.com](https://www.adafruit.com/) |
| ReSpeaker 2-Mic HAT | Dual MEMS | I2S + GPIO | ~25 | [seeedstudio.com](https://www.seeedstudio.com/) |
| Blue Snowball USB | Kondensator | USB | ~80 | [digitec.ch](https://www.digitec.ch/) |

**Empfehlung:**
- **Einfach:** USB-Mikrofon (Plug-and-Play)
- **Voice Recognition:** ReSpeaker 2-Mic HAT (Array, Noise Cancellation)
- **Studio-Qualität:** Blue Snowball

**Wichtig (Pi 5 + HAT Stacking):**
- M.2 HAT+ blockiert GPIO → USB-Mikrofon bevorzugen bei Hailo-Projekten

### Lautsprecher & Audio-Ausgabe

| Komponente | Typ | Leistung | Preis (CHF) | Bezugsquelle |
|------------|-----|----------|-------------|--------------|
| **Mini-Lautsprecher** | 3W, 8Ω | 3W | ~5 | [adafruit.com](https://www.adafruit.com/) |
| Adafruit I2S Amp | MAX98357A | 3W, I2S | ~12 | [adafruit.com](https://www.adafruit.com/) |
| HiFiBerry DAC+ | Audio HAT | Line-Out | ~40 | [hifiberry.com](https://www.hifiberry.com/) |
| USB-Soundkarte | 3.5mm Jack | USB 2.0 | ~15 | [digitec.ch](https://www.digitec.ch/) |

⚠️ **Der Pi 5 hat keinen 3,5-mm-Klinkenanschluss** – anders als Pi 1 bis 4. Audio läuft
über USB, I2S oder HDMI. Der TRRS-Anschluss der älteren Modelle liefert zudem nur
Line-Pegel, keinen Lautsprecherpegel.

---

## Edge AI Hardware

### NPU / AI Accelerators

| Komponente | Performance | Interface | Preis (CHF) | Bezugsquelle |
|------------|-------------|-----------|-------------|--------------|
| **AI HAT+ 13 TOPS** | 13 TOPS (**Hailo-8L**) | PCIe (Pi 5), Chip aufgelötet | ~70 | [pi-shop.ch](https://www.pi-shop.ch/), [raspberrypi.com](https://www.raspberrypi.com/) |
| **AI HAT+ 26 TOPS** | 26 TOPS (**Hailo-8**) | PCIe (Pi 5), Chip aufgelötet | ~110 | [raspberrypi.com](https://www.raspberrypi.com/) |
| **AI HAT+ 2** | GenAI-fähig (**Hailo-10H**) | PCIe (Pi 5) | – | [raspberrypi.com](https://www.raspberrypi.com/) |
| **AI Camera** (IMX500) | Inferenz **im Kameramodul** | CSI – **belegt kein PCIe** | ~70 | [raspberrypi.com](https://www.raspberrypi.com/) |
| ~~Raspberry Pi AI Kit~~ | 13 TOPS (Hailo-8L, M.2-Modul) | PCIe (Pi 5) | ~70 | 🔴 **Nicht mehr in Produktion** |
| Coral USB Accelerator | 4 TOPS | USB 3.0 | ~80 | [coral.ai](https://coral.ai/), [mouser.com](https://www.mouser.com/) |

> ⚠️ **13 TOPS = Hailo-8L, 26 TOPS = Hailo-8.** Beide werden als «AI HAT+» verkauft und
> unterscheiden sich im Namen nur durch die TOPS-Zahl.

**Empfehlung:**
- **Ein Modell, Einstieg, Bildung:** AI HAT+ 13 TOPS (Hailo-8L)
- **Mehrere Modelle parallel:** AI HAT+ 26 TOPS (Hailo-8)
- **Zusätzlich Sprachmodelle auf der NPU:** AI HAT+ 2 (Hailo-10H)
- **PCIe wird für NVMe gebraucht:** **AI Camera** – die Inferenz läuft im Kameramodul
- **Pi 4 (kein PCIe):** Coral USB Accelerator

**Wichtig:**
- Hailo nur auf Pi 5 (PCIe erforderlich)
- Active Cooler obligatorisch bei Hailo

### M.2-Adapter (Pi 5)

| Komponente | Listenpreis | Formfaktoren | Gedacht für | Bezugsquelle |
|------------|-------------|--------------|-------------|--------------|
| **M.2 HAT+ Standard** | $12 | **2230 und 2242** | Pi 5 mit Active Cooler (16-mm-Stacking-Header liegt bei) | [pi-shop.ch](https://www.pi-shop.ch/) |
| M.2 HAT+ Compact | $15 | **nur 2230** | Offizielles Raspberry Pi Case (lässt den Gehäuselüfter frei) | [pi-shop.ch](https://www.pi-shop.ch/) |

Beide: PCIe 2.0 x1 bis 500 MB/s, bis 3 A ans M.2-Gerät, Power- und Aktivitäts-LED,
HAT+-konform und automatisch erkannt, Produktion bis mindestens Januar 2032.

**Die Wahl ist eine Gehäusefrage, keine Leistungsfrage:** Standard nehmen, ausser das
offizielle Gehäuse ist gesetzt – dann Compact, aber nur mit 2230-Modulen.

⚠️ **Betriebstemperatur 0–50 °C** – niedriger als die 0–70 °C des Pi 5. Für den Stapel
gilt die niedrigere Grenze. Details: [`pcie.md`](pcie.md).

⚠️ **Kein FFC-Kabel improvisieren.** Max. 50 mm, impedanzkontrolliert, Typ
opposite-sides-contact. Ein gleichseitiges Kabel falsch herum eingesteckt zerstört
Hardware. Das beiliegende Kabel verwenden.

### Kameras für AI

| Komponente | Sensor | Besonderheit | Preis (CHF) | Bezugsquelle |
|------------|--------|--------------|-------------|--------------|
| **Camera Module 3** | Sony IMX708 | Autofokus, HDR | ~40 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Camera Module 3 NoIR | Sony IMX708 | Infrarot (Nachtsicht) | ~45 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Arducam Hawk-Eye 64MP | OV64A40 | 64 MP, 4K60 | ~90 | [arducam.com](https://www.arducam.com/) |

---

## Stromversorgung

### Netzteile

| Komponente | Leistung | Anschluss | Preis (CHF) | Bezugsquelle |
|------------|----------|-----------|-------------|--------------|
| **Official Pi 5 PSU** | 27W (5.1V/5A) | USB-C PD | ~15 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Official Pi 4 PSU | 15W (5.1V/3A) | USB-C | ~12 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Anker PowerPort Atom PD1 | 30W USB-C PD | USB-C | ~35 | [digitec.ch](https://www.digitec.ch/) |
| CanaKit 3.5A PSU | 15W (5V/3A) | Micro-USB (Pi 3) | ~10 | [amazon.de](https://www.amazon.de/) |

**Wichtig:**
- ⚠️ **Pi 5 benötigt USB-C PD** (nicht nur USB-C!)
- Unterdimensionierte Netzteile führen zu Instabilität
- Bei Hailo-8L: 27W Netzteil obligatorisch

### Batterien & Akkus

| Komponente | Kapazität | Ausgabe | Preis (CHF) | Bezugsquelle |
|------------|-----------|---------|-------------|--------------|
| **PiJuice HAT** | LiPo 12000 mAh | 5V/2.5A | ~80 | [pi-shop.ch](https://www.pi-shop.ch/) |
| Anker PowerCore 20000 | 20000 mAh | USB-A/C | ~60 | [digitec.ch](https://www.digitec.ch/) |
| Voltaic V88 | 24000 mAh | USB-C PD | ~150 | [voltaicsystems.com](https://www.voltaicsystems.com/) |

**Empfehlung:**
- **Mobile Projekte:** PiJuice HAT (UPS-Funktion)
- **Feldarbeit:** Voltaic V88 (Solar-kompatibel)

---

## Werkzeug & Zubehör

### Breadboards & Jumper Wires

| Komponente | Spezifikation | Preis (CHF) | Bezugsquelle |
|------------|---------------|-------------|--------------|
| **830-Point Breadboard** | Lötfrei, 830 Kontakte | ~5 | [pi-shop.ch](https://www.pi-shop.ch/), [reichelt.com](https://www.reichelt.com/) |
| Jumper Wire Kit | M-M, M-F, F-F | ~8 | [pi-shop.ch](https://www.pi-shop.ch/) |
| GPIO Extension Board | 40-Pin T-Cobbler | ~10 | [adafruit.com](https://www.adafruit.com/) |

### Widerstände & Elektronik

| Komponente | Werte | Preis (CHF) | Bezugsquelle |
|------------|-------|-------------|--------------|
| **Widerstands-Kit** | 600 Stk., 1Ω-1MΩ | ~10 | [reichelt.com](https://www.reichelt.com/) |
| LED-Kit | 100 Stk., 5mm, div. Farben | ~8 | [reichelt.com](https://www.reichelt.com/) |
| Kondensatoren-Kit | 120 Stk., Keramik/Elektrolyt | ~12 | [reichelt.com](https://www.reichelt.com/) |

### Mess- & Lötgeräte

| Komponente | Spezifikation | Preis (CHF) | Bezugsquelle |
|------------|---------------|-------------|--------------|
| **Multimeter (Digital)** | UNI-T UT33D | ~25 | [digitec.ch](https://www.digitec.ch/) |
| Lötstation | Regelbar, 60W | ~50 | [digitec.ch](https://www.digitec.ch/) |
| Logic Analyzer | 8-Kanal USB | ~30 | [amazon.de](https://www.amazon.de/) |

---

## Bezugsquellen-Übersicht

### Schweiz
- **[pi-shop.ch](https://www.pi-shop.ch/)** – Offizieller Schweizer Pi-Distributor
- **[digitec.ch](https://www.digitec.ch/)** – Grösster CH-Elektronik-Händler
- **[galaxus.ch](https://www.galaxus.ch/)** – Digitec-Schwester (gleiche Preise)

### Europa
- **[reichelt.com](https://www.reichelt.com/)** – DE, grosse Auswahl Elektronik
- **[pi3g.com](https://pi3g.com/)** – DE, Raspberry Pi Spezialist
- **[berrybase.de](https://www.berrybase.de/)** – DE, Raspberry Pi & Zubehör

### International
- **[adafruit.com](https://www.adafruit.com/)** – US, beste Tutorials
- **[pimoroni.com](https://shop.pimoroni.com/)** – UK, kreative HATs
- **[sparkfun.com](https://www.sparkfun.com/)** – US, Entwicklerboards
- **[seeedstudio.com](https://www.seeedstudio.com/)** – CN, günstige Sensoren

**Versandkosten beachten:** Innerhalb CH meist gratis ab ~50 CHF. Aus EU: Zoll ab ~65 CHF.

---

## Projekt-spezifische Kits

### KI-Kamera-Projekt
- Raspberry Pi 5 (8 GB)
- AI Kit (Hailo-8L)
- Camera Module 3
- Active Cooler
- 27W USB-C PD PSU
- 64 GB SD-Karte

**Total: ~270 CHF**

### Ollama-Chatbot
- Raspberry Pi 5 (8 GB)
- USB-Mikrofon
- Mini-Lautsprecher + I2S Amp
- Active Cooler
- 128 GB SD-Karte

**Total: ~180 CHF**

### Ollama-Chatbot XL (7B/8B-Modelle)
- Raspberry Pi 5 (**16 GB**)
- NVMe SSD 256 GB + M.2 HAT+ (Modellablage, schnelleres Laden)
- USB-Mikrofon
- Mini-Lautsprecher + I2S Amp
- Active Cooler
- 27W USB-C PD PSU

**Total: ~400 CHF**

> Hinweis: M.2 HAT+ und Hailo-8L belegen denselben PCIe-Anschluss – entweder NVMe **oder**
> NPU, nicht beides.

### Wetterstation
- Raspberry Pi 4 (4 GB)
- BME280 (Temp/Humidity/Pressure)
- BH1750 (Lux)
- SSD1306 OLED Display
- Passiv-Kühlung

**Total: ~120 CHF**

⚠️ **Aussenaufstellung:** Der Pi 5 ist für **0 °C bis 70 °C Umgebungstemperatur**
spezifiziert. Für den Winterbetrieb draussen entweder beheiztes Gehäuse, Innenaufstellung
mit Aussensensor oder ein Mikrocontroller (Pico W, ESP32) als Aussenknoten einplanen.

---

## Mechanik & Gehäusebau

Masse, Bohrbild, Steckerpositionen, Bumper-Geometrie und die Checkliste für Gehäuse- und
3D-Druck-Konstruktion stehen in [`mechanical.md`](mechanical.md).

Kurzfassung für die Beschaffung von Halterungen:

| Grösse | Wert |
|--------|------|
| Platine | 85 × 56 mm |
| Realer Platzbedarf (Buchsenüberstand 3 mm) | 88 × 56 mm |
| Mit offiziellem Bumper | 89,6 × 60,6 × 10 mm |
| Bohrbild | 58 × 49 mm, Ø 2,7 mm, M2.5 |
| Bauhöhe der nackten Platine | ~19 mm (CAD-Anhaltswert) |

Raspberry Pi stellt ein **MIT-lizenziertes STEP-Modell des Boards** bereit – für
Passformprüfungen die beste Quelle. Für bemasste Ausschnitte gilt weiterhin die
Zeichnung: Modell und Zeichnung widersprechen sich bei den Micro-HDMI-Positionen.
