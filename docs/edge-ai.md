# Edge AI auf Raspberry Pi

## Inhaltsverzeichnis
1. [Ollama](#ollama)
2. [Hailo-8L NPU](#hailo-8l-npu)
3. [TensorFlow Lite](#tensorflow-lite)
4. [Performance-Vergleich](#performance-vergleich)
5. [Use Cases & Best Practices](#use-cases--best-practices)

---

## Ollama

### Überblick

Ollama ermöglicht das lokale Ausführen von Large Language Models (LLMs) auf dem Raspberry Pi. Ideal für:
- Privacy-sensitive Anwendungen
- Offline AI-Assistenten
- Lokale Code-Completion
- Embedded Chatbots

### Installation

**Raspberry Pi 4/5 (64-bit OS – zwingend, nicht die 32-Bit-Variante):**

```bash
# Ollama installieren
curl -fsSL https://ollama.com/install.sh | sh

# Service-Status prüfen
sudo systemctl status ollama

# Alternativ: Manuelle Installation
# Download ARM64 binary von https://ollama.com/download/linux-arm64
```

### Modell-Empfehlungen

**Raspberry Pi 5 (8 GB):**

| Modell | Parameter | RAM | Geschwindigkeit | Use Case |
|--------|-----------|-----|-----------------|----------|
| `phi3:mini` | 3.8B | ~3 GB | ~5 tok/s | Empfohlen für Chat |
| `llama3.2:3b` | 3B | ~2.5 GB | ~6 tok/s | Leichtgewichtig, schnell |
| `gemma2:2b` | 2B | ~2 GB | ~8 tok/s | Schnellste Option |
| `qwen2.5:3b` | 3B | ~2.5 GB | ~6 tok/s | Mehrsprachig |

**Raspberry Pi 5 (16 GB):**

Die 16-GB-Variante (Product Brief RP-008348-DS) hebt die RAM-Grenze auf – der limitierende
Faktor ist dann die **Speicherbandbreite**, nicht mehr die Kapazität. Grössere Modelle
laufen, aber nicht schneller pro Parameter.

| Modell | Parameter | RAM | Geschwindigkeit | Use Case |
|--------|-----------|-----|-----------------|----------|
| `llama3.1:8b` (q4) | 8B | ~5 GB | ~2 tok/s | Qualität vor Tempo, Batch/Offline |
| `qwen2.5:7b` (q4) | 7B | ~4.5 GB | ~2–3 tok/s | Mehrsprachig, längere Kontexte |
| `phi3:mini` | 3.8B | ~3 GB | ~5 tok/s | Weiterhin die beste Interaktiv-Wahl |
| Vision + LLM parallel | – | ~8–10 GB | – | Hailo-Pipeline **und** Ollama gleichzeitig |

➜ **Der eigentliche Gewinn der 16-GB-Variante ist nicht ein grösseres Modell, sondern
Parallelität:** Kamera-Pipeline, Vektorindex und LLM passen gleichzeitig in den RAM, ohne
zu swappen. Für reinen Chat bleibt `phi3:mini` auch auf 16 GB die sinnvollere Wahl.

**Raspberry Pi 4 (4/8 GB):**

| Modell | Parameter | RAM | Use Case |
|--------|-----------|-----|----------|
| `gemma2:2b` | 2B | ~2 GB | Einzige realistische Option |
| `phi3:mini` | 3.8B | ~3 GB | Nur auf 8 GB Pi 4 (langsam) |

**⚠️ Nicht empfohlen auf Raspberry Pi:**
- Llama 3.1 8B auf 8 GB Pi 5 (zu langsam, ~1-2 tok/s; auf 16 GB nur für Offline-Jobs)
- Llama 2 13B (OOM auf 8 GB RAM, auf 16 GB unbrauchbar langsam)

### Basis-Verwendung

```bash
# Modell herunterladen
ollama pull phi3:mini

# Modell ausführen (interaktiv)
ollama run phi3:mini

# Modell über API nutzen
curl http://localhost:11434/api/generate -d '{
  "model": "phi3:mini",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

### Python-Integration

```python
import requests
import json

def ollama_chat(prompt, model="phi3:mini"):
    url = "http://localhost:11434/api/generate"
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }
    response = requests.post(url, json=payload)
    return response.json()["response"]

# Verwendung
answer = ollama_chat("What is a Raspberry Pi?")
print(answer)
```

### Performance-Optimierung

**System-Tuning:**
```bash
# GPU-Memory reduzieren (mehr RAM für Ollama)
# /boot/firmware/config.txt
gpu_mem=64

# Swap erhöhen (für grössere Modelle)
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# CONF_SWAPSIZE=4096
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

**Thermal Management:**
```bash
# Ollama ist CPU-intensiv → Active Cooler empfohlen
vcgencmd measure_temp
# Ziel: <80°C unter Last
```

### Systemd-Service

```bash
# Service-Status
sudo systemctl status ollama

# Service neu starten
sudo systemctl restart ollama

# Logs anzeigen
journalctl -u ollama -f

# Service bei Boot deaktivieren (RAM sparen)
sudo systemctl disable ollama
```

---

## Hailo-8L NPU

### Überblick

> **Drei Hardwarevarianten – die Wahl ist eine Beschaffungsentscheidung:**
>
> | Variante | NPU | Vision | **LLM** |
> |----------|-----|--------|---------|
> | **AI Kit** (M.2 HAT+) | Hailo-8L | ✅ | ❌ – 🔴 nicht mehr in Produktion |
> | **AI HAT+** | Hailo-8L / Hailo-8 | ✅ | ❌ |
> | **AI HAT+ 2** | **Hailo-10H** | ✅ | ✅ |
>
> 🔴 **Nur das AI HAT+ 2 kann Sprachmodelle auf der NPU ausführen.** Das lässt sich später
> nicht per Software nachrüsten – und es ist die Antwort auf den Zielkonflikt weiter unten,
> bei dem Ollama auf der CPU alle Kerne und den Arbeitsspeicher belegt. Details in
> `hailo.md`.

Der Hailo-8L ist ein Edge AI Accelerator (Neural Processing Unit) für Raspberry Pi 5. Bietet:
- **26 TOPS** bei INT8-Precision
- **6W TDP** (zusätzlich zu Pi 5)
- M.2-Modul am PCIe-Anschluss des Pi 5
- Spezialisiert auf Computer Vision

⚠️ **PCIe-Spezifikation:** Der Product Brief spezifiziert für den Pi 5 **PCIe 2.0 x1**
(bis 500 MB/s über den M.2 HAT+). Das Steckerdokument formuliert es unmissverständlich:
*«Signals can be run at Gen 3 speeds, but this is not officially supported.»*
Gen 3 (`dtparam=pciex1_gen=3`) ist damit ein Opt-in ohne Signalintegritäts-Garantie.
Der Hailo-8L läuft auch mit Gen 2 – bei Link-Fehlern, sporadischen Aussetzern oder
AER-Meldungen in `dmesg` ist **Rückstellen auf Gen 2 der erste Schritt**, nicht der letzte.

> ℹ️ **Für die AI-Hardware differenziert die offizielle Dokumentation:**
> Beim **AI Kit** wird Gen 3 **ausdrücklich empfohlen** und muss von Hand aktiviert werden;
> beim **AI HAT+ und AI HAT+ 2** setzt die Firmware es **automatisch**. Das ist der einzige
> dokumentierte Fall, in dem Raspberry Pi selbst zu Gen 3 rät – bei eigener Hardware mit
> bekannter Signalstrecke. Für beliebige PCIe-Geräte bleibt es beim Opt-in.

### Hardware-Setup

**Benötigte Komponenten:**
1. Raspberry Pi 5 (4 GB genügt – das Modell liegt auf der NPU, nicht im RAM)
2. **M.2 HAT+ Standard** (2230 und 2242) oder AI Kit – die **Compact**-Variante
   unterstützt nur 2230
3. Hailo-8L M.2 Modul
4. **Active Cooler** (kritisch!) – der 16-mm-Stacking-Header des M.2 HAT+ Standard ist
   genau dafür bemessen, dass der HAT darüber passt
5. 27W USB-C PD Netzteil
6. Platz im Gehäuse für den HAT-Stapel → [`mechanical.md`](mechanical.md)
7. Das **mitgelieferte** FFC-Kabel – max. 50 mm, impedanzkontrolliert, Typ
   opposite-sides-contact → [`pcie.md`](pcie.md)

⚠️ **Umgebungstemperatur:** Der M.2 HAT+ ist für **0–50 °C** spezifiziert, der Pi 5 für
0–70 °C. Für den Stapel gilt die niedrigere Grenze – ein Hailo-Aufbau ist ein
**0–50-°C-System**. Im geschlossenen Gehäuse unter Dauerlast ist das schnell erreicht.

⚠️ **FFC falsch herum = Kurzschluss.** Ein Kabel mit gleichseitigen Kontakten ist nicht
umkehrbar und beschädigt Pi und/oder HAT. Nie improvisieren, nie verlängern.

**Installation:**

```bash
# 1. PCIe Gen 3 – nur beim AI Kit nötig; AI HAT+ und AI HAT+ 2 setzen es selbst
sudo raspi-config        # 6 Advanced Options → A8 PCIe Speed → Yes
# gleichwertig in /boot/firmware/config.txt:
dtparam=pciex1_gen=3

# 2. Reboot
sudo reboot

# 3. PCIe-Verbindung prüfen
lspci
# Erwartung: "Hailo-8 AI Processor"

dmesg | grep -i hailo
# Erwartung: Keine Fehler

# 4. Link-Speed verifizieren
sudo lspci -vv | grep -A 10 Hailo
# Erwartung: "LnkSta: Speed 8GT/s" (Gen 3)
```

### Software-Installation

> 🔴 **Reihenfolge einhalten – der PCIe-Treiber ist ein Kernelmodul.** Erst aktualisieren
> und neu starten, dann die passenden Kernel-Header installieren, dann die Runtime. Wer
> danach noch aktualisiert, hat ein Modul für den vorherigen Kernel.
>
> ```bash
> sudo apt update && sudo apt full-upgrade
> sudo reboot
> sudo apt install linux-headers-rpi-v8    # dauert Minuten, ohne Fortschrittsanzeige
> uname -r && ls /lib/modules/             # müssen zusammenpassen
> ```
>
> Nach einem Kernel-Update kann es **Wochen** dauern, bis das Header-Paket nachzieht. In
> dieser Zeit scheitert jeder Modulbau – auch der automatische über DKMS, und zwar still:
> Das Gerät bootet, aber die NPU ist weg. Details in `kernel.md`.

```bash
# 1. System UND Firmware aktualisieren
sudo apt update && sudo apt full-upgrade -y
sudo rpi-eeprom-update -a
sudo reboot

# 2. Alles Nötige in einem Paket – Treiber, HailoRT, Tappas
sudo apt install dkms
sudo apt install hailo-all        # AI Kit und AI HAT+ (Hailo-8L / Hailo-8)
# sudo apt install hailo-h10-all  # AI HAT+ 2 (Hailo-10H) – schliesst hailo-all AUS

sudo reboot

# 3. Verfügbarkeit prüfen
hailortcli fw-control identify
dmesg | grep -i hailo
```

> 🔴 **Nicht über eine `.deb`-Datei von der Hailo-Website und nicht über
> `pip install hailort`.** Die Paketquelle von Raspberry Pi liefert aufeinander
> abgestimmte Versionen von Kerneltreiber, Laufzeit und Post-Processing; von Hand
> zusammengesuchte Komponenten passen leicht nicht zueinander und funktionieren dann
> **nicht korrekt**. Wer eine bestimmte Werkzeugkettenversion braucht, pinnt sie mit
> `apt-mark hold` – siehe `hailo.md`.

➜ **Vollständige Anleitung inklusive Versionspinning, fertiger Vision-Demos und lokaler
LLMs auf dem AI HAT+ 2: `hailo.md`.**

### Modell-Deployment

**Unterstützte Frameworks:**
- YOLO (v5, v7, v8)
- EfficientDet
- ResNet
- MobileNet
- Custom ONNX/TFLite (via Hailo Dataflow Compiler)

**Beispiel: YOLOv8 Objekt-Erkennung**

```python
from hailo_platform import HEF, VDevice, HailoStreamInterface
import numpy as np
import cv2

# HEF-Modell laden (Hailo Executable Format)
hef = HEF("yolov8s.hef")

# Virtual Device erstellen
with VDevice() as target:
    # Input/Output-Streams konfigurieren
    configure_params = {
        "batch_size": 1
    }
    network_group = target.configure(hef, configure_params)[0]
    
    # Inferenz
    with network_group.activate():
        # Bild vorbereiten
        image = cv2.imread("test.jpg")
        image_resized = cv2.resize(image, (640, 640))
        
        # Format konvertieren (HWC → CHW, uint8)
        input_data = image_resized.transpose(2, 0, 1)
        input_data = np.expand_dims(input_data, axis=0)
        
        # Inferenz ausführen
        output = network_group.infer({
            "input_layer1": input_data
        })
        
        # Postprocessing (YOLO-spezifisch)
        detections = postprocess_yolo(output)
```

### Performance-Benchmarks

**YOLOv8s (640×640 Eingabe):**

| Hardware | FPS | Latenz |
|----------|-----|--------|
| **Hailo-8L** | **~45 FPS** | **~22 ms** |
| Pi 5 CPU (Cortex-A76) | ~2 FPS | ~500 ms |
| Pi 5 CPU + TFLite | ~5 FPS | ~200 ms |

**→ Hailo ist ~20× schneller als CPU-Inferenz**

### Thermisches Management

⚠️ **Kritisch:** Hailo-8L + Pi 5 = ~15W Gesamt-TDP

```bash
# Thermal Monitoring (kontinuierlich)
watch -n 1 'vcgencmd measure_temp && cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null'

# Active Cooler ist obligatorisch!
# Erwartung: <80°C unter sustained load
```

### Troubleshooting

**Problem: Hailo wird nicht erkannt**

```bash
# PCIe-Link prüfen
lspci | grep -i hailo

# Falls nicht sichtbar:
# 1. Gen 3 aktiviert? (config.txt)
# 2. HAT+ richtig montiert? (FFC-Kabel)
# 3. Power OK? (Lightning Bolt?)
```

**Problem: Langsame Inferenz**

```bash
# Link Speed prüfen (muss 8GT/s sein)
sudo lspci -vv | grep -A 5 "Hailo" | grep LnkSta

# Falls 5GT/s (Gen 2):
# → config.txt prüfen (dtparam=pciex1_gen=3)
# → Reboot erforderlich
```

---

## TensorFlow Lite

### Überblick

TensorFlow Lite (TFLite) ist Googles Edge AI Framework. Läuft auf:
- Raspberry Pi 4/5 CPU
- Optional: Coral Edge TPU (USB-Beschleuniger)

**Vorteile:**
- Breite Modell-Kompatibilität
- Gute Dokumentation
- Community-Support

**Nachteile:**
- Langsamer als Hailo (reiner CPU-Betrieb)
- Coral Edge TPU nicht auf Pi 5 getestet

### Installation

```bash
# TFLite Runtime installieren
pip install tflite-runtime

# Oder: Full TensorFlow (schwerer)
pip install tensorflow
```

### Basis-Verwendung

```python
import numpy as np
import tflite_runtime.interpreter as tflite

# Modell laden
interpreter = tflite.Interpreter(model_path="model.tflite")
interpreter.allocate_tensors()

# Input/Output Details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Inferenz
input_data = np.array([[1.0, 2.0, 3.0]], dtype=np.float32)
interpreter.set_tensor(input_details[0]['index'], input_data)
interpreter.invoke()

# Ergebnis abrufen
output_data = interpreter.get_tensor(output_details[0]['index'])
print(output_data)
```

### Modell-Optimierung

**Quantization (INT8):**

```python
import tensorflow as tf

# Float32-Modell konvertieren
converter = tf.lite.TFLiteConverter.from_saved_model("saved_model/")

# INT8-Quantization
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.int8]

# Konvertieren
tflite_model = converter.convert()

# Speichern
with open("model_int8.tflite", "wb") as f:
    f.write(tflite_model)
```

**Performance-Gewinn:**
- Modellgrösse: ~4× kleiner
- Inferenz-Geschwindigkeit: ~2× schneller
- Genauigkeit: ~1-2% Verlust (akzeptabel)

---

## Performance-Vergleich

### Computer Vision (YOLOv8s, 640×640)

| Hardware | FPS | Latenz | Power | Kosten |
|----------|-----|--------|-------|--------|
| **Hailo-8L (Pi 5)** | **45** | **22 ms** | **+6W** | **~$70** |
| TFLite CPU (Pi 5) | 5 | 200 ms | +0W | $0 |
| TFLite CPU (Pi 4) | 2 | 500 ms | +0W | $0 |
| Coral Edge TPU | 30 | 33 ms | +2W | $60 |

### LLM Inference (Phi-3 Mini, 3.8B)

| Hardware | Speed | Latenz/Token | RAM |
|----------|-------|--------------|-----|
| Ollama (Pi 5, 8GB) | 5 tok/s | 200 ms | ~3 GB |
| Ollama (Pi 4, 8GB) | 2 tok/s | 500 ms | ~3 GB |

---

## Use Cases & Best Practices

### Empfohlene Anwendungen

**Hailo-8L:**
- ✅ Echtzeit-Objekt-Erkennung (Sicherheitskamera, Robotik)
- ✅ Personen-Tracking
- ✅ Gesichtserkennung
- ✅ Qualitätskontrolle (Fertigung)
- ❌ LLM Inference (nicht unterstützt)
- ❌ Audio Processing (nicht optimiert)

**Ollama:**
- ✅ Lokale Chatbots
- ✅ Code-Completion
- ✅ Textklassifikation
- ✅ Sentiment-Analyse
- ❌ Real-time Vision (zu langsam)
- ❌ 24/7 Background Service (RAM-Verbrauch)

**TensorFlow Lite:**
- ✅ Prototyping / Proof-of-Concept
- ✅ Bildklassifikation (non-real-time)
- ✅ Audio-Klassifikation
- ✅ Zeit-Serien-Analyse
- ❌ Echtzeit-Vision (zu langsam ohne TPU)

### Architektur-Patterns

**Pattern 0: Der Niedrigauflösungs-Strom – die Grundlage jeder Kamera-Pipeline**

```
Sensor → ISP ─┬─→ Vollauflösung  → Aufzeichnung / Ausgabe
              └─→ lores (z.B. 300×300) → Modell
```

Die Kamera liefert **parallel** einen zweiten, kleineren Bildstrom. Modelle arbeiten
ohnehin auf kleinen Eingaben (224×224, 257×257, 300×300); ein Vollbild anzufordern und
selbst zu skalieren, verschenkt Rechenzeit an eine Skalierung, die der ISP kostenlos
mitliefert.

```bash
rpicam-hello --lores-width 400 --lores-height 300 --post-process-file object_detect_tf.json
```

➜ **Vorfilter vor teurer Inferenz:** Die Stage `motion_detect` läuft ohne jede
Fremdbibliothek auf 128×96 und schreibt ihr Ergebnis in die Bildmetadaten. Auf einem
thermisch oder energetisch begrenzten Gerät startet die eigentliche Erkennung erst, wenn
sich überhaupt etwas bewegt hat. Details in `camera.md`.

> ℹ️ **Die Hailo-Stages sind in den ausgelieferten `rpicam-apps` bereits enthalten** – im
> Gegensatz zu den OpenCV- und TFLite-Stages, die deaktiviert sind (`camera.md`). Fertige
> Konfigurationen für Objekterkennung, Segmentierung und Posenschätzung liegen unter
> `/usr/share/rpi-camera-assets/`; eine Neuübersetzung ist dafür **nicht** nötig
> (`hailo.md`).

> ⚠️ **Auf dem Pi 5 kodiert die Videoaufnahme in Software**, nicht in Hardware wie auf dem
> Pi 4. Wer gleichzeitig aufzeichnet und Inferenz betreibt, muss diese CPU-Last einplanen.

**Pattern 1: Hailo + Ollama Combo**
```
Kamera → Hailo (Objekt-Erkennung, 45 FPS)
         ↓
     Detektierte Objekte
         ↓
     Ollama (Beschreibung generieren)
         ↓
     Text-to-Speech
```

**Use Case:** Blindenhilfe-System, das Szenen beschreibt.

**Pattern 2: Edge Processing + Cloud Fallback**
```
Sensor → TFLite (lokale Klassifikation)
         ↓
    Confidence > 0.9? → Aktion
         ↓ (Nein)
    API-Call zu Cloud-Modell → Validierung
```

**Use Case:** Offline-fähige Anwendungen mit Quality-Fallback.

### Power & Thermal Management

**Empfohlene Konfiguration:**

```bash
# /boot/firmware/config.txt

# Hailo-Projekt (Pi 5 + Hailo-8L):
over_voltage=2           # Leichte Übertaktung für Stabilität
arm_freq=2400            # Standard (nicht höher!)
gpu_mem=128              # GPU-Memory für Kamera
dtparam=pciex1_gen=3     # Hailo Gen 3 aktivieren

# Ollama-Projekt (Pi 5, kein Hailo):
gpu_mem=64               # Weniger GPU, mehr RAM
```

**Thermisches Monitoring:**

```python
import subprocess

def check_thermal_throttling():
    result = subprocess.run(
        ["vcgencmd", "get_throttled"],
        capture_output=True,
        text=True
    )
    throttled = int(result.stdout.split("=")[1], 16)
    
    if throttled & 0x80000:
        print("⚠️ THERMAL THROTTLING AKTIV!")
        return True
    return False

# In Haupt-Loop integrieren
while True:
    if check_thermal_throttling():
        # Inferenz pausieren oder taktrate reduzieren
        time.sleep(5)
```

---

## Weitere Ressourcen

### Hailo
- [Hailo Developer Zone](https://hailo.ai/developer-zone/)
- [Raspberry Pi AI Kit](https://www.raspberrypi.com/products/ai-kit/)
- [Hailo Model Zoo](https://github.com/hailo-ai/hailo_model_zoo)

### Ollama
- [Ollama Documentation](https://github.com/ollama/ollama)
- [Ollama Model Library](https://ollama.com/library)
- [Raspberry Pi Forum: Ollama](https://forums.raspberrypi.com/viewtopic.php?t=362971)

### TensorFlow Lite
- [TFLite Guide](https://www.tensorflow.org/lite/guide)
- [TFLite Model Maker](https://www.tensorflow.org/lite/models)
- [Pre-trained Models](https://tfhub.dev/s?deployment-format=lite)

### Benchmarks
- [Raspberry Pi AI Benchmarks](https://github.com/raspberrypi/picamera2/tree/main/examples)
- [Hailo Performance Tests](https://community.hailo.ai/)
