# Demo 06: Multi-Cloud High Availability and Failover

**Time: ~5 minutes**

> This demo builds on demos 04 and 05 with both clusters running.

## What You'll Show

1. Both clusters running simultaneously
2. Replication between AKS and EKS
3. Live failover from one cloud to another

## Architecture

```
       Application
           |
      DNS / Router
        /       \
   AKS            EKS
  (Primary)     (Secondary)
      |              |
  DocumentDB    DocumentDB
   Cluster       Cluster
      \              /
   PostgreSQL Logical
      Replication
```

## Steps

### 1. Show Both Clusters

```bash
# AKS
kubectl --context aks-demo get documentdb,pods -n documentdb-ns

# EKS
kubectl --context eks-demo get documentdb,pods -n documentdb-ns
```

### 2. Show Replication Status

```bash
# Check replication lag
for ctx in aks-demo eks-demo; do
  echo "=== $ctx ==="
  kubectl --context $ctx get documentdb -n documentdb-ns -o wide
done
```

### 3. Write to Primary, Read from Secondary

```bash
# Write to AKS (primary)
mongosh "mongodb://docdb:<password>@<AKS-IP>:10260/..." --eval '
  db.demo.insertOne({ 
    source: "aks-primary", 
    timestamp: new Date(), 
    message: "Hello from Azure!" 
  })
'

# Read from EKS (secondary) - verify replication
mongosh "mongodb://docdb:<password>@<EKS-IP>:10260/..." --eval '
  db.demo.find({ source: "aks-primary" })
'
```

### 4. Simulate Failover

```bash
# Promote EKS to primary
kubectl documentdb promote \
  --documentdb docdb-demo \
  --namespace documentdb-ns \
  --hub-context hub \
  --target-cluster eks-demo \
  --cluster-context eks-demo

# Verify new primary
kubectl --context eks-demo get documentdb -n documentdb-ns -o wide
```

### 5. Write to New Primary

```bash
# Write to EKS (now primary)
mongosh "mongodb://docdb:<password>@<EKS-IP>:10260/..." --eval '
  db.demo.insertOne({
    source: "eks-primary",
    timestamp: new Date(),
    message: "Hello from AWS! Failover complete."
  })
'
```

## Talking Points

- "Your database just failed over from Azure to AWS in 30 seconds"
- "No application code changes — DNS handles routing"
- "This is real multi-cloud HA, not marketing slides"
- "Built on PostgreSQL logical replication — battle-tested"
- "You could add GKE as a third region with the same operator"
