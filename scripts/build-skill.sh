#!/bin/bash

# Build Script für raspberry-pi-ai.skill
# Erstellt eine .skill-Datei (ZIP) aus den Markdown-Dokumenten.
#
# Das Paket-Layout steht in skill-manifest.txt im Projekt-Root – dort und
# nur dort werden Dateien hinzugefügt oder umbenannt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
SKILL_NAME="raspberry-pi-ai"
OUTPUT_FILE="$PROJECT_ROOT/${SKILL_NAME}.skill"
MANIFEST="$PROJECT_ROOT/skill-manifest.txt"

# Fester Zeitstempel für alle Archiv-Einträge (siehe ZIP-Schritt unten)
SOURCE_TIMESTAMP="202401010000.00"

echo "🔨 Building ${SKILL_NAME}.skill..."
echo ""

if [ ! -f "$MANIFEST" ]; then
    echo "❌ Error: skill-manifest.txt not found in $PROJECT_ROOT!"
    exit 1
fi

# Aufräumen
if [ -d "$BUILD_DIR" ]; then
    echo "🧹 Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR/$SKILL_NAME"

# Dateien gemäss Manifest kopieren
echo "📄 Copying files from skill-manifest.txt..."
COUNT=0
while IFS='=' read -r target source; do
    # Kommentare und Leerzeilen überspringen
    [ -z "${target// }" ] && continue
    case "$target" in \#*) continue ;; esac

    if [ -z "${source:-}" ]; then
        echo "❌ Error: Manifest-Zeile ohne Quellpfad: '$target'"
        exit 1
    fi
    if [ ! -f "$PROJECT_ROOT/$source" ]; then
        echo "❌ Error: Quelldatei '$source' (→ $target) nicht gefunden!"
        exit 1
    fi

    mkdir -p "$(dirname "$BUILD_DIR/$SKILL_NAME/$target")"
    cp "$PROJECT_ROOT/$source" "$BUILD_DIR/$SKILL_NAME/$target"
    echo "   $source → $target"
    COUNT=$((COUNT + 1))
done < "$MANIFEST"

if [ "$COUNT" -eq 0 ]; then
    echo "❌ Error: Manifest enthält keine Dateien!"
    exit 1
fi

if [ ! -f "$BUILD_DIR/$SKILL_NAME/SKILL.md" ]; then
    echo "❌ Error: Das Manifest muss SKILL.md enthalten!"
    exit 1
fi

# Validierung: Verweist SKILL.md auf Dateien, die nicht im Paket liegen?
echo ""
echo "🔎 Validating references in SKILL.md..."
MISSING=0
while read -r ref; do
    [ -z "$ref" ] && continue
    rel="${ref#/mnt/skills/user/"${SKILL_NAME}"/}"
    if [ ! -f "$BUILD_DIR/$SKILL_NAME/$rel" ]; then
        echo "❌ SKILL.md verweist auf '$rel' – Datei fehlt im Paket."
        MISSING=1
    fi
done < <(grep -o "/mnt/skills/user/${SKILL_NAME}/[A-Za-z0-9_./-]*\.md" "$PROJECT_ROOT/SKILL.md" | sort -u)

if [ "$MISSING" -ne 0 ]; then
    echo ""
    echo "❌ Build abgebrochen: Referenzen unvollständig."
    rm -rf "$BUILD_DIR"
    exit 1
fi
echo "   ✓ Alle in SKILL.md referenzierten Dateien sind im Paket."

# ZIP erstellen
#
# Der Build ist bit-identisch reproduzierbar: alle Einträge bekommen einen
# festen Zeitstempel und -X unterdrückt die zusätzlichen Dateiattribute.
# Dadurch erzeugt gleicher Inhalt immer dasselbe Archiv – nur so lässt sich
# in der CI prüfen, ob das eingecheckte Archiv zu den Quellen passt.
echo ""
echo "📦 Creating .skill archive..."
find "$BUILD_DIR" -exec touch -t "$SOURCE_TIMESTAMP" {} +
rm -f "$OUTPUT_FILE"
(cd "$BUILD_DIR" && find "$SKILL_NAME" -type f | LC_ALL=C sort | zip -X -q -@ "$OUTPUT_FILE")

# Aufräumen
rm -rf "$BUILD_DIR"

# Ergebnis
if [ -f "$OUTPUT_FILE" ]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo ""
    echo "✅ Success!"
    echo "   Output: $OUTPUT_FILE"
    echo "   Size: $SIZE"
    echo ""
    echo "📂 Paketinhalt:"
    unzip -Z1 "$OUTPUT_FILE" | grep -v '/$' | sed 's/^/   /'
    echo ""
    echo "📤 Upload to Claude:"
    echo "   1. Open https://claude.ai"
    echo "   2. Go to Settings → Skills"
    echo "   3. Click 'Upload Skill'"
    echo "   4. Select $OUTPUT_FILE"
else
    echo "❌ Error: Build failed!"
    exit 1
fi
