# JARVIS Cloud - Memory API

A cloud-hosted AI memory system providing long-term semantic memory storage via REST API. Built on [Redis Agent Memory Server](https://github.com/redis/agent-memory-server) with vector search, deployed to Azure Container Apps.

Any service, device, or application can consume this API to store, retrieve, and search memories.

## Architecture

```
                                    JARVIS Cloud Memory API

    +-----------------+     +-----------------+     +-----------------+
    |   JARVIS Voice  |     |  Smart Home     |     |   Mobile        |
    |   Assistant     |     |   Devices       |     |    App          |
    +--------+--------+     +--------+--------+     +--------+--------+
             |                       |                       |
             |      HTTPS REST API Calls                     |
             |                       |                       |
             v                       v                       v
    +---------------------------------------------------------------+
    |                                                               |
    |              JARVIS Cloud Memory API                          |
    |   https://agent-memory-server.lemonbay-c4ff031f.eastus2...    |
    |                                                               |
    |    +---------------------------------------------------+     |
    |    |            API Endpoints                           |     |
    |    |  POST /v1/long-term-memory/        (create)       |     |
    |    |  POST /v1/long-term-memory/search  (semantic)     |     |
    |    |  GET  /health                       (health)      |     |
    |    +---------------------------------------------------+     |
    |                        |                                     |
    |                        v                                     |
    |    +---------------------------------------------------+     |
    |    |         Redis Agent Memory Server                  |     |
    |    |  - OpenAI embeddings (text-embedding-3-small)     |     |
    |    |  - Semantic vector search                          |     |
    |    |  - Memory deduplication                            |     |
    |    +---------------------------------------------------+     |
    |                        |                                     |
    |                        v                                     |
    |    +---------------------------------------------------+     |
    |    |         Redis Stack (RediSearch)                   |     |
    |    |  - Vector similarity search                        |     |
    |    |  - High-performance storage                        |     |
    |    +---------------------------------------------------+     |
    |                                                               |
    +---------------------------------------------------------------+

                     Azure Container Apps
```

### Azure Infrastructure

```
+-----------------------------------------------------------------------+
|                    Azure Container Apps                                 |
|                    (rg-youni-dev, East US 2)                           |
|                                                                         |
|  +------------------+    +------------------------+                    |
|  |   Redis Stack    |    |  Agent Memory Server   |                    |
|  |   (Vectors)      |<---|       (REST)           |                    |
|  |                  |    |                        |                    |
|  |  internal        |    |  external              |                    |
|  |  :6379 (TCP)     |    |  :8000                 |                    |
|  +------------------+    +-----------+------------+                    |
|                                      |                                  |
+--------------------------------------+----------------------------------+
                                       |
                             +---------+---------+
                             |   HTTPS Access    |
                             +---------+---------+
                                       |
                       +---------------+---------------+
                       |   REST API Consumers          |
                       |  - JARVIS Voice Assistant     |
                       |  - Smart Home/HA              |
                       |  - Mobile Apps                |
                       |  - Any HTTP Client            |
                       +-------------------------------+
```

## Base URL

```
https://agent-memory-server.lemonbay-c4ff031f.eastus2.azurecontainerapps.io
```

---

# API Reference

## Authentication

Currently no authentication required. Uses `namespace` parameter to isolate data.

## Common Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `namespace` | string | Unique identifier for the user/device/service (default: "jarvis") |
| `id` | string | Unique memory identifier (UUID recommended) |

---

## Long-Term Memory

### Create Memory

Store a new memory with semantic embeddings.

**Endpoint:** `POST /v1/long-term-memory/`

**Request Body:**
```json
{
  "id": "string (required) - unique ID",
  "text": "string (required) - content to remember",
  "namespace": "string (optional, default: 'jarvis')"
}
```

**Example:**
```bash
curl -X POST "https://agent-memory-server.lemonbay-c4ff031f.eastus2.azurecontainerapps.io/v1/long-term-memory/" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "mem-001",
    "text": "User prefers temperature set to 72 degrees",
    "namespace": "jarvis"
  }'
```

**Response:**
```json
{
  "id": "mem-001",
  "text": "User prefers temperature set to 72 degrees",
  "namespace": "jarvis"
}
```

---

### Search Memories (Semantic)

Find memories using semantic similarity search.

**Endpoint:** `POST /v1/long-term-memory/search`

**Request Body:**
```json
{
  "text": "string (required) - search query",
  "namespace": "string (optional, default: 'jarvis')",
  "limit": 5
}
```

**Example:**
```bash
curl -X POST "https://agent-memory-server.lemonbay-c4ff031f.eastus2.azurecontainerapps.io/v1/long-term-memory/search" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "temperature preferences",
    "namespace": "jarvis",
    "limit": 5
  }'
```

**Response:**
```json
{
  "memories": [
    {
      "id": "mem-001",
      "text": "User prefers temperature set to 72 degrees",
      "dist": 0.234
    }
  ]
}
```

---

### Health Check

**Endpoint:** `GET /health`

**Example:**
```bash
curl "https://agent-memory-server.lemonbay-c4ff031f.eastus2.azurecontainerapps.io/health"
```

---

# Integration Examples

## Python

```python
import requests
import uuid

BASE_URL = "https://agent-memory-server.lemonbay-c4ff031f.eastus2.azurecontainerapps.io"
NAMESPACE = "jarvis"

# Create a memory
def create_memory(text):
    response = requests.post(
        f"{BASE_URL}/v1/long-term-memory/",
        json={"id": str(uuid.uuid4()), "text": text, "namespace": NAMESPACE}
    )
    return response.json()

# Search memories (semantic)
def search_memories(query, limit=5):
    response = requests.post(
        f"{BASE_URL}/v1/long-term-memory/search",
        json={"text": query, "namespace": NAMESPACE, "limit": limit}
    )
    return response.json()

# Usage
create_memory("User's favorite color is blue")
results = search_memories("favorite color")
print(results)
```

## JavaScript/Node.js

```javascript
const BASE_URL = "https://agent-memory-server.lemonbay-c4ff031f.eastus2.azurecontainerapps.io";
const NAMESPACE = "jarvis";

// Create a memory
async function createMemory(text) {
  const response = await fetch(`${BASE_URL}/v1/long-term-memory/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      id: crypto.randomUUID(),
      text,
      namespace: NAMESPACE
    })
  });
  return response.json();
}

