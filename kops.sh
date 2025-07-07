#!/bin/bash
set -euo pipefail

# Export path for local binaries if needed
export PATH=$PATH:/usr/local/bin

# Download latest stable kubectl
echo "📦 Downloading latest stable kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -sSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Download correct version of kops
KOPS_VERSION="1.30.3"
echo "📦 Downloading kops version v${KOPS_VERSION}..."
curl -LO "https://github.com/kubernetes/kops/releases/download/v${KOPS_VERSION}/kops-linux-amd64"

# Make both binaries executable
chmod +x kubectl kops-linux-amd64

# Move them into PATH
sudo mv kubectl /usr/local/bin/kubectl
sudo mv kops-linux-amd64 /usr/local/bin/kops

# Check if files are valid executables
echo "🔍 Validating binaries..."
file /usr/local/bin/kubectl
file /usr/local/bin/kops

# Check versions
echo "✅ kubectl version:"
kubectl version --client

echo "✅ kops version:"
kops version

# --- Configuration Section ---
BUCKET_NAME="avinash912.k8s.local"
REGION="ap-south-1"
CLUSTER_NAME="aviiinasshh.k8s.local"
ZONES="ap-south-1a"
MASTER_SIZE="t2.medium"
NODE_SIZE="t2.micro"

# --- S3 State Store Setup ---
echo "🌐 Setting up S3 bucket for Kops state store..."
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" \
  || echo "⚠️ Bucket already exists or is globally unique."

echo "🔁 Enabling versioning on the bucket..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Export state store
export KOPS_STATE_STORE="s3://${BUCKET_NAME}"

# --- Cluster Creation ---
echo "🚀 Creating Kubernetes cluster: $CLUSTER_NAME"
kops create cluster \
  --name "$CLUSTER_NAME" \
  --zones "$ZONES" \
  --master-count=1 \
  --master-size "$MASTER_SIZE" \
  --node-count=2 \
  --node-size "$NODE_SIZE" \
  --yes

# Optional: Apply admin access
echo "🔐 Applying admin access..."
kops update cluster --name "$CLUSTER_NAME" --yes --admin

echo "✅ Done! Cluster creation has been initiated."
echo "⏳ Use 'kops validate cluster --name $CLUSTER_NAME' in a few minutes to check its status."
