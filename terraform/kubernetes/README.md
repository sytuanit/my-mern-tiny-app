# Terraform Kubernetes Deployment

Deploy my-tiny-app, my-tiny-app-consumer, and my-tiny-app-ui to Minikube using Terraform.

## 🚀 Quick Start

### Prerequisites

1. **Minikube** installed and running
2. **Terraform** installed
3. **Docker** installed
4. **kubectl** installed

### Deploy

```powershell
.\deploy-minikube-terraform.ps1
```

Script sẽ tự động:
- Check Minikube status
- Configure Docker for Minikube
- Build Docker images
- Initialize Terraform
- Apply Terraform configuration
- Wait for deployments

## 📁 Structure

```
terraform/kubernetes/
├── main.tf          # Main Terraform configuration
├── variables.tf     # Input variables
├── outputs.tf      # Output values
└── README.md       # This file
```

## 🔧 Manual Deployment

```powershell
# 1. Set Docker environment
minikube docker-env | Invoke-Expression

# 2. Build images
docker build -t localhost/my-tiny-app:latest ./my-tiny-app
docker build -t localhost/my-tiny-app-consumer:latest ./my-tiny-app-consumer
docker build -t localhost/my-tiny-app-ui:latest ./my-tiny-app-ui

# 3. Initialize Terraform
cd terraform/kubernetes
terraform init

# 4. Plan
terraform plan \
  -var="docker_registry=localhost" \
  -var="image_tag=latest" \
  -var="image_pull_policy=Never"

# 5. Apply
terraform apply \
  -var="docker_registry=localhost" \
  -var="image_tag=latest" \
  -var="image_pull_policy=Never"
```

## 📊 Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `namespace` | Kubernetes namespace | `my-tiny-app` |
| `kubeconfig_path` | Path to kubeconfig | `""` (use default) |
| `kube_context` | Kubernetes context | `minikube` |
| `docker_registry` | Docker registry | `localhost` |
| `image_tag` | Image tag | `latest` |
| `image_pull_policy` | Image pull policy | `Never` |

## 🗑️ Destroy

```powershell
cd terraform/kubernetes
terraform destroy \
  -var="docker_registry=localhost" \
  -var="image_tag=latest" \
  -var="image_pull_policy=Never"
```

## 📝 Notes

- Uses `image_pull_policy: Never` for local images
- All resources are created in `my-tiny-app` namespace
- UI service uses NodePort on port 30002
- Health checks configured for all apps
- Resource limits set for all deployments

