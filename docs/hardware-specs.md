# Hardware-Spezifikationen – Raspberry Pi 4 & 5

## Inhaltsverzeichnis
1. [Raspberry Pi 5](#raspberry-pi-5)
2. [Raspberry Pi 4](#raspberry-pi-4)
3. [GPIO-Pinout](#gpio-pinout)
4. [Strombudgets](#strombudgets)
5. [Thermisches Management](#thermisches-management)
6. [Schnittstellen](#schnittstellen)

---

## Raspberry Pi 5

### Kernspezifikationen

| Komponente | Spezifikation |
|------------|---------------|
| **SoC** | Broadcom BCM2712 (16nm) |
| **CPU** | 4× Arm Cortex-A76 @ 2.4 GHz |
| **GPU** | VideoCore VII @ 800 MHz |
| **RAM** | 4GB oder 8GB LPDDR4X-4267 |
| **I/O-Controller** | RP1 (separater Chip!) |
| **PCIe** | 1× PCIe 2.0/3.0 (via FFC) |
| **USB** | 2× USB 3.0, 2× USB 2.0 |
| **Stromversorgung** | 5V/5A via USB-C PD |
| **TDP** | ~12W (Peak: ~27W mit Peripherie) |

### Kritische Unterschiede zu Pi 4

**RP1 I/O-Controller:**
- Separater Chip für alle Peripherie (GPIO, I2C, SPI, UART, PWM)
- Erfordert Kernel 6.6+ und angepasste Treiber
- `RPi.GPIO` ist **inkompatibel** → Verwende `gpiozero` mit lgpio

**Mini-CSI-Anschlüsse:**
- 22-Pin-Stecker (schmal), nicht 15-Pin wie Pi 4
- Kamera Module 1/2 benötigen Adapter-Kabel
- Camera Module 3 hat natives Mini-CSI-Kabel

**PCIe Gen 3:**
- Standardmässig Gen 2 (5 GT/s)
- Gen 3 (8 GT/s) muss in `config.txt` aktiviert werden
- Wichtig für Hailo-8L NPU und NVMe SSDs

**Stromversorgung:**
- USB-C PD erforderlich (nicht nur USB-C)
- 27W offizielles Netzteil empfohlen
- Unterspannungserkennung strenger (mehr false positives)

### GPIO-Besonderheiten Pi 5

```
RP1-Chip Limitationen:
- Max. 16 mA pro Pin (wie Pi 4)
- Pull-Up/Pull-Down: 50 kΩ (schwächer als Pi 4: 50-65 kΩ)
- Neue GPIO-Nummern für zusätzliche Pins (GPIO 27, 28)
```

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

**Temperatur-Limits:**
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
- 2× Mini-CSI (22-Pin, schmal)
- Unterstützt bis zu 2 Kameras gleichzeitig
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

- 1× PCIe 2.0 (5 GT/s, Standard)
- 1× PCIe 3.0 (8 GT/s, opt-in via config.txt)
- Via FFC-Kabel und M.2 HAT+

**Aktivierung Gen 3:**
```bash
# /boot/firmware/config.txt
dtparam=pciex1_gen=3
```

---

## Wichtige Sicherheitshinweise

### Elektrische Grenzen

⚠️ **Kritisch:**
- GPIO sind **nicht 5V-tolerant**
- Max. 16 mA pro Pin
- Max. ~50 mA pro GPIO-Bank
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

---

## Weitere Ressourcen

- [Raspberry Pi 5 Datasheet](https://datasheets.raspberrypi.com/rpi5/raspberry-pi-5-product-brief.pdf)
- [Raspberry Pi 4 Datasheet](https://datasheets.raspberrypi.com/rpi4/raspberry-pi-4-datasheet.pdf)
- [GPIO Pinout (interaktiv)](https://pinout.xyz/)
- [Official Documentation](https://www.raspberrypi.com/documentation/)
