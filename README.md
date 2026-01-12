# JARVIS Cloud - Memory API

A cloud-hosted AI memory system providing long-term semantic memory storage via REST API. Built on [Mem0](https://github.com/mem0ai/mem0) and [Qdrant](https://qdrant.tech/), deployed to Azure Container Apps.

Any service, device, or application can consume this API to store, retrieve, and search memories.

## Architecture

```
                                    JARVIS Cloud Memory API

    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
    │   ADA V2    │     │  Smart Home │     │   Mobile    │
    │  Assistant  │     │   Devices   │     │    App      │
    └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
           │                   │                   │
           │      HTTPS REST API Calls             │
           │                   │                   │
           ▼                   ▼                   ▼
    ┌─────────────────────────────────────────────────────┐
    │                                                     │
    │              JARVIS Cloud Memory API                │
    │         https://mem0-api.<env>.azurecontainerapps.io│
    │                                                     │
    │    ┌─────────────────────────────────────────┐     │
    │    │            API Endpoints                 │     │
    │    │  POST /api/v1/memories/     (create)    │     │
    │    │  GET  /api/v1/memories/     (list)      │     │
    │    │  POST /api/v1/memories/filter (search)  │     │
    │    │  GET  /api/v1/stats/        (stats)     │     │
    │    └─────────────────────────────────────────┘     │
    │                        │                           │
    │                        ▼                           │
    │    ┌─────────────────────────────────────────┐     │
    │    │              Mem0 Engine                 │     │
    │    │  • Fact extraction (OpenAI GPT-4o-mini) │     │
    │    │  • Embeddings (text-embedding-3-small)  │     │
    │    │  • Deduplication & categorization       │     │
    │    └─────────────────────────────────────────┘     │
    │                        │                           │
    │                        ▼                           │
    │    ┌─────────────────────────────────────────┐     │
    │    │         Qdrant Vector Database          │     │
    │    │  • Semantic similarity search           │     │
    │    │  • High-performance vector storage      │     │
    │    └─────────────────────────────────────────┘     │
    │                                                     │
    └─────────────────────────────────────────────────────┘

                     Azure Container Apps
```

## Base URL

```
https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io
```

**Interactive API Documentation:** [/docs](https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/docs)

---

# API Reference

## Authentication

Currently no authentication required. All requests use `user_id` parameter to isolate data.

## Common Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `user_id` | string | Unique identifier for the user/device/service |
| `app` | string | Application name (e.g., "jarvis", "smart-home") |

---

## Memories

### Create Memory

Store a new memory. The system automatically extracts facts and generates embeddings.

**Endpoint:** `POST /api/v1/memories/`

**Request Body:**
```json
{
  "user_id": "string (required)",
  "text": "string (required) - The content to remember",
  "app": "string (optional, default: 'openmemory')",
  "metadata": {"key": "value"},
  "infer": true
}
```

**Example:**
```bash
curl -X POST "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/memories/" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "jarvis-001",
    "text": "User prefers temperature set to 72 degrees",
    "app": "smart-home"
  }'
```

**Response:**
```json
{
  "id": "e1cc967e-a332-4a3f-a9f2-9d18f62a2bf0",
  "content": "Prefers temperature set to 72 degrees",
  "state": "active",
  "app_id": "58be6e2a-c33f-44fa-acd5-15c085169200",
  "created_at": "2026-01-11T20:42:42.621330",
  "user_id": "bcce6c42-5277-4245-a9df-43b3d7f00287"
}
```

---

### List Memories

Retrieve all memories for a user.

**Endpoint:** `GET /api/v1/memories/`

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `user_id` | string | Yes | User identifier |
| `app_id` | uuid | No | Filter by application |
| `from_date` | integer | No | Unix timestamp - filter after this date |
| `to_date` | integer | No | Unix timestamp - filter before this date |
| `categories` | string | No | Filter by category |
| `search_query` | string | No | Text search |
| `page` | integer | No | Page number (default: 1) |
| `size` | integer | No | Page size (default: 50, max: 100) |

**Example:**
```bash
curl "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/memories/?user_id=jarvis-001&size=10"
```

---

### Search/Filter Memories

Advanced search with multiple filters.

**Endpoint:** `POST /api/v1/memories/filter`

**Request Body:**
```json
{
  "user_id": "string (required)",
  "search_query": "string (optional) - semantic search",
  "app_ids": ["uuid array (optional)"],
  "category_ids": ["uuid array (optional)"],
  "from_date": 1718505600,
  "to_date": 1718592000,
  "sort_column": "created_at",
  "sort_direction": "desc",
  "page": 1,
  "size": 50
}
```

**Example:**
```bash
curl -X POST "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/memories/filter" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "jarvis-001",
    "search_query": "temperature preferences"
  }'
```

---

### Get Single Memory

Retrieve a specific memory by ID.

**Endpoint:** `GET /api/v1/memories/{memory_id}`

**Example:**
```bash
curl "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/memories/e1cc967e-a332-4a3f-a9f2-9d18f62a2bf0"
```

---

### Update Memory

Update an existing memory's content.

**Endpoint:** `PUT /api/v1/memories/{memory_id}`

**Request Body:**
```json
{
  "memory_content": "string (required) - new content",
  "user_id": "string (required)"
}
```

**Example:**
```bash
curl -X PUT "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/memories/e1cc967e-a332-4a3f-a9f2-9d18f62a2bf0" \
  -H "Content-Type: application/json" \
  -d '{
    "memory_content": "Prefers temperature set to 70 degrees",
    "user_id": "jarvis-001"
  }'
```

---

### Delete Memories

Delete one or more memories.

**Endpoint:** `DELETE /api/v1/memories/`

**Request Body:**
```json
{
  "memory_ids": ["uuid array (required)"],
  "user_id": "string (required)"
}
```

**Example:**
```bash
curl -X DELETE "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/memories/" \
  -H "Content-Type: application/json" \
  -d '{
    "memory_ids": ["e1cc967e-a332-4a3f-a9f2-9d18f62a2bf0"],
    "user_id": "jarvis-001"
  }'
```

---

### Get Related Memories

Find memories semantically related to a specific memory.

**Endpoint:** `GET /api/v1/memories/{memory_id}/related`

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `user_id` | string | Yes | User identifier |
| `page` | integer | No | Page number |
| `size` | integer | No | Page size |

**Example:**
```bash
curl "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/memories/e1cc967e-a332-4a3f-a9f2-9d18f62a2bf0/related?user_id=jarvis-001"
```

---

### Get Categories

List all memory categories for a user.

**Endpoint:** `GET /api/v1/memories/categories`

**Example:**
```bash
curl "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/memories/categories?user_id=jarvis-001"
```

---

### Archive Memories

Archive memories (soft delete).

**Endpoint:** `POST /api/v1/memories/actions/archive`

**Query Parameters:**
| Parameter | Type | Required |
|-----------|------|----------|
| `user_id` | uuid | Yes |

**Request Body:** Array of memory UUIDs
```json
["uuid1", "uuid2", "uuid3"]
```

---

### Pause Memories

Temporarily pause memories from being returned in searches.

**Endpoint:** `POST /api/v1/memories/actions/pause`

**Request Body:**
```json
{
  "user_id": "string (required)",
  "memory_ids": ["uuid array (optional)"],
  "category_ids": ["uuid array (optional)"],
  "app_id": "uuid (optional)",
  "all_for_app": false,
  "global_pause": false,
  "state": "paused"
}
```

---

### Get Memory Access Log

View access history for a specific memory.

**Endpoint:** `GET /api/v1/memories/{memory_id}/access-log`

**Query Parameters:**
| Parameter | Type | Default |
|-----------|------|---------|
| `page` | integer | 1 |
| `page_size` | integer | 10 |

---

## Applications

Track which applications/services are creating memories.

### List Applications

**Endpoint:** `GET /api/v1/apps/`

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Filter by app name |
| `is_active` | boolean | Filter by active status |
| `sort_by` | string | Sort column (default: "name") |
| `sort_direction` | string | "asc" or "desc" |
| `page` | integer | Page number |
| `page_size` | integer | Results per page |

**Example:**
```bash
curl "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/apps/"
```

---

### Get Application Details

**Endpoint:** `GET /api/v1/apps/{app_id}`

---

### Update Application

Enable/disable an application.

**Endpoint:** `PUT /api/v1/apps/{app_id}?is_active=true`

---

### Get Application Memories

List all memories created by a specific application.

**Endpoint:** `GET /api/v1/apps/{app_id}/memories`

---

### Get Application Access History

List memories accessed by a specific application.

**Endpoint:** `GET /api/v1/apps/{app_id}/accessed`

---

## Statistics

### Get User Stats

Get memory statistics for a user.

**Endpoint:** `GET /api/v1/stats/`

**Query Parameters:**
| Parameter | Type | Required |
|-----------|------|----------|
| `user_id` | string | Yes |

**Example:**
```bash
curl "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/stats/?user_id=jarvis-001"
```

**Response:**
```json
{
  "total_memories": 42,
  "total_apps": 3,
  "apps": [
    {
      "id": "7b85aa0b-678b-4199-a7d1-596ba6cf36f4",
      "name": "jarvis",
      "is_active": true,
      "created_at": "2026-01-11T20:41:26.139667"
    }
  ]
}
```

---

## Configuration

### Get Current Configuration

**Endpoint:** `GET /api/v1/config/`

**Example:**
```bash
curl "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/config/"
```

---

### Update Configuration

**Endpoint:** `PUT /api/v1/config/`

**Request Body:**
```json
{
  "openmemory": {
    "custom_instructions": "string - custom fact extraction instructions"
  },
  "mem0": {
    "llm": {
      "provider": "openai",
      "config": {
        "model": "gpt-4o-mini",
        "temperature": 0.1,
        "max_tokens": 2000
      }
    },
    "embedder": {
      "provider": "openai",
      "config": {
        "model": "text-embedding-3-small"
      }
    }
  }
}
```

---

### Reset Configuration

Reset to default configuration.

**Endpoint:** `POST /api/v1/config/reset`

---

### LLM Configuration

- `GET /api/v1/config/mem0/llm` - Get LLM settings
- `PUT /api/v1/config/mem0/llm` - Update LLM settings

### Embedder Configuration

- `GET /api/v1/config/mem0/embedder` - Get embedder settings
- `PUT /api/v1/config/mem0/embedder` - Update embedder settings

### OpenMemory Configuration

- `GET /api/v1/config/openmemory` - Get custom instructions
- `PUT /api/v1/config/openmemory` - Update custom instructions

---

# Integration Examples

## Python

```python
import requests

BASE_URL = "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io"
USER_ID = "jarvis-001"

# Create a memory
def create_memory(text, app="jarvis"):
    response = requests.post(
        f"{BASE_URL}/api/v1/memories/",
        json={"user_id": USER_ID, "text": text, "app": app}
    )
    return response.json()

# Search memories
def search_memories(query):
    response = requests.post(
        f"{BASE_URL}/api/v1/memories/filter",
        json={"user_id": USER_ID, "search_query": query}
    )
    return response.json()

# Get stats
def get_stats():
    response = requests.get(f"{BASE_URL}/api/v1/stats/?user_id={USER_ID}")
    return response.json()

# Usage
create_memory("User's favorite color is blue")
results = search_memories("favorite color")
print(results)
```

## JavaScript/Node.js

```javascript
const BASE_URL = "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io";
const USER_ID = "jarvis-001";

// Create a memory
async function createMemory(text, app = "jarvis") {
  const response = await fetch(`${BASE_URL}/api/v1/memories/`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ user_id: USER_ID, text, app })
  });
  return response.json();
}

// Search memories
async function searchMemories(query) {
  const response = await fetch(`${BASE_URL}/api/v1/memories/filter`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ user_id: USER_ID, search_query: query })
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
BASE_URL="https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io"
USER_ID="jarvis-001"

# Create memory
create_memory() {
  curl -s -X POST "$BASE_URL/api/v1/memories/" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\": \"$USER_ID\", \"text\": \"$1\", \"app\": \"jarvis\"}"
}

# Search memories
search_memories() {
  curl -s -X POST "$BASE_URL/api/v1/memories/filter" \
    -H "Content-Type: application/json" \
    -d "{\"user_id\": \"$USER_ID\", \"search_query\": \"$1\"}"
}

# Usage
create_memory "User prefers jazz music"
search_memories "music preferences"
```

## Home Assistant / IoT Devices

```yaml
# Example Home Assistant REST command
rest_command:
  jarvis_remember:
    url: "https://mem0-api.greenstone-413be1c4.eastus.azurecontainerapps.io/api/v1/memories/"
    method: POST
    content_type: "application/json"
    payload: '{"user_id": "home-assistant", "text": "{{ memory }}", "app": "smart-home"}'
```

---

# Web Dashboard

A web UI is available to view and manage memories:

**URL:** https://mem0-ui.greenstone-413be1c4.eastus.azurecontainerapps.io

Features:
- View all memories
- Search and filter
- Edit/delete memories
- View statistics
- Manage applications

---

# Deployment

## Prerequisites

- Azure CLI installed and logged in (`az login`)
- Azure Subscription
- OpenAI API Key

## Quick Deploy

```bash
git clone https://github.com/vyente-ruffin/jarvis-cloud.git
cd jarvis-cloud
./scripts/deploy.sh <resource-group> <acr-name> <openai-api-key>
```

## Manual Deployment

See [scripts/deploy.sh](scripts/deploy.sh) for step-by-step Azure CLI commands.

---

# Project Structure

```
jarvis-cloud/
├── README.md              # This documentation
├── Dockerfile             # Custom Mem0 image with Azure fix
├── .env.example           # Environment template
├── azure/
│   ├── qdrant.yaml        # Qdrant container definition
│   ├── mem0-api.yaml      # Mem0 API container definition
│   └── mem0-ui.yaml       # Mem0 UI container definition
└── scripts/
    └── deploy.sh          # Automated deployment script
```

---

# Troubleshooting

## Memory client not available

Check API logs:
```bash
az containerapp logs show --name mem0-api --resource-group jarvis-rg --tail 50
```

Look for successful Qdrant connection:
```
HTTP Request: POST http://qdrant.internal.<env>/collections/... "HTTP/1.1 200 OK"
```

## Connection timeout

Ensure Qdrant allows insecure connections:
```bash
az containerapp ingress update --name qdrant --resource-group jarvis-rg --allow-insecure
```

## API returns null

This is normal when:
- Memory content is deduplicated (already exists)
- The `infer` parameter extracted no new facts

Check stats endpoint to verify memories are being stored.

---

# Related Projects

- [ADA V2](https://github.com/nazirlouis/ada_v2) - JARVIS personal assistant
- [Mem0](https://github.com/mem0ai/mem0) - Underlying memory framework
- [Qdrant](https://qdrant.tech/) - Vector database

---

# License

MIT
