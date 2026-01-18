# JARVIS Cloud - Memory API

> **DEPRECATION NOTICE:** This project has been superseded by [eon-memory](https://github.com/vyente-ruffin/eon-memory). All Azure resources are tagged with `cleanup=true` and scheduled for deletion. See the [Azure Resources](#azure-resources) section for the full list.

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

> **All resources below are tagged with `cleanup=true` and scheduled for deletion.**

### Resource Group: `rg-youni-dev` (eastus2)

| Resource | Type | Name | Purpose | Tag |
|----------|------|------|---------|-----|
| Container Registry | Microsoft.ContainerRegistry | `jarvisacrafttmtxdb5reg` | Docker images | `cleanup=true` |
| Log Analytics | Microsoft.OperationalInsights | `jarvis-law-afttmtxdb5reg` | Logging | `cleanup=true` |
| Application Insights | Microsoft.Insights/components | `jarvis-appi-afttmtxdb5reg` | Monitoring | `cleanup=true` |
| Container Apps Environment | Microsoft.App/managedEnvironments | `jarvis-cae-afttmtxdb5reg` | Hosts containers | `cleanup=true` |
| Storage Account | Microsoft.Storage | `jarvisredisstore` | Redis persistence (redis-data file share) | `cleanup=true` |
| Container App | Microsoft.App/containerApps | `redis` | Vector database (prod, internal) | `cleanup=true` |
| Container App | Microsoft.App/containerApps | `agent-memory-server` | Memory API (prod) | `cleanup=true` |
| Container App | Microsoft.App/containerApps | `redis-insight` | Redis web UI | `cleanup=true` |
| Azure OpenAI | Microsoft.CognitiveServices | `jarvis-voice-openai` | Embeddings API (shared with jarvis-voice) | `cleanup=true` |

### Resource Group: `rg-jarvis-dev` (eastus2)

| Resource | Type | Name | Purpose | Tag |
|----------|------|------|---------|-----|
| Container App | Microsoft.App/containerApps | `agent-memory-server-dev` | Memory API (dev) | `cleanup=true` |
| Container App | Microsoft.App/containerApps | `redis-dev` | Vector database (dev, internal) | `cleanup=true` |

### Cleanup Commands

To delete all tagged resources:

```bash
# List all resources with cleanup=true tag
az resource list --tag cleanup=true --query "[].{name:name, resourceGroup:resourceGroup, type:type}" -o table

# Delete resources (run for each resource group)
az resource list -g rg-youni-dev --tag cleanup=true --query "[].id" -o tsv | xargs -I {} az resource delete --ids {}
az resource list -g rg-jarvis-dev --tag cleanup=true --query "[].id" -o tsv | xargs -I {} az resource delete --ids {}

# Delete resource group (after all resources are removed)
az group delete --name rg-jarvis-dev --yes
```

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

# Redis Insight (Web UI)

A web-based UI for browsing and managing Redis data visually.

**URL:** https://redis-insight.lemonbay-c4ff031f.eastus2.azurecontainerapps.io

## UI Overview

Redis Insight provides a graphical interface to explore your Redis database:

```
+------------------------------------------------------------------+
|  Redis Logo    [Databases]  redis:6379  /  db0     [Refresh] [i] |
+------------------------------------------------------------------+
|  [Browse]  [Workbench]  [Analyze]  [Pub/Sub]                     |
+------------------------------------------------------------------+
|  LEFT PANEL (Tree View)     |  RIGHT PANEL (Details)             |
|                             |                                     |
|  > memory_idx (7 keys)      |  Hash: memory_idx:azure-test-001   |
|    - 01KF2MGXEB32...        |  Key Size: 8 KB  |  Length: 15     |
|    - azure-test-001  <--    |                                     |
|    - jarvis-858c...         |  Field          | Value            |
|  > memory-server (9 keys)   |  ---------------+------------------+
|  > runs (8 keys)            |  text           | User favorite... |
|  > working_memory (1 key)   |  memory_type    | semantic         |
|                             |  user_id        | sudo             |
+------------------------------------------------------------------+
```

## Step-by-Step: Viewing Memories

### 1. Connect to Database
- Open the URL in your browser
- Redis database `redis:6379` is auto-discovered
- Click on it to connect (or it may auto-connect)

### 2. Navigate the Browser Tab
- The **Browse** tab is selected by default
- Left panel shows a tree view of all Redis keys organized by namespace
- Right panel shows details of the selected key

### 3. Understanding the Folders

| Folder | Keys | Contents |
|--------|------|----------|
| `memory_idx` | 7 | **Your memories** - Each Hash contains one memory with text, metadata, and vector embedding |
| `memory-server` | 9 | Internal processing stream and events (serialized data, not human-readable) |
| `runs` | 8 | Background job tracking |
| `working_memory` | 1 | Short-term working memory buffer |

### 4. View a Memory
1. Click the arrow next to `memory_idx` to expand it
2. You'll see a list of Hash keys (your memory IDs)
3. Click any Hash entry (e.g., `azure-test-001`)
4. Right panel shows all fields in a table:
   - **Field** column: field names
   - **Value** column: field values
   - Look for the `text` field - that's your actual memory content

### 5. Key UI Elements

| Element | Location | Purpose |
|---------|----------|---------|
| **Tree View toggle** | Top of left panel | Switch between tree and list view |
| **Filter box** | Top of left panel | Search keys by name pattern |
| **Key Type dropdown** | Next to filter | Filter by type (Hash, String, Stream, etc.) |
| **Refresh button** | Top right | Reload data from Redis |
| **Unicode dropdown** | Above details table | Change encoding (keep as Unicode) |
| **Add Fields** | Above details table | Add new fields to a Hash |
| **Delete Key** | Top right of details | Delete the selected key |

## Memory Data Structure

Each memory in `memory_idx` is stored as a Redis Hash:

| Field | Type | Description |
|-------|------|-------------|
| `text` | string | **The actual memory content** (human-readable) |
| `memory_type` | string | Always "semantic" for long-term memories |
| `user_id` | string | User namespace (e.g., "sudo") |
| `topics` | string | Comma-separated topic tags (e.g., "jarvis-voice") |
| `id_` | string | Unique memory ID |
| `embedding` | binary | 1536-dimension vector for semantic search (not human-readable) |
| `created_at` | float | Unix timestamp when memory was created |
| `updated_at` | float | Unix timestamp when memory was last modified |
| `last_accessed` | float | Unix timestamp when memory was last retrieved |
| `access_count` | int | Number of times this memory was accessed |
| `memory_hash` | string | SHA256 hash for deduplication |
| `pinned` | int | 1 if pinned, 0 if not |
| `_metadata_json` | JSON | Full metadata as JSON (redundant but searchable) |
| `_index_name` | string | Redis index name ("memory_records") |

## Other Useful Tabs

| Tab | Purpose |
|-----|---------|
| **Workbench** | Run Redis commands directly (e.g., `KEYS *`, `HGETALL memory_idx:*`) |
| **Analyze** | View memory usage and key distribution statistics |
| **Pub/Sub** | Monitor real-time pub/sub messages |

## CLI Alternative

You can also access the same data via the Workbench tab or CLI:

```bash
# List all memory keys
KEYS memory_idx:*

# Get all fields for a specific memory
HGETALL memory_idx:azure-test-001

# Get just the text field
HGET memory_idx:azure-test-001 text
```

## Deploy Redis Insight

```bash
az containerapp create \
  --name redis-insight \
  --resource-group rg-youni-dev \
  --environment jarvis-cae-afttmtxdb5reg \
  --image redis/redisinsight:latest \
  --cpu 0.25 --memory 0.5Gi \
  --min-replicas 1 --max-replicas 1 \
  --ingress external --target-port 5540
```

---

# Related Projects

- [JARVIS Voice](https://github.com/vyente-ruffin/jarvis-voice) - Voice assistant frontend
- [Redis Agent Memory Server](https://github.com/redis/agent-memory-server) - Memory framework
- [Redis Stack](https://redis.io/docs/stack/) - Vector database

---

# License

MIT
