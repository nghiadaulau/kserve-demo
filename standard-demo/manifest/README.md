# LLM Inference Service Demo - Phi-3 Mini

This guide demonstrates how to deploy an LLM Inference Service using KServe with the Phi-3 Mini model from HuggingFace.

## Overview

This demo deploys:
- **LLMInferenceService** named `llama3-demo` using Microsoft Phi-3-mini-4k-instruct model
- **vLLM** as the inference runtime
- **HuggingFace Hub** integration for model storage
- **Single GPU** workload configuration

## Prerequisites

Before running this demo, ensure you have:

1. ✅ **KServe installed** - See [install-kserve.md](../install-kserve.md)
2. ✅ **GPU nodes available** - See [install-gpu-device-plugin.md](../install-gpu-device-plugin.md)
3. ✅ **HuggingFace token** - Required for accessing models from HuggingFace Hub
4. ✅ **kubectl configured** - Can access your EKS cluster

## Important: Update Storage Initializer Resources

**⚠️ CRITICAL STEP**: Before deploying the LLM Inference Service, you **must** update the storage initializer resource limits in the KServe ConfigMap. The default values are insufficient for downloading large models from HuggingFace.

### Why This Is Required

The storage initializer init container is responsible for downloading models. Large LLM models (like Phi-3) require more memory and CPU resources than the default configuration provides. Without updating these values, the model download will fail due to insufficient resources.

### Default Values

The default storage initializer configuration in `inferenceservice-config` ConfigMap has:
- `memoryRequest`: 100Mi
- `memoryLimit`: 1Gi
- `cpuRequest`: 100m
- `cpuLimit`: 1

These values are **too low** for downloading LLM models.

### Update the ConfigMap

Edit the `inferenceservice-config` ConfigMap in the `kserve` namespace:

```bash
kubectl edit configmap inferenceservice-config -n kserve
```

Find the `storageInitializer` section and update it with higher resource values:

```yaml
storageInitializer: |-
  {
      "image" : "kserve/storage-initializer:latest",
      "memoryRequest": "4Gi",
      "memoryLimit": "8Gi",
      "cpuRequest": "2",
      "cpuLimit": "4",
      "caBundleConfigMapName": "",
      "caBundleVolumeMountPath": "/etc/ssl/custom-certs",
      "enableModelcar": false,
      "cpuModelcar": "10m",
      "memoryModelcar": "15Mi"
  }
```

**Recommended values for LLM models**:
- `memoryRequest`: 4Gi (minimum, increase for larger models)
- `memoryLimit`: 8Gi (minimum, increase for larger models)
- `cpuRequest`: 2 (for faster download)
- `cpuLimit`: 4 (for faster download)

**Note**: Adjust these values based on:
- Model size (larger models need more memory)
- Network speed (faster CPU helps with download)
- Available cluster resources

### Alternative: Apply ConfigMap Patch

You can also patch the ConfigMap directly:

```bash
kubectl patch configmap inferenceservice-config -n kserve --type merge -p '{
  "data": {
    "storageInitializer": "{\"image\":\"kserve/storage-initializer:latest\",\"memoryRequest\":\"4Gi\",\"memoryLimit\":\"8Gi\",\"cpuRequest\":\"2\",\"cpuLimit\":\"4\",\"caBundleConfigMapName\":\"\",\"caBundleVolumeMountPath\":\"/etc/ssl/custom-certs\",\"enableModelcar\":false,\"cpuModelcar\":\"10m\",\"memoryModelcar\":\"15Mi\"}"
  }
}'
```

### Verify the Update

Verify the ConfigMap was updated correctly:

```bash
kubectl get configmap inferenceservice-config -n kserve -o jsonpath='{.data.storageInitializer}' | jq
```

You should see the updated memory and CPU values.

## Step 1: Create Namespace

Create the namespace for the demo:

```bash
kubectl create namespace llm-demo
```

## Step 2: Create HuggingFace Secret

