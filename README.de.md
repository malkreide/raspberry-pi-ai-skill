🌐 [English](README.md) | **Deutsch**

# Raspberry Pi AI Skill 🤖

**Claude AI Skill für professionelle Raspberry Pi Entwicklung mit Edge AI Integration**

[![CI](https://github.com/malkreide/raspberry-pi-ai-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/malkreide/raspberry-pi-ai-skill/actions/workflows/ci.yml)
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
- **Pi 5 Support**: Spezifische Unterstützung für RP1-Chip, PCIe, Mini-CSI, RTC und Power-Button
- **Mechanik & Gehäuse**: Platinenmasse, Bohrbild, Steckerpositionen, offizieller Bumper,
  Betriebstemperatur – aus dem offiziellen Product Brief und den Massblättern von Raspberry Pi
- **PCIe & M.2**: Steckerpinout, FFC-Anforderungen, Sideband-Signale für eigene Platinen,
  M.2-HAT+-Varianten und die Temperaturgrenze im Stapel
- **RP1 & GPIO**: Pad-Grenzwerte (12 mA statt 16 mA), PCIe-Latenz beim GPIO-Zugriff,
  vier I2C- und sechs SPI-Instanzen, PIO, Hardware-Entprellung

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
"Welches Innenmass braucht mein Pi-5-Gehäuse?"
"Mein Hailo-NPU taucht nicht in lspci auf"
"Warum flackern meine WS2812-LEDs auf dem Pi 5?"
```

## 📚 Dokumentation

### Kern-Dateien

- **[SKILL.md](SKILL.md)** – Hauptskill-Definition mit Workflows und Checklisten
- **[debugging-playbook.md](debugging-playbook.md)** – Systematisches Debugging-Framework

### Referenzen

- **[hardware-specs.md](docs/hardware-specs.md)** – Raspberry Pi 4/5 Spezifikationen, GPIO-Pinouts, Strombudgets, RAM-Varianten
- **[setup-provisioning.md](docs/setup-provisioning.md)** – Boot-Medium, Imager, Netzteile, Headless-Setup, erster Start, Klassensatz
- **[mechanical.md](docs/mechanical.md)** – Platinenmasse, Bohrbild, Steckerpositionen, offizieller Bumper, Gehäuse- und 3D-Druck-Checkliste
- **[pcie.md](docs/pcie.md)** – PCIe-Pinout, FFC-Anforderungen, Sideband-Signale, Power States, M.2 HAT+
- **[rp1-gpio.md](docs/rp1-gpio.md)** – RP1-Pad-Grenzwerte, GPIO-Latenz, Alternativfunktionen, PIO, Hardware-Entprellung
- **[edge-ai.md](docs/edge-ai.md)** – Ollama, Hailo-8L, TFLite Setup und Best Practices
- **[component-catalog.md](docs/component-catalog.md)** – Empfohlene Komponenten mit Bezugsquellen

### Templates

- **[plan-template.md](templates/plan-template.md)** – Projekt-Bauplan-Vorlage

### Datenquellen

Hardware- und Mechanikangaben stammen aus den offiziellen Raspberry-Pi-Dokumenten:

| Dokument | Nummer |
|----------|--------|
| Raspberry Pi 5 Product Brief | RP-008348-DS (April 2026) |
| Raspberry Pi 5 Mechanical Drawing | RP-008347-DS-1 |
| Raspberry Pi 5 Bumper Mechanical Drawing | RP-006237-DD-1 (Rev. 1) |
| Raspberry Pi Bumper Product Brief | RP-008144-DS-1 (Oktober 2024) |
| Pi 5 Bumper 3D CAD Data (STEP) | RP-006236-DD-1 |
| Raspberry Pi 5 3D STEP (with graphics) | RP-010082-CA-1 |
| Raspberry Pi Documentation – Getting started | raspberrypi.com |
| Raspberry Pi Connector for PCIe | RP-008298-DS-1 (Rev. 1.1) |
| Raspberry Pi M.2 HAT+ Product Brief | RP-009234-MM-1 (September 2025) |
| Raspberry Pi Case for Raspberry Pi 5 | RP-008159-DS-1 (April 2024) |
| Raspberry Pi RP1 Peripherals | RP-008370-DS-1 |

Mechanische Masse sind Referenzwerte mit Toleranzen und ausdrücklich nicht als
Produktionsdaten freigegeben – für Serienteile am physischen Board nachmessen.

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
- ✅ Umgebungstemperatur innerhalb der spezifizierten 0 °C bis 70 °C
- ✅ Induktive Lasten: Freilaufdioden bei Motoren/Relays
- ✅ Stabile, ebene, nicht leitfähige Unterlage; Gehäuse nie abgedeckt
- ✅ PCIe-FFC vom Typ opposite-sides-contact (gleichseitiges Kabel falsch herum = Kurzschluss)

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

### Beispiel 2: Gehäuse-Konstruktion

**User:** «Ich möchte ein Gehäuse für den Pi 5 3D-drucken»

**Claude (mit Skill):**

- Innenmass ≥ **88 × 56 mm** (85 mm Platine + 3 mm Steckerüberstand)
- Mit offiziellem Bumper: **89,6 × 60,6 × 10 mm**
- Bohrbild **58 × 49 mm**, Ø 2,7 mm (M2.5), 3,5 mm von den Kanten
- Ausschnittmitten: USB-C 11,2 mm, HDMI 0 25,8 mm, HDMI 1 39,2 mm ab linker Kante
- FDM-Toleranz: +0,8–1,0 mm pro Seite
- Lüftungsöffnungen zwingend – das Gehäuse darf nie abgedeckt werden

*→ Details in [mechanical.md](docs/mechanical.md)*

### Beispiel 3: Hailo-8L NPU Setup

**User:** «Wie installiere ich den Hailo-8L auf dem Pi 5?»

**Claude (mit Skill):**

1. PCIe-Modus entscheiden – Gen 2 ist spezifiziert, Gen 3 ein Opt-in ausserhalb der Spezifikation in `/boot/firmware/config.txt`
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

Das Paket-Layout steht in [`skill-manifest.txt`](skill-manifest.txt) – dort und nur dort
werden Dateien hinzugefügt oder umbenannt:

```
raspberry-pi-ai/
├── SKILL.md
├── references/
│   ├── debugging-playbook.md
│   ├── hardware-specs.md
│   ├── mechanical.md
│   ├── edge-ai.md
│   └── component-catalog.md
└── assets/
    └── plan-template.md
```

Der Build ist bit-identisch reproduzierbar: alle Archiv-Einträge bekommen einen festen
Zeitstempel, gleicher Inhalt ergibt also immer dieselbe `.skill`-Datei.

### Validierung

```bash
python3 scripts/validate-skill.py
```

Geprüft wird:

1. Das Manifest ist wohlgeformt und alle Quelldateien existieren
2. `SKILL.md` hat gültiges Frontmatter (`name`, `description`)
3. Alle in `SKILL.md` referenzierten Skill-Pfade sind im Manifest abgedeckt
4. Das eingecheckte `raspberry-pi-ai.skill` entspricht den Quelldateien
5. Keine toten relativen Links in den Markdown-Dokumenten

Punkt 4 ist der wichtigste: Das Archiv liegt im Repository und veraltet still, sobald eine
Referenz bearbeitet, aber nicht neu gebaut wird.

### CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) läuft bei jedem Push auf `main` und
bei jedem Pull Request:

| Job | Prüft |
|-----|-------|
| **Build & Validate Skill** | Validiert das eingecheckte Archiv, baut es neu, prüft die Reproduzierbarkeit, lädt die `.skill` als Artefakt hoch |
| **Shellcheck** | Lintet `scripts/*.sh` |

Vor einem Pull Request lokal ausführen:

```bash
./scripts/build-skill.sh && python3 scripts/validate-skill.py && shellcheck scripts/*.sh
```

### Releases

[`.github/workflows/release.yml`](.github/workflows/release.yml) veröffentlicht bei jedem
`v*`-Tag ein GitHub Release und hängt die gebaute `raspberry-pi-ai.skill` als Asset an.
Erst dadurch funktioniert der Download-Link oben in diesem README.

```bash
git tag v1.1.0
git push origin v1.1.0
```

Der Weg über die GitHub-Oberfläche funktioniert ebenfalls («Create new tag on publish»).
Der Workflow findet das Release dann bereits vor und hängt nur noch das Asset an – Titel und
Notes, die du geschrieben hast, bleiben unverändert.

Vor der Veröffentlichung läuft die vollständige Validierung erneut, das Paket wird neu
gebaut, die Reproduzierbarkeit geprüft, und es wird kontrolliert, dass der Tag auf einem
Commit liegt, der in `main` enthalten ist – so kann kein ungeprüfter Feature-Branch zu
`latest` werden.

Ist ein Lauf fehlgeschlagen oder stammt ein Tag aus der Zeit vor diesem Workflow, lässt er
sich manuell nachziehen: **Actions → Release → Run workflow → Tag eintragen**.

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
- **Umgebungstemperatur:** Der Pi 5 ist für 0 °C bis 70 °C spezifiziert – Aussenbetrieb im
  Winter liegt ausserhalb der Spezifikation
- **PCIe Gen 3:** Offiziell bietet der Pi 5 PCIe 2.0 x1; Gen 3 ist ein Opt-in ausserhalb
  der Spezifikation
- **PCIe-FFC:** Max. 50 mm, impedanzkontrolliert, opposite-sides-contact – ein falsches
  Kabel kann Hardware zerstören
- **M.2 HAT+ Umgebungsgrenze:** 0 °C bis 50 °C, niedriger als der Pi 5 selbst – im Stapel
  zählt die Grenze des HAT
- **GPIO-Treiberstrom:** Der Pi 5 kann max. 12 mA pro Pin – Pi-4-Anleitungen mit 16 mA
  sind nicht übertragbar
- **GPIO-Latenz:** Jeder Zugriff läuft über PCIe (~1 µs); Bit-Banging aus Pi-4-Code
  funktioniert nicht zuverlässig
- **Peripherie am Pi 5:** Mit einem 3-A-Netzteil werden angeschlossene Geräte auf
  600 mA begrenzt – ohne Unterspannungswarnung
- **Kein Video über USB-C:** Der USB-C-Port ist auf keinem Pi ein Displayausgang
- **Mechanische Masse:** Die Zeichnungen von Raspberry Pi sind Referenzwerte mit Toleranzen
  und ausdrücklich nicht als Produktionsdaten freigegeben

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
