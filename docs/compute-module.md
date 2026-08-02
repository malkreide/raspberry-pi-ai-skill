# Compute Modules – CM1 bis CM5 und die IO-Boards

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «Compute Module hardware»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/compute-module.html)).

Compute Modules sind die Einplatinenrechner ohne Anschlüsse – gedacht für Geräte, in denen
der Rechner verbaut statt bedient wird. Statt HDMI, USB und Ethernet gibt es einen
Steckverbinder, den ein **Trägerboard** (Carrier oder IO-Board) auf die tatsächlich
benötigten Anschlüsse führt.

Diese Referenz ergänzt `hardware-specs.md` (Einplatinenrechner und Keyboard-Modelle) um
die Modul-Varianten und deren Eigenheiten.

## Inhaltsverzeichnis
1. [Modellübersicht](#modellübersicht)
2. [Die Bauform-Falle](#die-bauform-falle)
3. [IO-Boards](#io-boards)
4. [GPIO auf dem Compute Module](#gpio-auf-dem-compute-module)
5. [eMMC beschreiben](#emmc-beschreiben)
6. [Bootloader-EEPROM](#bootloader-eeprom)
7. [Kameras anschliessen](#kameras-anschliessen)
8. [Zubehör für CM5](#zubehör-für-cm5)
9. [Bekannte Probleme](#bekannte-probleme)

---

## Modellübersicht

| Modell | Basis | SoC | CPU | RAM | eMMC | Bauform |
|--------|-------|-----|-----|-----|------|---------|
| **CM5** (2024) | Pi 5 | BCM2712 | 4× A76 @ 2,4 GHz | 2/4/8/**16 GB** | 0/16/32/**64 GB** | 2× 100-Pin |
| **CM4S** (2022) | Pi 4B | BCM2711 | 4× A72 @ **1,5 GHz** | 1/2/4/8 GB | 0/8/16/32/64 GB | **DDR2-SODIMM** |
| **CM4** (2020) | Pi 4B | BCM2711 | 4× A72 @ **1,5 GHz** | 1/2/4/8 GB | 0/8/16/32/64 GB | 2× 100-Pin |
| CM3+ (2019) | Pi 3B+ | BCM2837B0 | 4× A53 @ 1,2 GHz | 1 GB | 0/8/16/32/64 GB | DDR2-SODIMM |
| CM3 (2017) | Pi 3B | BCM2837 | 4× A53 @ 1,2 GHz | 1 GB | 0/4 GB | DDR2-SODIMM |
| CM1 (2014) | Pi 1B | BCM2835 | 1× ARM1176 @ 700 MHz | 512 MB | 4 GB | DDR2-SODIMM |

**Lite-Varianten** (Zusatz `Lite` oder `L`) haben **kein eMMC** und booten von microSD –
nur bei ihnen ist der Kartenschacht der IO-Boards überhaupt nutzbar. Bei allen anderen
Varianten wird er ignoriert.

> ⚠️ **CM4 und CM4S takten mit 1,5 GHz, nicht mit 1,8 GHz.** Der Pi 4B erreicht die
> 1,8 GHz erst über `arm_boost=1` (siehe `config-txt.md`); die Compute Modules bleiben bei
> der Basisfrequenz. Wer Laufzeiten von einem Pi 4B auf ein CM4 überträgt, rechnet rund
> **17 % zu optimistisch**.

**WLAN und Bluetooth** sind nur bei CM4 und CM5 verfügbar, und dort **optional** – es gibt
Varianten ohne. Bei CM1, CM3, CM3+ und CM4S gibt es sie gar nicht.

### Temperaturbereich

Das **CM4** ist in zwei Ausführungen erhältlich:

| Variante | Betriebstemperatur |
|----------|--------------------|
| Standard | −20 °C bis +85 °C |
| Erweitert | **−40 °C bis +85 °C** |

➜ Das ist der praktische Grund, aus dem Compute Modules in Aussenanwendungen landen: Der
Pi 5 ist nur für **0 °C bis +70 °C** spezifiziert (siehe `hardware-specs.md`). Für
Winterbetrieb im Freien ist das CM4 in der erweiterten Ausführung die einzige Variante, die
sich ohne Heizung rechtfertigen lässt.

### Abgekündigte Modelle

🔴 **CM3 und CM3Lite haben am 16. Oktober 2025 das Lebensende erreicht** – der SoC wird
nicht mehr gefertigt. Ersatz:

| Fall | Empfehlung |
|------|------------|
| Bestehendes Design mit CM3 | **CM3+** – gleiche Bauform, besseres Wärmeverhalten, BCM2837B0 |
| Neues Design, SODIMM nötig | **CM4S** |
| Neues Design, freie Wahl | **CM4 oder CM5** |

---

## Die Bauform-Falle

🔴 **Die DDR2-SODIMM-Module passen mechanisch in jeden DDR2-SODIMM-Sockel – die
Pinbelegung ist aber eine völlig andere als bei Speicherriegeln.**

Ein Compute Module in einem Speichersockel oder ein Speicherriegel in einem CM-Sockel
steckt also problemlos und zerstört im Zweifel beides. Der Sockel ist nur die
mechanische Bauform, kein Kompatibilitätsversprechen.

Mit dem CM4 wurde auf **zwei 100-polige Steckverbinder** gewechselt. Das ergibt eine
kleinere Grundfläche und erst die zusätzlichen Schnittstellen: zweiter HDMI-Ausgang, PCIe
und Ethernet. **CM4 und CM5 teilen diese Bauform** – ein CM5 passt also auf ein
CM4-Trägerboard, wenn auch mit Einschränkungen.

---

## IO-Boards

Das IO-Board ist Entwicklungswerkzeug und Referenzentwurf zugleich: Für die Serie entsteht
daraus meist ein eigenes, kleineres Trägerboard mit nur den benötigten Anschlüssen.

| IO-Board | Passt zu | Versorgung | Grösse |
|----------|----------|------------|--------|
| **CM5IO** (2024) | CM5; CM4 eingeschränkt | 5 V über USB-C | 160 × 90 mm |
| **CM4IO** (2020) | CM4; CM5 eingeschränkt | 5 V über GPIO **oder 12 V Hohlstecker** | 160 × 90 mm |
| CMIO3 (2017) | CM1, CM3, CM3+, CM4S | 5 V über GPIO oder Micro-USB | 85 × 105 mm |
| CMIO1 (2014) | **nur CM1** | 5 V über GPIO oder Micro-USB | 85 × 105 mm |

### Was das CM5IO bietet

- **USB-C-Versorgung nach Pi-5-Standard:** 5 V/5 A (25 W), oder 5 V/3 A (15 W) mit der
  bekannten **600-mA-Grenze für Peripherie**
- **M.2-M-Key-Steckplatz für 2230, 2242, 2260 und 2280** – dieselbe Bandbreite wie beim
  Pi 500+ und mehr als beide M.2-HAT+-Varianten (siehe `pcie.md`)
- 2× HDMI, **2× kombinierte DSI/CSI-2-Anschlüsse** (22-polig, 0,5 mm)
- 2× USB 3.0 Typ A, 1× USB-C (zum Beschreiben des eMMC)
- Gigabit-Ethernet mit PoE, 40-Pin-HAT-Footprint, RTC-Batteriesockel, Power-Taste
- **4-poliger JST-SH-PWM-Lüfteranschluss** – wie beim Pi 5

### Was das CM4IO anders macht

- **12 V über Hohlstecker, und bis 26 V, wenn PCIe ungenutzt bleibt** – für Anlagen mit
  vorhandener 12- oder 24-V-Schiene ist das der Grund, zum CM4IO zu greifen.
- **PCIe-Gen-2-Steckplatz** statt M.2 – eine echte Steckkarte, kein Modul
- **DSI und CSI getrennt:** je zwei Anschlüsse, nicht kombiniert wie beim CM5IO
- Nur **2× USB 2.0**
- **12-V-Lüfter mit PWM** statt des 5-V-JST-SH-Anschlusses

### Auf beiden: umschaltbare GPIO-Spannung

🔴 **CM4IO und CM5IO erlauben 1,8 V *oder* 3,3 V an den GPIO-Pins.** Bei allen
Einplatinenrechnern sind die 3,3 V fest verdrahtet.

Das ist Freiheit und Fussangel zugleich: Ein 3,3-V-Sensor an einem auf 1,8 V gestellten
Board erreicht die Eingangsschwelle nicht, und in der Gegenrichtung liegt Überspannung an.
**Vor dem ersten Anschluss die Jumper-Stellung prüfen** – das Fehlerbild («Sensor liefert
nichts») führt sonst in die Software.

Weitere Jumper schalten eMMC-Boot, EEPROM-Schreibschutz und Funk ab.

---

## GPIO auf dem Compute Module

Der BCM283x hat **drei Bänke mit insgesamt 54 GPIO**:

| Bank | Pins | Verwendbar? |
|------|------|-------------|
| Bank 0 | 28 | ✅ |
| Bank 1 | 18 | ✅ |
| **Bank 2** | 8 | 🔴 **nicht verwenden** |

**Bank 2 steuert eMMC, HDMI-Hotplug-Erkennung sowie ACT-LED und USB-Boot.** Wer sie
belegt, legt im besten Fall die Statusanzeige lahm und im schlechtesten das Boot-Medium.

Die tatsächliche Funktion und Spannung eines Pins prüft:

```bash
pinctrl
```

Das ist der schnellste Weg zu der Frage, ob ein Device-Tree-Overlay überhaupt greift.

### Peripherie beschreiben: Overlay statt eigenem Device Tree

Für eigene Trägerboards lässt sich ein vollständiger Device Tree bauen – **empfohlen ist
das nicht.** Ein **Overlay** beschreibt nur die zusätzliche Hardware und wird mit dem
Basis-Device-Tree verschmolzen:

```bash
sudo apt install device-tree-compiler
sudo dtc -@ -I dts -O dtb -o /boot/firmware/overlays/example1.dtbo \
         /boot/firmware/example1-overlay.dts
```

```ini
# In /boot/firmware/config.txt
dtoverlay=example1
```

⚠️ **Das `-@` ist fast immer nötig** – ohne diesen Schalter übersetzt `dtc` keine externen
Referenzen, und das Overlay bleibt wirkungslos.

➜ **Der Vorteil des Overlays ist der Update-Pfad:** Standard-Images von Raspberry Pi OS
bleiben nutzbar. Ein eigener Device Tree zwingt dazu, bei **jedem** OS-Update ein
angepasstes Image zu bauen.

### `dt-blob.bin` – was vor Linux passiert

Die GPU liest **vor** `config.txt` die Datei `dt-blob.bin` und setzt daraus die
GPIO-Startzustände. Standardmässig existiert die Datei nicht; `start.elf` bringt eine
eingebaute Fassung mit.

Sie ist dann nötig, wenn ein Pin **schon während des GPU-Starts** einen bestimmten Zustand
braucht – etwa eine Reset-Leitung, die in der richtigen Lage gehalten werden muss, bevor
Linux-Treiber laden. Sie legt ausserdem HDMI-Hotplug-Pin, GPCLK-Ausgänge und die ACT-LED
fest.

```bash
dtc -I dts -O dtb -o dt-blob.bin minimal-cm-dt-blob.dts
```

### Device Tree debuggen

```bash
# Den tatsaechlich zusammengesetzten Baum auslesen
dtc -I fs -O dts -o proc-dt.dts /proc/device-tree

# Meldungen der GPU
sudo vclog --msg
```

Mit `dtdebug=1` in der `config.txt` wird die Ausgabe deutlich gesprächiger.

---

## eMMC beschreiben

Das eMMC hängt an der primären SD-Karten-Schnittstelle und wird über **`rpiboot`** vom
Host-Rechner aus beschrieben. Lite-Varianten haben kein eMMC – dort gilt der normale Weg
über `setup-provisioning.md`.

**Am CM5IO:**

1. Modul aufstecken – es muss **flach aufliegen**
2. Jumper **`nRPI_BOOT` auf `J2`** setzen (eMMC-Boot abschalten)
3. **USB-C-Buchse `J11`** mit dem Host verbinden
4. Erst danach die Stromversorgung anschliessen

```bash
sudo apt install rpiboot
sudo rpiboot
```

Nach wenigen Sekunden erscheint das Modul als Massenspeicher (`/dev/sda`, `/dev/sdb` – mit
`lsblk` anhand der Kapazität prüfen). Beschreiben mit dem Raspberry Pi Imager oder:

```bash
sudo dd if=raw_os_image.img of=/dev/sdX bs=4MiB
```

Danach **`nRPI_BOOT` wieder abziehen**, USB trennen und die Stromversorgung aus- und
einschalten.

> ⚠️ **USB-Hubs verhindern die Erkennung.** Wird das Modul nicht gefunden, direkt an den
> Host stecken, bevor irgendetwas anderes untersucht wird.

Für mehrere Module: **Raspberry Pi Secure Boot Provisioner**; für angepasste Images
**pi-gen**. Zum Beschreiben von NVMe, eMMC und USB-Blockgeräten ist das
**`mass-storage-gadget`** aus `usbboot` schneller als `rpiboot` und bietet zusätzlich eine
UART-Konsole zum Debuggen.

---

## Bootloader-EEPROM

Ab CM4 liegt der Bootloader im EEPROM statt in der Boot-Partition.

🔴 **Das ROM führt auf Compute Modules niemals eine `recovery.bin` von SD oder eMMC aus.**
Deshalb ist `rpi-eeprom-update` dort **ab Werk abgeschaltet**: Das eMMC ist nicht
entnehmbar, und eine fehlerhafte `recovery.bin` würde das Gerät unbootbar machen. Der
Rettungsweg über eine frische SD-Karte, der bei Einplatinenrechnern funktioniert, steht
hier nicht zur Verfügung.

**Vor dem Serieneinsatz** empfiehlt die Dokumentation drei Schritte:

1. Eine **bestimmte Bootloader-Version** festlegen und auf jedem Modul prüfen
2. `BOOT_ORDER` explizit setzen (Nibble-Schema in `configuration.md`)
3. Den **Hardware-Schreibschutz** des EEPROM aktivieren – `eeprom_write_protect=1` in der
   `config.txt`, danach `EEPROM_nWP` auf Masse ziehen

```bash
cd usbboot/recovery
# boot.conf anpassen: BOOT_ORDER=0xf1 (eMMC), 0xf2 (Netz), 0xf6 (NVMe), 0xf15 (USB→eMMC)
./update-pieeprom.sh
../rpiboot -d .
```

> 🔴 **Der Self-Update-Modus arbeitet nicht atomar.** Fällt während des EEPROM-Updates die
> Spannung aus, ist das EEPROM beschädigt. Auf Geräten ohne gesicherte Versorgung ist das
> ein Risiko, das gegen den Komfort abzuwägen ist.

Beim Beschreiben des EEPROM darf **`EEPROM_nWP` nicht auf Masse liegen** – sonst schlägt
der Schreibvorgang fehl.

---

## Kameras anschliessen

Der Anschluss unterscheidet sich je IO-Board erheblich – hier verlaufen die meisten
Fehlschläge.

### I2C-Zuordnung

Die Treiber erwarten **CAM1 auf `i2c-10`** und **CAM0 auf `i2c-0`**. Welche GPIOs das sind,
hängt vom Board ab:

| IO-Board | `i2c-10` | `i2c-0` |
|----------|----------|---------|
| CM4IO | GPIO 44, 45 | GPIO 0, 1 |
| **CMIO3** (CM1, CM3, CM3+, CM4S) | GPIO 0, 1 | GPIO 28, 29 |

➜ **Die Zuordnung ist zwischen den Board-Generationen vertauscht.** Auf dem CMIO3 braucht
es deshalb:

```ini
dtoverlay=cm-swap-i2c0
```

Für eigene Trägerboards mit abweichender Belegung stehen `i2c0-gpio0`, `i2c0-gpio28`,
`i2c0-gpio44` sowie die entsprechenden `i2c10-*`-Varianten bereit.

### Vorgehen

Zuerst diese Zeilen in `/boot/firmware/config.txt` **entfernen oder auskommentieren** –
sonst greift die automatische Erkennung dazwischen:

```ini
# camera_auto_detect=1
# dtparam=i2c_arm=on
```

Danach den Treiber **von Hand** benennen:

| Kamera | Overlay |
|--------|---------|
| v1 | `dtoverlay=ov5647` |
| v2 | `dtoverlay=imx219` |
| v3 | `dtoverlay=imx708` |
| HQ | `dtoverlay=imx477` |
| GS | `dtoverlay=imx296` |

Für die zweite Kamera dasselbe Overlay mit dem Zusatz `,cam0` – etwa
`dtoverlay=imx708,cam0`.

**Board-spezifisch:**

- **CM5:** zwei Jumper auf `J6` gemäss Aufdruck
- **CM4:** für die zweite Kamera die `J6`-Pins mit zwei **senkrecht** gesetzten Jumpern
- **CM1, CM3, CM3+, CM4S:** vier Drahtbrücken je Kamera (GPIO 0→CD1_SDA, 1→CD1_SCL,
  2→CAM1_I01, 3→CAM1_I00; für CAM0 entsprechend 28–31), dazu `dtparam=cam1_reg`
  beziehungsweise `dtparam=cam0_reg`

```bash
rpicam-hello --list-cameras
```

> ℹ️ **Am CM4IO teilen sich beide Kameras einen Regler** – es gibt nur einen GPIO für
> `cam1_reg` und `cam0_reg`. Auf CMIO3 ist gar keiner verdrahtet, die Regler sind dort
> abgeschaltet. Für eigene Boards:
> `dtparam=cam1_reg_gpio=<Pin>` – funktioniert **nur für direkt am SoC hängende GPIOs**,
> nicht für Expander-Pins.

---

## Zubehör für CM5

| Zubehör | Angaben |
|---------|---------|
| **CM5IO-Gehäuse** | Zweiteilig, Blech, ca. 170 × 94 × 28 mm, ~350 g, Lüfter vormontiert |
| **Antenne (CM4/CM5)** | Dual-Band, U.FL auf SMA, Kabel ~205 mm, Antenne ~108,5 mm |
| **CM5-Kühler** | Passiv, Alu mit Silikonpad, ca. 41 × 56 × 12,7 mm |

⚠️ **Beim Gehäuse gibt es zwei Fassungen.** In **Version 1** sitzt der Lüfter näher an der
Längskante – dort passen **Lüfter und Kühler nicht gleichzeitig hinein**, der Lüfter muss
weichen. **Version 2** hat den Lüfter zur Schmalseite verschoben und bietet Platz für
beides. Äusserlich sind die Fassungen gleich gross.

**Die Antenne muss in der Software freigeschaltet werden:**

```ini
# In /boot/firmware/config.txt
dtparam=ant2
```

➜ Ohne diese Zeile bleibt die interne Antenne aktiv, und die externe wirkt nicht. Das
erklärt Fälle, in denen die Reichweite nach dem Anbau unverändert schlecht bleibt.

> ℹ️ Beim Zusammenbau den **U.FL-Stecker vor dem Kühler** anschliessen – danach ist er nur
> noch schwer zugänglich. Der Kühler wird so aufgesetzt, dass seine Aussparung über der
> internen Antenne liegt.

---

## Bekannte Probleme

| Symptom | Ursache und Abhilfe |
|---------|---------------------|
| **CM3 bootet vereinzelt nicht** | Zeitverhalten zwischen CPU und eMMC in Verbindung mit der Art, wie die FAT32-Partition angelegt wurde. Partition von Hand erstellen: `parted` → `mkpart primary fat32 4MiB 64MiB`, dann `mkfs.vfat -F32` |
| **CM1 an manchen USB-Ports nicht erkannt** | Der CM1-Bootloader sendet ein leicht fehlerhaftes USB-Paket. Die meisten Hosts ignorieren das, manche nicht. Ab CM3 behoben – anderen Port oder Host verwenden |
| **`rpiboot` findet das Modul nicht** | Unter **Ubuntu 24.04 und älter** ist die mitgelieferte Fassung defekt – `rpiboot` **aus den Quellen bauen**. Sonst: direkt statt über einen Hub anschliessen |

---

## Weitere Ressourcen

- `hardware-specs.md` – Einplatinenrechner, Keyboard-Modelle, Modellerkennung
- `pcie.md` – PCIe, M.2 HAT+, Formfaktoren
- `camera.md` – libcamera, rpicam-apps, Tuning
- `configuration.md` – `BOOT_ORDER`, EEPROM, Device Tree und Overlays
- [Compute Module hardware](https://www.raspberrypi.com/documentation/computers/compute-module.html)
- [usbboot auf GitHub](https://github.com/raspberrypi/usbboot) – `rpiboot`, `mass-storage-gadget`
- [pi-gen](https://github.com/RPi-Distro/pi-gen) – eigene OS-Images bauen
