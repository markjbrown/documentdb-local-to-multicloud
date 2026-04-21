# DocumentDB: From Localhost to Multi-Cloud

Build, test, and scale across clouds with DocumentDB.

**Session:** From Localhost to Multi-Cloud: Building Production-Ready Apps with DocumentDB
**Event:** Techorama Belgium 2026 (May 11-13, Antwerp)
**Speaker:** Mark Brown

## What You'll Learn

- Set up a complete local development environment in under 5 minutes
- Build AI-powered features with built-in vector search (no API keys required)
- Use Index Advisor to automatically optimize slow queries
- Deploy to Kubernetes on any cloud provider
- Implement cross-cloud failover for true high availability
- Build CI/CD pipelines that test against real DocumentDB instances

## Quick Start

```bash
# Clone and start everything (DocumentDB + auto-loaded sample data)
git clone https://github.com/AzureCosmosDB/documentdb-local-to-multicloud.git
cd documentdb-local-to-multicloud
docker compose up -d

# Connect with mongosh
mongosh "mongodb://demo:demo@localhost:27017/?tls=true&tlsAllowInvalidCertificates=true"
```

That's it. DocumentDB is running locally with 20,000 restaurant documents and vector embeddings pre-loaded.

## Prerequisites

- [Docker Desktop](https://www.docker.com/)
- [Visual Studio Code](https://code.visualstudio.com/)
- [DocumentDB for VS Code Extension](https://marketplace.visualstudio.com/items?itemName=ms-documentdb.vscode-documentdb)
- Python 3.11+ (for demo scripts)

## Repository Structure

```
├── scripts/                    # Demo scripts (query, vector search, data gen)
│   ├── query_examples.py       # Index Advisor demo (before/after COLLSCAN→IXSCAN)
│   ├── vector_restaurants_demo.py  # Vector search with fake embeddings
│   ├── fake_embeddings.py      # Deterministic embeddings (no API key needed)
│   ├── generate_restaurants.py # Generate synthetic restaurant data
│   └── load_restaurants.py     # Load data into DocumentDB
├── data/                       # Sample datasets
│   ├── restaurants.json        # 20K restaurant documents
│   ├── restaurants_vectors.json # Same + 256-dim vector embeddings
│   └── embedded_data.json      # 1K Airbnb listings with OpenAI embeddings
├── infra/
│   ├── azure/                  # Bicep template + deploy script for AKS
│   ├── aws/                    # eksctl config + deploy script for EKS
│   └── scripts/                # Start/stop for cost management
├── docker-compose.yml          # One-command local setup with auto-seeding
├── docker/seed/                # Auto-seed containers
├── k8s/                        # Kubernetes manifests (AKS + EKS)
├── demo/                       # Per-section demo guides with commands
├── docs/                       # Presenter runbook + technical docs
├── monitoring/                 # Prometheus alerts
├── tests/                      # Integration tests
├── .github/workflows/          # CI/CD with DocumentDB emulator
├── .devcontainer/              # GitHub Codespaces config
└── SETUP.md                    # Detailed setup instructions
```

## Demo Scripts

### Index Advisor Demo (query_examples.py)

Interactive demo showing before/after query optimization:

```bash
pip install -r requirements.txt
python scripts/query_examples.py
```

Shows 6 scenarios with COLLSCAN → IXSCAN transitions, timing comparisons, and compound index creation.

### Vector Search Demo (vector_restaurants_demo.py)

Semantic search using deterministic fake embeddings (no OpenAI API key required):

```bash
python scripts/vector_restaurants_demo.py --query "cozy romantic date night pasta" --mode compact --k 10
```

### Data Generation

Generate fresh restaurant data with configurable hot clusters:

```bash
python scripts/generate_restaurants.py --count 5000 --hot-count 1000 --hot-cuisine Italian
```

## Multi-Cloud Deployment

### Azure (AKS)

```bash
bash infra/azure/deploy.sh
```

### AWS (EKS)

```bash
bash infra/aws/deploy.sh
```

### Cost Management

```bash
bash infra/scripts/start.sh   # Start clusters for rehearsal/demo
bash infra/scripts/stop.sh    # Stop/delete to save costs
```

See [SETUP.md](SETUP.md) for detailed instructions.

## License

MIT
