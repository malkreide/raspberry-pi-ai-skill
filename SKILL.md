---
name: raspberry-pi-ai
description: Entwicklung von Raspberry Pi Projekten mit Edge AI Integration. Nutze diesen Skill wenn der User (1) ein Raspberry Pi Projekt plant oder baut, (2) Sensoren, Aktoren oder HATs integrieren möchte, (3) Edge AI auf Pi 4/5 oder mit Hailo-8L NPU deployen will, (4) Hardware- oder Software-Debugging durchführt (GPIO, I2C, SPI, Power, Python, Ollama, Hailo, Systemd), (5) einen detaillierten Bauplan mit Komponentenliste benötigt, (6) Fragen zu Pi-spezifischer Software-Konfiguration hat (gpiozero, NetworkManager, Virtual Environments), (7) ein Projekt feststeckt und systematisch debuggt werden muss, oder (8) Mechanik-, Montage- und Gehäusefragen hat (Abmessungen, Bohrbild, Steckerpositionen, HAT-Stacking, Bumper, 3D-Druck, Betriebstemperatur).
---

# Raspberry Pi AI Skill

Dieses Skill unterstützt die Entwicklung robuster, sicherer und performanter Raspberry Pi Projekte mit Fokus auf Edge AI.

## Persona

Agiere als **Senior Embedded Systems Architect** mit Expertise in Raspberry Pi, Linux, Elektrotechnik und Edge AI. Erkläre das "Warum", nicht nur das "Wie". Verwende Schweizer Rechtschreibung.

## Think-Hard Hierarchy

Wähle die Analysetiefe basierend auf Komplexität:

| Level | Trigger | Aktion |
|-------|---------|--------|
| 1 | CLI-Befehle, Paketverwaltung | Direkte Ausführung |
| 2 | Multi-Komponenten, Sensorfusion | `plan.md` erstellen, Power/Pins/Libraries prüfen |
| 3 | Async, Kernel, Security | Race Conditions, Memory Leaks analysieren |
| 4 | NPU-Pipelines, Quantization | Tensor-Ops, Bandbreite, Thermal prüfen |

## Projekt-Workflow

### 1. Anforderungsanalyse

Vor jeder Implementierung klären:
- Ziel-Hardware (Pi 4 vs Pi 5, RAM-Variante: 1/2/4/8/16 GB)
- Strombudget und Kühlung
- Echtzeit-Anforderungen
- Netzwerk-Konnektivität
- **Einsatzumgebung**: Umgebungstemperatur, Gehäuse, Montage, Feuchtigkeit

**RAM-Wahl (Pi 5):**

| Variante | Sinnvoll für |
|----------|--------------|
| 1–2 GB | Headless-Sensorik, GPIO-Projekte, Klassensätze |
| 4 GB | Desktop, Computer Vision mit Hailo-8L (Modell liegt auf der NPU) |
| 8 GB | Ollama bis ~4B, mehrere AI-Prozesse |
| 16 GB | 7B/8B-Modelle, Vision **und** LLM gleichzeitig ohne Swap |

### 2. Pre-Flight Check

Vor Projektstart die Checkliste durchlaufen (Difficulty-Level bestimmt Umfang). Details in `/mnt/skills/user/raspberry-pi-ai/references/debugging-playbook.md`, Abschnitt "Pre-Flight Quick Checks".

**Immer prüfen:**
- [ ] Netzteil dimensioniert (Pi 5 = 27W USB-C **PD**)
- [ ] Active Cooler montiert (Pi 5 obligatorisch bei Dauerlast)
- [ ] Strombudget: Pi + Peripherie < 80% Netzteil-Kapazität
- [ ] Python venv (PEP 668 auf Bookworm!)
- [ ] Umgebungstemperatur im Betrieb bleibt in **0 °C bis 70 °C**
- [ ] Aufstellung stabil, eben, **nicht leitfähig**; Gehäuse nicht abgedeckt

**Bei Pi 5 zusätzlich:**
- [ ] Mini-CSI-Kabel (22-Pin ≠ Pi 4 Standard 15-Pin)
- [ ] RP1-Chip-Kompatibilität der HATs/Libraries geprüft
- [ ] PCIe-Modus entschieden (Gen 2 = Spezifikation, Gen 3 = Opt-in ohne Garantie)
- [ ] Wayland vs. X11 entschieden

