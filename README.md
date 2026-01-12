# JARVIS Cloud - Azure Memory System

A cloud-hosted AI memory system built on [Mem0](https://github.com/mem0ai/mem0) and [Qdrant](https://qdrant.tech/), deployed to Azure Container Apps. This serves as the long-term memory backend for the [ADA V2](https://github.com/nazirlouis/ada_v2) personal assistant.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Azure Container Apps                                 │
│                         (jarvis-env)                                        │
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐         │
│  │                 │    │                 │    │                 │         │
│  │     Qdrant      │◄───│    Mem0 API     │    │    Mem0 UI      │         │
│  │  Vector Store   │    │   (MCP Server)  │    │   (Dashboard)   │         │
│  │                 │    │                 │    │                 │         │
│  │   Port: 6333    │    │   Port: 8765    │    │   Port: 3000    │         │
│  │   (internal)    │    │   (external)    │    │   (external)    │         │
│  │                 │    │                 │    │                 │         │
│  └─────────────────┘    └────────┬────────┘    └────────┬────────┘         │
│                                  │                      │                   │
│         Internal Ingress         │    External Ingress  │                   │
│         (port 80)                │    (HTTPS)           │                   │
│                                  │                      │                   │
└──────────────────────────────────┼──────────────────────┼───────────────────┘
                                   │                      │
                                   ▼                      ▼
                    ┌──────────────────────────┐  ┌──────────────────┐
                    │                          │  │                  │
                    │   MCP SSE Endpoint       │  │   Web Browser    │
                    │   /mcp/claude/sse/sudo   │  │   Dashboard      │
                    │                          │  │                  │
                    └──────────────┬───────────┘  └──────────────────┘
                                   │
                                   ▼
                    ┌──────────────────────────┐
                    │                          │
                    │        ADA V2            │
                    │   Personal Assistant     │
                    │                          │
                    └──────────────────────────┘
```

## Components

| Component | Image | Purpose |
|-----------|-------|---------|
| **Qdrant** | `qdrant/qdrant:latest` | Vector database for semantic memory search |
| **Mem0 API** | `mem0-patched:v3` (custom) | Memory API + MCP server for AI agents |
| **Mem0 UI** | `mem0ai/openmemory-ui:latest` | Web dashboard to view/manage memories |

## Current Deployment

| Resource | URL |
|----------|-----|
| Mem0 API | https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io |
| Mem0 UI | https://mem0-ui.greenstone-413be1c4.eastus.azurecontainerapps.io |
| API Docs | https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/docs |

## Prerequisites

- **Azure CLI** installed and logged in (`az login`)
- **Azure Subscription** with Container Apps support
- **OpenAI API Key** for memory extraction and embeddings
- **Azure Container Registry** (created during deployment)

## Quick Start

### Option 1: Automated Deployment

```bash
# Clone the repo
git clone https://github.com/vyente-ruffin/jarvis-cloud.git
cd jarvis-cloud

# Run deployment script
./scripts/deploy.sh jarvis-rg jarvisacr sk-proj-your-openai-key
```

### Option 2: Manual Deployment

#### Step 1: Create Resource Group & Environment

```bash
# Set variables
RESOURCE_GROUP="jarvis-rg"
LOCATION="eastus"
ACR_NAME="jarvisacr$(date +%s)"
ENVIRONMENT="jarvis-env"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true

# Create Container Apps environment
az containerapp env create --name $ENVIRONMENT --resource-group $RESOURCE_GROUP --location $LOCATION
```

#### Step 2: Build Custom Mem0 Image

The official `mem0/openmemory-mcp` image has hardcoded Qdrant settings. We patch it for Azure:

```bash
# Build and push to ACR
az acr build --registry $ACR_NAME --image mem0-patched:v3 --file Dockerfile .
```

#### Step 3: Deploy Qdrant

```bash
az containerapp create \
  --name qdrant \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image qdrant/qdrant:latest \
  --cpu 0.5 --memory 1Gi \
  --target-port 6333 \
  --ingress internal \
  --min-replicas 1

# Enable HTTP access (required for mem0)
az containerapp ingress update --name qdrant --resource-group $RESOURCE_GROUP --allow-insecure
```

#### Step 4: Deploy Mem0 API

```bash
az containerapp create \
  --name mem0-api \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image ${ACR_NAME}.azurecr.io/mem0-patched:v3 \
  --registry-server ${ACR_NAME}.azurecr.io \
  --cpu 0.5 --memory 1Gi \
  --target-port 8765 \
  --ingress external \
  --secrets "openai-key=sk-proj-your-key" \
  --env-vars "OPENAI_API_KEY=secretref:openai-key" "USER=sudo"
```

#### Step 5: Deploy Mem0 UI

```bash
# Get the Mem0 API URL
MEM0_API_URL=$(az containerapp show --name mem0-api --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)

az containerapp create \
  --name mem0-ui \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT \
  --image mem0ai/openmemory-ui:latest \
  --cpu 0.25 --memory 0.5Gi \
  --target-port 3000 \
  --ingress external \
  --env-vars "NEXT_PUBLIC_API_URL=https://${MEM0_API_URL}" "NEXT_PUBLIC_USER_ID=sudo"
```

## Usage

### Add a Memory via API

```bash
curl -X POST "https://mem0-api.<env>.eastus.azurecontainerapps.io/api/v1/memories/" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "sudo",
    "text": "I prefer dark mode for all applications"
  }'
