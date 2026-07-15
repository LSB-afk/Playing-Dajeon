#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGRAM_DIR="$ROOT_DIR/docs/diagrams"
MERMAID_CLI_VERSION="11.16.0"

for source in "$DIAGRAM_DIR"/*.mmd; do
    name="$(basename "$source" .mmd)"

    npx --yes "@mermaid-js/mermaid-cli@$MERMAID_CLI_VERSION" \
        -i "$source" \
        -o "$DIAGRAM_DIR/$name.svg" \
        -c "$DIAGRAM_DIR/mermaid-config.json" \
        -t neutral \
        -b transparent

    npx --yes "@mermaid-js/mermaid-cli@$MERMAID_CLI_VERSION" \
        -i "$source" \
        -o "$DIAGRAM_DIR/$name.png" \
        -c "$DIAGRAM_DIR/mermaid-config.json" \
        -t neutral \
        -b white \
        -w 1800 \
        -s 2
done

echo "Mermaid SVG/PNG 렌더링 완료: $DIAGRAM_DIR"
