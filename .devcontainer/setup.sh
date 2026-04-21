#!/bin/bash
# Post-create setup for Codespaces / devcontainer
set -e

echo "=== Setting up DocumentDB demo environment ==="

# Install Python dependencies
pip install pymongo python-dotenv openai langchain fastapi uvicorn

# Pull and start DocumentDB local
echo "Starting DocumentDB local..."
docker pull ghcr.io/documentdb/documentdb/documentdb-local:latest
docker run -dt -p 10260:10260 --name docdb \
  ghcr.io/documentdb/documentdb/documentdb-local:latest \
  --username demo --password test

# Wait for DocumentDB to be ready
echo "Waiting for DocumentDB..."
for i in {1..20}; do
  if docker exec docdb mongosh "mongodb://demo:test@localhost:10260/?tls=true&tlsAllowInvalidCertificates=true" --eval "db.runCommand({ping:1})" 2>/dev/null; then
    echo "✅ DocumentDB is ready"
    break
  fi
  sleep 3
done

echo ""
echo "=== Setup complete ==="
echo "DocumentDB: mongodb://demo:test@localhost:10260/?tls=true&tlsAllowInvalidCertificates=true"
