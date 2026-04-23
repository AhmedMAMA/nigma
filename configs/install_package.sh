```bash
#!/usr/bin/env bash
# install_yolo_jetson.sh (compatible JetPack 4 & 5)

set -Eeuo pipefail
trap 'echo "❌ Erreur ligne $LINENO"; exit 1' ERR

echo "🔍 Vérifications système..."

# --- Dépendances de base ---
command -v python3 >/dev/null || { echo "❌ Python3 requis"; exit 1; }
command -v apt-get >/dev/null || { echo "❌ apt-get requis"; exit 1; }

# --- Architecture ---
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" ]]; then
    echo "❌ Architecture non supportée : $ARCH (Jetson requis)"
    exit 1
fi

# --- Vérifier Jetson ---
if [[ -f /etc/nv_tegra_release ]]; then
    L4T_RELEASE=$(sed -n 's/.*R\([0-9]*\).*/\1/p' /etc/nv_tegra_release)
    echo "✅ Jetson détecté (L4T R$L4T_RELEASE)"
else
    echo "❌ Not a Jetson device"
    exit 1
fi

# --- Détecter version JetPack ---
if (( L4T_RELEASE < 32 )); then
    echo "❌ Version JetPack trop ancienne (>= 4 requis)"
    exit 1
elif (( L4T_RELEASE < 35 )); then
    echo "⚠️ JetPack 4 détecté (mode compatibilité)"
    JETPACK_VERSION=4
else
    echo "✅ JetPack 5+ détecté"
    JETPACK_VERSION=5
fi

# --- Version Python ---
read MAJOR MINOR <<< "$(python3 -c 'import sys; print(sys.version_info.major, sys.version_info.minor)')"

if (( JETPACK_VERSION == 4 )); then
    echo "⚠️ JetPack 4 → utilisation Python système"
    PYTHON=python3
elif (( MAJOR > 3 || (MAJOR == 3 && MINOR >= 8) )); then
    PYTHON=python3
else
    echo "❌ Python >= 3.8 requis"
    exit 1
fi

echo "✅ Python utilisé : $($PYTHON --version)"

# --- Installation venv si nécessaire ---
if ! $PYTHON -m venv --help >/dev/null 2>&1; then
    echo "📦 Installation python3-venv..."
    sudo apt-get update
    sudo apt-get install -y python3-venv
fi

# --- Mise à jour système ---
echo "📦 Mise à jour système..."
sudo apt-get update
sudo apt-get upgrade -y

# --- OpenCV Jetson ---
echo "📸 Installation OpenCV..."
sudo apt-get install -y python3-opencv

# --- Création environnement ---
ENV_NAME="yolo_env"

if [[ -d "$ENV_NAME" ]]; then
    echo "⚠️ Suppression ancien environnement..."
    rm -rf "$ENV_NAME"
fi

echo "🐍 Création environnement virtuel..."
$PYTHON -m venv "$ENV_NAME"
source "$ENV_NAME/bin/activate"

# --- Upgrade pip ---
python -m pip install --upgrade pip setuptools wheel

# --- PyTorch NVIDIA ---
echo "🔥 Installation PyTorch NVIDIA..."

if (( JETPACK_VERSION == 5 )); then
    pip install --no-cache-dir torch torchvision torchaudio \
        --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v5
else
    echo "⚠️ Installation PyTorch compatible JetPack 4"
    pip install --no-cache-dir numpy==1.19.4
    pip install --no-cache-dir torch==1.10.0 torchvision==0.11.1
fi

# --- Vérification CUDA ---
echo "🔍 Vérification CUDA PyTorch..."
python - <<EOF
import torch
print("CUDA disponible :", torch.cuda.is_available())
if torch.cuda.is_available():
    print("GPU :", torch.cuda.get_device_name(0))
else:
    print("Aucun GPU détecté")
EOF

# --- Fonction installation ---
check_and_install() {
    local MODULE="$1"
    local PACKAGE="$2"

    if python -c "import ${MODULE}" &>/dev/null; then
        echo "✔️ ${PACKAGE} déjà installé"
    else
        echo "⬇️ Installation de ${PACKAGE}..."
        python -m pip install "${PACKAGE}"
    fi
}

echo "📦 Installation des dépendances..."

check_and_install numpy numpy
check_and_install onnx onnx

# --- YOLO (adapté Jetson) ---
echo "🤖 Installation YOLO..."

if (( JETPACK_VERSION == 5 )); then
    pip install ultralytics
else
    echo "⚠️ JetPack 4 → version compatible YOLO"
    pip install ultralytics==8.0.20 || pip install yolov5
fi

# --- Test final YOLO ---
echo "🧪 Test YOLO..."
python - <<EOF
try:
    from ultralytics import YOLO
    model = YOLO("yolov8n.pt")
    print("✅ YOLOv8 prêt !")
except:
    print("⚠️ Fallback YOLOv5")
    import torch
    model = torch.hub.load('ultralytics/yolov5', 'yolov5n')
    print("✅ YOLOv5 prêt !")
EOF

echo ""
echo "🎉 Installation terminée avec succès !"
echo ""
echo "👉 Active l'environnement :"
echo "   source ${ENV_NAME}/bin/activate"
echo ""
echo "👉 Test GPU :"
echo "   python -c 'import torch; print(torch.cuda.is_available())'"

# --- Option reboot ---
read -p "🔄 Redémarrer maintenant ? (y/n): " REBOOT
if [[ "$REBOOT" == "y" ]]; then
    sudo reboot
fi
```