// Search memories (semantic)
async function searchMemories(query, limit = 5) {
  const response = await fetch(`${BASE_URL}/v1/long-term-memory/search`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text: query, namespace: NAMESPACE, limit })
  });
  return response.json();
}

// Usage
await createMemory("User wakes up at 7 AM");
const results = await searchMemories("wake up time");
console.log(results);
```

## cURL (Shell Scripts)

```bash
#!/bin/bash
BASE_URL="https://agent-memory-server.lemonbay-c4ff031f.eastus2.azurecontainerapps.io"
NAMESPACE="jarvis"

# Create memory
create_memory() {
  curl -s -X POST "$BASE_URL/v1/long-term-memory/" \
    -H "Content-Type: application/json" \
    -d "{\"id\": \"$(uuidgen)\", \"text\": \"$1\", \"namespace\": \"$NAMESPACE\"}"
}

# Search memories (semantic)
search_memories() {
  curl -s -X POST "$BASE_URL/v1/long-term-memory/search" \
    -H "Content-Type: application/json" \
    -d "{\"text\": \"$1\", \"namespace\": \"$NAMESPACE\", \"limit\": 5}"
}

# Usage
create_memory "User prefers jazz music"
search_memories "music preferences"
```

---

# Deployment

## Prerequisites

- Azure CLI installed and logged in (`az login`)
- Azure Subscription
- OpenAI API Key

## Azure Resources

| Resource | Type | Name | Purpose |
|----------|------|------|---------|
| Container Registry | Microsoft.ContainerRegistry | `jarvisacrafttmtxdb5reg` | Docker images |
| Log Analytics | Microsoft.OperationalInsights | `jarvis-law-*` | Logging |
| Container Apps Environment | Microsoft.App/managedEnvironments | `jarvis-cae-afttmtxdb5reg` | Hosts containers |
| Storage Account | Microsoft.Storage | `jarvisredisstore` | Redis persistence |
| File Share | Azure Files | `redis-data` | Redis AOF data |
| Container App | Microsoft.App/containerApps | `redis` | Vector database (internal) |
| Container App | Microsoft.App/containerApps | `agent-memory-server` | Memory API |

## Deploy Redis Stack with Persistence

```bash
# 1. Create storage account
az storage account create \
  --name jarvisredisstore \
  --resource-group rg-youni-dev \
  --location eastus2 \
  --sku Standard_LRS

