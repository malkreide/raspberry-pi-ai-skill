🌐 [English](README.md) | **Deutsch**

# Raspberry Pi AI Skill 🤖

**Claude AI Skill für professionelle Raspberry Pi Entwicklung mit Edge AI Integration**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-4%20%7C%205-C51A4A?logo=raspberry-pi)](https://www.raspberrypi.com/)
[![Claude AI](https://img.shields.io/badge/Claude-AI%20Skill-5436DA)](https://www.anthropic.com/claude)

*Entwickelt von Hayal*

---

## 📋 Überblick

Dieses Claude AI Skill unterstützt die systematische Entwicklung robuster, sicherer und performanter Raspberry Pi Projekte mit Fokus auf Edge AI. Es agiert als **Senior Embedded Systems Architect** und kombiniert Best Practices aus Embedded Systems, Linux-Administration, Elektrotechnik und Machine Learning.

### 🎯 Hauptfunktionen

- **Projekt-Workflow**: Strukturierter Prozess von Anforderungsanalyse bis Deployment
- **Hardware-Integration**: GPIO, I2C, SPI, Kameras, Sensoren, HATs
- **Edge AI**: Ollama, Hailo-8L NPU, TensorFlow Lite
- **Systematisches Debugging**: Isolationsmethode, Stolpersteine-Katalog, Eskalationspfade
- **Sicherheit**: Proaktive Validierung kritischer Parameter (Spannung, Strom, Temperatur)
- **Pi 5 Support**: Spezifische Unterstützung für RP1-Chip, PCIe Gen 3, Mini-CSI

## 🚀 Schnellstart

### Installation in Claude

1. **Skill-Datei herunterladen:**
   - Download: [raspberry-pi-ai.skill](https://github.com/malkreide/raspberry-pi-ai-skill/releases/latest/download/raspberry-pi-ai.skill)

2. **In Claude hochladen:**
   - Öffne [claude.ai](https://claude.ai)
   - Navigiere zu Settings → Skills
   - Klicke auf «Upload Skill»
   - Wähle `raspberry-pi-ai.skill`

3. **Skill aktivieren:**
   - Der Skill ist nun in allen Conversations verfügbar
   - Claude wird automatisch erkennen, wann er relevant ist

### Verwendung

Das Skill wird automatisch aktiviert bei:

```
"Ich möchte einen Raspberry Pi 5 mit Kamera und Ollama aufsetzen"
"Mein GPIO-Sensor funktioniert nicht"
"Wie integriere ich den Hailo-8L NPU?"
"Erstelle mir einen Bauplan für eine KI-Kamera"
```

## 📚 Dokumentation

### Kern-Dateien

- **[SKILL.md](SKILL.md)** – Hauptskill-Definition mit Workflows und Checklisten
- **[debugging-playbook.md](debugging-playbook.md)** – Systematisches Debugging-Framework

### Referenzen

- **[hardware-specs.md](docs/hardware-specs.md)** – Raspberry Pi 4/5 Spezifikationen, GPIO-Pinouts, Strombudgets
- **[edge-ai.md](docs/edge-ai.md)** – Ollama, Hailo-8L, TFLite Setup und Best Practices
- **[component-catalog.md](docs/component-catalog.md)** – Empfohlene Komponenten mit Bezugsquellen

### Templates

- **[plan-template.md](templates/plan-template.md)** – Projekt-Bauplan-Vorlage

## 🛠️ Features im Detail

### Think-Hard Hierarchy

Das Skill passt die Analysetiefe an die Komplexität an:

| Level | Trigger | Aktion |
|-------|---------|--------|
| 1 | CLI-Befehle, Paketverwaltung | Direkte Ausführung |
| 2 | Multi-Komponenten, Sensorfusion | Plan erstellen, Power/Pins prüfen |
| 3 | Async, Kernel, Security | Race Conditions, Memory Leaks analysieren |
| 4 | NPU-Pipelines, Quantization | Tensor-Ops, Bandbreite, Thermal prüfen |

### Isolationsmethode

Kernprinzip: **Nie Hardware und Software gleichzeitig debuggen.**

1. **Hardware isoliert testen** → GPIO-Blink, I2C-Scan, Kamera-Test
2. **Software isoliert testen** → Mock-Daten, Library-Imports
3. **Schnittstelle testen** → Berechtigungen, Device-Nodes, venv

### Sicherheits-Checklisten

Proaktive Validierung kritischer Parameter:

- ✅ 3.3V GPIO-Toleranz (keine 5V-Signale!)
- ✅ Strombudget: Pi + Peripherie < 80% PSU-Kapazität
- ✅ Thermisches Management: Active Cooler für Pi 5
- ✅ Induktive Lasten: Freilaufdioden bei Motoren/Relays

## 🎓 Entwickelt für Bildung

Dieses Skill wurde von **Hayal** entwickelt, um:

- Lehrpersonen bei der Integration von Raspberry Pi im Unterricht zu unterstützen
- Schüler*innen beim systematischen Lernen von Embedded Systems zu begleiten
- Best Practices aus der professionellen Embedded-Entwicklung zugänglich zu machen
- Die Brücke zwischen Theorie und Praxis zu schlagen

## 📖 Beispiele

### Beispiel 1: GPIO LED-Steuerung

**User:** «Erstelle ein Script, das eine LED an GPIO17 blinken lässt»

**Claude (mit Skill):**

```python
# Pre-Flight Check:
# - GPIO17 ist frei (nicht von HAT verwendet)
# - LED + Vorwiderstand dimensioniert (220Ω für 3.3V)

from gpiozero import LED
from time import sleep

led = LED(17)

try:
    while True:
        led.on()
        sleep(1)
        led.off()
        sleep(1)
except KeyboardInterrupt:
    led.close()
```

### Beispiel 2: Hailo-8L NPU Setup

**User:** «Wie installiere ich den Hailo-8L auf dem Pi 5?»

**Claude (mit Skill):**

1. PCIe Gen 3 aktivieren in `/boot/firmware/config.txt`
2. Active Cooler montieren (NPU + Pi 5 = ~15W Zusatzlast)
3. Hailo-Treiber installieren
4. Thermal Monitoring einrichten
5. Validierung mit `hailortcli fw-control identify`

*→ Details in [edge-ai.md](docs/edge-ai.md)*

## 🔧 Entwicklung

### Eigene .skill-Datei bauen

```bash
# Repository klonen
git clone https://github.com/malkreide/raspberry-pi-ai-skill.git
cd raspberry-pi-ai-skill

# Skill-Datei bauen
./scripts/build-skill.sh

# Output: raspberry-pi-ai.skill
```

### Beitragen

Contributions sind willkommen! Bitte:

1. Fork das Repository
2. Erstelle einen Feature-Branch (`git checkout -b feature/neue-funktion`)
3. Commit deine Änderungen (`git commit -m 'Füge neue Funktion hinzu'`)
4. Push zum Branch (`git push origin feature/neue-funktion`)
5. Erstelle einen Pull Request

Siehe [CONTRIBUTING.md](CONTRIBUTING.md) für Details.

## 📊 Use Cases

### Bildung

- Informatik-Unterricht (Sekundarstufe II)
- MINT-Förderprogramme
- Raspberry Pi Workshops
- Maker-Projekte

### Prototyping

- IoT-Proof-of-Concepts
- Edge AI Experimente
- Sensor-Netzwerke
- Robotik-Projekte

### Produktion (Limited)

- Embedded Dashboards
- Datenerfassung
- Lokale KI-Inferenz
- Monitoring-Systeme

## ⚠️ Bekannte Limitationen

- **Pi 5 Mini-CSI:** Kamera-Kabel-Inkompatibilität mit Pi 4 Kabeln
- **PEP 668:** Bookworm blockiert systemweite pip-Installs → venv verwenden
- **RP1-Chip:** Ältere HATs/Libraries können inkompatibel sein
- **Thermal:** Pi 5 benötigt Active Cooler für sustained loads

## 📜 Lizenz

MIT License - siehe [LICENSE](LICENSE)

## 🙏 Credits

- **Entwicklung:** Hayal Oezkan
- **AI Framework:** Anthropic Claude
- **Hardware:** Raspberry Pi Foundation
- **Community:** Raspberry Pi Forums, GitHub Contributors

## 📞 Kontakt & Support

- **Issues:** [GitHub Issues](https://github.com/malkreide/raspberry-pi-ai-skill/issues)
- **Discussions:** [GitHub Discussions](https://github.com/malkreide/raspberry-pi-ai-skill/discussions)

---

**Made with ❤️ in Zürich**

[LinkedIn](https://www.linkedin.com/in/hayaloezkan/) • [Documentation](docs/) • [Contributing](CONTRIBUTING.md)
