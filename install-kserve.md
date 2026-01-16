# Install KServe (Standard Mode) with LLMInferenceService

This guide will walk you through installing KServe (Standard Mode) and LLMInferenceService on your EKS cluster. This installation includes all required infrastructure components and dependencies.

## Prerequisites

Before installing KServe, ensure you have completed the previous setup steps:

1. ✅ **EKS cluster deployed** - See [terraform.md](terraform.md)
2. ✅ **kubectl configured** - You can connect to your EKS cluster
3. ✅ **GPU Device Plugin installed** (if using GPUs) - See [install-gpu-device-plugin.md](install-gpu-device-plugin.md)
4. ✅ **Required tools installed**:
   - **helm** - Kubernetes package manager
   - **kustomize** - Kubernetes configuration management
   - **yq** - YAML processor

### Verify Prerequisites

Verify kubectl is configured and can access your cluster:

```bash
kubectl cluster-info
kubectl get nodes
```

Verify required tools are installed:

```bash
helm version
kustomize version
yq --version
```

## Overview

This installation script will install:

- **KServe (Standard Mode)** - Lightweight Kubernetes-native model serving framework
- **LLMInferenceService** - Support for large language model inference
- **All required infrastructure components** and dependencies

### What Gets Installed

#### Infrastructure Components for KServe Standard:

- ✅ **KEDA** - Kubernetes Event-Driven Autoscaling for Standard KServe autoscaling
- ✅ **KEDA OpenTelemetry Addon** - OpenTelemetry integration for Standard KServe autoscaling

#### Infrastructure Components for LLMInferenceService:

- ✅ **External Load Balancer (MetalLB)** - For local clusters (not required for EKS with AWS Load Balancer Controller)
- ✅ **Cert Manager** - Certificate management for TLS
- ✅ **Gateway API CRDs** - Kubernetes Gateway API Custom Resource Definitions
- ✅ **Gateway API Inference Extension CRDs** - KServe-specific Gateway API extensions
- ✅ **Envoy Gateway** - High-performance edge and service proxy
- ✅ **Envoy AI Gateway** - AI/ML optimized gateway for inference workloads
- ✅ **LeaderWorkerSet** - Multi-node deployment support for distributed inference
- ✅ **GatewayClass** - Gateway API class configuration
- ✅ **Gateway** - Ingress gateway for KServe

#### KServe Components:

- ✅ **KServe CRDs and Controller (Standard)** - Core KServe functionality
- ✅ **LLMInferenceService CRDs and Controller** - LLM inference support

## Installation Steps

### Step 1: Navigate to KServe Repository

If you haven't already cloned the KServe repository, clone it first:

```bash
git clone https://github.com/kserve/kserve.git
cd kserve
```

Or if you already have the repository:

```bash
cd kserve
```

### Step 2: Make Script Executable

Ensure the installation script is executable:

```bash
chmod +x hack/setup/quick-install/kserve-standard-mode-full-install-with-manifests.sh
```

### Step 3: Run the Installation Script

Execute the installation script:

```bash
./hack/setup/quick-install/kserve-standard-mode-full-install-with-manifests.sh
```

**Note**: The script includes all manifests embedded, so it doesn't require external network access during installation (except for downloading container images).

### Step 4: Monitor Installation Progress

The script will install components in the following order:

1. Cert Manager
2. KEDA
3. KEDA OpenTelemetry Addon
4. External Load Balancer (if needed)
5. Gateway API Extension CRDs
6. Envoy Gateway
7. Envoy AI Gateway
8. Gateway API GatewayClass
9. Gateway API Gateway
10. LeaderWorkerSet Operator
11. KServe CRDs and Controller
12. LLMInferenceService CRDs and Controller

The installation process may take 5-10 minutes depending on your cluster resources and network speed.

## Verify Installation

After the installation script completes, verify that all components are working correctly.

### Check All Pods Are Running

Verify pods in each namespace are in `Running` state:

```bash
# Check Cert Manager
kubectl get pods -n cert-manager

# Check Envoy Gateway
kubectl get pods -n envoy-gateway-system

# Check Envoy AI Gateway
kubectl get pods -n envoy-ai-gateway-system

# Check LeaderWorkerSet
kubectl get pods -n lws-system

# Check KServe
kubectl get pods -n kserve
```

**Expected Output**: All pods should show `STATUS: Running` and `READY: 1/1` (or appropriate ready state).

Example:
```
NAME                                      READY   STATUS    RESTARTS   AGE
kserve-controller-manager-xxxxx           1/1     Running   0          5m
llmisvc-controller-manager-yyyyy          1/1     Running   0          5m
```

### Check LLMInferenceService CRD