Create a secret with your HuggingFace token for accessing models:

```bash
# Edit hf-secret.yaml and replace <YOUR-TOKEN> with your actual HuggingFace token
kubectl apply -f hf-secret.yaml
```

**To get a HuggingFace token**:
1. Go to https://huggingface.co/settings/tokens
2. Create a new token with "Read" permissions
3. Replace `<YOUR-TOKEN>` in `hf-secret.yaml` with your token

**Security Note**: Never commit tokens to version control. Consider using sealed-secrets or external secret management.

## Step 3: Create ClusterStorageContainer

Create the ClusterStorageContainer for HuggingFace Hub integration:

```bash
kubectl apply -f huggingface-storage.yaml
```

This configuration:
- Uses `kserve/storage-initializer:latest` image
- Configures HuggingFace token from the secret
- Sets resource limits for the storage initializer
- Supports `hf://` URI format

## Step 4: Create LLMInferenceServiceConfig Resources

Create the configuration resources:

```bash
kubectl apply -f config.yaml
```

This creates three `LLMInferenceServiceConfig` resources:

1. **model-llama3-8b**: Model configuration
   - Model URI: `hf://microsoft/Phi-3-mini-4k-instruct`
   - Model name: `microsoft/Phi-3-mini-4k-instruct`

2. **workload-single-gpu**: Workload configuration
   - Replicas: 1
   - Container image: `vllm/vllm-openai:latest`
   - Resources:
     - GPU: 1 (request and limit)
     - CPU: 2 request, 4 limit
     - Memory: 12Gi request, 16Gi limit

3. **router-managed**: Router configuration
   - Gateway, route, and scheduler settings

## Step 5: Deploy LLMInferenceService

Deploy the LLM Inference Service:

```bash
kubectl apply -f llama3-demo.yaml
```

This creates the `LLMInferenceService` that combines all the configurations:
- Uses the model configuration
- Uses the workload configuration
- Uses the router configuration
- References the HuggingFace secret for authentication

## Verification

### Check LLMInferenceService Status

Check the status of the LLM Inference Service:

```bash
kubectl get llminferenceservice llama3-demo -n llm-demo
```

Expected output:
```
NAME           READY   URL
llama3-demo     True    http://llama3-demo.llm-demo.example.com
```

### Check Pod Status

Monitor the pods being created:

```bash
kubectl get pods -n llm-demo -w
```

You should see:
- **Storage initializer init container** downloading the model (this may take several minutes)
- **Main container** running vLLM inference server

Wait for all pods to be in `Running` state:

```bash
kubectl get pods -n llm-demo
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
llama3-demo-xxxxx                 1/1     Running   0          5m
```

### Check Storage Initializer Logs

Monitor the storage initializer to see model download progress:

```bash
# Get the pod name
POD_NAME=$(kubectl get pods -n llm-demo -l serving.kserve.io/inferenceservice=llama3-demo -o jsonpath='{.items[0].metadata.name}')

# Check init container logs
kubectl logs $POD_NAME -n llm-demo -c storage-initializer
```

You should see logs indicating:
- Model download from HuggingFace
- Model extraction and preparation
- Successful completion

**Note**: Model download can take 5-15 minutes depending on:
- Model size
- Network speed
- Cluster resources

### Check Main Container Logs

Check the vLLM inference server logs:

```bash
kubectl logs $POD_NAME -n llm-demo -c main
```

You should see vLLM server starting up and ready to serve requests.

### Verify GPU Allocation

Verify the pod has GPU allocated:

```bash
kubectl describe pod $POD_NAME -n llm-demo | grep -A 5 "Limits\|Requests"
```

You should see:
```
Limits:
  cpu:              4
  memory:           16Gi
  nvidia.com/gpu:  1
Requests:
  cpu:              2
  memory:           12Gi
  nvidia.com/gpu:  1
```

### Check Service Endpoint

Get the service URL:

```bash
kubectl get llminferenceservice llama3-demo -n llm-demo -o jsonpath='{.status.url}'
```

