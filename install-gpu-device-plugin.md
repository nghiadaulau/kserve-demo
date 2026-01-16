# Install NVIDIA Kubernetes Device Plugin

This guide will walk you through installing the NVIDIA Kubernetes Device Plugin on your Amazon EKS cluster. This plugin is required to enable GPU support in Kubernetes after you have deployed GPU-enabled node groups.

## Prerequisites

Before installing the NVIDIA Device Plugin, ensure you have:

1. ✅ **EKS cluster deployed** with Terraform (see `terraform/terraform.md`)
2. ✅ **GPU node groups created** - Your EKS cluster should have GPU-enabled node groups using AL2023 NVIDIA AMI
3. ✅ **kubectl configured** - You can connect to your EKS cluster
4. ✅ **Helm installed** - Required for installing the device plugin (see `prepare.md`)

### Verify Prerequisites

Verify that your GPU nodes are running:

```bash
kubectl get nodes -l eks.amazonaws.com/nodegroup=gpu
```

You should see your GPU nodes listed. If no nodes appear, ensure your Terraform deployment completed successfully and the node groups have finished provisioning.

Verify that nodes have NVIDIA GPUs:

```bash
kubectl get nodes -o jsonpath='{.items[*].status.capacity.nvidia\.com/gpu}'
```

**Note**: Before installing the device plugin, this command may return empty. After installation, it should show the number of GPUs per node.

## Overview

The NVIDIA Kubernetes Device Plugin enables Kubernetes to:
- Discover NVIDIA GPUs on nodes
- Expose GPU resources to pods
- Schedule GPU workloads correctly
- Manage GPU allocation and sharing

**Target Environment**: EKS with NVIDIA GPU nodes using AL2023 NVIDIA AMI

**Official AWS Documentation**: https://docs.aws.amazon.com/eks/latest/userguide/ml-eks-k8s-device-plugin.html

## Installation Methods

You can install the NVIDIA Device Plugin using either:
1. **Automated Script** (Recommended) - Use the provided installation script
2. **Manual Installation** - Install step-by-step using Helm commands

## Method 1: Automated Installation (Recommended)

Use the provided installation script for a streamlined installation process.

### Run the Installation Script

Navigate to the docs directory and run the script:

```bash
cd docs/
chmod +x install-kubernetes-device-plugin-for-gpus.sh
./install-kubernetes-device-plugin-for-gpus.sh
```

The script will:
1. Add the NVIDIA Helm repository
2. Update Helm repositories
3. Show available chart versions
4. Prompt you for the chart version (default: 0.17.4)
5. Install the device plugin with GPU Feature Discovery enabled
6. Wait for the DaemonSet to roll out
7. Verify the installation

### What the Script Does

The script performs the following operations:

```bash
# Add NVIDIA Helm repository
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin

# Update repositories
helm repo update

# Install the device plugin
helm install nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia \
  --create-namespace \
  --version 0.17.4 \
  --set gfd.enabled=true
```

**Key Configuration**:
- **Namespace**: `nvidia` (created automatically)
- **Release Name**: `nvdp`
- **GPU Feature Discovery (GFD)**: Enabled - Automatically discovers GPU features and labels nodes

## Method 2: Manual Installation

If you prefer to install manually or need more control over the installation:

### Step 1: Add NVIDIA Helm Repository

```bash
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
```

### Step 2: Update Helm Repositories

```bash
helm repo update
```

### Step 3: List Available Versions (Optional)

View available chart versions:

```bash
helm search repo nvdp/nvidia-device-plugin --versions
```

### Step 4: Install the Device Plugin

Install with the default version (0.17.4):

```bash
helm install nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia \
  --create-namespace \
  --version 0.17.4 \
  --set gfd.enabled=true
```

Or install the latest version:

```bash
helm install nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia \
  --create-namespace \
  --set gfd.enabled=true
```

### Step 5: Wait for DaemonSet Rollout

Wait for the DaemonSet to be ready on all nodes:

```bash
kubectl rollout status ds/nvdp-nvidia-device-plugin -n nvidia
```

This may take a few minutes as the plugin needs to be deployed on each GPU node.

## Verification

After installation, verify that the plugin is working correctly.

### Check DaemonSet Status

Verify the DaemonSet is running:

```bash
kubectl get ds -n nvidia nvdp-nvidia-device-plugin
```

Expected output:
```
NAME                          DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
nvdp-nvidia-device-plugin     2         2         2       2            2           <none>          5m
```

All pods should be in `READY` state. The number should match your GPU node count.

