🌐 **English** | [Deutsch](README.de.md)

# Raspberry Pi AI Skill 🤖

**Claude AI Skill for Professional Raspberry Pi Development with Edge AI Integration**

[![CI](https://github.com/malkreide/raspberry-pi-ai-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/malkreide/raspberry-pi-ai-skill/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-4%20%7C%205-C51A4A?logo=raspberry-pi)](https://www.raspberrypi.com/)
[![Claude AI](https://img.shields.io/badge/Claude-AI%20Skill-5436DA)](https://www.anthropic.com/claude)

*Developed by Hayal*

---

## 📋 Overview

This Claude AI Skill supports the systematic development of robust, secure, and performant Raspberry Pi projects with a focus on Edge AI. It acts as a **Senior Embedded Systems Architect** and combines best practices from embedded systems, Linux administration, electrical engineering, and machine learning.

### 🎯 Key Features

- **Project Workflow**: Structured process from requirements analysis to deployment
- **Hardware Integration**: GPIO, I2C, SPI, cameras, sensors, HATs
- **Edge AI**: Ollama, Hailo-8L NPU, TensorFlow Lite
- **Systematic Debugging**: Isolation method, common pitfalls catalog, escalation paths
- **Safety**: Proactive validation of critical parameters (voltage, current, temperature)
- **Pi 5 Support**: Specific support for RP1 chip, PCIe, Mini-CSI, RTC and power button
- **Mechanics & Enclosures**: Board dimensions, mounting pattern, connector positions,
  official bumper, ambient temperature limits — sourced from the official Raspberry Pi
  product brief and mechanical drawings
- **PCIe & M.2**: Connector pinout, FFC requirements, sideband signals for custom boards,
  M.2 HAT+ variants and the stacked ambient-temperature limit
- **RP1 & GPIO**: Pad limits (12 mA, not 16 mA), PCIe latency on every GPIO access,
  four I2C and six SPI instances, PIO, hardware debouncing

## 🚀 Quick Start

### Installation in Claude

1. **Download the skill file:**
   - Download: [raspberry-pi-ai.skill](https://github.com/malkreide/raspberry-pi-ai-skill/releases/latest/download/raspberry-pi-ai.skill)

2. **Upload to Claude:**
   - Open [claude.ai](https://claude.ai)
   - Navigate to Settings → Skills
   - Click "Upload Skill"
   - Select `raspberry-pi-ai.skill`

3. **Activate the skill:**
   - The skill is now available in all conversations
   - Claude will automatically detect when it is relevant

### Usage

The skill is automatically activated when you say things like:

```
"I want to set up a Raspberry Pi 5 with a camera and Ollama"
"My GPIO sensor isn't working"
"How do I integrate the Hailo-8L NPU?"
"Create a build plan for an AI camera"
"What inner dimensions does my Pi 5 enclosure need?"
"My Hailo NPU doesn't show up in lspci"
"Why do my WS2812 LEDs flicker on the Pi 5?"
```

## 📚 Documentation

### Core Files

- **[SKILL.md](SKILL.md)** – Main skill definition with workflows and checklists
- **[debugging-playbook.md](debugging-playbook.md)** – Systematic debugging framework

### References

- **[hardware-specs.md](docs/hardware-specs.md)** – Raspberry Pi 4/5 specifications, GPIO pinouts, power budgets, RAM variant selection
- **[setup-provisioning.md](docs/setup-provisioning.md)** – Boot media, Imager, power supplies, headless setup, first boot, classroom fleets
- **[mechanical.md](docs/mechanical.md)** – Board dimensions, mounting pattern, connector positions, official bumper, enclosure and 3D-print checklist
- **[pcie.md](docs/pcie.md)** – PCIe connector pinout, FFC requirements, sideband signals, power states, M.2 HAT+
- **[rp1-gpio.md](docs/rp1-gpio.md)** – RP1 pad limits, GPIO latency, alternate functions, PIO, hardware debouncing
- **[edge-ai.md](docs/edge-ai.md)** – Ollama, Hailo-8L, TFLite setup and best practices
- **[component-catalog.md](docs/component-catalog.md)** – Recommended components with suppliers

### Templates

- **[plan-template.md](templates/plan-template.md)** – Project build plan template

### Data Sources

Hardware and mechanical figures are taken from the official Raspberry Pi documents:

| Document | Number |
|----------|--------|
| Raspberry Pi 5 Product Brief | RP-008348-DS (April 2026) |
| Raspberry Pi 5 Mechanical Drawing | RP-008347-DS-1 |
| Raspberry Pi 5 Bumper Mechanical Drawing | RP-006237-DD-1 (Rev. 1) |
| Raspberry Pi Bumper Product Brief | RP-008144-DS-1 (October 2024) |
| Pi 5 Bumper 3D CAD Data (STEP) | RP-006236-DD-1 |
| Raspberry Pi 5 3D STEP (with graphics) | RP-010082-CA-1 |
| Raspberry Pi Documentation – Getting started | raspberrypi.com |
| Raspberry Pi Connector for PCIe | RP-008298-DS-1 (Rev. 1.1) |
| Raspberry Pi M.2 HAT+ Product Brief | RP-009234-MM-1 (September 2025) |
| Raspberry Pi Case for Raspberry Pi 5 | RP-008159-DS-1 (April 2024) |
| Raspberry Pi RP1 Peripherals | RP-008370-DS-1 |

Mechanical figures are reference values with tolerances and are explicitly not released as
production data — measure against a physical board for production work.

## 🛠️ Features in Detail

### Think-Hard Hierarchy

The skill adapts analysis depth to complexity:

| Level | Trigger | Action |
|-------|---------|--------|
| 1 | CLI commands, package management | Direct execution |
| 2 | Multi-component, sensor fusion | Create plan, check power/pins |
| 3 | Async, kernel, security | Analyze race conditions, memory leaks |
| 4 | NPU pipelines, quantization | Check tensor ops, bandwidth, thermal |

### Isolation Method

Core principle: **Never debug hardware and software at the same time.**

1. **Test hardware in isolation** → GPIO blink, I2C scan, camera test
2. **Test software in isolation** → Mock data, library imports
3. **Test the interface** → Permissions, device nodes, venv

### Safety Checklists

Proactive validation of critical parameters:

- ✅ 3.3V GPIO tolerance (no 5V signals!)
- ✅ Power budget: Pi + peripherals < 80% PSU capacity
- ✅ Thermal management: Active cooler for Pi 5
- ✅ Ambient temperature within the specified 0 °C to 70 °C
- ✅ Inductive loads: Flyback diodes for motors/relays
- ✅ Stable, flat, non-conductive mounting surface; enclosure never covered
- ✅ PCIe FFC of the opposite-sides-contact type (a same-side cable inserted backwards shorts the board)

## 🎓 Developed for Education

This skill was developed by **Hayal** to:

- Support teachers integrating Raspberry Pi in their classrooms
- Guide students in learning embedded systems systematically
- Make best practices from professional embedded development accessible
- Bridge the gap between theory and practice

## 📖 Examples

### Example 1: GPIO LED Control

**User:** "Create a script that blinks an LED on GPIO17"

**Claude (with skill):**

```python
# Pre-Flight Check:
# - GPIO17 is free (not used by HAT)
# - LED + resistor dimensioned (220Ω for 3.3V)

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

### Example 2: Enclosure Design

**User:** "I want to 3D print a case for the Pi 5"

**Claude (with skill):**

- Inner dimensions ≥ **88 × 56 mm** (85 mm board + 3 mm connector overhang)
- With the official bumper: **89.6 × 60.6 × 10 mm**
- Mounting pattern **58 × 49 mm**, Ø 2.7 mm (M2.5), 3.5 mm from the edges
- Cutout centres: USB-C 11.2 mm, HDMI 0 25.8 mm, HDMI 1 39.2 mm from the left edge
- FDM tolerance: add 0.8–1.0 mm per side
- Ventilation openings mandatory — the enclosure must never be covered

*→ Details in [mechanical.md](docs/mechanical.md)*

### Example 3: Hailo-8L NPU Setup

**User:** "How do I install the Hailo-8L on the Pi 5?"

**Claude (with skill):**

1. Decide the PCIe mode — Gen 2 is the specified default, Gen 3 an out-of-spec opt-in in `/boot/firmware/config.txt`
2. Mount active cooler (NPU + Pi 5 = ~15W additional load)
3. Install Hailo drivers
4. Set up thermal monitoring
5. Validate with `hailortcli fw-control identify`

*→ Details in [edge-ai.md](docs/edge-ai.md)*

## 🔧 Development

### Build Your Own .skill File

```bash
# Clone the repository
git clone https://github.com/malkreide/raspberry-pi-ai-skill.git
cd raspberry-pi-ai-skill

# Build the skill file
./scripts/build-skill.sh

# Output: raspberry-pi-ai.skill
```

The package layout is defined in [`skill-manifest.txt`](skill-manifest.txt) — the single
place where files are added or renamed:

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

The build is bit-for-bit reproducible: all archive entries get a fixed timestamp, so
identical content always yields an identical `.skill` file.

### Validation

```bash
python3 scripts/validate-skill.py
```

Checks:

1. The manifest is well-formed and every source file exists
2. `SKILL.md` has valid frontmatter (`name`, `description`)
3. Every skill path referenced in `SKILL.md` is covered by the manifest
4. The committed `raspberry-pi-ai.skill` matches the source files
5. No dead relative links in any Markdown document

Check 4 is the important one: the archive is committed to the repository, so it silently
goes stale whenever a reference is edited without rebuilding.

### CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every push to `main` and on
every pull request:

| Job | Does |
|-----|------|
| **Build & Validate Skill** | Validates the committed archive, rebuilds it, verifies the build is reproducible, uploads the `.skill` as an artifact |
| **Shellcheck** | Lints `scripts/*.sh` |

Run both locally before opening a pull request:

```bash
./scripts/build-skill.sh && python3 scripts/validate-skill.py && shellcheck scripts/*.sh
```

### Releases

[`.github/workflows/release.yml`](.github/workflows/release.yml) publishes a GitHub Release
whenever a `v*` tag is pushed, with the built `raspberry-pi-ai.skill` attached as an asset.
That is what makes the download link at the top of this README resolve.

```bash
git tag v1.1.0
git push origin v1.1.0
```

Creating the release through the GitHub web UI ("Create new tag on publish") works too —
the workflow then finds the release already there and only attaches the asset, leaving the
title and notes you wrote untouched.

Before publishing, the workflow re-runs the full validation, rebuilds the package, verifies
the build is reproducible, and checks that the tag points at a commit contained in `main` —
so an unreviewed feature branch cannot become `latest`.

If a run failed, or a tag predates this workflow, publish it manually:
**Actions → Release → Run workflow → enter the tag**.

### Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📊 Use Cases

### Education

- Computer science classes (secondary level)
- STEM programs
- Raspberry Pi workshops
- Maker projects

### Prototyping

- IoT proof-of-concepts
- Edge AI experiments
- Sensor networks
- Robotics projects

### Production (Limited)

- Embedded dashboards
- Data acquisition
- Local AI inference
- Monitoring systems

## ⚠️ Known Limitations

- **Pi 5 Mini-CSI:** Camera cable incompatibility with Pi 4 cables
- **PEP 668:** Bookworm blocks system-wide pip installs → use venv
- **RP1 Chip:** Older HATs/libraries may be incompatible
- **Thermal:** Pi 5 requires active cooler for sustained loads
- **Ambient temperature:** The Pi 5 is specified for 0 °C to 70 °C — outdoor winter
  deployments are out of spec
- **PCIe Gen 3:** Officially the Pi 5 provides PCIe 2.0 x1; Gen 3 is an out-of-spec opt-in
- **PCIe FFC:** Max 50 mm, impedance-controlled, opposite-sides-contact — a wrong cable can destroy hardware
- **M.2 HAT+ ambient limit:** 0 °C to 50 °C, lower than the Pi 5 itself — the stack is limited by the HAT
- **GPIO drive strength:** The Pi 5 maxes out at 12 mA per pin — Pi 4 guides quoting 16 mA do not carry over
- **GPIO latency:** Every access goes over PCIe (~1 µs); bit-banged Pi 4 code is unreliable
- **Pi 5 peripherals:** A 3 A supply limits attached devices to 600 mA — with no undervoltage warning
- **No video over USB-C:** The USB-C port is not a display output on any Pi
- **Mechanical dimensions:** Raspberry Pi's drawings are reference values with tolerances
  and are explicitly not released for production data

## 📜 License

MIT License - see [LICENSE](LICENSE)

## 🙏 Credits

- **Development:** Hayal Oezkan
- **AI Framework:** Anthropic Claude
- **Hardware:** Raspberry Pi Foundation
- **Community:** Raspberry Pi Forums, GitHub Contributors

## 📞 Contact & Support

- **Issues:** [GitHub Issues](https://github.com/malkreide/raspberry-pi-ai-skill/issues)
- **Discussions:** [GitHub Discussions](https://github.com/malkreide/raspberry-pi-ai-skill/discussions)

---

**Made with ❤️ in Zürich**

[LinkedIn](https://www.linkedin.com/in/hayaloezkan/) • [Documentation](docs/) • [Contributing](CONTRIBUTING.md)
