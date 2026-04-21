# Demo 04: Deploy to Azure Kubernetes Service (AKS)

**Time: ~5 minutes (pre-deployed, show results)**

> **Pre-deploy before the session**: Run `infra/scripts/start.sh` → option 1

## What You'll Show

1. DocumentDB operator installed on AKS via Helm
2. DocumentDB cluster running as a K8s custom resource
3. External access via LoadBalancer
4. Same connection string pattern

## Steps (during demo, cluster is already running)

### 1. Show the Cluster

```bash
# Show nodes
kubectl get nodes

# Show DocumentDB operator
kubectl get pods -n documentdb-operator

# Show DocumentDB instance
kubectl get documentdb -n documentdb-ns
kubectl get pods -n documentdb-ns
```

### 2. Show the Custom Resource

```bash
kubectl describe documentdb docdb-demo -n documentdb-ns
```

### 3. Get Connection Info

```bash
# Get external IP
kubectl get svc -n documentdb-ns

# Connect
mongosh "mongodb://docdb:<password>@<EXTERNAL-IP>:10260/?tls=true&tlsAllowInvalidCertificates=true&authMechanism=SCRAM-SHA-256"
```

### 4. Show Same Data

```javascript
// Import same dataset
// Run same queries
// Same results as local
db.listings.find({ property_type: "Apartment" }).limit(3)
```

## How It Was Deployed

Walk through `infra/azure/deploy.sh`:
1. Bicep template creates AKS cluster
2. cert-manager installed (required by operator)
3. DocumentDB operator installed via Helm
4. DocumentDB custom resource applied
5. LoadBalancer exposes the service

## Talking Points

- "Same DocumentDB, now on Kubernetes"
- "Operator manages lifecycle — scaling, backups, failover"
- "Helm chart makes installation a one-liner"
- "Your app code doesn't change — same MongoDB connection string"
