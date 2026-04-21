#!/bin/bash
# Stop demo infrastructure - save costs when not rehearsing
# AKS can be stopped (preserves state). EKS must be deleted.
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-docdb-demo-rg}"
AKS_CLUSTER="${AKS_CLUSTER:-docdb-demo-aks}"
EKS_CLUSTER="${EKS_CLUSTER:-docdb-demo-eks}"
EKS_REGION="${EKS_REGION:-us-west-2}"

echo "============================================"
echo "  DocumentDB Demo Infrastructure - STOP"
echo "============================================"
echo ""
echo "Choose what to stop:"
echo "  1) AKS only (stops cluster, preserves state, ~free)"
echo "  2) EKS only (deletes cluster to stop billing)"
echo "  3) Both clusters"
echo "  4) Local only (stop Docker container)"
echo "  5) DESTROY everything (delete all resources)"
read -rp "Selection [1-5]: " choice

case $choice in
  1)
    echo "=== Stopping AKS cluster ==="
    az aks stop --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER"
    echo "✅ AKS stopped. No compute charges while stopped."
    echo "   Storage charges continue (~\$1/month for disks)."
    echo "   Restart with: ./start.sh → option 1"
    ;;
  2)
    echo "=== Deleting EKS cluster ==="
    echo "⚠️  EKS cannot be stopped, only deleted. Data will be lost."
    read -rp "Continue? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      eksctl delete cluster --name "$EKS_CLUSTER" --region "$EKS_REGION" --wait
      echo "✅ EKS deleted. No further charges."
    fi
    ;;
  3)
    echo "=== Stopping AKS ==="
    az aks stop --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER" &
    echo "=== Deleting EKS ==="
    eksctl delete cluster --name "$EKS_CLUSTER" --region "$EKS_REGION" --wait &
    wait
    echo "✅ Both clusters stopped/deleted."
    ;;
  4)
    echo "=== Stopping local DocumentDB ==="
    docker stop docdb 2>/dev/null && echo "✅ Container stopped" || echo "Container not running"
    ;;
  5)
    echo "⚠️  This will DELETE all Azure and AWS resources permanently."
    read -rp "Type 'destroy' to confirm: " confirm
    if [[ "$confirm" == "destroy" ]]; then
      echo "Deleting Azure resource group..."
      az group delete --name "$RESOURCE_GROUP" --yes --no-wait
      echo "Deleting EKS cluster..."
      eksctl delete cluster --name "$EKS_CLUSTER" --region "$EKS_REGION" --wait 2>/dev/null || true
      echo "Stopping local Docker..."
      docker rm -f docdb 2>/dev/null || true
      echo "✅ All resources destroyed."
    else
      echo "Cancelled."
    fi
    ;;
  *)
    echo "Invalid selection"
    exit 1
    ;;
esac

echo ""
echo "💰 Cost reminder:"
echo "   AKS stopped: ~\$1/mo (disk storage only)"
echo "   EKS running: ~\$140-230/mo"
echo "   AKS running: ~\$512/mo"
