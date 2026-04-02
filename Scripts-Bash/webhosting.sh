#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
error()   { echo -e "${RED}❌ $1${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $1${NC}"; }


# ── REGIÓN Y BUCKET ──
DEFAULT_REGION=$(aws configure get region)
read -p "Bucket Name: " NAME
read -p "Region [$DEFAULT_REGION]: " REGION
REGION=${REGION:-$DEFAULT_REGION}

if [[ "$REGION" == "us-east-1" ]]; then
  aws s3api create-bucket --bucket "$NAME" --region "$REGION" > /dev/null
else
  aws s3api create-bucket --bucket "$NAME" --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" > /dev/null
fi

BUCKET="$NAME"
success "Bucket Creado: $BUCKET"





# ── VERIFICAR ARCHIVOS EN ./dist ──
for EXT in html css js php; do
  COUNT=$(find . -name "*.$EXT" | wc -l | tr -d ' ')
  if [ "$COUNT" -gt 0 ]; then
    success ".$EXT — $COUNT archivo(s)"
  else
    error ".$EXT — ninguno encontrado"
  fi
done

# ── EXTENSIONES A EXCLUIR ──
echo
echo "=== Extensiones a excluir ==="
echo "Escribe una extensión sin punto (ej: log, txt)"
echo "Escribe 'q' para terminar."
echo

EXTENSIONS=()
while true; do
  read -p "Extension: " ext
  if [[ "$ext" == "q" ]]; then
    echo "Finalizando entrada..."
    break
  fi
  if [[ -n "$ext" ]]; then
    EXTENSIONS+=("$ext")
    echo "Agregado: $ext"
  fi
done

echo
echo "Extensiones excluidas:"
printf " - %s\n" "${EXTENSIONS[@]}"

EXCLUDE_ARGS=()
for e in "${EXTENSIONS[@]}"; do
  EXCLUDE_ARGS+=(--exclude "*.$e")
done

# ── SUBIR ARCHIVOS ──
aws s3 sync . "s3://$BUCKET" "${EXCLUDE_ARGS[@]}"
success "Archivos subidos"

# ── VERIFICAR ACCESO PÚBLICO ──
BLOCK=$(aws s3api get-public-access-block \
  --bucket "$BUCKET" \
  --query "PublicAccessBlockConfiguration.BlockPublicPolicy" \
  --output text 2>/dev/null || echo "False")

if [ "$BLOCK" = "True" ]; then
  success "Bucket privado"
else
  warn "Bucket público — bloqueando..."
  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  success "Bloqueado"
fi

# ── OAC ──
OAC_FILE=$(find . -maxdepth 1 -name "oac.json" | head -1)

if [[ -n "$OAC_FILE" ]]; then
  success "oac.json encontrado"
  OAC_ID=$(aws cloudfront create-origin-access-control \
    --origin-access-control-config file://$OAC_FILE \
    --query "OriginAccessControl.Id" --output text)
else
  warn "oac.json no encontrado — usando configuración predeterminada..."
  OAC_ID=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config "$(printf '{
    "Name": "%s-oac-%s",
    "Description": "OAC para %s",
    "OriginAccessControlOriginType": "s3",
    "SigningBehavior": "always",
    "SigningProtocol": "sigv4"
  }' "$BUCKET" "$(date +%s)" "$BUCKET")" \
  --query "OriginAccessControl.Id" --output text)
fi
success "OAC creado: $OAC_ID"

# ── DISTRIBUCIÓN ──
DIST_FILE=$(find . -maxdepth 1 -name "distribution.json" | head -1)  # FIX Bug 2

if [[ -n "$DIST_FILE" ]]; then
  success "distribution.json encontrado"
  DISTRIBUTION_ID=$(aws cloudfront create-distribution \
    --distribution-config file://$DIST_FILE \
    --query "Distribution.Id" --output text)  # FIX Bug 4
else
  warn "distribution.json no encontrado — usando configuración predeterminada..."
  DISTRIBUTION_ID=$(aws cloudfront create-distribution \
    --distribution-config "$(printf '{
      "CallerReference": "%s-%s",
      "Comment": "Distribucion para %s",
      "Enabled": true,
      "HttpVersion": "http2and3",
      "IsIPV6Enabled": true,
      "DefaultRootObject": "index.html",
      "PriceClass": "PriceClass_100",
      "Origins": {
        "Quantity": 1,
        "Items": [{
          "Id": "S3Origin",
          "DomainName": "%s.s3.%s.amazonaws.com",
          "S3OriginConfig": { "OriginAccessIdentity": "" },
          "OriginAccessControlId": "%s"
        }]
      },
      "DefaultCacheBehavior": {
        "TargetOriginId": "S3Origin",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
          "Quantity": 2,
          "Items": ["GET", "HEAD"],
          "CachedMethods": { "Quantity": 2, "Items": ["GET", "HEAD"] }
        },
        "Compress": true,
        "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
        "OriginRequestPolicyId": "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
      },
      "CustomErrorResponses": {
      "Quantity": 2,
      "Items": [
        { "ErrorCode": 403, "ResponseCode": "200", "ResponsePagePath": "/index.html", "ErrorCachingMinTTL": 10 },
        { "ErrorCode": 404, "ResponseCode": "200", "ResponsePagePath": "/index.html", "ErrorCachingMinTTL": 10 }
      ]
     }
    }' "$BUCKET" "$(date +%s)" "$BUCKET" "$BUCKET" "$REGION" "$OAC_ID")" \
    --query "Distribution.Id" --output text)  # FIX Bug 3
fi
success "Distribución creada: $DISTRIBUTION_ID"

# ── BUCKET POLICY ──
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
POLICY_FILE=$(find . -maxdepth 1 -name "policy.json" | head -1)

if [[ -n "$POLICY_FILE" ]]; then
  success "policy.json encontrado"
  aws s3api put-bucket-policy --bucket "$BUCKET" --policy file://$POLICY_FILE
else
  warn "policy.json no encontrado — usando configuración predeterminada..."
  aws s3api put-bucket-policy \
    --bucket "$BUCKET" \
    --policy "$(printf '{
      "Version": "2012-10-17",
      "Statement": [{
        "Sid": "AllowCloudFrontOAC",
        "Effect": "Allow",
        "Principal": { "Service": "cloudfront.amazonaws.com" },
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::%s/*",
        "Condition": {
          "StringEquals": {
            "AWS:SourceArn": "arn:aws:cloudfront::%s:distribution/%s"
          }
        }
      }]
    }' "$BUCKET" "$ACCOUNT_ID" "$DISTRIBUTION_ID")"
fi
success "Bucket Policy aplicada"

# ── RESUMEN FINAL ──
echo ""
echo "========================================"
success "Despliegue completado"
echo "  Bucket:       s3://$BUCKET"
echo "  Distribución: $DISTRIBUTION_ID"
echo "  URL:          https://$(aws cloudfront get-distribution --id "$DISTRIBUTION_ID" --query "Distribution.DomainName" --output text)"
echo "========================================"