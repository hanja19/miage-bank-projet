#!/bin/bash

# Chemins automatiques
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
REPORT_DIR="$PROJECT_ROOT/build-reports"
IMAGE_NAME="localhost/miage-bank:v1"
TAR_PATH="$PROJECT_ROOT/image.tar"

mkdir -p "$REPORT_DIR"

echo "--- Démarrage de l'exportation des rapports ---"

# 1. LINTING
echo "Export Hadolint..."
if hadolint "$PROJECT_ROOT/Partie A/01-image-build/Containerfile" > "$REPORT_DIR/hadolint-report.txt" 2>&1; then
    echo "Containerfile est parfait !" >> "$REPORT_DIR/hadolint-report.txt"
fi

# 2. BUILD & EXPORT (pour être sûr d'avoir le tar pour les autres outils)
echo "Build et Export TAR..."
buildah bud -t $IMAGE_NAME "$PROJECT_ROOT/Partie A/01-image-build/"
buildah push $IMAGE_NAME "docker-archive:$TAR_PATH"

# 3. TRIVY (On force l'écriture du JSON et du texte)
echo "Export Trivy..."
trivy image --input "$TAR_PATH" --severity HIGH,CRITICAL --format json --output "$REPORT_DIR/trivy-report.json"
trivy image --input "$TAR_PATH" --severity HIGH,CRITICAL > "$REPORT_DIR/trivy-report.txt" 2>&1

# 4. DIVE
echo "Export Dive..."
CI=true dive --source docker-archive "$TAR_PATH" --lowestEfficiency=0.95 > "$REPORT_DIR/dive-report.txt" 2>&1

echo "--- TERMINÉ : ALLER On verifie le dossier build-reports ---"