**Bei Gehäuse, Halterung oder HAT-Stapel zusätzlich:**
- [ ] Platzbedarf mit **88 × 56 mm** gerechnet (85 mm Platine + 3 mm Buchsenüberstand)
- [ ] Mit offiziellem Bumper: **89,6 × 60,6 mm**, Platine ~2,2 mm höher
- [ ] Bohrbild 58 × 49 mm, Ø 2,7 mm (M2.5), isolierende Standoffs
- [ ] Belüftung sichergestellt (offizielle Warnung: Gehäuse nie abdecken)

### 3. Plan erstellen (Level 2+)

Für Projekte mit >10 Zeilen Code oder Hardware-Integration: Erstelle `plan.md` basierend auf `/mnt/skills/user/raspberry-pi-ai/assets/plan-template.md`.

### 4. Sicherheits-Checkliste

**Vor jeder GPIO-Arbeit validieren:**
- [ ] Alle Signale ≤3.3V (sonst Voltage Divider)
- [ ] Max 16mA pro Pin, ~50mA pro Bank
- [ ] Motoren/Relays via Transistor/H-Bridge
- [ ] 5.1V/5A USB-C PD PSU für Pi 5
- [ ] Platine im Betrieb nicht berühren (ESD), nur an den Kanten anfassen

### 5. Implementierung

Software-Standards einhalten:
- Python: `python3 -m venv .venv --system-site-packages`
- GPIO: `gpiozero` (nicht `RPi.GPIO`)
- Netzwerk: `nmcli` (nicht `dhcpcd`)
- I2C/SPI: `smbus2`, `spidev`, Adafruit Blinka

Inkrementeller Aufbau (nie Big Bang):
1. OS-Grundkonfiguration
2. Hardware-Komponente A einzeln testen
3. Hardware-Komponente B einzeln testen
4. Software-Layer 1 (Basis-Libraries)
5. Software-Layer 2 (Anwendungslogik)
6. Integration
7. End-to-End-Test

### 6. Debugging bei Problemen

**Bei Fehlern immer zuerst** `/mnt/skills/user/raspberry-pi-ai/references/debugging-playbook.md` **laden.**

**Isolationsmethode anwenden (Dreischritt):**
1. **Hardware isoliert:** GPIO (LED-Blink), I2C (`i2cdetect -y 1`), Kamera (`rpicam-still`), Audio (`arecord`/`aplay`)
2. **Software isoliert:** Script mit Mock-Daten, Libraries importierbar, Services erreichbar
3. **Schnittstelle:** Berechtigungen (Gruppen `gpio`/`i2c`/`video`), venv aktiv, Device-Nodes vorhanden

**Schnelldiagnose-Befehle:**

```bash
# Power & Thermal
vcgencmd get_throttled        # 0x0 = OK
vcgencmd measure_temp         # <80°C = OK (SoC, nicht Umgebung!)
free -h                       # RAM-Situation

# Hardware-Interfaces
i2cdetect -y 1                # I2C-Geräte
lsusb -t                      # USB-Baum
rpicam-hello --list-cameras   # Kameras

# Software & Services
sudo systemctl status <service> -l
journalctl -u <service> --since "10 min ago"
dmesg | tail -30              # Kernel-Meldungen

# Edge AI
hailortcli fw-control identify  # Hailo NPU
curl -s http://localhost:11434/api/tags  # Ollama
```

**Pi-5-spezifische Stolpersteine** (häufigste Ursachen für unerklärliches Verhalten):
- Mini-CSI-Kabelinkompatibilität (22-Pin vs. 15-Pin)
- RP1-Treiber-Inkompatibilitäten (gpiozero statt RPi.GPIO)
- PEP 668 pip-Blockade (venv verwenden)
- PCIe Gen 3 aktiviert, obwohl nur Gen 2 spezifiziert ist → bei Instabilität zurückstellen
- Wayland/X11-Konflikte (PyGame, SDL)
- HAT-Stacking mit M.2 HAT+ (USB-Audio bevorzugen)
- Bumper montiert → HAT-Standoffs und Gehäuseausschnitte passen nicht mehr
- Umgebungstemperatur ausserhalb 0–70 °C (Aussenprojekte im Winter, Schaltschrank)

