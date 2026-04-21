#!/bin/bash
# Deploy EKS cluster for DocumentDB demo
set -euo pipefail

CLUSTER_NAME="${EKS_CLUSTER_NAME:-docdb-demo-eks}"
REGION="${EKS_REGION:-us-west-2}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Deploying EKS cluster ==="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"

# Create EKS cluster using eksctl
eksctl create cluster -f "$SCRIPT_DIR/cluster-config.yaml"

# Update kubeconfig
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

# Create gp3 storage class
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: documentdb-storage
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Retain
EOF

echo ""
echo "=== Installing DocumentDB operator ==="

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
echo "Waiting for cert-manager..."
kubectl wait --for=condition=available --timeout=120s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=120s deployment/cert-manager-webhook -n cert-manager

# Install DocumentDB operator
helm repo add documentdb https://documentdb.github.io/documentdb-kubernetes-operator
helm repo update
helm install documentdb-operator documentdb/documentdb-operator \
  --namespace documentdb-operator --create-namespace

echo "Waiting for operator..."
kubectl wait --for=condition=available --timeout=120s deployment/documentdb-operator -n documentdb-operator

echo ""
echo "=== Deploying DocumentDB instance ==="

DOCDB_PASSWORD="${DOCDB_PASSWORD:-$(openssl rand -base64 16)}"

kubectl create namespace documentdb-ns --dry-run=client -o yaml | kubectl apply -f -

cat <<EOF | kubectl apply -f -
apiVersion: documentdb.io/preview
kind: DocumentDB
metadata:
  name: docdb-demo
  namespace: documentdb-ns
spec:
  environment: eks
  nodeCount: 1
  instancesPerNode: 1
  credential:
    password: "$DOCDB_PASSWORD"
  resource:
    storage:
      pvcSize: 20Gi
      storageClass: documentdb-storage
  exposeViaService:
    serviceType: LoadBalancer
    serviceAnnotations:
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
EOF

echo ""
echo "=== EKS deployment complete ==="
echo "Password: $DOCDB_PASSWORD"
echo ""
echo "Waiting for NLB hostname (2-5 min)..."
for i in {1..60}; do
  NLB_HOST=$(kubectl get svc -n documentdb-ns -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [ -n "$NLB_HOST" ] && [ "$NLB_HOST" != "null" ]; then
    echo "NLB hostname: $NLB_HOST"
    break
  fi
  echo "  Waiting... ($i/60)"
  sleep 10
done

if [ -n "$NLB_HOST" ] && [ "$NLB_HOST" != "null" ]; then
  EKS_URI="mongodb://docdb:${DOCDB_PASSWORD}@${NLB_HOST}:10260/?tls=true&tlsAllowInvalidCertificates=true&authMechanism=SCRAM-SHA-256"

  echo ""
  echo "=== Loading demo data ==="
  MONGODB_URI="$EKS_URI" bash "$REPO_ROOT/data/load-data.sh"

  echo ""
  echo "=== Wiping indexes (ready for Index Advisor demo) ==="
  MONGODB_URI="$EKS_URI" bash "$REPO_ROOT/data/wipe-data.sh" --indexes

  echo ""
  echo "Connect:"
  echo "  mongosh \"$EKS_URI\""
else
  echo "⚠️  NLB not ready. Load data manually after hostname is assigned."
  echo "  MONGODB_URI=\"mongodb://docdb:\$PASSWORD@<HOST>:10260/...\" bash data/load-data.sh"
fi
