# Hailo-NPU – Hardware, Installation, Vision und lokale LLMs

Quelle: **Offizielle Raspberry-Pi-Dokumentation, «AI software»**
([raspberrypi.com/documentation](https://www.raspberrypi.com/documentation/computers/ai.html)).

Diese Referenz beschreibt den **offiziell unterstützten** Weg, eine Hailo-NPU am Pi 5 zu
betreiben – von der Hardwarewahl über die Installation bis zu Objekterkennung und lokal
laufenden Sprachmodellen. `edge-ai.md` ordnet ein, **welcher** Beschleuniger und welches
Modell zu einem Projekt passen; hier steht, **wie** es aufgesetzt wird.

## Inhaltsverzeichnis
1. [Drei Hardwarevarianten – und was sie können](#drei-hardwarevarianten--und-was-sie-können)
2. [Voraussetzungen](#voraussetzungen)
3. [PCIe Gen 3 – der eine dokumentierte Ausnahmefall](#pcie-gen-3--der-eine-dokumentierte-ausnahmefall)
4. [Installation](#installation)
5. [Überprüfen](#überprüfen)
6. [Vision-Modelle sofort nutzen](#vision-modelle-sofort-nutzen)
7. [🔴 Versionen festhalten](#-versionen-festhalten)
8. [Lokale LLMs auf dem AI HAT+ 2](#lokale-llms-auf-dem-ai-hat-2)
9. [Open WebUI über Docker](#open-webui-über-docker)
10. [Fehlersuche](#fehlersuche)

---

## Drei Hardwarevarianten – und was sie können

| Variante | NPU | Vision | **GenAI / LLM** | Status |
|----------|-----|--------|-----------------|--------|
| **AI Kit** (M.2 HAT+ mit vorinstalliertem Modul) | Hailo-8L | ✅ | ❌ | 🔴 **Nicht mehr in Produktion** |
| **AI HAT+** | Hailo-8L **oder** Hailo-8 | ✅ | ❌ | Empfohlen |
| **AI HAT+ 2** | **Hailo-10H** + **8 GB eigener Speicher** | ✅ | ✅ **LLMs und VLMs** bis ~6 Mrd. Parameter | Empfohlen |

> ➜ **Der Unterschied ist nicht nur der Chip, sondern der Speicher.** Das AI HAT+ 2 trägt
> **8 GB eigenen Arbeitsspeicher auf dem HAT**. Die Modellgewichte liegen dort, nicht im RAM
> des Pi. Daraus folgt eine Beschaffungsregel, die dem Reflex widerspricht:
> **Für GenAI ist das AI HAT+ 2 an einem 4-GB-Pi 5 die bessere Wahl als ein 16-GB-Pi 5
> ohne HAT** – der grosse Pi kauft CPU-Inferenz, der HAT kauft NPU-Inferenz mit eigenem
> Speicher.

> ⚠️ **Kühlung: Heatsink *und* Active Cooler.** Dem AI HAT+ 2 liegt ein eigener Kühlkörper
> für den Hailo-10H bei – er ersetzt **nicht** die Kühlung des Pi. Beide sind nötig; die
> Temperaturgrenze des Stapels richtet sich weiterhin nach der niedrigsten Angabe aller
> Komponenten (`mechanical.md`).

> ➜ **Für neue Projekte kein AI Kit mehr einplanen.** Raspberry Pi empfiehlt für neue
> Entwürfe ausdrücklich AI HAT+ oder AI HAT+ 2. Vorhandene Kits funktionieren weiter.

> 🔴 **Nur das AI HAT+ 2 kann Sprachmodelle.** Wer lokale LLMs auf der NPU laufen lassen
> will, braucht den **Hailo-10H** – Hailo-8 und Hailo-8L können ausschliesslich Vision.
> Das ist eine **Beschaffungsentscheidung**, die sich später nicht per Software korrigieren
> lässt und deshalb in die Anforderungsanalyse gehört.

Für Vision-Language-Modelle und weitere GenAI-Aufgaben verweist die Dokumentation auf
Hailos eigenes Repository `hailo-apps`.

---

## Voraussetzungen

- **Raspberry Pi 5**
- **Raspberry Pi OS Trixie, 64 Bit** – ausdrücklich genannt
- Eine der drei Hardwarevarianten oben
- Für Vision zusätzlich eine unterstützte Kamera (z.B. Camera Module 3)

> ⚠️ **Reihenfolge beim Zusammenbau: erst die Kamera anschliessen, dann die AI-Hardware.**
> Der HAT deckt den Kameraanschluss ab; wer ihn zuerst montiert, muss ihn wieder abbauen.
> Zwischen den Schritten bleibt das Gerät **stromlos**.

➜ Mechanik, Kühlung und die Temperaturgrenze des Stapels stehen in `mechanical.md` und
`pcie.md`; die 0–50-°C-Grenze des M.2 HAT+ gilt für den ganzen Aufbau.

---

## PCIe Gen 3 – der eine dokumentierte Ausnahmefall

Der Skill hält an mehreren Stellen fest, dass **Gen 2 die Spezifikation und Gen 3 ein
Opt-in auf eigenes Risiko** ist. Für die Hailo-Hardware differenziert die offizielle
Dokumentation das:

| Hardware | Gen 3 |
|----------|-------|
| **AI Kit** | **Ausdrücklich empfohlen** – muss von Hand aktiviert werden |
| **AI HAT+** und **AI HAT+ 2** | Wird **automatisch** gesetzt – nichts zu tun |

```bash
sudo raspi-config     # 6 Advanced Options → A8 PCIe Speed → Yes
sudo reboot
# entspricht: dtparam=pciex1_gen=3 in /boot/firmware/config.txt
```

> ➜ **Das ist die einzige Konstellation, in der Raspberry Pi selbst zu Gen 3 rät.** Der
> Widerspruch zur allgemeinen Warnung (`pcie.md`) ist keiner: Bei der eigenen AI-Hardware
> ist die Signalstrecke bekannt und geprüft. Für **beliebige** PCIe-Geräte bleibt es beim
> Opt-in ohne Zusage.
>
> Bleibt es bei einem AI Kit trotzdem instabil – sporadische Aussetzer, AER-Meldungen in
> `dmesg` –, ist Zurückstellen auf Gen 2 weiterhin der erste Diagnoseschritt. Die NPU
> läuft auch dort, nur langsamer angebunden.

---

## Installation

### Schritt 1: System und Firmware aktualisieren

```bash
sudo apt update
sudo apt full-upgrade -y
sudo rpi-eeprom-update -a
sudo reboot
```

> ⚠️ **`rpi-eeprom-update -a` gehört ausdrücklich dazu.** Der Bootloader wird hier
> mitaktualisiert – das ist mehr als das übliche `full-upgrade` (siehe
> `configuration.md`).

### 🔴 Schritt 2: Das richtige Paket – und nur eines

```bash
sudo apt install dkms

# AI Kit und AI HAT+ (Hailo-8L / Hailo-8)
sudo apt install hailo-all

# AI HAT+ 2 (Hailo-10H)
sudo apt install hailo-h10-all
```

> 🔴 **`hailo-all` und `hailo-h10-all` können nicht nebeneinander bestehen.** Wer die
> Hardware wechselt, muss das alte Paket entfernen. Beide zu installieren scheitert oder
> hinterlässt ein defektes System.

Die Pakete bringen alles Nötige mit:

| Bestandteil | Zweck |
|-------------|-------|
| Hailo-Kerneltreiber und Firmware | Ansprache der NPU über PCIe |
| **HailoRT** | Laufzeitumgebung |
| **Hailo Tappas Core** | Post-Processing-Bibliotheken |

> 🔴 **Korrektur gegenüber verbreiteten Anleitungen:** Die Installation läuft **über
> `apt`** – nicht über eine von Hailos Website geladene `.deb`-Datei und nicht über
> `pip install hailort`. Die Paketquelle von Raspberry Pi liefert aufeinander abgestimmte
> Versionen von Treiber, Laufzeit und Post-Processing; von Hand zusammengesuchte
> Komponenten passen leicht nicht zueinander (siehe
> [Versionen festhalten](#-versionen-festhalten)).

> ⚠️ **`dkms` ist die Voraussetzung dafür, dass der Kerneltreiber Kernel-Updates
> übersteht.** Damit gilt hier alles aus `kernel.md`: Passen die Kernel-Header nicht zum
> laufenden Kernel, scheitert der Neubau **still** – das Gerät bootet, die NPU ist weg.

### Schritt 3: Neu starten

```bash
sudo reboot
```

---

## Überprüfen

```bash
hailortcli fw-control identify
```

```
Executing on device: 0000:01:00.0
Firmware Version: 4.17.0 (release,app,extended context switch buffer)
Board Name: Hailo-8
Device Architecture: HAILO8L
Serial Number: HLDDLBB234500054
```

> ℹ️ **Bei AI HAT+ und AI HAT+ 2 können Serial Number, Part Number und Product Name als
> `<N/A>` erscheinen. Das ist erwartet** und beeinträchtigt nichts. Wer das für einen
> Defekt hält, sucht an der falschen Stelle.

```bash
dmesg | grep -i hailo
```

Erwartete Kernmeldungen: `Init module. driver version …`, `Firmware was loaded
successfully`, `Added board …, /dev/hailo0`.

> ℹ️ Zwei Zeilen im Protokoll sehen nach Problemen aus, sind aber normal:
> - `Force setting max_desc_page_size to 4096 (recommended value is 16384)`
> - `Disabling ASPM L0s` / `Successfully disabled ASPM L0s`
>
> Das Abschalten von **ASPM** ist beabsichtigt – dieselbe Massnahme, die `rp1-gpio.md` für
> latenzkritische PCIe-Zugriffe beschreibt.

---

## Vision-Modelle sofort nutzen

```bash
sudo apt update && sudo apt install rpicam-apps
rpicam-hello                      # Kamera prüfen
```

> 🔴 **Korrektur:** Die Hailo-Post-Processing-Stages sind in den **ausgelieferten**
> `rpicam-apps` enthalten – anders als die OpenCV- und TFLite-Stages, die deaktiviert sind
> (`camera.md`). Für die Hailo-Demos ist **keine Neuübersetzung nötig**. Das Build-Flag
> `-Denable_hailo` steht auf `auto` und greift, sobald HailoRT installiert ist.

Fertige Konfigurationen liegen unter **`/usr/share/rpi-camera-assets/`**:

| Aufgabe | Befehl |
|---------|--------|
| Objekterkennung (YOLOv6) | `rpicam-hello -t 0 --post-process-file /usr/share/rpi-camera-assets/hailo_yolov6_inference.json` |
| Objekterkennung (YOLOv8) | `… hailo_yolov8_inference.json` |
| Objekterkennung, leichtgewichtig und schnell (YOLOX) | `… hailo_yolox_inference.json` |
| **Personen- und Gesichtserkennung** (YOLOv5) | `… hailo_yolov5_inference.json` |
| **Segmentierung** mit Farbmaske | `… hailo_yolov5_segmentation.json --framerate 20` |
| **Posenschätzung**, 17 Punkte | `… hailo_yolov8_pose.json` |

Nützliche Zusätze: `-n` schaltet die Vorschau ab (Pflicht bei headless Betrieb), `-v 2`
gibt die Ergebnisse als **Text** aus statt sie zu zeichnen.

> ➜ **`-v 2` ist der Einstieg in eine eigene Anwendung.** Damit lässt sich die Erkennung
> prüfen, bevor eine Zeile eigener Code geschrieben ist – und die Textausgabe zeigt, welche
> Felder überhaupt zur Verfügung stehen.

> ℹ️ Die Demos verwenden `rpicam-hello`; `rpicam-vid` und `rpicam-still` funktionieren
> ebenso, brauchen je nach Anwendungsfall aber angepasste Optionen (`camera.md`).

> ⚠️ **Die Segmentierung braucht `--framerate 20`.** Sie ist rechenintensiver als die
> reine Objekterkennung – ein Hinweis darauf, dass nicht jede Stage bei voller Bildrate
> läuft.

**Weiterführend:** Hailos eigene Beispiele im Repository `hailo-rpi5-examples`, der
**Hailo Model Explorer** als Modell-Zoo.

---

## 🔴 Versionen festhalten

> **Kerneltreiber, Laufzeit und Post-Processing müssen zueinander passen. Tun sie es nicht,
> funktionieren sie nicht korrekt.** Ebenso muss die Version der Hailo-Werkzeugkette, mit
> der ein Modell kompiliert wurde, zur installierten Laufzeit passen.

```bash
# Etwaige Sperren zuerst lösen
sudo apt-mark unhold hailo-tappas-core hailort hailo-dkms

# Gewünschte Version exakt installieren (Beispiel 4.19)
sudo apt install hailo-tappas-core=3.30.0-1 hailort=4.19.0-3 \
                 hailo-dkms=4.19.0-1 python3-hailort=4.19.0-2

# Und festhalten
sudo apt-mark hold hailo-tappas-core hailort hailo-dkms python3-hailort
```

➜ **Für ein Feldgerät ist `apt-mark hold` auf diesen vier Paketen der Normalfall**, nicht
die Ausnahme: Ein selbst kompiliertes Modell ist an eine Werkzeugkettenversion gebunden,
und ein unbeaufsichtigtes `full-upgrade` kann die Laufzeit darunter wegziehen.

> ⚠️ **`hold` hat einen Preis.** Gehaltene Pakete bekommen keine Sicherheitsfixes mehr.
> Die Sperre gehört dokumentiert – im `plan.md` mit Datum, Version und dem Grund – und in
> die Wartungsplanung: Beim Aktualisieren müssen Modell und Laufzeit **gemeinsam** neu
> bedacht werden.

➜ Dieselbe Logik wie bei `kernel.md`: Wer Teile des Systems einfriert, übernimmt deren
Pflege.

---

## Lokale LLMs auf dem AI HAT+ 2

**Nur mit Hailo-10H.** Der Aufbau besteht aus vier Schichten:

| Schicht | Bestandteil |
|---------|-------------|
| Hardware | Pi 5 + Hailo-10H (AI HAT+ 2), **8 GB Speicher auf dem HAT** |
| Software | Treiber, HailoRT, Tappas – über `hailo-h10-all` |
| Modelle | **Hailo Gen-AI Model Zoo** |
| Backend | **`hailo-ollama`** – lädt Modelle, steuert die Inferenz, stellt eine REST-Schnittstelle bereit |
| Frontend (optional) | **Open WebUI** im Docker-Container |

### Server installieren und starten

```bash
# Debian-Paket des Gen-AI Model Zoo herunterladen und installieren
sudo dpkg -i hailo_gen_ai_model_zoo_5.1.1_arm64.deb

# Server starten (belegt das Terminal)
hailo-ollama
```

### Modelle laden und abfragen

```bash
# Verfügbare Modelle auflisten
curl --silent http://localhost:8000/hailo/v1/list

# Modell herunterladen
curl --silent http://localhost:8000/api/pull \
     -H 'Content-Type: application/json' \
     -d '{ "model": "qwen2:1.5b", "stream": true }'

# Abfrage senden
curl --silent http://localhost:8000/api/chat \
     -H 'Content-Type: application/json' \
     -d '{"model": "qwen2:1.5b",
          "messages": [{"role": "user", "content": "Übersetze ins Französische: Die Katze sitzt auf dem Tisch."}]}'
```

> ⚠️ **`hailo-ollama` ist nicht das gewöhnliche Ollama.** Gleicher Name, ähnliche
> Schnittstelle, aber ein anderes Programm mit eigenem Modellbestand aus dem Hailo Gen-AI
> Model Zoo – und **Port 8000** statt 11434. Modelle aus der Ollama-Bibliothek lassen sich
> nicht einfach übernehmen; sie müssen für den Hailo-10H vorliegen.

➜ **Der architektonische Gewinn:** Auf einem Pi 5 mit AI HAT+ 2 läuft das Sprachmodell auf
der NPU statt auf der CPU. Damit entfällt der Zielkonflikt aus `edge-ai.md`, bei dem
Ollama den Arbeitsspeicher und alle vier Kerne belegt und für eine parallele
Vision-Pipeline nichts übrig bleibt. **Für Vision *und* Sprache auf einem Gerät ist das
der Weg**, nicht ein 16-GB-Pi mit CPU-Inferenz.

➜ Für einen Dauerbetrieb gehört `hailo-ollama` in eine **systemd-Unit**, damit der Dienst
Neustarts übersteht – Muster dafür in `edge-ai.md`.

---

## Open WebUI über Docker

Optional: eine Chat-Oberfläche im Browser statt `curl`-Aufrufen.

> 🔴 **Der Docker-Umweg ist keine Stilfrage.** Open WebUI ist **nicht mit Python 3.13
> kompatibel** – und genau das liefert Raspberry Pi OS Trixie. Der Container bringt seine
> eigene Laufzeitumgebung mit; eine Installation direkt auf dem System scheitert.

**Docker installieren** (Kurzfassung; ausführlich in der Docker-Dokumentation für Debian):

```bash
# Alte Pakete entfernen
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)

# Offizielle Paketquelle einrichten
sudo apt update && sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker

# Ohne sudo arbeiten
sudo groupadd docker
sudo usermod -aG docker "$USER"
newgrp docker          # oder ab- und wieder anmelden
docker run hello-world
```

> ⚠️ **`Suites:` muss den Codenamen des Systems enthalten** (`trixie`). Nach dem Anlegen
> prüfen: `cat /etc/apt/sources.list.d/docker.sources`. Ein leeres oder falsches `Suites`
> führt zu einer Paketquelle, die nichts findet.

**Open WebUI starten** – `hailo-ollama` muss bereits laufen:

```bash
docker pull ghcr.io/open-webui/open-webui:main

docker run -d \
  -e OLLAMA_BASE_URL=http://127.0.0.1:8000 \
  -v open-webui:/app/backend/data \
  --name open-webui --network=host --restart always \
  ghcr.io/open-webui/open-webui:main

docker logs open-webui -f      # Start kann bis zu einer Minute dauern
```

Danach im Browser: `http://127.0.0.1:8080`.

> ⚠️ **`--network=host` und `--restart always` sind bewusst gesetzt:** Der Container muss
> `hailo-ollama` auf `127.0.0.1:8000` erreichen, und er soll Neustarts überstehen. Wer die
> Oberfläche im Netz erreichbar macht, sollte die Hinweise aus `remote-access.md` und
> `configuration.md` beachten – Open WebUI gehört nicht ungeschützt ins offene Netz.

---

## Fehlersuche

| Symptom | Erste Prüfung |
|---------|---------------|
| `hailortcli` findet kein Gerät | `lspci \| grep -i Hailo`; FFC-Kabel und Sitz des HAT prüfen (`pcie.md`) |
| NPU nach einem Update verschwunden | Kernel-Header und DKMS (`kernel.md`, Playbook-Abschnitt 27) |
| `<N/A>` bei Serial/Part/Product | **Kein Fehler** bei AI HAT+ und AI HAT+ 2 |
| Modell lädt nicht oder liefert Unsinn | Versionen von Werkzeugkette und Laufzeit vergleichen |
| Inferenz langsamer als erwartet | `sudo lspci -vv \| grep -A5 Hailo \| grep LnkSta` – bei AI Kit Gen 3 prüfen |
| Aussetzer, AER-Meldungen | Auf Gen 2 zurückstellen; Temperatur und Netzteil prüfen |
| Beide `hailo-*-all`-Pakete installiert | Nicht möglich – eines entfernen |

```bash
lspci | grep -i hailo
dmesg | grep -i hailo
hailortcli fw-control identify
dkms status
sudo lspci -vv | grep -A 10 Hailo | grep LnkSta
vcgencmd measure_temp && vcgencmd get_throttled
```

---

## Weitere Ressourcen

- [AI software](https://www.raspberrypi.com/documentation/computers/ai.html)
- [`hailo-rpi5-examples`](https://github.com/hailo-ai/hailo-rpi5-examples) – Beispiele von Hailo
- [`hailo-apps`](https://github.com/hailo-ai/hailo-apps) – VLMs und weitere GenAI-Aufgaben
- [Hailo Model Explorer](https://hailo.ai/products/hailo-software/model-explorer/) – Modell-Zoo
- [Open WebUI](https://docs.openwebui.com/) – Schnellstart
- `edge-ai.md` – Auswahl zwischen NPU, CPU-Inferenz und TFLite, Modellempfehlungen
- `camera.md` – Post-Processing-Gerüst, Niedrigauflösungs-Strom
- `pcie.md` – PCIe-Anschluss, FFC, Power States
- `kernel.md` – Kernel-Header und DKMS
