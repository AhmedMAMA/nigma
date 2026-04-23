#!/usr/bin/env bash (located_camSel)

set -Eeuo pipefail

echo "🔍 Détection des périphériques vidéo..."

# --- Liste des devices ---
shopt -s nullglob
devices=(/dev/video*)

if (( ${#devices[@]} == 0 )); then
    echo "❌ Aucun device vidéo trouvé"
    exit 1
fi

echo "📷 Devices détectés :"
printf ' - %s\n' "${devices[@]}"

# --- Fonction pour trouver une caméra "utile" ---
find_good_cam() {
    for dev in "${devices[@]}"; do

        # Vérifier si le device fonctionne
        if v4l2-ctl -d "$dev" --all &>/dev/null; then

            name=$(v4l2-ctl -d "$dev" --all | grep "Card type" | cut -d: -f2 | xargs)

            # Exclure webcam interne typique (à adapter selon ton cas)
            if [[ "$name" != *"Integrated"* && "$name" != *"Webcam"* ]]; then
                echo "$dev"
                return 0
            fi
        fi
    done

    return 1
}

# --- Vérifier dépendance ---
if ! command -v v4l2-ctl &>/dev/null; then
    echo "📦 Installation de v4l-utils..."
    sudo apt-get update
    sudo apt-get install -y v4l-utils
fi

# --- Trouver la bonne caméra ---
echo "🔎 Recherche caméra externe..."

GOOD_CAM=$(find_good_cam || true)

if [[ -n "${GOOD_CAM:-}" ]]; then
    echo "✅ Caméra sélectionnée : $GOOD_CAM"
else
    echo "⚠️ Aucune caméra externe trouvée → fallback sur ${devices[0]}"
    GOOD_CAM="${devices[0]}"
fi

echo "🎯 Device final : $GOOD_CAM"