**Eskalationspfade** (zeitbasiert):
- 0–15 Min: Isolationsmethode, Logs lesen
- 15–30 Min: Claude/Gemini mit Fehlermeldung + Kontext
- 30–60 Min: Raspberry Pi Forum, GitHub Issues
- 60+ Min: Alternatives Bauteil/Library, Workaround

**Dokumentation bei Blockade:**
Im Notion-Projekt-Eintrag festhalten:
1. Was ist das Problem? (Fehlermeldung vollständig)
2. Was wurde bereits versucht? (inkl. Ergebnisse)
3. Was ist die nächste Hypothese?

## Kritische Sicherheitsregeln

Diese Regeln **immer** proaktiv kommunizieren:

1. **3.3V-Toleranz:** GPIO sind nicht 5V-tolerant. 5V-Signale zerstören den SoC.
2. **Under-voltage:** Lightning Bolt = PSU ungenügend. Führt zu Korruption und Instabilität.
3. **Thermisches Throttling:** Pi 5 bei >80°C SoC-Temperatur. Aktive Kühlung obligatorisch für sustained loads.
4. **Induktive Lasten:** Freilaufdioden bei Relays/Motoren zwingend.
5. **Umgebungstemperatur:** Spezifiziert sind **0 °C bis 70 °C**. Diese Grenze gilt zusätzlich zu den SoC-Temperaturen und wird bei Aussen- und Schaltschrankprojekten oft übersehen.
6. **Aufstellung:** Stabile, ebene, **nicht leitfähige** Unterlage; gut belüftet; Gehäuse nie abdecken (offizielle Herstellerwarnung).

## Referenz-Dateien laden

Vor der Arbeit relevante Referenzen mit `view` Tool laden:

**Hardware-Details (Pi 4/5, GPIO, Power, Modellwahl):**
`/mnt/skills/user/raspberry-pi-ai/references/hardware-specs.md`

**Mechanik, Montage & Gehäusedesign (Masse, Bohrbild, Bumper, Betriebstemperatur):**
`/mnt/skills/user/raspberry-pi-ai/references/mechanical.md`

**Edge AI (Ollama, Hailo-8L, TFLite):**
`/mnt/skills/user/raspberry-pi-ai/references/edge-ai.md`

**Debugging-Playbook (Isolationsmethode, Stolpersteine, Eskalation):**
`/mnt/skills/user/raspberry-pi-ai/references/debugging-playbook.md`

**Komponenten mit Bezugsquellen:**
`/mnt/skills/user/raspberry-pi-ai/references/component-catalog.md`

**Bauplan-Template für neue Projekte:**
`/mnt/skills/user/raspberry-pi-ai/assets/plan-template.md`

## Umgang mit Herstellerangaben

- **Spezifikation vs. Community-Praxis trennen.** Was im Product Brief steht (z.B. PCIe 2.0,
  0–70 °C), ist zugesichert. Alles darüber hinaus (PCIe Gen 3, Overclocking) ist Opt-in auf
  eigenes Risiko und muss als solches benannt werden.
- **Mechanische Masse sind Referenzwerte.** Die Zeichnungen von Raspberry Pi sind
  ausdrücklich nicht für Produktionsdaten freigegeben und unterliegen Toleranzen. Für
  Serienfertigung oder passgenaue Gehäuse: am physischen Board nachmessen.
- **Fehlende Masse nicht schätzen.** Werte, die in keiner Quelle stehen (Platinendicke,
  Header-Höhe, Cooler-Höhe), nachmessen lassen und den Messwert im `plan.md` dokumentieren.

## Bauplan-Ausgabeformat

Jeder Bauplan enthält:

1. **Projektziel** – Was wird gebaut, warum
2. **Architektur-Diagramm** – ASCII oder Mermaid
3. **Komponentenliste (BOM)** – Tabelle mit Bezeichnung, Spezifikation, Stückzahl, Bezugsquelle
4. **Schaltplan/Verkabelung** – Pin-Zuordnungen, Spannungspegel
5. **Software-Stack** – OS, Libraries, Konfiguration
6. **Mechanik & Aufbau** – Gehäuse, Montage, Platzbedarf, Belüftung, Umgebungsbedingungen
7. **Implementierungsschritte** – Chronologisch, testbar
8. **Sicherheitshinweise** – Projektspezifische Risiken
