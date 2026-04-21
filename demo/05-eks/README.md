# Demo 05: Deploy to AWS Elastic Kubernetes Service (EKS)

**Time: ~4 minutes (pre-deployed, show results)**

> **Pre-deploy before the session**: Run `infra/scripts/start.sh` → option 2

## What You'll Show

1. Same operator, same Helm chart, different cloud
2. DocumentDB running on EKS with NLB
3. Connection string is identical pattern

## Steps (during demo, cluster is already running)

### 1. Switch Context

```bash
kubectl config use-context eks-demo
```

### 2. Show the Cluster

```bash
kubectl get nodes
kubectl get documentdb -n documentdb-ns
kubectl get pods -n documentdb-ns
kubectl get svc -n documentdb-ns
```

### 3. Connect

```bash
mongosh "mongodb://docdb:<password>@<NLB-HOSTNAME>:10260/?tls=true&tlsAllowInvalidCertificates=true&authMechanism=SCRAM-SHA-256"
```

### 4. Side-by-Side Comparison

Show both terminals:
- Left: AKS cluster (`kubectl config use-context aks-demo`)
- Right: EKS cluster (`kubectl config use-context eks-demo`)

```bash
# Same command, different cloud
kubectl get documentdb -n documentdb-ns
```

## Key Differences from AKS

| Aspect | AKS | EKS |
|--------|-----|-----|
| Storage class | managed-premium | gp3 |
| Load balancer | Azure LB | AWS NLB |
| Auth | Managed Identity | IAM Roles |
| Deploy tool | Bicep + az CLI | eksctl |
| **DocumentDB config** | **Identical** | **Identical** |

## Talking Points

- "Exact same Helm chart, exact same operator, exact same DocumentDB"
- "Only the storage class and load balancer annotations change"
- "Your application code is 100% unchanged"
- "This is what open source + Kubernetes gives you: true portability"
