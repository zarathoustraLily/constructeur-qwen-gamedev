#!/usr/bin/env bash
# Télécharge Godot 4.7.2 Linux (binaire officiel, utilisable en --headless) dans godot_bin/.
# Réservé à la session cloud : sur la machine de l'utilisateur, Godot est déjà installé
# et son chemin est dans config.toml. Le binaire n'est jamais versionné (godot_bin/ est ignoré).
# En cas d'échec réseau : code de sortie 1, et pytest marque les tests moteur « skip ».
set -euo pipefail

VERSION="${1:-4.7.2}"
RACINE="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$RACINE/godot_bin"
NOM="Godot_v${VERSION}-stable_linux.x86_64"
BASE="https://github.com/godotengine/godot/releases/download/${VERSION}-stable"

if [ -x "$DEST/$NOM" ]; then
    echo "Déjà installé : $DEST/$NOM"
    "$DEST/$NOM" --headless --version
    exit 0
fi

mkdir -p "$DEST"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if ! curl -fsSL --retry 3 -o "$TMP/$NOM.zip" "$BASE/$NOM.zip" \
   || ! curl -fsSL --retry 3 -o "$TMP/SHA512-SUMS.txt" "$BASE/SHA512-SUMS.txt"; then
    echo "Échec du téléchargement de Godot $VERSION : les tests moteur seront ignorés (skip)." >&2
    echo "À noter dans ETAT.md." >&2
    exit 1
fi

ATTENDU="$(grep " $NOM.zip\$" "$TMP/SHA512-SUMS.txt" | cut -d' ' -f1)"
OBTENU="$(sha512sum "$TMP/$NOM.zip" | cut -d' ' -f1)"
if [ -z "$ATTENDU" ] || [ "$ATTENDU" != "$OBTENU" ]; then
    echo "Empreinte SHA-512 incorrecte pour $NOM.zip" >&2
    exit 1
fi

unzip -q -o "$TMP/$NOM.zip" -d "$DEST"
chmod +x "$DEST/$NOM"
"$DEST/$NOM" --headless --version
echo "Installé : $DEST/$NOM"
