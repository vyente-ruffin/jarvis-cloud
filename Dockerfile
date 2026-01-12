# JARVIS Cloud - Mem0 API with Azure Container Apps Qdrant Fix
#
# This Dockerfile patches the OpenMemory MCP server to work with
# Azure Container Apps internal ingress for Qdrant connectivity.
#
# Build: az acr build --registry <acr-name> --image mem0-patched:v3 .
#
FROM mem0/openmemory-mcp:latest

# Patch the default Qdrant host to use Azure internal FQDN
# Replace 'greenstone-413be1c4' with your Container Apps environment ID
ARG QDRANT_FQDN=qdrant.internal.greenstone-413be1c4.eastus.azurecontainerapps.io

# Patch the default host from 'mem0_store' to Azure internal FQDN
RUN sed -i "s/\"host\": \"mem0_store\"/\"host\": \"${QDRANT_FQDN}\"/" /usr/src/openmemory/app/utils/memory.py

# Patch the fallback port from 6333 to 80 (Azure internal ingress uses port 80)
RUN sed -i 's/"port": 6333/"port": 80/' /usr/src/openmemory/app/utils/memory.py

# The base image already exposes port 8765 and sets the entrypoint
