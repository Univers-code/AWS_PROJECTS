#!/bin/bash
set -euo pipefail

echo "Necesita crear el lifecycle primero antes de ejecutarlo, sino dará error."
echo "Las configuraciones del lifecyle son independientes para cada uso."
sleep 5
clear


GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'


success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }


DEFAULT_REGION=$(aws configure get region)

read -p "BUCKET NAME: " NAME
read -p "REGION [$DEFAULT_REGION]: " REGION_INPUT
REGION=${REGION_INPUT:-$DEFAULT_REGION}


echo "Creando bucket..."
if aws s3api head-bucket --bucket "$NAME" 2>/dev/null; then
    warn "El bucket ya existe: $NAME"
    exit 1
fi


if [[ "$DEFAULT_REGION" != "$REGION" ]]; then
    aws s3api create-bucket --bucket "$NAME" --region "$REGION"  --create-bucket-configuration LocationConstraint="$REGION"
else
    aws s3api create-bucket --bucket "$NAME" --region "$DEFAULT_REGION"
fi

success "Bucket creado satisfactoriamente: $NAME"


echo "Habilitando versioning..."
aws s3api put-bucket-versioning --bucket "$NAME" --versioning-configuration Status=Enabled
aws s3api get-bucket-versioning --bucket "$NAME"
success "Bucket versioning aplicado correctamente!"


echo "Buscando archivos lifecycle..."
LIFE=( $(find . -maxdepth 1 -name "*lifecycle*.json") )

if [[ ${#LIFE[@]} -eq 0 ]]; then
    error "No se encontró ningún archivo lifecycle en el directorio."
    echo "Eliminando bucket $NAME"

    aws s3api delete-bucket --bucket "$NAME"
    success "El bucket fue eliminado sastifactoriamente."
    echo "Para volver a ejecutar, por favor crear el lifecyle."
    sleep 2
    exit 1
fi

echo "Archivos encontrados:"
for f in "${LIFE[@]}"; do
    echo " - $f"
done

read -p "Escriba el archivo lifecycle a utilizar: " LIFECYCLE

if [[ ! -f "$LIFECYCLE" ]]; then
    error "Archivo '$LIFECYCLE' no existe!"
    exit 1
fi

aws s3api put-bucket-lifecycle-configuration --bucket "$NAME" --lifecycle-configuration file://"$LIFECYCLE"

success "Lifecycle aplicado correctamente!"

success "Script culminado satisfactoriamente!"