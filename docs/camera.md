# Kamera-Software – rpicam-apps, libcamera, Post-Processing

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «Camera software»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/camera_software.html)).

Diese Referenz behandelt die Software-Seite der Kamera: Aufnahme, Konfiguration, Streaming
und das Post-Processing-Gerüst, über das Objekterkennung in die Kamerapipeline kommt. Für
Edge-AI-Projekte mit Bildverarbeitung ist der Abschnitt
[Post-Processing](#post-processing--der-einstieg-für-edge-ai) der wichtigste.

## Inhaltsverzeichnis
1. [🔴 Der Bruch: Der Legacy-Stack ist tot](#-der-bruch-der-legacy-stack-ist-tot)
2. [Die rpicam-Werkzeuge](#die-rpicam-werkzeuge)
3. [Vorschau, headless und SSH](#vorschau-headless-und-ssh)
4. [Bilder aufnehmen](#bilder-aufnehmen)
5. [Video – und der Encoder-Bruch beim Pi 5](#video--und-der-encoder-bruch-beim-pi-5)
6. [Hohe Bildraten](#hohe-bildraten)
7. [Kameras konfigurieren](#kameras-konfigurieren)
8. [Tuning-Dateien – und NoIR richtig](#tuning-dateien--und-noir-richtig)
9. [Mehrere Kameras und Software-Synchronisation](#mehrere-kameras-und-software-synchronisation)
10. [Post-Processing – der Einstieg für Edge AI](#post-processing--der-einstieg-für-edge-ai)
11. [Streaming über das Netz](#streaming-über-das-netz)
12. [Eigene Builds mit OpenCV, TFLite und Hailo](#eigene-builds-mit-opencv-tflite-und-hailo)
13. [Picamera2](#picamera2)
14. [USB-Webcam](#usb-webcam)
15. [Fehlersuche](#fehlersuche)

---

## 🔴 Der Bruch: Der Legacy-Stack ist tot

> **`raspistill`, `raspivid` und die ursprüngliche `picamera`-Bibliothek (nicht Picamera2)
> werden nicht mehr unterstützt.** Sie waren jahrelang als veraltet markiert und sind es
> jetzt endgültig. Der Legacy-Stack kennt **nur** Camera Module 1, Camera Module 2 und die
> HQ-Kamera – und wird **nie** neuere Module unterstützen.

Betroffen sind damit **Camera Module 3, Global Shutter Camera und AI Camera (IMX500)
vollständig**.

| Alt (unbrauchbar) | Neu |
|-------------------|-----|
| `raspistill` | `rpicam-still` / `rpicam-jpeg` |
| `raspivid` | `rpicam-vid` |
| `import picamera` | `from picamera2 import Picamera2` |

> ⚠️ **Ab Raspberry Pi OS Bookworm heissen die Programme `rpicam-*`.** Anleitungen aus der
> Zwischenzeit nennen sie `libcamera-*` – gemeint ist dasselbe.

➜ **Praxisregel für dieses Skill:** Eine Anleitung, ein Forenbeitrag oder ein
Codebeispiel, in dem `raspistill`, `raspivid` oder `import picamera` vorkommt, ist
**veraltet** – unabhängig davon, wie plausibel der Rest wirkt. Das ist der schnellste
Alterstest für Kamera-Material im Netz.

**Der Unterbau:** `libcamera` ist eine offene Bibliothek, die den Sensor und den
Bildsignalprozessor (ISP) ansteuert und eine C++-Schnittstelle bereitstellt. Sie
**kodiert und zeigt selbst nichts an** – dafür sind die `rpicam-apps` da. Darunter sitzt
ein Raspberry-Pi-eigener Pipeline-Handler mit den Bildverarbeitungsalgorithmen (AEC/AGC,
AWB, Objektivschattierung).

**Unterstützte Sensoren:** offiziell OV5647 (V1), IMX219 (V2), IMX708 (V3), IMX477 (HQ),
IMX500 (AI), IMX296 (GS); von Drittanbietern IMX290, IMX327, IMX378, IMX519, OV9281.

---

## Die rpicam-Werkzeuge

| Werkzeug | Zweck | In Raspberry Pi OS enthalten |
|----------|-------|------------------------------|
| `rpicam-hello` | Vorschau anzeigen – der «Funktionstest» | ✅ |
| `rpicam-jpeg` | Einzelbild aufnehmen, schlicht | ✅ |
| `rpicam-still` | Einzelbild mit vielen Optionen (Nachfolger von `raspistill`) | ✅ |
| `rpicam-vid` | Video aufnehmen | ✅ |
| `rpicam-raw` | Rohe Bayer-Bilder direkt vom Sensor | ✅ |
| **`rpicam-detect`** | Bild aufnehmen, **wenn ein Objekt erkannt wird** | 🔴 **Nein** – nur selbst gebaut mit TFLite |

Zwei Pakete: **`rpicam-apps`** (mit Desktop-Vorschau, in Raspberry Pi OS vorinstalliert) und
**`rpicam-apps-lite`** (nur DRM-Vorschau, in Raspberry Pi OS Lite vorinstalliert).

```bash
rpicam-hello                     # 5 Sekunden Vorschau
rpicam-hello --timeout 0         # unbegrenzt, Abbruch mit Strg+C
rpicam-hello --list-cameras      # welche Kameras, welche Sensormodi
rpicam-hello --version           # libcamera- und rpicam-apps-Version
```

**`--list-cameras` lesen:** Die Modusangabe hat die Form
`S<Bayer-Reihenfolge><Bit-Tiefe>_<Packung> : <Auflösungen>`; der Zuschnitt steht in
nativen Sensorpixeln als `(x, y)/Breite×Höhe`.

```
0 : imx477 [4056x3040] (/base/soc/i2c0mux/i2c@1/imx477@1a)
    Modes: 'SRGGB12_CSI2P' : 2028x1520 [40.01 fps - (0, 0)/4056x3040 crop]
                             4056x3040 [10.00 fps - (0, 0)/4056x3040 crop]
```

➜ **Das ist die verlässliche Quelle für erreichbare Bildraten.** Die HQ-Kamera liefert bei
voller Auflösung **10 fps** – wer 30 fps braucht, muss einen kleineren Modus wählen. Vor
jeder Aufwandsschätzung für eine Vision-Pipeline hier nachsehen, statt Datenblattwerte zu
übernehmen.

---

## Vorschau, headless und SSH

Die Vorschau nutzt **Zero-Copy-GPU-Pufferfreigabe** – ohne Desktop direkt über DRM, mit
Desktop über die Desktop-Umgebung.

> 🔴 **X-Weiterleitung wird nicht unterstützt.** Wer per `ssh -X` verbunden ist und
> `rpicam-hello` startet, bekommt keine Vorschau. Das ist kein Fehler, sondern eine Folge
> der Zero-Copy-Architektur.

```bash
rpicam-hello --qt-preview     # einzige Variante, die X-Weiterleitung kann – teuer
rpicam-hello -n               # gar keine Vorschau (--nopreview)
```

➜ **Für headless Aufbauten – also den Normalfall in diesem Skill – gehört `-n` in jeden
Aufruf.** Es spart zusätzlich CPU-Zeit, was bei hohen Bildraten zählt.

> ⚠️ Auf älteren Systemen mit Gtk2 und OpenCV kann die Qt-Vorschau mit
> `Glib-GObject`-Fehlern scheitern. Abhilfe: in `/etc/xdg/qt5ct/qt5ct.conf` als root
> `style=gtk2` durch `style=gtk3` ersetzen.

**Informationszeile** im Fenstertitel – nützlich zum Einrichten:

```bash
rpicam-hello --info-text "rot %rg, blau %bg, Fokus %focus, AF %afstate"
```

| Platzhalter | Bedeutung |
|-------------|-----------|
| `%frame` / `%fps` | Bildnummer / momentane Bildrate |
| `%exp` | Belichtungszeit in Mikrosekunden |
| `%ag` / `%dg` | Analoge / digitale Verstärkung |
| `%rg` / `%bg` | Rot- / Blauverstärkung |
| `%focus` | Schärfemass – **grösser ist schärfer** |
| `%lp` / `%afstate` | Objektivposition in Dioptrien / Autofokus-Zustand |

---

## Bilder aufnehmen

```bash
rpicam-jpeg --output test.jpg
rpicam-still --output test.jpg --timeout 2000 --width 640 --height 480
rpicam-still --encoding png --output test.png
```

> ⚠️ **Die Dateiendung bestimmt das Format nicht** – `--encoding` tut es. Eine Datei namens
> `bild.png`, aufgenommen ohne `--encoding png`, enthält ein JPEG.

Formate: `jpg`, `png`, `bmp`, `rgb`, `yuv420`. Qualität über `--quality` (Standard 93).

### Rohdaten (DNG)

```bash
rpicam-still --raw --output test.jpg     # erzeugt zusätzlich test.dng
```

Die DNG-Datei enthält die Sensordaten **ohne jede Verarbeitung** durch ISP oder CPU, dazu
Metadaten: Belichtungszeit, Schwarzwert, Weissabgleich-Verstärkungen und die vom ISP
verwendete Farbmatrix. Lesbar mit `dcraw`, RawTherapee oder `exiftool`.

> ℹ️ **Zwei Eigenheiten der Metadaten:**
> - Der **ISO-Wert ist das Hundertfache der analogen Verstärkung** – `ISO 400` bedeutet
>   Verstärkung 4.
> - Als Kalibrierungslichtquelle steht **immer `D65`**, unabhängig von der tatsächlichen
>   Beleuchtung. Das ist eine Eigenheit des AWB-Algorithmus, kein Messwert.

### Lange Belichtung

```bash
rpicam-still -o lang.jpg --shutter 100000000 --gain 1 --awbgains 1,1 --immediate
```

> ➜ **Die drei Zusätze sind nicht optional.** Ohne feste Werte für Verstärkung und
> Weissabgleich müssen AEC/AGC und AWB erst konvergieren – bei einer 100-Sekunden-Belichtung
> kostet das ein Vielfaches der eigentlichen Aufnahmezeit. `--immediate` überspringt die
> Vorschauphase ganz.

Die maximalen Belichtungszeiten stehen in der Hardware-Dokumentation der jeweiligen Kamera.

### Zeitraffer

```bash
mkdir timelapse
rpicam-still --timeout 30000 --timelapse 2000 -o timelapse/image%04d.jpg

sudo apt install ffmpeg
ffmpeg -r 10 -f image2 -pattern_type glob -i 'timelapse/*.jpg' \
       -s 1280x720 -vcodec libx264 timelapse.mp4
```

Für sehr lange Zeiträume ist ein `cron`-Eintrag robuster als ein tagelang laufender Prozess.

---

## Video – und der Encoder-Bruch beim Pi 5

```bash
rpicam-vid -t 10s -o test.h264
```

### 🔴 Der Pi 5 hat keinen Hardware-H.264-Encoder

> **Pi 4 und älter kodieren H.264 in Hardware. Der Pi 5 kodiert in Software.**

Das hat drei Folgen, die in der Projektplanung auftauchen müssen:

1. **CPU-Last.** Die Videokodierung belegt auf dem Pi 5 Rechenzeit, die auf dem Pi 4 der
   Hardwareblock übernommen hat. Bei einer Pipeline, die gleichzeitig Inferenz macht, ist
   das ein echter Posten im Budget.
2. **Latenz.** Die Software-Encoder liefern Einzelbilder später aus – für Echtzeit-Streaming
   spürbar.
3. **`--save-pts` gibt es auf dem Pi 5 nicht.** Stattdessen `libav` verwenden, das
   Zeitstempel für Containerformate selbst erzeugt.

```bash
rpicam-vid --low-latency -t 10s -o test.mp4
```

`--low-latency` unterdrückt B-Frames und Arithmetikkodierung. Preis: etwas schlechtere
Kompression und geringfügig ungünstigere Kernauslastung; 1080p30 bleibt problemlos
erreichbar.

### Container statt roher Bitstrom

```bash
rpicam-vid -t 10s -o test.mp4                    # Pi 5: MP4 direkt
rpicam-vid -t 10s --codec libav -o test.mp4      # Pi 4 und älter
```

> 🔴 **Neuere VLC-Versionen spielen rohe `.h264`-Dateien nicht mehr ab** – es erscheinen
> nur wenige oder verzerrte Bilder. Entweder `ffplay` verwenden oder gleich in einen
> Container schreiben. Rohe H.264-Ströme werden generell schlecht unterstützt.

**Weitere Codecs:** `--codec mjpeg`, `--codec yuv420`, `--codec libav`. Auch hier bestimmt
die Option das Format, nicht die Dateiendung.

**Nützliche Optionen für Dauerbetrieb:**

| Option | Wirkung |
|--------|---------|
| `--segment <ms>` | Ausgabe in Abschnitte zerlegen; mit `%05d` im Dateinamen kombinieren |
| `--circular [MB]` | Ringpuffer im Speicher, wird beim Beenden auf die Platte geschrieben |
| `--inline` | Sequenzkopf in **jedem** Keyframe – nötig bei `segment`, `split`, `circular` und Streaming |
| `--intra <n>` | Abstand der Keyframes (Standard 60) |
| `--signal` / `--keypress` | Aufnahme über `SIGUSR1` bzw. Eingabetaste starten und stoppen |
| `--initial pause` | Mit angehaltener Aufnahme starten |
| `--frames <n>` | Genau n Bilder – überschreibt `--timeout` |

➜ **`--circular` ist das Muster für eine Ereigniskamera:** Es läuft dauernd, verbraucht
keinen Plattenplatz, und beim Auslösen liegen die Sekunden **vor** dem Ereignis vor.

---

## Hohe Bildraten

Für Aufnahmen über 60 fps empfiehlt die Dokumentation fünf Massnahmen – vier davon
betreffen andere Referenzen dieses Skills:

```bash
rpicam-vid --level 4.2 --framerate 120 --width 1280 --height 720 \
           --denoise cdn_off -n -t 10000 -o video.264
```

| Massnahme | Wo |
|-----------|-----|
| H.264-Level auf `4.2` setzen | `--level 4.2` |
| Farbrauschunterdrückung abschalten | `--denoise cdn_off` |
| Vorschau abschalten | `-n` |
| **`force_turbo=1`** – verhindert Drosselung des CPU-Takts während der Aufnahme | `config.txt` (siehe `config-txt.md`) |
| Auflösung senken | `--width 1280 --height 720` oder kleiner |
| **Pi 4:** GPU übertakten (`gpu_freq=550`) | `config.txt` |

> ⚠️ **`force_turbo=1` hat Nebenwirkungen.** In Verbindung mit einer `over_voltage_*`-
> Einstellung > 0 setzt es das dauerhafte Übertaktungsbit im SoC (`config-txt.md`).
> Ausserdem läuft der Chip dauerhaft auf Höchsttakt – bei einem Gerät ohne aktive Kühlung
> ist das kontraproduktiv, weil die thermische Drosselung dann umso früher greift.

**Bildaussetzer** lassen sich zusätzlich über `--buffer-count` verringern (Standard: 1 für
Standbilder, 6 für Video).

---

## Kameras konfigurieren

Im Normalfall ist **keine** Konfiguration nötig – `camera_auto_detect=1` steht in
Raspberry Pi OS voreingestellt und lädt das passende Overlay automatisch.

Konfiguration wird nötig bei Drittanbieter-Kameras oder wenn ein bestimmtes Overlay
erzwungen werden soll:

| Modul | `config.txt` |
|-------|--------------|
| V1 (OV5647) | `dtoverlay=ov5647` |
| V2 (IMX219) | `dtoverlay=imx219` |
| HQ (IMX477) | `dtoverlay=imx477` |
| GS (IMX296) | `dtoverlay=imx296` |
| Camera Module 3 (IMX708) | `dtoverlay=imx708` |
| IMX290 / IMX327 | `dtoverlay=imx290,clock-frequency=74250000` **oder** `37125000` |
| IMX378 | `dtoverlay=imx378` |
| OV9281 | `dtoverlay=ov9281` |

> 🔴 **Ein explizites `dtoverlay` wirkt nur mit `camera_auto_detect=0`.** Wer die
> Overlay-Zeile einträgt und die Automatik stehen lässt, wundert sich, warum sich nichts
> ändert. Danach neu starten.

> ⚠️ **IMX290 und IMX327 teilen sich denselben Treiber**, brauchen aber je nach Modul
> unterschiedliche Taktfrequenzen. Der richtige Wert steht in der Anleitung des
> Modulherstellers – raten führt zu einem Sensor, der sich nicht meldet.

**Zwei Kameraanschlüsse** (Pi 5, Compute Modules): `,cam0` an das Overlay anhängen wählt
Anschluss 0; ohne Zusatz wird Anschluss 1 geprüft.

```ini
camera_auto_detect=0
dtoverlay=imx477,cam0
```

> ℹ️ Für **offizielle** Kameramodule an gewöhnlichen Pi-Boards (keine Compute Modules)
> erkennt die Automatik alle angeschlossenen Kameras korrekt – auch an beiden Anschlüssen.

---

## Tuning-Dateien – und NoIR richtig

Jede Kamera hat eine Tuning-Datei, die Algorithmen und Hardware für die beste Bildqualität
einstellt. **libcamera erkennt nur den Sensor, nicht das Modul** – deshalb brauchen manche
Module eine abweichende Datei.

### 🔴 NoIR-Kameras: die Tuning-Datei, nicht `awb_auto_is_greyworld`

> **`rpicam-apps` kann den automatischen Weissabgleich nicht in den Greyworld-Modus
> versetzen.** Die `config.txt`-Option `awb_auto_is_greyworld` gehört zum alten
> Firmware-Pfad und wirkt auf den modernen Kamera-Stack **nicht**. Der richtige Weg ist
> eine NoIR-Tuning-Datei.

```bash
# Pi 5 und neuer
rpicam-hello --tuning-file /usr/share/libcamera/ipa/rpi/pisp/imx219_noir.json

# Pi 4 und älter
rpicam-hello --tuning-file /usr/share/libcamera/ipa/rpi/vc4/imx219_noir.json
```

> ⚠️ **Der Pfad unterscheidet sich nach Modell:** `pisp/` ab Pi 5, `vc4/` davor. Eine aus
> einer Anleitung übernommene Zeile schlägt auf dem jeweils anderen Modell fehl.

Tuning-Dateien lassen sich kopieren und anpassen, um das Kameraverhalten dauerhaft zu
verändern. libcamera pflegt auch Dateien für Module von Drittanbietern.

---

## Mehrere Kameras und Software-Synchronisation

**Anschlussmöglichkeiten:**

| Weg | Gleichzeitiger Betrieb |
|-----|------------------------|
| Compute Module I/O Board – zwei Anschlüsse | ✅ |
| **Pi 5 – zwei MIPI-Anschlüsse** | ✅ |
| Video-Mux-Platine an einem Anschluss | 🔴 **Nein – immer nur eine Kamera** |

```bash
rpicam-hello --list-cameras
rpicam-vid --camera 1 -o kamera1.mp4
```

> 🔴 **libcamera hat keine Stereo-Unterstützung.** Zwei gleichzeitig laufende Kameras
> müssen in **getrennten Prozessen** betrieben werden, und es gibt keine Möglichkeit,
> AEC/AGC und AWB zwischen ihnen abzugleichen. Für gleiche Belichtung beider Bilder müssen
> die Algorithmen auf manuell gestellt werden.

### Software-Synchronisation

Neuere Funktion: Kameras gleichen ihre Bildzeitpunkte **ohne Verkabelung** ab – über das
Netzwerk, auch modellübergreifend und über mehrere Pi hinweg.

```bash
# Client ZUERST starten – er wartet, bis ein Server sendet
rpicam-vid -n -t 20s --camera 1 --codec libav -o client.mp4 --sync client

# Dann der Server
rpicam-vid -n -t 20s --camera 0 --codec libav -o server.mp4 --sync server
```

**Funktionsweise:** Ein Server sendet in festem Takt (Standard: einmal pro Sekunde)
Zeitnachrichten ins Netz. Clients verlängern oder verkürzen einzelne Bilddauern, bis sie
zum Server passen. Nach einer festen Anzahl Bilder (Standard 100) erreichen beide den
**Synchronisationspunkt** – erst ab dann wird aufgezeichnet.

| Konstellation | Erreichbare Abweichung |
|---------------|------------------------|
| Gleiches Modell, gleicher Pi | **einige zehn Mikrosekunden** |
| Verschiedene Modelle | deutlich mehr – die Bildraten driften laufend auseinander |
| Verschiedene Geräte | zusätzlich der Fehler der Systemuhren |

> ⚠️ **Drei Fallstricke:**
> 1. **Es gibt keinen Rückkanal.** Der Server weiss nicht, ob Clients synchronisiert sind –
>    oder ob überhaupt welche existieren. Deshalb **Clients zuerst starten**.
> 2. **Die Bildrate muss unter dem Maximum des gewählten Modus liegen.** Der Algorithmus
>    muss Bilder **verkürzen** können; läuft die Kamera schon am Anschlag, scheitert das.
> 3. **Über mehrere Geräte hinweg müssen die Systemuhren stimmen.** NTP ist in Raspberry Pi
>    OS voreingestellt; wo das nicht genügt, braucht es PTP. Ein Uhrenversatz geht direkt in
>    den Fehler ein – **und die Zeitstempel der Bilder verraten das nicht**.

---

## Post-Processing – der Einstieg für Edge AI

Alle `rpicam-apps` teilen ein Post-Processing-Gerüst. Die Bilder durchlaufen eine Kette von
**Stages**, die über eine JSON-Datei konfiguriert wird.

```json
{
    "sobel_cv": { "ksize": 5 },
    "negate": {}
}
```

```bash
rpicam-hello --post-process-file stages.json
```

### 🔴 OpenCV- und TFLite-Stages fehlen in der Auslieferung

> **Die mit Raspberry Pi OS gelieferten `rpicam-apps` enthalten weder OpenCV noch
> TensorFlow Lite.** Alle Stages mit `_cv`- oder `_tf`-Bezug sind deshalb **deaktiviert**.
> Wer sie braucht, muss `rpicam-apps` neu übersetzen (siehe unten).

Ohne Neuübersetzung nutzbar:

| Stage | Zweck |
|-------|-------|
| `negate` | Hell/Dunkel umkehren – das Minimalbeispiel |
| `hdr` | HDR und Dynamikkompression (DRC) |
| **`motion_detect`** | **Bewegungserkennung – ohne jede Fremdbibliothek** |

Nach Neuübersetzung zusätzlich: `sobel_cv`, `face_detect_cv`, `annotate_cv`,
`object_classify_tf`, `object_detect_tf`, `pose_estimation_tf`, `segmentation_tf`,
`plot_pose_cv`, `object_detect_draw_cv`.

### Der Niedrigauflösungs-Strom – das zentrale Muster

Die Kamera liefert **parallel einen zweiten, kleineren Bildstrom** (`--lores-width`,
`--lores-height`). Die Analyse läuft darauf, die Ausgabe bleibt in voller Auflösung.

```bash
# Bewegungserkennung auf 128×96 – vernachlässigbare Last
rpicam-hello --lores-width 128 --lores-height 96 --post-process-file motion_detect.json

# Objekterkennung auf 300×300 (MobileNet SSD), Ausgabe in voller Auflösung
rpicam-hello --lores-width 400 --lores-height 300 --post-process-file object_detect_tf.json
```

➜ **Das ist die Architektur, die jede Vision-Pipeline auf dem Pi haben sollte:** Modelle
arbeiten ohnehin auf kleinen Eingaben (224×224, 257×257, 300×300). Ein Modell auf dem
Vollbild laufen zu lassen und selbst zu skalieren, verschenkt Rechenzeit an eine
Skalierung, die der ISP kostenlos mitliefert.

**Typische Eingabegrössen der mitgelieferten Stages:**

| Stage | Auflösung |
|-------|-----------|
| `object_classify_tf` | 224×224 |
| `pose_estimation_tf`, `segmentation_tf` | 257×257 → **258×258 wählen** (YUV420 braucht gerade Masse) |
| `object_detect_tf` | 300×300 |
| `face_detect_cv` | zwischen 320×240 und 640×480 |

> ⚠️ **`face_detect_cv` läuft nur bei Vorschau und Videoaufnahme**, nicht bei
> Standbildaufnahme.

> ⚠️ Bei `rpicam-vid` schaltet ein Niedrigauflösungs-Strom die zusätzliche
> Farbrauschunterdrückung ab.

### Bewegungserkennung ohne Fremdbibliotheken

`motion_detect` vergleicht eine Bildregion mit dem vorherigen Bild und schreibt das Ergebnis
in die Metadaten unter `motion_detect.result`.

```json
{
    "motion_detect": {
        "roi_x": 0.1, "roi_y": 0.1, "roi_width": 0.8, "roi_height": 0.8,
        "difference_m": 0.1, "difference_c": 10,
        "region_threshold": 0.005,
        "frame_period": 5, "hskip": 2, "vskip": 2
    }
}
```

➜ **Für ein batteriebetriebenes oder thermisch begrenztes Feldgerät ist das der richtige
Vorfilter:** Die teure Inferenz läuft erst, wenn sich überhaupt etwas bewegt hat.
`hskip`/`vskip` senken die Last zusätzlich durch Unterabtastung.

### Eigene Stages schreiben

Abgeleitet von `PostProcessingStage`, registriert über `RegisterStage`, eingetragen in
`meson.build`. Vier Hinweise aus der Dokumentation, die über die Brauchbarkeit entscheiden:

> 🔴 **`Process()` blockiert die Bildpipeline.** Ein zu langsamer Aufruf lässt die Aufnahme
> stocken. Alles Zeitaufwendige gehört in einen eigenen Thread – und dorthin muss der
> Bildpuffer **kopiert** werden.

- Für TFLite-Stages von `TfStage` ableiten – die Klasse lagert die Modellausführung bereits
  in einen eigenen Thread aus.
- Das Gerüst verarbeitet Bilder ohnehin parallel. OpenCV und TFLite bringen **innerhalb**
  eines Bildes nochmals Parallelität mit – diese besser serialisieren.
- Die Ströme liefern **YUV420**; für viele OpenCV- und TFLite-Funktionen ist eine
  Umwandlung nötig. Bilder möglichst **an Ort und Stelle** verändern.

---

## Streaming über das Netz

> **Empfehlung der Dokumentation: für praktisch alle Anwendungen den `libav`-Unterbau
> verwenden und einen MPEG-2-Transportstrom senden.** Roher H.264 wird von vielen Playern
> schlecht oder gar nicht unterstützt.

```bash
# UDP – MPEG-TS (empfohlen)
rpicam-vid -t 0 -n --codec libav --libav-format mpegts -o udp://<ip>:<port>
vlc udp://@:<port>

# TCP – der Pi wartet auf den Client
rpicam-vid -t 0 -n --codec libav --libav-format mpegts -o "tcp://0.0.0.0:<port>?listen=1"
vlc tcp://<server-ip>:<port>

# RTSP über VLC als Server
rpicam-vid -t 0 -n --codec libav --libav-format mpegts -o - \
  | cvlc stream:///dev/stdin --sout '#rtp{sdp=rtsp://:8554/stream1}'
```

Wiedergabe mit geringer Verzögerung: `ffplay <url> -fflags nobuffer -flags low_delay -framedrop`

**Audio** hinzufügen (nur in Formaten, die es zulassen – etwa MPEG-TS):

```bash
rpicam-vid -t 0 --codec libav --libav-format mpegts --libav-audio -o "udp://<ip>:<port>"
pactl list | grep -A2 'Source #' | grep 'Name: '     # verfügbare ALSA-Quellen
```

### MediaMTX – der bequemste Weg

MediaMTX unterstützt Raspberry-Pi-Kameras **nativ**, ohne `rpicam-vid` als externen Prozess:

```yaml
paths:
  cam:
    source: rpiCamera
    sourceOnDemand: yes      # Kamera erst belegen, wenn jemand zusieht
```

Abruf über `rtsp://<server>:8554/cam` oder im Browser über `http://<server>:8889/cam`
(WebRTC).

Alternativ `rpicam-vid` extern laufen lassen – dann bleibt die Möglichkeit,
Post-Processing-Stages oder Picamera2 dazwischenzuschalten:

```yaml
paths:
  cam:
    source: udp://127.0.0.1:1234
```

```bash
rpicam-vid -t 0 -n --codec libav --low-latency --libav-format mpegts \
           -o udp://127.0.0.1:1234?pkt_size=1316
```

> ⚠️ **Aussetzer im Strom kommen oft von zu kleinen UDP-Empfangspuffern.**
>
> ```
> net.core.rmem_default=1000000
> net.core.rmem_max=1000000
> ```
>
> Diese Zeilen gehören in `/etc/sysctl.d/99-network-tuning.conf` – **unter Bookworm
> stattdessen direkt in `/etc/sysctl.conf`**. Danach `sudo sysctl -p <datei>` oder neu
> starten.

Weitere geprüfte Server: **MistServer** und **go2rtc**. Beide nehmen einen MPEG-TS-Strom von
`rpicam-vid` entgegen; native Kameraunterstützung hat nur MediaMTX.

---

## Eigene Builds mit OpenCV, TFLite und Hailo

Nötig für OpenCV-/TFLite-/Hailo-Stages, für `rpicam-detect` und für eigene Stages.

```bash
# ZUERST die vorinstallierte Fassung entfernen
sudo apt remove --purge rpicam-apps

# Abhängigkeiten (ohne libcamera neu zu bauen)
sudo apt install -y libcamera-dev libepoxy-dev libjpeg-dev libtiff5-dev libpng-dev libopencv-dev
sudo apt install -y cmake libboost-program-options-dev libdrm-dev libexif-dev meson ninja-build

git clone https://github.com/raspberrypi/rpicam-apps.git
cd rpicam-apps
```

**Für Raspberry Pi OS Lite / headless:**

```bash
meson setup build -Denable_libav=disabled -Denable_drm=enabled -Denable_egl=disabled \
  -Denable_qt=disabled -Denable_opencv=enabled -Denable_tflite=enabled -Denable_hailo=enabled
meson compile -C build
sudo meson install -C build
sudo ldconfig
rpicam-still --version        # Datum des eigenen Builds prüfen
```

| Flag | Zweck |
|------|-------|
| `-Denable_opencv=enabled` | OpenCV-Stages – **erfordert installiertes OpenCV** |
| `-Denable_tflite=enabled` | TFLite-Stages |
| **`-Denable_hailo=enabled`** | **HailoRT-Stages – erfordert installiertes HailoRT** |
| `-Ddownload_hailo_models=true` | Modelle für die Hailo-Stages mitladen (Standard) |
| `-Dneon_flags=armv8-neon` | Beschleunigung auf Pi 3/4 unter einem **32-Bit**-OS |

Jedes Flag kennt `enabled` (Fehlschlag, wenn Abhängigkeit fehlt), `disabled` und `auto`.

> ℹ️ **TensorFlow Lite kommt ab Raspberry Pi OS Trixie als Paket:**
> `sudo apt install libtensorflow-lite-dev`. Danach `rpicam-apps` neu übersetzen.

> ⚠️ **Auf Geräten mit 1 GB Speicher oder weniger** kann der Build den Speicher sprengen –
> `-j 1` anhängen (Pi Zero, Pi 3).

> ⚠️ **`libcamera` muss nur in Ausnahmefällen selbst gebaut werden.** Wenn doch: Es hat
> **keine stabile Binärschnittstelle** – nach jedem libcamera-Build muss `rpicam-apps`
> ebenfalls neu übersetzt werden.

---

## Picamera2

Die Python-Schnittstelle zum modernen Stack – Nachfolger der alten `picamera`-Bibliothek.

```bash
sudo apt install -y python3-picamera2                        # mit GUI-Abhängigkeiten
sudo apt install -y python3-picamera2 --no-install-recommends # ohne
```

> 🔴 **Nicht über `pip` installieren.** Wer das früher getan hat:
> `pip3 uninstall picamera2`. Picamera2 gehört zu den Paketen, die über `apt` kommen –
> passend zur Regel aus `os-and-software.md`.

Aktuelle Raspberry-Pi-OS-Abbilder bringen Picamera2 mit; die Lite-Abbilder ohne
GUI-Abhängigkeiten, Vorschau dort über DRM/KMS.

---

## USB-Webcam

Wo keine Bildqualität und keine Steuerung nötig ist, genügt oft eine USB-Kamera.

```bash
sudo apt install fswebcam
sudo usermod -a -G video <benutzer>     # sonst: «permission denied»
# neu anmelden, dann prüfen mit: groups

fswebcam -r 1280x720 --no-banner bild.jpg
```

> ⚠️ **Ohne `-r` nimmt `fswebcam` eine sehr niedrige Auflösung** und blendet einen
> Zeitstempel-Balken ein. Beides muss man aktiv abstellen.

`fswebcam` kennt **keine** Platzhalter im Dateinamen – dafür braucht es ein Skript:

```bash
#!/bin/bash
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
fswebcam -r 1280x720 --no-banner "$DATE.jpg"
```

Zeitraffer über `crontab -e`, etwa `* * * * * /home/<benutzer>/webcam.sh 2>&1`.

---

## Fehlersuche

### Vorschau bleibt schwarz oder zerfällt

| Modell | Grenze der Grafikhardware |
|--------|---------------------------|
| Pi 3 und älter | **2048 × 2048 Pixel** |
| Pi 4 | **4096 × 4096 Pixel** |

> ➜ **Videoaufnahme oberhalb dieser Breite erzeugt fehlerhafte oder fehlende
> Vorschaubilder** – die Aufnahme selbst ist davon nicht betroffen. Mit `-n` verschwindet
> das Problem. Bildrisse («tearing») in einer Desktop-Umgebung sind bekannt und nicht
> behebbar.

### Kamera wird gar nicht erkannt

1. **FFC-Kabel prüfen:** fest und gerade eingesteckt, Kontakte in der richtigen Richtung.
2. 🔴 **CSI statt DSI.** Beide Anschlüsse nehmen dasselbe Kabel auf, aber **nur der
   CSI-Anschluss versorgt und steuert die Kamera**. Die Beschriftung steht auf der Platine.
3. **Software aktualisieren.**
4. **Netzteil:** Ein Kameramodul zieht zusätzlich **200–250 mA**. Bei knappem Netzteil ist
   die Kamera das Erste, was ausfällt – siehe auch `setup-provisioning.md`.

### Defektpixelkorrektur der HQ-Kamera

Der `imx477`-Treiber aktiviert die sensorseitige Korrektur (DPC) voreingestellt:

```bash
sudo echo 0 > /sys/module/imx477/parameters/dpc_enable
```

➜ Relevant bei Astrofotografie und wissenschaftlichen Aufnahmen, wo die Korrektur echte
Signale wegrechnen kann.

### Fehlerbericht vorbereiten

Vor einer Frage im Forum oder einem Issue bereitlegen:

```bash
uname -a
rpicam-hello --version
rpicam-hello --list-cameras
```

Dazu: Kameramodell, Pi-Modell samt Speichergrösse und die Konsolenausgabe.

### Was es in `rpicam-apps` nicht mehr gibt

Aus `raspicam` entfallen ersatzlos oder mit anderem Weg:

| Entfallen | Ersatz |
|-----------|--------|
| `--annotate` | Post-Processing-Stage `annotate_cv` |
| `--imxfx`, `--colfx`, `--opacity` | Post-Processing |
| `--drc` | Post-Processing-Stage `hdr` |
| `--vstab` (Bildstabilisierung) | – |
| `--stereo`, `--3dswap` | – |
| `--ISO` | Entsprechende Verstärkung über `--gain` selbst ausrechnen |
| Flimmerperiode | – |
| Serienbild (`burst`) | `rpicam-vid --codec mjpeg --segment 1` |
| Drehung um 90°/270° | Nur 0° und 180° (`--rotation`) |

> ⚠️ **`raspicam` vermischte Messmethode und Belichtung** – `rpicam-apps` trennt beides
> (`--metering` und `--exposure`). Wer eine alte Zeile übersetzt, muss das auseinanderhalten.

> ⚠️ **Mehrbuchstabige Kurzoptionen gibt es nicht mehr.** Die Langformen heissen gleich,
> einzelne Kurzbuchstaben blieben erhalten.

---

## Weitere Ressourcen

- [Camera software](https://www.raspberrypi.com/documentation/computers/camera_software.html)
- [Picamera2-Handbuch](https://github.com/raspberrypi/picamera2)
- [rpicam-apps](https://github.com/raspberrypi/rpicam-apps) – Quelltext, Beispiel-JSONs unter `assets/`
- [Tuning guide für Raspberry-Pi-Kameras und libcamera](https://datasheets.raspberrypi.com/camera/raspberry-pi-camera-guide.pdf)
- `edge-ai.md` – Hailo, Ollama, TFLite und die Modellauswahl
- `config-txt.md` – `camera_auto_detect`, `force_turbo`, Overlays
- `component-catalog.md` – Kameramodule mit Bezugsquellen
