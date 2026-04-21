#!/bin/bash
# Start demo infrastructure - spin up both AKS and EKS clusters
# Run this before rehearsing or on demo day
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-docdb-demo-rg}"
AKS_CLUSTER="${AKS_CLUSTER:-docdb-demo-aks}"
EKS_CLUSTER="${EKS_CLUSTER:-docdb-demo-eks}"
EKS_REGION="${EKS_REGION:-us-west-2}"

echo "============================================"
echo "  DocumentDB Demo Infrastructure - START"
echo "============================================"
echo ""

# Check prerequisites
command -v az >/dev/null 2>&1 || { echo "❌ Azure CLI required"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI required"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl required"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "❌ Helm required"; exit 1; }

echo "Choose what to start:"
echo "  1) AKS only (Azure)"
echo "  2) EKS only (AWS)"
echo "  3) Both clusters (multi-cloud demo)"
echo "  4) Local only (Docker)"
read -rp "Selection [1-4]: " choice

case $choice in
  1)
    echo ""
    echo "=== Starting AKS cluster ==="
    # Start stopped AKS cluster
    az aks start --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" 2>/dev/null || {
      echo "Cluster not found. Deploying new cluster..."
      bash "$REPO_ROOT/infra/azure/deploy.sh"
    }
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing
    echo "✅ AKS cluster running"
    kubectl get nodes
    ;;
  2)
    echo ""
    echo "=== Starting EKS cluster ==="
    # Check if EKS cluster exists
    aws eks describe-cluster --name "$EKS_CLUSTER" --region "$EKS_REGION" >/dev/null 2>&1 || {
      echo "Cluster not found. Deploying new cluster..."
      bash "$REPO_ROOT/infra/aws/deploy.sh"
    }
    aws eks update-kubeconfig --name "$EKS_CLUSTER" --region "$EKS_REGION"
    echo "✅ EKS cluster running"
    kubectl get nodes
    ;;
  3)
    echo ""
    echo "=== Starting both clusters ==="
    # Start AKS
    echo "Starting AKS..."
    az aks start --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" 2>/dev/null || {
      echo "AKS not found. Deploying..."
      bash "$REPO_ROOT/infra/azure/deploy.sh"
    }
    # Start/verify EKS
    echo "Verifying EKS..."
    aws eks describe-cluster --name "$EKS_CLUSTER" --region "$EKS_REGION" >/dev/null 2>&1 || {
      echo "EKS not found. Deploying..."
      bash "$REPO_ROOT/infra/aws/deploy.sh"
    }
    # Get credentials for both
    az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" --overwrite-existing --context aks-demo
    aws eks update-kubeconfig --name "$EKS_CLUSTER" --region "$EKS_REGION" --alias eks-demo
    echo ""
    echo "✅ Both clusters running"
    echo "AKS context: aks-demo"
    echo "EKS context: eks-demo"
    echo ""
    echo "Switch contexts:"
    echo "  kubectl config use-context aks-demo"
    echo "  kubectl config use-context eks-demo"
    ;;
  4)
    echo ""
    echo "=== Starting local DocumentDB ==="
    docker start docdb 2>/dev/null || {
      echo "Container not found. Creating..."
      docker pull ghcr.io/documentdb/documentdb/documentdb-local:latest
      docker run -dt -p 10260:10260 --name docdb \
        ghcr.io/documentdb/documentdb/documentdb-local:latest \
        --username demo --password test
    }
    echo "✅ DocumentDB local running on port 10260"
    echo "Connect: mongosh \"mongodb://demo:test@localhost:10260/?tls=true&tlsAllowInvalidCertificates=true\""
    ;;
  *)
    echo "Invalid selection"
    exit 1
    ;;
esac

echo ""
echo "============================================"
echo "  Infrastructure ready for demo"
echo "============================================"
