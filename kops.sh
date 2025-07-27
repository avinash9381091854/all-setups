#!/bin/bash
set -euo pipefail

# ===== Configuration =====
BUCKET_NAME="avinash912-$(date +%s).k8s.local"  # ensure globally unique
CLUSTER_NAME="rahams.k8s.local"
REGION="us-east-1"
ZONES="us-east-1a"

# ===== Download kubectl =====
echo "📦 Downloading kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -sSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# ===== Download kops =====
echo "📦 Downloading kops..."
curl -LO https://github.com/kubernetes/kops/releases/latest/download/kops-linux-amd64
chmod +x kops-linux-amd64
sudo mv kops-linux-amd64 /usr/local/bin/kops

# ===== Verify installations =====
echo "✅ Verifying installations..."
kubectl version --client
kops version

# ===== Create S3 bucket for Kops =====
echo "🪣 Creating S3 bucket: $BUCKET_NAME..."
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"

# ===== Enable versioning =====
echo "🔄 Enabling versioning on bucket..."
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# ===== Export state store environment variable =====
export KOPS_STATE_STORE="s3://$BUCKET_NAME"
echo "📌 KOPS_STATE_STORE set to $KOPS_STATE_STORE"

# ===== Create Kubernetes cluster =====
echo "🛠️ Creating Kubernetes cluster..."
kops create cluster \
  --name "$CLUSTER_NAME" \
  --zones "$ZONES" \
  --master-size t2.medium \
  --node-size t2.micro \
  --master-count 1 \
  --node-count 2

# ===== Apply the changes =====
echo "🚀 Deploying the cluster..."
kops update cluster --name "$CLUSTER_NAME" --yes --admin

echo "✅ Cluster deployment initiated."
