#!/bin/bash

# Configuration des chemins
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
REPORT_DIR="$PROJECT_ROOT/build-reports"
CONTAINERFILE_PATH="Partie A/01-image-build/Containerfile"

# Liste des micro-services
SERVICES=("amc_clients" "amc_comptes")

mkdir -p "$REPORT_DIR"
rm -f "$PROJECT_ROOT"/*.tar

echo "--- Démarrage de l'automatisation industrielle (MIAGE-Bank) ---"

# 1. LINTING
echo "[1/4] Analyse Hadolint..."
hadolint "$PROJECT_ROOT/$CONTAINERFILE_PATH" > "$REPORT_DIR/hadolint-report.txt" 2>&1

# On se place à la racine pour que le contexte de build soit correct
cd "$PROJECT_ROOT" || exit

for SERVICE in "${SERVICES[@]}"; do
    IMAGE_NAME="localhost/miage-bank-$SERVICE:v1"
    TAR_PATH="$PROJECT_ROOT/$SERVICE.tar"
    
    # Chemin relatif du JAR depuis la racine du projet (SANS le / au début)
    JAR_PATH="src/AMSC/$SERVICE/target/$SERVICE-0.0.1-SNAPSHOT.jar"

    echo "-----------------------------------"
    echo "TRAITEMENT : $SERVICE"
    echo "-----------------------------------"

    # 2. BUILD & EXPORT
    echo "[2/4] Buildah : Construction de $IMAGE_NAME..."
    # On lance le build avec le contexte actuel (.)
    buildah bud --build-arg JAR_FILE="$JAR_PATH" -f "$CONTAINERFILE_PATH" -t "$IMAGE_NAME" .
    
    echo "[2/4] Export de l'archive $SERVICE.tar..."
    buildah push "$IMAGE_NAME" "docker-archive:$TAR_PATH"

    # 3. TRIVY
    echo "[3/4] Trivy : Scan de sécurité..."
    trivy image --input "$TAR_PATH" --severity HIGH,CRITICAL --format json --output "$REPORT_DIR/trivy-$SERVICE.json"

    # 4. DIVE
    echo "[4/4] Dive : Audit d'efficience..."
    CI=true dive --source docker-archive "$TAR_PATH" --lowestEfficiency=0.95 > "$REPORT_DIR/dive-$SERVICE.txt" 2>&1
done

echo "--- TERMINÉ : Les rapports sont dans le dossier build-reports ---"