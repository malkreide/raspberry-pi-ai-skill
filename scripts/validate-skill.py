#!/usr/bin/env python3
"""Validiert das Repository und die gebaute .skill-Datei.

Prüfungen:
  1. Manifest ist wohlgeformt und alle Quelldateien existieren
  2. SKILL.md hat gültiges Frontmatter (name, description)
  3. Alle in SKILL.md referenzierten Skill-Pfade sind im Manifest abgedeckt
  4. Das eingecheckte raspberry-pi-ai.skill entspricht den Quelldateien
  5. Keine toten relativen Links in den Markdown-Dokumenten

Aufruf:
    python3 scripts/validate-skill.py

Exit-Code 0 = alles in Ordnung, 1 = mindestens eine Prüfung fehlgeschlagen.
"""

from __future__ import annotations

import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL_NAME = "raspberry-pi-ai"
MANIFEST = ROOT / "skill-manifest.txt"
ARCHIVE = ROOT / f"{SKILL_NAME}.skill"
MOUNT_PREFIX = f"/mnt/skills/user/{SKILL_NAME}/"

errors: list[str] = []
notes: list[str] = []


def fail(msg: str) -> None:
    errors.append(msg)


def read_manifest() -> dict[str, str]:
    """Liest skill-manifest.txt als {Zielpfad im Paket: Quellpfad im Repo}."""
    if not MANIFEST.exists():
        fail("skill-manifest.txt fehlt.")
        return {}

    mapping: dict[str, str] = {}
    for lineno, raw in enumerate(MANIFEST.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            fail(f"skill-manifest.txt:{lineno}: erwartet 'ziel=quelle', gefunden '{line}'")
            continue
        target, source = (part.strip() for part in line.split("=", 1))
        if not target or not source:
            fail(f"skill-manifest.txt:{lineno}: leerer Ziel- oder Quellpfad")
            continue
        if target in mapping:
            fail(f"skill-manifest.txt:{lineno}: Zielpfad '{target}' doppelt vergeben")
            continue
        mapping[target] = source
    return mapping


def check_manifest_sources(mapping: dict[str, str]) -> None:
    for target, source in sorted(mapping.items()):
        if not (ROOT / source).is_file():
            fail(f"Manifest: Quelldatei '{source}' (→ {target}) existiert nicht.")
    if "SKILL.md" not in mapping:
        fail("Manifest: Eintrag für SKILL.md fehlt.")


def check_frontmatter() -> None:
    path = ROOT / "SKILL.md"
    if not path.is_file():
        fail("SKILL.md fehlt im Repository-Root.")
        return

    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not match:
        fail("SKILL.md: kein YAML-Frontmatter am Dateianfang gefunden.")
        return

    block = match.group(1)
    name = re.search(r"^name:\s*(\S.*)$", block, re.M)
    description = re.search(r"^description:\s*(\S.*)$", block, re.M)

    if not name:
        fail("SKILL.md: Frontmatter-Feld 'name' fehlt.")
    elif name.group(1).strip() != SKILL_NAME:
        fail(f"SKILL.md: 'name' ist '{name.group(1).strip()}', erwartet '{SKILL_NAME}'.")

    if not description:
        fail("SKILL.md: Frontmatter-Feld 'description' fehlt.")
    elif len(description.group(1).strip()) < 40:
        fail("SKILL.md: 'description' ist zu kurz, um den Skill zuverlässig auszulösen.")


def check_skill_references(mapping: dict[str, str]) -> None:
    path = ROOT / "SKILL.md"
    if not path.is_file():
        return

    refs = set(re.findall(rf"{re.escape(MOUNT_PREFIX)}[A-Za-z0-9_./-]*\.md", path.read_text(encoding="utf-8")))
    if not refs:
        notes.append("SKILL.md referenziert keine Dateien unter " + MOUNT_PREFIX)
    for ref in sorted(refs):
        rel = ref[len(MOUNT_PREFIX):]
        if rel not in mapping:
            fail(f"SKILL.md referenziert '{rel}', das Manifest packt diese Datei nicht.")


def check_archive_is_current(mapping: dict[str, str]) -> None:
    """Vergleicht das eingecheckte Archiv inhaltlich mit den Quelldateien.

    Verglichen werden Dateiinhalte, nicht ZIP-Bytes – Zeitstempel im Archiv
    sollen keinen Fehlschlag auslösen.
    """
    if not ARCHIVE.exists():
        fail(f"{ARCHIVE.name} fehlt. 'scripts/build-skill.sh' ausführen und committen.")
        return

    try:
        with zipfile.ZipFile(ARCHIVE) as zf:
            members = {n for n in zf.namelist() if not n.endswith("/")}
            expected = {f"{SKILL_NAME}/{t}" for t in mapping}

            for extra in sorted(members - expected):
                fail(f"{ARCHIVE.name} enthält '{extra}', das nicht im Manifest steht.")
            for missing in sorted(expected - members):
                fail(f"{ARCHIVE.name} fehlt '{missing}'.")

            for target, source in sorted(mapping.items()):
                member = f"{SKILL_NAME}/{target}"
                src = ROOT / source
                if member not in members or not src.is_file():
                    continue
                if zf.read(member) != src.read_bytes():
                    fail(
                        f"{ARCHIVE.name}: '{target}' weicht von '{source}' ab. "
                        "'scripts/build-skill.sh' ausführen und das Ergebnis committen."
                    )
    except zipfile.BadZipFile:
        fail(f"{ARCHIVE.name} ist kein gültiges ZIP-Archiv.")


def check_markdown_links() -> None:
    link_re = re.compile(r"\]\((?!https?:|mailto:|#)([^)\s]+)\)")
    for path in sorted(ROOT.rglob("*.md")):
        if ".git" in path.parts or "build" in path.parts:
            continue
        for match in link_re.finditer(path.read_text(encoding="utf-8")):
            target = match.group(1).split("#")[0]
            if not target:
                continue
            if not (path.parent / target).resolve().exists():
                fail(f"{path.relative_to(ROOT)}: toter relativer Link → '{target}'")


def main() -> int:
    mapping = read_manifest()
    if mapping:
        check_manifest_sources(mapping)
        check_skill_references(mapping)
        check_archive_is_current(mapping)
    check_frontmatter()
    check_markdown_links()

    for note in notes:
        print(f"ℹ️  {note}")

    if errors:
        print(f"\n❌ {len(errors)} Problem(e) gefunden:\n")
        for err in errors:
            print(f"   • {err}")
        return 1

    print("✅ Alle Prüfungen bestanden.")
    print(f"   Manifest: {len(mapping)} Datei(en)")
    print(f"   Archiv:   {ARCHIVE.name} ist aktuell")
    return 0


if __name__ == "__main__":
    sys.exit(main())
