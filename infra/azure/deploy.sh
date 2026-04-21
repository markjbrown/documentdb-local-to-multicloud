#!/bin/bash
# Deploy AKS cluster for DocumentDB demo
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-docdb-demo-rg}"
LOCATION="${LOCATION:-eastus2}"
CLUSTER_NAME="${CLUSTER_NAME:-docdb-demo-aks}"

echo "=== Deploying AKS cluster ==="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Cluster: $CLUSTER_NAME"

# Create resource group
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

# Deploy Bicep template
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$(dirname "$0")/main.bicep" \
  --parameters "$(dirname "$0")/main.bicepparam" \
  --parameters clusterName="$CLUSTER_NAME" location="$LOCATION" \
  --output none

# Get credentials
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing

echo ""
echo "=== Installing DocumentDB operator ==="

# Install cert-manager (required by operator)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
echo "Waiting for cert-manager..."
kubectl wait --for=condition=available --timeout=120s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=120s deployment/cert-manager-webhook -n cert-manager

# Install DocumentDB operator via Helm
helm repo add documentdb https://documentdb.github.io/documentdb-kubernetes-operator
helm repo update
helm install documentdb-operator documentdb/documentdb-operator \
  --namespace documentdb-operator --create-namespace

echo "Waiting for operator..."
kubectl wait --for=condition=available --timeout=120s deployment/documentdb-operator -n documentdb-operator

echo ""
echo "=== Deploying DocumentDB instance ==="

# Generate password if not set
DOCDB_PASSWORD="${DOCDB_PASSWORD:-$(openssl rand -base64 16)}"

kubectl create namespace documentdb-ns --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: documentdb.io/preview
kind: DocumentDB
metadata:
  name: docdb-demo
  namespace: documentdb-ns
spec:
  environment: aks
  nodeCount: 1
  instancesPerNode: 1
  credential:
    password: "$DOCDB_PASSWORD"
  resource:
    storage:
      pvcSize: 20Gi
  exposeViaService:
    serviceType: LoadBalancer
EOF

echo ""
echo "=== AKS deployment complete ==="
echo "Password: $DOCDB_PASSWORD"
echo ""
echo "Wait for LoadBalancer IP:"
echo "  kubectl get svc -n documentdb-ns -w"
echo ""
echo "Connect:"
echo "  mongosh \"mongodb://docdb:\$PASSWORD@<EXTERNAL-IP>:10260/?tls=true&tlsAllowInvalidCertificates=true&authMechanism=SCRAM-SHA-256\""