### Check Pod Status

View the device plugin pods:

```bash
kubectl get pods -n nvidia
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
nvdp-nvidia-device-plugin-xxxxx   1/1     Running   0          5m
nvdp-nvidia-device-plugin-yyyyy   1/1     Running   0          5m
```

### Verify GPU Resources on Nodes

Check that GPUs are now allocatable on your nodes:

```bash
kubectl get nodes -o=custom-columns=NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu
```

Expected output:
```
NAME                                          GPU
ip-10-0-1-xxx.ap-southeast-1.compute.internal   1
ip-10-0-2-xxx.ap-southeast-1.compute.internal   1
```

Each GPU node should show the number of GPUs available (typically 1 for g4dn.xlarge instances).

### Check Node Labels (GPU Feature Discovery)

If GPU Feature Discovery (GFD) is enabled, verify that nodes are labeled with GPU information:

```bash
kubectl get nodes --show-labels | grep nvidia.com
```

You should see labels like:
- `nvidia.com/gpu.count=1`
- `nvidia.com/gpu.product=*`
- `nvidia.com/gpu.memory=*`

### Detailed Node Information

Get detailed GPU information from a specific node:

```bash
kubectl describe node <node-name> | grep -A 10 "nvidia.com"
```

## Testing GPU Allocation

Create a test pod to verify GPU allocation works:

### Create a Test Pod

Create a file `test-gpu-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
  restartPolicy: Never
  containers:
  - name: cuda-container
    image: nvidia/cuda:12.0.0-base-ubuntu22.04
    command: ["nvidia-smi"]
    resources:
      limits:
        nvidia.com/gpu: 1
```

Apply the test pod:

```bash
kubectl apply -f test-gpu-pod.yaml
```

### Verify GPU Access

Check the pod logs to see GPU information:

```bash
kubectl logs gpu-test
```

You should see output from `nvidia-smi` showing GPU details.

### Clean Up Test Pod

```bash
kubectl delete pod gpu-test
rm test-gpu-pod.yaml
```

## Troubleshooting

### DaemonSet Not Starting

If the DaemonSet pods are not starting:

1. **Check pod events**:
   ```bash
   kubectl describe pod -n nvidia -l app=nvidia-device-plugin-ds
   ```

2. **Check pod logs**:
   ```bash
   kubectl logs -n nvidia -l app=nvidia-device-plugin-ds
   ```

3. **Verify node labels**: Ensure nodes are labeled correctly for GPU workloads

### GPUs Not Showing as Allocatable

If `kubectl get nodes` doesn't show GPU resources:

1. **Verify DaemonSet is running** on GPU nodes:
   ```bash
   kubectl get pods -n nvidia -o wide
   ```

2. **Check node conditions**:
   ```bash
   kubectl describe node <gpu-node-name>
   ```

3. **Verify NVIDIA drivers**: Ensure the AL2023 NVIDIA AMI has NVIDIA drivers installed:
   ```bash
   kubectl debug node/<gpu-node-name> -it --image=busybox -- nvidia-smi
   ```

### Pods Cannot Allocate GPUs

If pods fail to schedule with GPU requests:

1. **Check node capacity**:
   ```bash
   kubectl describe node <gpu-node-name> | grep -i gpu
   ```

2. **Verify resource requests**: Ensure your pod spec includes:
   ```yaml
   resources:
     limits:
       nvidia.com/gpu: 1
     requests:
       nvidia.com/gpu: 1
   ```

3. **Check for taints**: GPU nodes might have taints that require tolerations

### Upgrade the Device Plugin

To upgrade to a newer version:

```bash
helm repo update
helm upgrade nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia \
  --version <new-version> \
  --set gfd.enabled=true
```

### Uninstall the Device Plugin

To remove the device plugin:

```bash
helm uninstall nvdp -n nvidia
```

**Warning**: Removing the device plugin will prevent Kubernetes from discovering GPUs. Existing GPU workloads may continue to run, but new GPU pods cannot be scheduled.

## Next Steps

After successfully installing the NVIDIA Device Plugin:

1. ✅ Verify GPU resources are available: `kubectl get nodes -o json | grep nvidia.com/gpu`
2. ✅ Proceed with KServe installation for GPU-enabled model serving
3. ✅ Deploy GPU workloads that request `nvidia.com/gpu` resources

## References

- **AWS Documentation**: https://docs.aws.amazon.com/eks/latest/userguide/ml-eks-k8s-device-plugin.html
- **NVIDIA Device Plugin**: https://github.com/NVIDIA/k8s-device-plugin
