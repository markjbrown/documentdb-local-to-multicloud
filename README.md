# DocumentDB: From Localhost to Multi-Cloud

Build, test, and scale across clouds with DocumentDB.

**Session:** From Localhost to Multi-Cloud: Building Production-Ready Apps with DocumentDB
**Event:** Techorama Belgium 2026 (May 11-13, Antwerp)
**Speaker:** Mark Brown

## What You'll Learn

- Set up a complete local development environment in under 5 minutes
- Build AI-powered features with built-in vector search
- Use Index Advisor to automatically optimize slow queries
- Deploy to Kubernetes on any cloud provider
- Implement cross-cloud failover for true high availability
- Build CI/CD pipelines that test against real DocumentDB instances

## Prerequisites

- [Docker Desktop](https://www.docker.com/)
- [Visual Studio Code](https://code.visualstudio.com/)
- [DocumentDB for VS Code Extension](https://marketplace.visualstudio.com/items?itemName=ms-documentdb.vscode-documentdb)

## Quick Start

```bash
# Pull and run DocumentDB locally
docker pull ghcr.io/documentdb/documentdb/documentdb-local:latest
docker run -dt -p 10260:10260 --name docdb ghcr.io/documentdb/documentdb/documentdb-local:latest --username demo --password test

# Connect with mongosh
mongosh "mongodb://demo:test@localhost:10260/?tls=true&tlsAllowInvalidCertificates=true"
```

## License

MIT