```

### Search Memories

```bash
curl "https://mem0-api.<env>.eastus.azurecontainerapps.io/api/v1/memories/?user_id=sudo"
```

### Get Stats

```bash
curl "https://mem0-api.<env>.eastus.azurecontainerapps.io/api/v1/stats/?user_id=sudo"
```

### MCP Integration (for AI Agents)

Connect your AI agent to the MCP SSE endpoint:

```
https://mem0-api.<env>.eastus.azurecontainerapps.io/mcp/claude/sse/sudo
```

## Project Structure

```
jarvis-cloud/
├── README.md              # This file
├── Dockerfile             # Custom Mem0 image with Azure fix
├── azure/
│   ├── qdrant.yaml        # Qdrant container app definition
│   ├── mem0-api.yaml      # Mem0 API container app definition
│   └── mem0-ui.yaml       # Mem0 UI container app definition
├── scripts/
│   └── deploy.sh          # Automated deployment script
└── .env.example           # Environment variables template
```

## Key Technical Details

### The Qdrant Fix

The official `mem0/openmemory-mcp` image has Qdrant connection settings hardcoded to `mem0_store:6333` (Docker Compose service name). For Azure Container Apps, we need to:

1. **Change the host** to the Azure internal FQDN: `qdrant.internal.<env>.<region>.azurecontainerapps.io`
2. **Change the port** from `6333` to `80` (Azure internal ingress proxies to container port)
3. **Enable insecure connections** on Qdrant ingress (HTTP, not HTTPS internally)

This is done by patching the source code in the Dockerfile:

```dockerfile
RUN sed -i 's/"host": "mem0_store"/"host": "qdrant.internal.<env>.eastus.azurecontainerapps.io"/' \
    /usr/src/openmemory/app/utils/memory.py
RUN sed -i 's/"port": 6333/"port": 80/' /usr/src/openmemory/app/utils/memory.py
```

### Azure Container Apps Internal Ingress

- Internal services use port 80/443, NOT the container port
- The internal FQDN follows: `<app-name>.internal.<env-id>.<region>.azurecontainerapps.io`
- `allowInsecure: true` is required for HTTP communication between containers

## Troubleshooting

### Memory client not available

Check the Mem0 API logs:
```bash
az containerapp logs show --name mem0-api --resource-group jarvis-rg --tail 50
```

Look for:
- `Qdrant response: {'results': []}` - Qdrant connected successfully
- `HTTP/1.1 200 OK` to Qdrant URL - Connection working
- `timed out` or `Name or service not known` - Connection issue

### 301 Redirect Error

Enable insecure connections on Qdrant:
```bash
az containerapp ingress update --name qdrant --resource-group jarvis-rg --allow-insecure
```

## Related Projects

- [ADA V2](https://github.com/nazirlouis/ada_v2) - Personal AI assistant that uses this memory system
- [JARVIS On-Prem](https://github.com/vyente-ruffin/jarvis-onprem) - Local/on-prem version for Claude Code MCP
- [Mem0](https://github.com/mem0ai/mem0) - The underlying memory framework
- [Qdrant](https://qdrant.tech/) - Vector database for semantic search

## License

MIT
