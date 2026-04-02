#!/bin/bash
set -e

# Creacion de bucket
read -r -p "BUCKET NAME: " NOMBRE
read -r -p "REGION [us-east-1]: " REGION
REGION="${REGION:-us-east-1}"

aws s3api create-bucket --bucket $NOMBRE --region $REGION
BUCKET=$NOMBRE

# Creacion de las policy y public access
aws s3api put-public-access-block --bucket $BUCKET --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

aws s3api put-bucket-policy --bucket $BUCKET --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
        \"Effect\": \"Allow\",
        \"Principal\": \"*\",
        \"Action\": \"s3:GetObject\",
        \"Resource\": \"arn:aws:s3:::$BUCKET/*\"
    }]
}"

# Crear archivos HTML
echo "<h1> My bucket is RUNNING </h1>" > index.html
echo "<h1> Pagina no encontrada </h1>" > error.html
INDEX="index.html"
ERROR="error.html"

# Hosting web del bucket
aws s3 website s3://$BUCKET --index-document $INDEX --error-document $ERROR

aws s3 sync . s3://$BUCKET --exclude "*.sh"

echo "✓ Bucket is already running!"
echo "  http://$BUCKET.s3-website-$REGION.amazonaws.com"