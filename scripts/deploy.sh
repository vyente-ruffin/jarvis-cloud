#!/bin/bash
#
# JARVIS Cloud - Azure Deployment Script
# Deploys Mem0 Memory System to Azure Container Apps
#
# Usage: ./scripts/deploy.sh <resource-group> <acr-name> <openai-api-key>
#

set -e

# Configuration
RESOURCE_GROUP="${1:-jarvis-rg}"
ACR_NAME="${2:-jarvisacr}"
OPENAI_API_KEY="${3}"
LOCATION="eastus"
ENVIRONMENT_NAME="jarvis-env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Validate inputs
if [ -z "$OPENAI_API_KEY" ]; then
    error "Usage: $0 <resource-group> <acr-name> <openai-api-key>"
fi

log "Starting JARVIS Cloud deployment..."
log "Resource Group: $RESOURCE_GROUP"
log "ACR: $ACR_NAME"
log "Location: $LOCATION"

# Step 1: Create Resource Group
log "Creating resource group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# Step 2: Create Azure Container Registry
log "Creating Azure Container Registry..."
az acr create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$ACR_NAME" \
    --sku Basic \
    --admin-enabled true \
    --output none || warn "ACR may already exist"

# Step 3: Build and push custom Mem0 image
log "Building custom Mem0 image with Qdrant fix..."
az acr build \
    --registry "$ACR_NAME" \
    --image mem0-patched:v3 \
    --file Dockerfile \
    .

# Step 4: Create Container Apps Environment
log "Creating Container Apps environment..."
az containerapp env create \
    --name "$ENVIRONMENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output none || warn "Environment may already exist"

# Get environment ID for FQDN
ENV_ID=$(az containerapp env show --name "$ENVIRONMENT_NAME" --resource-group "$RESOURCE_GROUP" --query "properties.defaultDomain" -o tsv | cut -d'.' -f2)
log "Environment ID: $ENV_ID"

# Step 5: Deploy Qdrant (internal only)
log "Deploying Qdrant vector database..."
az containerapp create \
    --name qdrant \
    --resource-group "$RESOURCE_GROUP" \
    --environment "$ENVIRONMENT_NAME" \
    --image qdrant/qdrant:latest \
    --cpu 0.5 \
    --memory 1Gi \
    --target-port 6333 \
    --ingress internal \
    --min-replicas 1 \
    --max-replicas 1 \
    --output none || warn "Qdrant may already exist"

# Enable insecure connections for HTTP
az containerapp ingress update \
    --name qdrant \
    --resource-group "$RESOURCE_GROUP" \
    --allow-insecure \
    --output none

QDRANT_FQDN="qdrant.internal.${ENV_ID}.${LOCATION}.azurecontainerapps.io"
log "Qdrant internal FQDN: $QDRANT_FQDN"

# Step 6: Deploy Mem0 API
log "Deploying Mem0 API..."
az containerapp create \
    --name mem0-api \
    --resource-group "$RESOURCE_GROUP" \
    --environment "$ENVIRONMENT_NAME" \
    --image "${ACR_NAME}.azurecr.io/mem0-patched:v3" \
    --registry-server "${ACR_NAME}.azurecr.io" \
    --cpu 0.5 \
    --memory 1Gi \
    --target-port 8765 \
    --ingress external \
    --min-replicas 1 \
    --max-replicas 3 \
    --secrets "openai-key=${OPENAI_API_KEY}" \
    --env-vars "OPENAI_API_KEY=secretref:openai-key" "USER=sudo" \
    --output none || warn "Mem0 API may already exist"

MEM0_API_URL=$(az containerapp show --name mem0-api --resource-group "$RESOURCE_GROUP" --query "properties.configuration.ingress.fqdn" -o tsv)
log "Mem0 API URL: https://$MEM0_API_URL"

# Step 7: Deploy Mem0 UI
log "Deploying Mem0 UI..."
az containerapp create \
    --name mem0-ui \
    --resource-group "$RESOURCE_GROUP" \
    --environment "$ENVIRONMENT_NAME" \
    --image mem0ai/openmemory-ui:latest \
    --cpu 0.25 \
    --memory 0.5Gi \
    --target-port 3000 \
    --ingress external \
    --min-replicas 1 \
    --max-replicas 1 \
    --env-vars "NEXT_PUBLIC_API_URL=https://${MEM0_API_URL}" "NEXT_PUBLIC_USER_ID=sudo" \
    --output none || warn "Mem0 UI may already exist"

MEM0_UI_URL=$(az containerapp show --name mem0-ui --resource-group "$RESOURCE_GROUP" --query "properties.configuration.ingress.fqdn" -o tsv)
log "Mem0 UI URL: https://$MEM0_UI_URL"

# Summary
echo ""
echo "=============================================="
echo -e "${GREEN}JARVIS Cloud Deployment Complete!${NC}"
echo "=============================================="
echo ""
echo "Mem0 API:  https://$MEM0_API_URL"
echo "Mem0 UI:   https://$MEM0_UI_URL"
echo "API Docs:  https://$MEM0_API_URL/docs"
echo ""
echo "Test with:"
echo "  curl -X POST https://$MEM0_API_URL/api/v1/memories/ \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"user_id\": \"sudo\", \"text\": \"Test memory\"}'"
echo ""
