# Offizielles Zubehör – HATs, Monitor und USB-Peripherie

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «Accessories»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/accessories/)).

Diese Referenz behandelt das offizielle Zubehör, das **an die GPIO-Leiste, an USB oder an
die Stromversorgung geht** – und damit mit anderen Baugruppen kollidieren kann. Der
Schwerpunkt liegt auf den beiden Fragen, die im Entwurf früh geklärt werden müssen:
**welche GPIOs ist das Zubehör los?** und **woher kommt der Strom?**

Kameras stehen in `camera.md` (Software) und `component-catalog.md` (Auswahl), die
Hailo-Beschleuniger in `hailo.md`, Displays in `interfaces.md`, Masse und Stapelhöhe in
`mechanical.md`.

## Inhaltsverzeichnis
1. [🔴 Die GPIO-Landkarte des offiziellen Zubehörs](#-die-gpio-landkarte-des-offiziellen-zubehörs)
2. [Build HAT](#build-hat)
3. [Sense HAT](#sense-hat)
4. [Audio-Boards (DAC, DigiAMP+, Codec Zero)](#audio-boards-dac-digiamp-codec-zero)
5. [TV HAT](#tv-hat)
6. [Raspberry Pi Monitor](#raspberry-pi-monitor)
7. [USB-Zubehör](#usb-zubehör)

---

## 🔴 Die GPIO-Landkarte des offiziellen Zubehörs

Fast jedes HAT belegt mehr Pins, als sein Datenblatt auf den ersten Blick vermuten lässt.
Die folgende Übersicht ist dafür da, **vor der Beschaffung** zu erkennen, ob zwei geplante
Baugruppen überhaupt zusammenpassen.

| Zubehör | Belegte GPIOs (BCM) | Kollidiert typischerweise mit |
|---------|---------------------|-------------------------------|
| **Jedes HAT mit ID-EEPROM** | **0, 1** (ID_SD / ID_SC) | jedem anderen HAT – siehe Hinweis unten |
| **Build HAT** | 0, 1, **4, 14, 15, 16, 17** | UART-Konsole (14/15), 1-Wire (4), alles auf 16/17 |
| **Sense HAT** | 0, 1, **2, 3** (I²C) + Interrupt-Pin | anderen I²C-Geräten nur bei Adresskonflikt |
| **Audio-Boards (I²S)** | 0, 1, **2, 3, 18, 19, 20, 21** | SPI1 (16–21), PWM-Audio, Paralleldisplay |
| **TV HAT** | 0, 1, **SPI0 + Interrupt** | anderen SPI0-Teilnehmern (Chip-Selects) |

> ⚠️ **GPIO 0 und 1 sind kein freier Anwender-I²C.** Sie führen den ID-EEPROM-Bus, über den
> der Bootloader HATs erkennt und deren Overlay lädt. Wer sie im eigenen Entwurf für
> Sensoren zweckentfremdet, verhindert die HAT-Erkennung – und wer zwei HATs stapelt, hat
> zwangsläufig zwei EEPROMs auf demselben Bus. **HAT-Stapel funktionieren nur, wenn
> höchstens eines der Boards ein ID-EEPROM mitbringt** oder der Hersteller den Stapel
> ausdrücklich vorsieht.

➜ Der Reflex bei «zwei HATs gleichzeitig» ist deshalb nicht «passt der Stecker mechanisch»,
sondern **die beiden Pinlisten nebeneinanderlegen**. Passen sie nicht, sind die Auswege in
dieser Reihenfolge: anderes Interface wählen (USB statt GPIO), einen Bus verlegen (zweiter
I²C/SPI-Bus des RP1, siehe `rp1-gpio.md` und `interfaces.md`), oder das Gerät auf ein
zweites Board auslagern.

---

## Build HAT

Der **Raspberry Pi Build HAT** verbindet den Pi mit LEGO® Education-Motoren und -Sensoren
(vier Anschlüsse A–D) und ist damit der Standardweg für Robotik im Unterricht.

### 🔴 Zwei Einschränkungen, die Projekte kippen

> 🔴 **Der Build HAT wird auf Raspberry Pi OS Trixie (noch) nicht unterstützt.**
> Für Projekte mit Build HAT bleibt **Bookworm** die Zielplattform. Das ist eine
> Entscheidung, die den ganzen Software-Stack festlegt – Python-Version, verfügbare
> Pakete, Support-Zeitraum – und deshalb **an den Anfang** eines Bauplans gehört, nicht
> ans Ende. Wer den Rest des Projekts auf Trixie entwirft und den Build HAT zuletzt
> ansteckt, baut zweimal.

> ⚠️ **Der Build HAT braucht ein eigenes 8-V-Netzteil.** Das offizielle Build-HAT-Netzteil
> liefert **8 V / 48 W** über einen **DC-Hohlstecker (5,5 / 2,1 mm)**. Das USB-C-Netzteil
> des Pi genügt nicht: Motoren ziehen ihren Strom aus den 8 V, nicht aus der 5-V-Schiene.

### Stromversorgung – wer speist wen

| Aufbau | Ergebnis |
|--------|----------|
| Build HAT am 8-V-Netzteil, Pi ohne eigenes Netzteil | **Der Build HAT versorgt den Pi mit** – ein Netzteil genügt |
| Build HAT ohne 8-V-Netzteil, Pi am USB-C-Netzteil | Der Pi läuft, **Motoren laufen nicht** |
| Keyboard-Computer (Pi 400 / 500 / 500+) | 🔴 **Der Build HAT kann diese Geräte nicht mitversorgen** – sie brauchen ihr eigenes USB-C-Netzteil |

➜ **Für Klassensätze ist die erste Zeile der Punkt.** Ein Build HAT plus 8-V-Netzteil ersetzt
das Pi-Netzteil und halbiert die Steckdosen pro Arbeitsplatz. Bei Pi 400/500 gilt das nicht –
dort sind es immer zwei Netzteile.

### Belegte GPIOs

Der Build HAT nutzt **GPIO 0/1** (ID-EEPROM), **GPIO 4**, **GPIO 14/15** (serielle
Verbindung zum RP2040 auf dem HAT) sowie **GPIO 16/17**.

> ⚠️ **GPIO 14/15 sind die Konsolen-UART-Pins.** Wer beim Build HAT parallel eine serielle
> Konsole zum Debuggen erwartet (`configuration.md`), findet sie belegt. Für Diagnose am
> Build-HAT-Aufbau bleibt SSH oder Bildschirm – die serielle Konsole ist keine Option.

### Software

```bash
# Python-Bibliothek (in einer venv, siehe os-and-software.md)
pip install buildhat
```

```python
from buildhat import Motor

motor = Motor('A')
motor.run_for_seconds(2)
```

Beim allerersten Start lädt die Bibliothek die Firmware auf den RP2040 des HAT – der erste
Aufruf dauert deshalb spürbar länger als die folgenden. Das ist kein Fehler.

---

## Sense HAT

Der **Sense HAT** bündelt Sensorik, eine 8×8-RGB-Matrix und einen 5-Wege-Joystick auf einem
Board – der schnellste Weg zu einem Datenlogger ohne eigene Verdrahtung.

| Sensor | Sense HAT (v1) | Sense HAT v2 |
|--------|----------------|--------------|
| Feuchte / Temperatur | HTS221 | **SHTC3** |
| Luftdruck / Temperatur | LPS25H | **LPS22HB** |
| Beschleunigung, Gyroskop, Magnetometer | LSM9DS1 | LSM9DS1 |

Dazu **8×8 RGB-LED-Matrix** und **5-Wege-Joystick**.

```bash
sudo apt install sense-hat
```

```python
from sense_hat import SenseHat

sense = SenseHat()
sense.show_message("Hallo")
print(sense.get_temperature(), sense.get_pressure(), sense.get_humidity())
```

> 🔴 **Die Temperaturwerte des Sense HAT sind systematisch zu hoch.** Das Board sitzt
> unmittelbar über dem SoC und misst dessen Abwärme mit. Der Fehler ist keine Kleinigkeit –
> er liegt je nach Last und Gehäuse im Bereich mehrerer Grad und **wächst mit der
> CPU-Last**, ist also nicht durch einen festen Offset zu beseitigen.
>
> Brauchbare Gegenmittel, in dieser Reihenfolge:
> 1. **Sense HAT über Stiftleisten-Verlängerung absetzen** – die einzige Massnahme, die das
>    Problem an der Wurzel löst.
> 2. **Externer Sensor** (z.B. DS18B20 an 1-Wire) für die eigentliche Messgrösse; der Sense
>    HAT bleibt für Druck, Feuchte und Lage zuständig.
> 3. Korrektur gegen `vcgencmd measure_temp` – nur eine Näherung, für Messreihen mit
>    wechselnder Last unzureichend.
>
> ➜ **Für ein Projekt, dessen Zweck die Lufttemperatur ist, ist der Sense HAT ohne
> Absetzen das falsche Werkzeug.** Das gehört in die Anforderungsanalyse, nicht in die
> Fehlersuche.

Es gibt zusätzlich einen **Sense-HAT-Emulator** für die Entwicklung ohne Hardware – nützlich
für Klassensätze, in denen nicht jeder Platz ein Board hat.

---

## Audio-Boards (DAC, DigiAMP+, Codec Zero)

Die offiziellen Audio-Boards (aus der übernommenen IQaudIO-Reihe) hängen am **I²S-Bus** und
liefern deutlich besseren Klang als der PWM-Ausgang der älteren Modelle.

| Board | Zweck |
|-------|-------|
| **DAC Pro / DAC+** | Line-Out und Kopfhörer, hochwertiger DAC |
| **DigiAMP+** | Verstärker für passive Lautsprecher |
| **Codec Zero** | Ein- **und** Ausgang, Mikrofon, Pi-Zero-Formfaktor |

### Zwei Schritte, die immer nötig sind

```ini
# /boot/firmware/config.txt

# 1. Den eingebauten Audioausgang abschalten – sonst konkurrieren zwei Geräte
#dtparam=audio=on

# 2. Das passende Overlay laden (Beispiel DAC+/DAC Pro)
dtoverlay=iqaudio-dacplus
```

> ⚠️ **`dtparam=audio=on` muss auskommentiert werden.** Bleibt es stehen, tauchen zwei
> ALSA-Geräte auf, die Standardauswahl fällt auf das falsche, und der Ton kommt nicht dort
> heraus, wo er soll. Das ist die häufigste Fehlerursache nach dem Anstecken eines
> Audio-Boards – und sie sieht wie ein Hardwaredefekt aus.

### Der Stapelkonflikt

I²S belegt **GPIO 18, 19, 20 und 21**, dazu **GPIO 2/3** für die Steuerung über I²C und
**GPIO 0/1** für das ID-EEPROM.

> 🔴 **Das kollidiert direkt mit SPI1 und mit dem DPI-Paralleldisplay.** Ein Audio-Board und
> ein DPI-Display an derselben GPIO-Leiste schliessen sich aus (`interfaces.md`). Wer Ton
> und ein Display braucht, nimmt **HDMI-Audio** oder ein **USB-Audiointerface** – beides
> lässt die GPIO-Leiste frei.

➜ **Für Edge-AI-Projekte mit Sprachein- oder -ausgabe ist USB-Audio meist die robustere
Wahl.** Es kostet keine GPIOs, überlebt einen Modellwechsel des Pi und braucht kein
Overlay. Der I²S-Weg lohnt sich, wo Klangqualität oder Latenz das Ziel sind.

---

## TV HAT

Der **Raspberry Pi TV HAT** ist ein **DVB-T2-Empfänger** im halben HAT-Formfaktor
(Pi-Zero-Grösse, passt aber auf jede 40-polige Leiste). Er hängt am **SPI-Bus** und braucht
eine Antenne am MCX-Anschluss.

Als Server-Software ist **TVHeadend** vorgesehen; der Pi wird damit zum Netzwerk-Tuner, den
andere Geräte im Haushalt abfragen.

> ⚠️ **DVB-T2 ist regional.** Ob der TV HAT nutzbar ist, hängt vom Sendestandard am
> Standort ab – in Ländern ohne DVB-T/T2-Ausstrahlung ist das Gerät funktionslos. Das vor
> der Beschaffung prüfen, nicht danach.

---

## Raspberry Pi Monitor

Der **Raspberry Pi Monitor** ist ein 15,6-Zoll-IPS-Display (1920 × 1080) mit eingebauten
Lautsprechern, das über **HDMI** das Bild und über **USB-C** den Strom bekommt.

### 🔴 Die Stromfalle

> 🔴 **Aus dem USB-Anschluss eines Raspberry Pi versorgt, läuft der Monitor dauerhaft im
> Power-Saving-Modus.** Für die volle Helligkeit und Lautstärke braucht er **1,5 A** über
> USB-PD. Ein USB-A-Anschluss des Pi kann das nicht liefern – der Monitor funktioniert,
> aber mit gedeckelter Maximalhelligkeit und -lautstärke.

| Symptom | Ursache |
|---------|---------|
| Bild sichtbar, aber auffällig dunkel; Lautstärke lässt sich nicht hochdrehen | Power-Saving-Modus – Speisung liefert **< 1,5 A** |
| Monitor schaltet sich **wiederholt ein und aus** | Strom reicht nicht einmal für den Power-Saving-Modus |
| Kein Bild, Monitor bleibt dunkel | HDMI-Quelle prüfen, dann Stromversorgung |

➜ **Die Lösung ist immer dieselbe: ein eigenes USB-PD-Netzteil für den Monitor.** Den
Monitor aus dem Pi zu speisen ist bequem und für einen Prüfaufbau in Ordnung, für einen
Dauerarbeitsplatz aber die falsche Entscheidung. Bei einem Pi 5, der ohnehin an der
5-A-Grenze arbeitet (`setup-provisioning.md`), zieht der Monitor zusätzlich am selben
Budget – erst recht ein Grund für ein zweites Netzteil.

Die Lautstärke- und Helligkeitstasten sitzen am Gerät; eine VESA-Montage (100 mm) ist
vorgesehen.

---

## USB-Zubehör

### USB 3 Hub

Vier Anschlüsse, **USB 3.0 / 5 Gbit/s**, mit optionaler externer Speisung.

| Betriebsart | Verfügbarer Strom für alle vier Anschlüsse zusammen |
|-------------|----------------------------------------------------|
| **Bus-gespeist** (nur am Pi) | **900 mA (4,5 W)** – geteilt durch alle vier Ports |
| **Selbst-gespeist** (5 V / 3 A Netzteil) | **15 W** |

> 🔴 **Bus-gespeist ist ein einziges 900-mA-Budget, kein Budget pro Anschluss.** Zwei
> externe 2,5-Zoll-Festplatten am bus-gespeisten Hub sind ausserhalb der Spezifikation,
> auch wenn sie kurzzeitig funktionieren. Alles mit eigenem Motor oder eigenem Funkmodul
> gehört an den **selbst-gespeisten** Hub.

➜ Das Zusammenspiel mit dem USB-Strombudget des Pi selbst – und die Eigenheit, dass ein
USB-3.0-Hub Tastatur und Maus an den USB-2.0-Zweig durchreicht – steht in `interfaces.md`.

### Raspberry Pi Flash Drive

USB-3.2-Gen-1-Stick (Typ A) in **128 GB** und **256 GB**.

| Modell | Zufalls-IOPS lesen | Zufalls-IOPS schreiben |
|--------|-------------------|------------------------|
| 128 GB | ~16 000 | ~21 000 |
| 256 GB | ~18 000 | ~22 000 |

*Herstellerangaben.* Zur Einordnung: Das liegt **über einer guten SD-Karte, aber deutlich
unter NVMe** – die vollständige Leiter mit den Konsequenzen für Bootmedien steht in
`component-catalog.md`.

Der Stick unterstützt **SMART** über den SAT-Aufsatz:

```bash
sudo smartctl -d sat,12 -x /dev/sda
```

➜ **Das ist der eigentliche Mehrwert gegenüber einem beliebigen Stick:** Ein Medium, dessen
Verschleiss sich auslesen lässt, taugt für unbeaufsichtigten Dauerbetrieb – eines ohne SMART
fällt ohne Vorwarnung aus. Für Geräte im Feld gehört ein SMART-Auszug in die
Wartungsroutine (`debugging-playbook.md`).

### Tastatur und Maus

Die offizielle **Raspberry Pi Keyboard and Hub** bringt einen **eingebauten USB-2.0-Hub**
mit. Der ist für Maus und USB-Sticks gedacht – **nicht** für strombedürftige Geräte:
Das Budget teilt sich mit der Tastatur selbst, und der Hub hängt am USB-2.0-Zweig, nicht am
USB-3.0-Zweig des Pi.

> ⚠️ **Keine externe Festplatte an den Tastatur-Hub.** Der Fehler äussert sich als
> sporadisches Ab- und Wiederanmelden des Laufwerks unter Last, nicht als klarer Ausfall –
> und ist deshalb schwer zuzuordnen. Massenspeicher gehört direkt an den Pi oder an einen
> selbst-gespeisten Hub.

---

## Weitere Ressourcen

- [Raspberry Pi Accessories – offizielle Dokumentation](https://www.raspberrypi.com/documentation/accessories/)
- `interfaces.md` – USB-Strombudget, Hub-Eigenheiten, DPI-Display an der GPIO-Leiste
- `rp1-gpio.md` – Alternativfunktionen, zweite I²C-/SPI-Busse zum Ausweichen
- `mechanical.md` – Stapelhöhe, Abstandsbolzen, Betriebstemperatur des Stapels
- `hailo.md` – AI HAT+ und AI HAT+ 2 am PCIe-Anschluss
