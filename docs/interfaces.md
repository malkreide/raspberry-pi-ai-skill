# Schnittstellen – SPI, USB, DPI und DSI

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «Computers → Hardware»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html)).

Diese Referenz behandelt drei Schnittstellen, deren Tücken selten in Anleitungen stehen,
aber regelmässig Projekte aufhalten: **SPI** (mehr Busse als bekannt, eine Falle im
3-Draht-Modus), **USB** (Strombudget und ein Hub-Fehler, der Tastaturen verschwinden lässt),
**DPI** (ein Display an der GPIO-Leiste – belegt fast alle Pins) und **DSI** (die offiziellen
Touch-Displays – mit Kompatibilitätsgrenzen, die vor dem Kauf zählen).

Ergänzt `rp1-gpio.md` (Pad-Grenzwerte, Alternativfunktionen, PIO) und
`hardware-specs.md` (Pinbelegung, Modellunterschiede).

## Inhaltsverzeichnis
1. [SPI](#spi)
2. [USB](#usb)
3. [DPI – Parallel-Display an der GPIO-Leiste](#dpi--parallel-display-an-der-gpio-leiste)
4. [DSI – die offiziellen Touch-Displays](#dsi--die-offiziellen-touch-displays)

---

## SPI

### Wie viele Busse es wirklich gibt

Die meisten Anleitungen kennen nur SPI0. Tatsächlich stehen je nach Modell deutlich mehr
zur Verfügung:

| Modell | SPI-Busse | Bemerkung |
|--------|-----------|-----------|
| Pi 1 A / B | SPI0 | |
| Pi Zero, 1 A+/B+, 2, 3 | SPI0, SPI1, (SPI2) | SPI2 nur auf CM1/CM3/CM3+ |
| **Pi 4, Pi 400, CM4** | **SPI0 – SPI6** | SPI3–SPI6 über Alternativfunktionen |
| **Pi 5, Pi 500** | **6 Instanzen** | über RP1, siehe `rp1-gpio.md` |

➜ **Wer auf dem Pi 4 an Bus-Kollisionen scheitert, hat mehr als einen Bus zur Auswahl.**
Zwei SPI-Geräte mit inkompatibler Taktpolarität müssen sich keinen teilen.

> ℹ️ **Zur genauen Zahl widersprechen sich die Quellen.** Die Prozessorseite zum BCM2711
> nennt «bis zu 6 SPI, davon fünf am Pi 4B herausgeführt», die SPI-Seite dokumentiert
> Header-Pins für SPI0, SPI1 und SPI3–SPI6. Auf die Praxis wirkt sich das kaum aus – die
> Belegungen unten sind belegt, und die Überschneidungen begrenzen die gleichzeitig
> nutzbare Zahl ohnehin stärker als das Maximum. **Vor der Platinenauslegung mit
> `dtoverlay -a | grep spi` prüfen, was die installierte Firmware tatsächlich anbietet.**

### Pinbelegung

**SPI0** (auf allen Modellen am Header):

| Funktion | Header-Pin | GPIO |
|----------|------------|------|
| MOSI | 19 | GPIO10 |
| MISO | 21 | GPIO9 |
| SCLK | 23 | GPIO11 |
| CE0 | 24 | GPIO8 |
| CE1 | 26 | GPIO7 |

**SPI1** (alle ausser Pi 1 A/B) – drei Chip-Selects:

| Funktion | Header-Pin | GPIO |
|----------|------------|------|
| MOSI | 38 | GPIO20 |
| MISO | 35 | GPIO19 |
| SCLK | 40 | GPIO21 |
| CE0 / CE1 / CE2 | 12 / 11 / 36 | GPIO18 / 17 / 16 |

**SPI3–SPI6** (nur BCM2711, also Pi 4 / 400 / CM4) – je zwei Chip-Selects:

| Bus | MOSI | MISO | SCLK | CE0 | CE1 |
|-----|------|------|------|-----|-----|
| SPI3 | GPIO2 | GPIO1 | GPIO3 | GPIO0 | GPIO24 |
| SPI4 | GPIO6 | GPIO5 | GPIO7 | GPIO4 | GPIO25 |
| SPI5 | GPIO14 | GPIO13 | GPIO15 | GPIO12 | GPIO26 |
| SPI6 | GPIO20 | GPIO19 | GPIO21 | GPIO18 | GPIO27 |

⚠️ **SPI3 belegt GPIO0–3.** GPIO2/3 sind die I2C-Pins mit den fest verbauten Pull-Ups,
GPIO0/1 sind für das HAT-EEPROM reserviert. SPI3 und I2C1 schliessen sich also aus.
**SPI6 überschneidet sich mit SPI1**, und **SPI4 mit SPI0s CE1** – die Busse liegen
teilweise übereinander und lassen sich nicht beliebig kombinieren.

### Aktivieren

```ini
# In /boot/firmware/config.txt
dtparam=spi=on             # SPI0 mit zwei Chip-Selects
dtoverlay=spi0-1cs         # SPI0 mit nur einem CS – gibt GPIO7 frei
dtoverlay=spi1-3cs         # SPI1 mit drei Chip-Selects
dtoverlay=spi4-2cs         # dito für SPI2 bis SPI6
```

```bash
dtoverlay -a | grep spi          # alle verfügbaren SPI-Overlays auflisten
dtoverlay -h spi0-2cs            # Parameter eines Overlays anzeigen
```

> ℹ️ **Der Linux-Treiber nutzt die Hardware-Chip-Selects nicht.** Er verwendet beliebige
> GPIOs als Software-CS. Das ist keine Einschränkung, sondern eine Freiheit: Jeder freie
> Pin kann CS-Leitung werden, und die Zahl der Geräte am Bus ist nicht auf zwei oder drei
> begrenzt. Die Zuordnung erfolgt über Overlay-Parameter (`/boot/firmware/overlays/README`).

### Taktrate

```
SCLK = Kerntakt / CDIV
```

`CDIV` muss **geradzahlig** sein; ungerade Werte werden abgerundet. Nicht jede rechnerisch
mögliche Rate funktioniert auch – Flankensteilheit und Leitungslänge setzen die reale
Grenze.

> ➜ **Faustregel: über 50 MHz wird es unzuverlässig.** Das ist keine harte Grenze, sondern
> hängt an Aufbau, Kabellänge und Gegenstelle. Bei sporadischen Übertragungsfehlern ist
> das Halbieren der Taktrate der erste Test, nicht der letzte.

### 🔴 Die Falle im 3-Draht-Modus

Im bidirektionalen Modus (`SPI_3WIRE`) teilen sich Ein- und Ausgang eine Leitung (MOMI
statt MISO/MOSI). Der Treiber `spi-bcm2835` unterstützt das – **aber nur halbduplex**:

> **Entweder `tx` oder `rx` im `spi_transfer`-Struct muss ein NULL-Zeiger sein.** Sind
> beide gesetzt, schlägt die Übertragung fehl.

⚠️ **`spidev_test.c` berücksichtigt das nicht und funktioniert im 3-Draht-Modus überhaupt
nicht.** Wer damit einen 3-Draht-Aufbau testet, misst den Fehler des Testprogramms, nicht
den der eigenen Verkabelung. Das ist ein klassischer verlorener Nachmittag.

### Unterstützte Modi und Wortbreiten

| Modusbit | Bedeutung |
|----------|-----------|
| `SPI_CPOL` / `SPI_CPHA` | Taktpolarität und -phase (die vier klassischen Modi 0–3) |
| `SPI_CS_HIGH` | Chip-Select aktiv High |
| `SPI_NO_CS` | ein Gerät am Bus, ohne CS |
| `SPI_3WIRE` | bidirektional – siehe Falle oben |

Wortbreite: **8 Bit** normal, **9 Bit** über den LoSSI-Modus (für MIPI-DBI-Typ-C-Displays).

### Schleifentest

Der schnellste Weg, Senden und Empfangen zu prüfen – **MOSI und MISO mit einem Draht
verbinden**:

```bash
wget https://raw.githubusercontent.com/raspberrypi/linux/rpi-6.1.y/tools/spi/spidev_test.c
gcc -o spidev_test spidev_test.c
./spidev_test -D /dev/spidev0.0
```

Kommen die gesendeten Bytes zurück, arbeiten Bus und Treiber. **Die CE-Leitungen prüft der
Test nicht.**

Aus der Shell heraus geht auch das Einfachste:

```bash
echo -ne "\x01\x02\x03" > /dev/spidev0.0
```

Aus Python: `pip install spidev`.

> ⚠️ Bibliotheken, die die Register direkt ansprechen statt über `/dev/spidev*` zu gehen,
> umgehen den Kernel-Treiber. Davon ist abzuraten – sie brechen bei Kernel- und
> Modellwechseln und kollidieren mit allem, was den Bus sonst noch nutzt.

---

## USB

### Wie viel Strom die Ports liefern

| Modell | Maximum über alle Ports |
|--------|-------------------------|
| Pi 1 Model B | 100 mA pro Port |
| Pi Zero, Pi 1 (übrige) | 500 mA pro Port |
| Pi 2, 3, 4 | **1200 mA** gesamt |
| **Pi 5** | **600 mA am 3-A-Netzteil, 1600 mA am 5-A-Netzteil** |

➜ **Der häufigste USB-Fehler ist ein Stromfehler.** Bevor irgendetwas anderes untersucht
wird: Gerät an einen **aktiven** Hub hängen. Damit ist die Frage in zwei Minuten geklärt.

```bash
vcgencmd get_config usb_max_current_enable    # 1 = hohes Limit aktiv
```

### 🔴 USB-3.0-Hubs und langsame Geräte (vor Pi 5)

Ein Fehler in der Hardware **der meisten USB-3.0-Hubs** führt dazu, dass Modelle **vor dem
Pi 4** nicht mit Low- oder Full-Speed-Geräten sprechen können, die an einem USB-3.0-Hub
hängen. Betroffen sind ausgerechnet **die meisten Tastaturen und Mäuse**.

Das Fehlerbild ist irreführend: Der Hub wird erkannt, USB-2.0-Geräte daran funktionieren,
nur Tastatur und Maus bleiben tot.

**Abhilfe:** Einen USB-2.0-Hub zwischen Pi und USB-3.0-Hub setzen, oder die langsamen
Geräte an einen USB-2.0-Hub am Downstream-Port hängen. Am einfachsten: langsame Geräte
gar nicht erst an einen USB-3.0-Hub.

### Single-TT- gegen Multi-TT-Hubs

Hubs übersetzen zwischen High-Speed und langsamen Geräten über einen **Transaction
Translator (TT)**. Die USB-Spezifikation erlaubt zwei Bauformen:

| Bauform | TT | Verhalten |
|---------|-----|-----------|
| **Single TT** | einer für **alle** Ports | Bei mehreren langsamen Geräten wird der TT zum Nadelöhr – die Geräte arbeiten unzuverlässig |
| **Multi TT** | einer **pro Port** | Für mehrere langsame Geräte die richtige Wahl |

➜ **Für mehrere langsame Geräte einen Multi-TT-Hub kaufen.** Das steht selten auf der
Verpackung, aber in den technischen Daten. Notbehelf: die langsamen Geräte auf die
Pi-eigenen Ports und den Hub verteilen, statt alle an den Hub zu hängen.

### Weitere bekannte Eigenheiten

| Symptom | Ursache | Abhilfe |
|---------|---------|---------|
| Alte Webcam läuft unzuverlässig | Full-Speed-Gerät mit hoher Datenrate und viel Software-Overhead | Niedrigere Auflösung wählen |
| Audiophile USB-Soundkarte setzt aus | 96/192 kHz sprengen die Bandbreite | Auf 44,1/48 kHz und 16 Bit zwingen |
| Mehrere langsame Geräte gleichzeitig instabil | Software-Overhead pro Gerät, nicht Bandbreite | Multi-TT-Hub, Geräte verteilen |

### Der Pi 4 hat nur einen USB-2.0-Pfad

Die vier Ports des Pi 4 hängen an einem VL805-Controller. Die **USB-2.0-Leitungen aller
vier Ports laufen über einen einzigen internen Hub**. Die verfügbare Bandbreite für alle
USB-1.1- und USB-2.0-Geräte zusammen entspricht damit **einem einzigen USB-2.0-Port** –
egal, auf wie viele Buchsen man sie verteilt.

➜ Für mehrere USB-Kameras oder USB-Audio am Pi 4 ist das die eigentliche Grenze.

**Der Pi 5 hat diese Einschränkung nicht:** Der RP1 bringt **zwei unabhängige
XHCI-Controller** mit, jeder mit eigenem USB-3.0- und USB-2.0-PHY. Das ergibt **mehr als
die doppelte nutzbare USB-Bandbreite** – und ist für Aufbauten mit mehreren USB-Geräten der
handfestere Unterschied zwischen Pi 4 und Pi 5 als der Prozessor. Details in
[`rp1-gpio.md`](rp1-gpio.md#weitere-rp1-funktionen).

### Rückspeisung vermeiden

Ein schlecht gebauter aktiver Hub kann Strom **zurück in den Pi** speisen. Das ist laut
USB-Spezifikation unzulässig und umgeht die **gesamte Schutzbeschaltung des Pi** – bei
einer Spannungsspitze fehlt dem Board damit jeder Schutz. Wenn ein Pi ohne eigenes
Netzteil allein am Hub startet, liegt genau dieser Fall vor.

---

## DPI – Parallel-Display an der GPIO-Leiste

Ein paralleles RGB-Display lässt sich direkt an die 40-polige Leiste hängen – als
Alternative zu HDMI und DSI. Verfügbar auf **allen Modellen mit 40-Pin-Header** und auf den
Compute Modules.

### Was es kostet: fast die ganze GPIO-Leiste

| Modus | Farbtiefe | Belegte GPIOs |
|-------|-----------|---------------|
| RGB565 | 16 Bit | GPIO0–19 |
| RGB666 | 18 Bit | GPIO0–9, 12–17, 20–25 |
| RGB888 | 24 Bit | **GPIO0–27 – alle** |

Dazu kommen in jedem Fall die Steuerleitungen: `PCLK` (GPIO0), `DE` (GPIO1), `VSYNC`
(GPIO2), `HSYNC` (GPIO3). Die Datenleitungen `DPI_D0`–`D23` liegen auf GPIO4–27.

🔴 **Bei RGB888 bleibt kein einziger GPIO für etwas anderes übrig.** Wer neben dem Display
noch Sensoren braucht, muss RGB565 wählen (GPIO20–27 bleiben frei) oder auf DSI/HDMI
ausweichen. Das ist die Entscheidung, die vor dem Kauf ansteht – nicht danach.

### Kollidierende Schnittstellen abschalten

DPI liegt auf denselben Pins wie I2C und SPI. Beides muss weichen:

```ini
dtparam=i2c_arm=off
dtparam=spi=off
```

⚠️ Wer das vergisst, bekommt ein Bild mit Störungen oder gar keines – und sucht den Fehler
beim Display.

### Einrichten

Ab **Bookworm** ist die frühere Konfiguration über `dpi_output_format` und `dpi_timings`
durch das Overlay `vc4-kms-dpi-generic` ersetzt. Alte Anleitungen mit diesen beiden
Parametern funktionieren nicht mehr.

Am einfachsten ist die automatische Erkennung, die standardmässig aktiv ist:

```ini
display_auto_detect=1
```

Für ein Display mit fertigem Overlay genügt dessen Name:

```ini
dtoverlay=vc4-kms-kippah-7inch-overlay
```

Für ein Display ohne eigenes Overlay lassen sich die Timings als Parameter angeben:

```ini
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dpi-generic,hactive=480,hfp=26,hsync=16,hbp=10
dtparam=vactive=640,vfp=25,vsync=10,vbp=16
dtparam=clock-frequency=32000000,rgb666-padhi
```

> ⚠️ **Eine Device-Tree-Zeile darf 80 Zeichen nicht überschreiten.** Längere Angaben auf
> mehrere `dtparam`-Zeilen aufteilen – wie im Beispiel oben. Das ist eine andere Grenze als
> die 98 Zeichen pro Zeile in der `config.txt` (siehe `config-txt.md`).

**Die wichtigsten Parameter:**

| Parameter | Bedeutung |
|-----------|-----------|
| `clock-frequency` | Pixeltakt in Hz |
| `hactive` / `vactive` | Sichtbare Pixel horizontal / Zeilen vertikal |
| `hfp` / `hbp` / `hsync` | Vordere, hintere Austastlücke und Synchronimpuls, horizontal |
| `vfp` / `vbp` / `vsync` | dasselbe vertikal |
| `rgb565` / `rgb666-padhi` / `rgb888` | Farbtiefe und Pinbelegung |
| `hsync-invert` / `vsync-invert` / `de-invert` | Signal aktiv Low |
| `pixclk-invert` | Daten an der fallenden Taktflanke |
| `width-mm` / `height-mm` | Physische Bildschirmgrösse (für die Skalierung) |
| `backlight-gpio` | GPIO für die Hintergrundbeleuchtung |

➜ Die Timings stammen aus dem Datenblatt des Panels. Ein falscher Wert bei `hfp`/`hbp`
zeigt sich als seitlich verschobenes oder gerissenes Bild – nicht als schwarzer Schirm.

---

## DSI – die offiziellen Touch-Displays

Anders als DPI belegt DSI **keine GPIO-Pins** für Bilddaten – es hängt am eigenen
Flachbandanschluss. Für Bedienoberflächen ist das der bessere Weg, weil die GPIO-Leiste
frei bleibt.

### Kompatibilität – hier liegen die Fallen

| Display | Auflösung | Läuft auf | **Läuft nicht auf** |
|---------|-----------|-----------|---------------------|
| **Touch Display** (7″) | 800 × 480 | Pi B+ und neuer | Zero-Reihe, Keyboard-Modelle |
| **Touch Display 2** 5″/7″ | 720 × 1280 | Pi B+ und neuer, alle CMIO | Zero-Reihe, Keyboard-Modelle |
| **Touch Display 2** 10″ | 1200 × 1920 | **Pi 5 und neuer**, CM5IO; CM4IO nur an **DISP1** | 🔴 **Pi 4B und älter** |

🔴 **Zwei Ausschlüsse, die vor dem Kauf zählen:**

1. **Zero-Reihe und Keyboard-Computer haben keinen DSI-Anschluss.** Kein Adapter hilft.
2. **Das 10-Zoll-Modell läuft nicht am Pi 4B und älter.** Am CM4IO nur an DISP1, nicht am
   zweiten Anschluss.

### Das richtige Flachbandkabel

Der Pi 5 hat einen **kleineren DSI-Anschluss** als seine Vorgänger:

| Ziel | Kabel |
|------|-------|
| Pi 4 und älter | 15-polig auf 15-polig |
| **Pi 5, CMIO-Boards** | **22-polig auf 15-polig** (Standard–Mini) |
| Pi 5 mit **10-Zoll**-Display | 22-polig auf 22-polig (Mini–Mini) |

> ⚠️ **Beim Touch Display 2 liegt das passende Kabel bei, beim ersten Touch Display nicht** –
> dort ist das 22-auf-15-Kabel für den Pi 5 **separat zu kaufen**. Das ist ein klassischer
> Beschaffungsfehler: Display da, Pi da, Projekt steht.
>
> Die kleinere Seite des 22-auf-15-Kabels gehört an den **Pi 5**, die grössere ans Display.

### 🔴 Die Stromversorgung falsch herum zerstört das Display

Das Touch Display 2 wird über ein **dreipoliges GPIO-Kabel** versorgt (Anschluss `J1` am
Display). Die Ausrichtung ist nicht beliebig:

> Mit **USB- und Ethernet-Buchsen nach unten** gehört das Kabel **senkrecht an die rechte
> obere Ecke** der GPIO-Leiste – die rote 5-V-Ader auf **Pin 2**, die schwarze Masse auf
> **Pin 6**.

Beim ersten Touch Display sind es zwei einzelne Drahtbrücken: **Pin 4 (5 V)** und
**Pin 6 (GND)**, alternativ Pin 2 für 5 V.

⚠️ **Wer das erste Touch Display über Micro-USB versorgt, darf die GPIO-Verbindung nicht
zusätzlich herstellen** – eines von beidem, nicht beides.

### Ausrichtung drehen

Mit Desktop über *Control Centre → Screens*, pro Display getrennt. Ohne Desktop über
`cmdline.txt`:

```
video=DSI-1:720x1280@60,rotate=90
```

> 🔴 **Zwei Einschränkungen dieses Wegs:**
> 1. **`rotate=` dreht nur die Textkonsole.** Anwendungen, die direkt auf DRM schreiben –
>    `cvlc`, die `rpicam`-Programme – brauchen ihre **eigene** Drehoption. Das erklärt ein
>    gedrehtes Terminal mit ungedrehtem Kamerabild.
> 2. **DSI und HDMI teilen sich denselben Wert.** Zwei Displays lassen sich über
>    `cmdline.txt` nicht unterschiedlich drehen – dafür braucht es den Desktop.

**Die Berührungsebene dreht sich nicht mit.** Sie wird über das Overlay gestellt:

| Display | Overlay |
|---------|---------|
| Touch Display (7″) | `vc4-kms-dsi-7inch` |
| Touch Display 2, 5″ | `vc4-kms-dsi-ili9881-5inch` |
| Touch Display 2, 7″ | `vc4-kms-dsi-ili9881-7inch` |
| Touch Display 2, 10″ | `vc4-kms-dsi-ili79600-10-1inch` |

```ini
dtoverlay=vc4-kms-dsi-ili9881-7inch,invx,invy
```

| Parameter | Wirkung |
|-----------|---------|
| `invx` / `invy` | Achse spiegeln |
| `swapxy` | Achsen tauschen (90°-Drehung) |
| `sizex` / `sizey` | Auflösung der Berührungsebene |
| `disable_touch` | Berührung abschalten, Bild behalten |

Boolesche Parameter gelten als gesetzt, sobald sie dastehen; `invx=0` schaltet sie ab.

> ⚠️ **Nur nötig, wenn ohne Desktop gedreht wird.** Im Desktop die Drehung dort einstellen –
> Device-Tree und Eingabebibliothek können sich sonst gegenseitig aufheben, und man dreht
> zweimal.
>
> Wird das Overlay von Hand gesetzt, muss `display_auto_detect=1` aus der `config.txt`
> **entfernt** werden.

### Abschalten

```ini
ignore_lcd=1            # Display gar nicht erst erkennen
disable_touchscreen=1   # Bild behalten, Berührung abschalten
```

### Was sonst noch zählt

| | Touch Display (7″) |
|---|---|
| Stromaufnahme | **200 mA bei 5 V** (volle Helligkeit) |
| Betriebstemperatur | **−20 bis +70 °C** |
| Hintergrundbeleuchtung | 20 000 Stunden |
| Berührungspunkte | 10 gleichzeitig |

Beim Touch Display 2 sind es **fünf** Punkte bei 5″ und 7″, **zehn** beim 10-Zoll-Modell.

➜ **Die 200 mA gehören ins Strombudget** (siehe `setup-provisioning.md`) – sie kommen zum
Eigenverbrauch des Boards und zur Kamera hinzu.

> ℹ️ Ab Bookworm bringt Raspberry Pi OS die Bildschirmtastatur **Squeekboard** mit. Sie
> erscheint bei Texteingabe automatisch; dauerhaft ein- oder ausschalten über
> `raspi-config` → *Display* oder *Control Centre → Display*.

⚠️ **Das Display muss in ein Gehäuse eingebaut werden**, das im Betrieb keinen Zugang zur
Platine lässt – ausdrückliche Herstellerauflage, nicht bloss eine Empfehlung.

---

## Weitere Ressourcen

- `rp1-gpio.md` – Pad-Grenzwerte, Alternativfunktionen, PIO, Latenz am Pi 5
- `hardware-specs.md` – Pinbelegung der 40-poligen Leiste, Modellunterschiede
- `setup-provisioning.md` – Netzteilwahl und Strombudget
- [SPI](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#serial-peripheral-interface-spi)
- [USB](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#universal-serial-bus-usb)
- [DPI](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#display-parallel-interface-dpi)
- `/boot/firmware/overlays/README` – auf dem Gerät, passend zur installierten Firmware