Verify the LLMInferenceService Custom Resource Definition is installed:

```bash
kubectl get crd llminferenceservices.serving.kserve.io
```

**Expected Output**:
```
NAME                                    CREATED AT
llminferenceservices.serving.kserve.io  2025-01-XX...
```

### Check Gateway Status

Verify the KServe ingress gateway is configured:

```bash
kubectl get gateway kserve-ingress-gateway -n kserve
```

**Expected Output**:
```
NAME                    CLASS              ADDRESS          READY   AGE
kserve-ingress-gateway  kserve-gateway     <pending>        True    5m
```

### Check Gateway External IP/Address

Get the external IP or address assigned to the gateway:

```bash
kubectl get gateway kserve-ingress-gateway -n kserve -o jsonpath='{.status.addresses[0].value}'
```

**Note**: On EKS, the gateway may use an AWS Load Balancer. The address may take a few minutes to be assigned. If it shows `<pending>`, wait a few minutes and check again.

For EKS with AWS Load Balancer Controller, you can also check:

```bash
kubectl get svc -n envoy-gateway-system
```

Look for a service of type `LoadBalancer` with an `EXTERNAL-IP` or `EXTERNAL-IP` showing the AWS ELB address.

### Verify KServe CRDs

Check that KServe Custom Resource Definitions are installed:

```bash
kubectl get crd | grep kserve.io
```

You should see CRDs like:
- `inferenceservices.serving.kserve.io`
- `llminferenceservices.serving.kserve.io`
- `servingruntimes.serving.kserve.io`
- `clusterservingruntimes.serving.kserve.io`

### Verify KEDA Installation

Check KEDA is running:

```bash
kubectl get pods -n keda-system
kubectl get crd | grep keda
```

## Installation Summary

After successful installation, you should have:

✅ All pods in `Running` state across all namespaces  
✅ Gateway shows `READY: True`  
✅ Gateway has `EXTERNAL-IP` or `ADDRESS` assigned (may take a few minutes on EKS)  
✅ KServe CRDs available  
✅ LLMInferenceService CRD available  
✅ KEDA installed and running  

## Troubleshooting

### Pods Not Starting

If pods are stuck in `Pending` or `CrashLoopBackOff`:

1. **Check pod events**:
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   ```

2. **Check pod logs**:
   ```bash
   kubectl logs <pod-name> -n <namespace>
   ```

3. **Check node resources**:
   ```bash
   kubectl describe nodes
   ```

### Gateway Not Getting External IP

On EKS, if the gateway address is `<pending>`:

1. **Check AWS Load Balancer Controller** is installed:
   ```bash
   kubectl get pods -n kube-system | grep aws-load-balancer
   ```

2. **Check service status**:
   ```bash
   kubectl get svc -n envoy-gateway-system
   ```

3. **Check AWS console** for Load Balancer creation

4. **Wait a few minutes** - AWS Load Balancer provisioning can take 2-5 minutes

### Cert Manager Issues

If Cert Manager pods are not running:

1. **Check Cert Manager CRDs**:
   ```bash
   kubectl get crd | grep cert-manager
   ```

2. **Verify webhook configuration**:
   ```bash
   kubectl get validatingwebhookconfigurations | grep cert-manager
   kubectl get mutatingwebhookconfigurations | grep cert-manager
   ```

### KEDA Not Scaling

If KEDA autoscaling is not working:

1. **Check KEDA operator logs**:
   ```bash
   kubectl logs -n keda-system -l app=keda-operator
   ```

2. **Verify ScaledObject CRD**:
   ```bash
   kubectl get crd scaledobjects.keda.sh
   ```

3. **Check ScaledObject resources**:
   ```bash
   kubectl get scaledobjects -A
   ```

### Reinstall or Uninstall

To reinstall (clean install):

```bash
./hack/setup/quick-install/kserve-standard-mode-full-install-with-manifests.sh --reinstall
```

To uninstall:

```bash
./hack/setup/quick-install/kserve-standard-mode-full-install-with-manifests.sh --uninstall
```

**Warning**: Uninstalling will remove all KServe components and may affect running InferenceServices.

## Additional Resources

- **KServe Documentation**: https://kserve.github.io/website/
- **KServe Quick Start**: https://kserve.github.io/website/docs/getting-started/quickstart-guide
- **KServe API Reference**: https://kserve.github.io/website/docs/reference/crd-api
- **KEDA Documentation**: https://keda.sh/docs/

## Support

For issues:
- Check the [KServe GitHub Issues](https://github.com/kserve/kserve/issues)
- Review the [KServe Documentation](https://kserve.github.io/website/)
- Check component-specific logs as shown in the troubleshooting section