## Troubleshooting

### Storage Initializer Fails with OOMKilled

**Problem**: Storage initializer pod is killed due to out of memory.

**Solution**: Increase the `memoryLimit` in the ConfigMap further:

```bash
kubectl patch configmap inferenceservice-config -n kserve --type merge -p '{
  "data": {
    "storageInitializer": "{\"memoryLimit\":\"16Gi\",\"memoryRequest\":\"8Gi\"}"
  }
}'
```

### Model Download Takes Too Long

**Problem**: Model download is very slow.

**Solutions**:
1. Increase CPU limits for faster download:
   ```bash
   kubectl patch configmap inferenceservice-config -n kserve --type merge -p '{
     "data": {
       "storageInitializer": "{\"cpuLimit\":\"8\",\"cpuRequest\":\"4\"}"
     }
   }'
   ```

2. Check network connectivity from the pod
3. Consider using a model cache or pre-downloading models

### Pod Stuck in Init:0/1

**Problem**: Pod is stuck in `Init:0/1` state.

**Solutions**:
1. Check storage initializer logs:
   ```bash
   kubectl logs <pod-name> -n llm-demo -c storage-initializer
   ```

2. Verify HuggingFace token is valid:
   ```bash
   kubectl get secret hf-secret -n llm-demo -o jsonpath='{.data.HF_TOKEN}' | base64 -d
   ```

3. Check if model exists on HuggingFace Hub:
   - Visit: https://huggingface.co/microsoft/Phi-3-mini-4k-instruct

### GPU Not Available

**Problem**: Pod cannot be scheduled due to GPU unavailability.

**Solutions**:
1. Check GPU nodes are available:
   ```bash
   kubectl get nodes -l eks.amazonaws.com/nodegroup=gpu
   ```

2. Verify GPU device plugin is running:
   ```bash
   kubectl get pods -n nvidia
   ```

3. Check GPU resources:
   ```bash
   kubectl describe nodes | grep nvidia.com/gpu
   ```

### HuggingFace Authentication Error

**Problem**: Storage initializer fails with authentication error.

**Solutions**:
1. Verify secret exists and has correct token:
   ```bash
   kubectl get secret hf-secret -n llm-demo
   ```

2. Check secret is referenced correctly in ClusterStorageContainer:
   ```bash
   kubectl get clusterstoragecontainer hf-hub -n llm-demo -o yaml
   ```

3. Verify LLMInferenceService annotation:
   ```bash
   kubectl get llminferenceservice llama3-demo -n llm-demo -o yaml | grep storageSecretName
   ```

## Clean Up

To remove the demo resources:

```bash
# Delete LLMInferenceService
kubectl delete llminferenceservice llama3-demo -n llm-demo

# Delete LLMInferenceServiceConfig resources
kubectl delete llminferenceserviceconfig model-llama3-8b workload-single-gpu router-managed -n llm-demo

# Delete ClusterStorageContainer
kubectl delete clusterstoragecontainer hf-hub -n llm-demo

# Delete secret
kubectl delete secret hf-secret -n llm-demo

# Delete namespace (optional)
kubectl delete namespace llm-demo
```

**Note**: If you updated the ConfigMap, you may want to revert it to default values:

```bash
kubectl patch configmap inferenceservice-config -n kserve --type merge -p '{
  "data": {
    "storageInitializer": "{\"image\":\"kserve/storage-initializer:latest\",\"memoryRequest\":\"100Mi\",\"memoryLimit\":\"1Gi\",\"cpuRequest\":\"100m\",\"cpuLimit\":\"1\"}"
  }
}'
```

## Files Overview

- **hf-secret.yaml**: HuggingFace token secret
- **huggingface-storage.yaml**: ClusterStorageContainer for HuggingFace Hub
- **config.yaml**: LLMInferenceServiceConfig resources (model, workload, router)
- **llama3-demo.yaml**: LLMInferenceService definition
