#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Install NVIDIA Kubernetes Device Plugin on Amazon EKS
#
# Official AWS documentation:
# https://docs.aws.amazon.com/eks/latest/userguide/ml-eks-k8s-device-plugin.html
#
# Target:
# - EKS with NVIDIA GPU nodes (AL2023 NVIDIA AMI)
# ------------------------------------------------------------------------------

NAMESPACE="nvidia"
HELM_REPO_NAME="nvdp"
HELM_REPO_URL="https://nvidia.github.io/k8s-device-plugin"
DEFAULT_VERSION="0.17.4"

echo "==> Adding NVIDIA Helm repository..."
helm repo add ${HELM_REPO_NAME} ${HELM_REPO_URL}

echo "==> Updating Helm repositories..."
helm repo update

echo "==> Available chart versions:"
helm search repo ${HELM_REPO_NAME} --devel

echo ""
read -p "Enter chart version [default: ${DEFAULT_VERSION}]: " CHART_VERSION

# Use default if empty
CHART_VERSION=${CHART_VERSION:-$DEFAULT_VERSION}

echo "==> Using chart version: ${CHART_VERSION}"

echo "==> Installing NVIDIA Kubernetes device plugin..."

helm install nvdp ${HELM_REPO_NAME}/nvidia-device-plugin \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --version ${CHART_VERSION} \
  --set gfd.enabled=true

echo "==> Waiting for DaemonSet rollout..."
kubectl rollout status ds/nvdp-nvidia-device-plugin -n ${NAMESPACE}

echo "==> Verifying DaemonSet..."
kubectl get ds -n ${NAMESPACE} nvdp-nvidia-device-plugin

echo ""
echo "==> Verifying GPU allocatable resources on nodes..."
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\\.com/gpu

echo ""
echo "Installation completed."
echo "AWS reference: https://docs.aws.amazon.com/eks/latest/userguide/ml-eks-k8s-device-plugin.html"