# 2. Create file share
az storage share-rm create \
  --resource-group rg-youni-dev \
  --storage-account jarvisredisstore \
  --name redis-data \
  --quota 1024

# 3. Link storage to environment
STORAGE_KEY=$(az storage account keys list -n jarvisredisstore --resource-group rg-youni-dev --query "[0].value" -o tsv)
az containerapp env storage set \
  --name jarvis-cae-afttmtxdb5reg \
  --resource-group rg-youni-dev \
  --storage-name redisdata \
  --azure-file-account-name jarvisredisstore \
  --azure-file-account-key "$STORAGE_KEY" \
  --azure-file-share-name redis-data \
  --access-mode ReadWrite

# 4. Create Redis with volume mount (use YAML for volume config)
az containerapp create \
  --name redis \
  --resource-group rg-youni-dev \
  --environment jarvis-cae-afttmtxdb5reg \
  --image redis/redis-stack:latest \
  --cpu 0.5 --memory 1Gi \
  --min-replicas 1 --max-replicas 1 \
  --ingress internal --target-port 6379 --transport tcp

# 5. Export and update with volume mount
az containerapp show --name redis --resource-group rg-youni-dev --output yaml > redis.yaml
# Add volumes and volumeMounts (see redis-app.yaml example)
az containerapp update --name redis --resource-group rg-youni-dev --yaml redis.yaml
```

## Deploy Agent Memory Server

```bash
# Create agent-memory-server container
az containerapp create \
  --name agent-memory-server \
  --resource-group rg-youni-dev \
  --environment jarvis-cae-afttmtxdb5reg \
  --image ghcr.io/redis/agent-memory-server:latest \
  --cpu 0.5 --memory 1Gi \
  --min-replicas 1 --max-replicas 3 \
  --ingress external --target-port 8000 \
  --env-vars \
    REDIS_URL="redis://redis:6379" \
    OPENAI_API_KEY="YOUR_OPENAI_KEY" \
    DISABLE_AUTH="true" \
    LONG_TERM_MEMORY="true" \
    LOG_LEVEL="INFO"
```

## Update OpenAI API Key

```bash
az containerapp update \
  --name agent-memory-server \
  --resource-group rg-youni-dev \
  --set-env-vars OPENAI_API_KEY="YOUR_NEW_KEY"
```

---

# Project Structure

```
jarvis-cloud/
+-- README.md              # This documentation
+-- .env.example           # Environment template
+-- azure/
|   +-- redis.yaml         # Redis Stack container definition
|   +-- agent-memory-server.yaml  # Memory API container definition
|   +-- qdrant.yaml        # (deprecated - was for Mem0)
|   +-- mem0-api.yaml      # (deprecated - replaced by Redis)
+-- scripts/
    +-- deploy.sh          # Deployment script
```

---

# Monitoring

```bash
# View agent-memory-server logs
az containerapp logs show --name agent-memory-server --resource-group rg-youni-dev --tail 100

# View Redis logs
az containerapp logs show --name redis --resource-group rg-youni-dev --tail 100

# Check health
curl https://agent-memory-server.lemonbay-c4ff031f.eastus2.azurecontainerapps.io/health
```

---

# Troubleshooting

## Memory search returns empty

Check agent-memory-server logs:
```bash
az containerapp logs show --name agent-memory-server --resource-group rg-youni-dev --tail 50
```

Verify OpenAI API key is set:
```bash
az containerapp show --name agent-memory-server --resource-group rg-youni-dev \
  --query "properties.template.containers[0].env"
```

## Connection timeout

Ensure Redis is running:
```bash
az containerapp show --name redis --resource-group rg-youni-dev \
  --query "properties.runningStatus"
```

## Persistence

Redis is configured with AOF (Append Only File) persistence, mounted to Azure Files:

- **Storage Account:** `jarvisredisstore`
- **File Share:** `redis-data`
- **Mount Path:** `/data`
- **Redis Args:** `--appendonly yes --dir /data`

Data persists across container restarts. To verify:
```bash
az storage file list --account-name jarvisredisstore --share-name redis-data --output table
```

---

# Related Projects

- [JARVIS Voice](https://github.com/vyente-ruffin/jarvis-voice) - Voice assistant frontend
- [Redis Agent Memory Server](https://github.com/redis/agent-memory-server) - Memory framework
- [Redis Stack](https://redis.io/docs/stack/) - Vector database

---

# License

MIT
