# 🚀 Pipeline CI/CD sur Azure AKS

Projet complet pour déployer une application FastAPI sur Azure Kubernetes Service (AKS) avec infrastructure Terraform et CI/CD GitHub Actions.

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│         Azure Cloud                 │
│  ┌─────────────────────────────┐   │
│  │  Virtual Network (10.0.0.0/16) │
│  │  ├── AKS Cluster (10.1.0.0/16) │
│  │  ├── PostgreSQL Flexible      │
│  │  │   (Private Endpoint)        │
│  │  └── ACR (Container Registry)  │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
            ▲
            │ GitHub Actions
            │
┌─────────────────────────────────────┐
│   GitHub Repository                 │
└─────────────────────────────────────┘
```

## 📁 Structure

```
kubernetes-azure/
├── app/                 # Application FastAPI + Dockerfile
├── terraform/           # IaC (modules: network, aks, acr, postgres)
├── k8s/                 # Manifests Kubernetes
└── .github/workflows/   # CI/CD Pipeline
```

## ⚡ Quick Start

### 1. Terraform (Déployer l'infra)

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Docker (Build & Push)

```bash
cd app
docker build -t acrjul24.azurecr.io/fastapi-app:latest .
az acr login -n acrjul24
docker push acrjul24.azurecr.io/fastapi-app:latest
```

### 3. Kubernetes (Déployer l'app)

```bash
az aks get-credentials -g rg-aks-jul24 -n aks-jul24
kubectl apply -f k8s/
```

## 🔧 Commandes Utiles

```bash
# Vérifier les pods
kubectl get pods -n fastapi-ns

# Logs
kubectl logs -n fastapi-ns -l app=fastapi

# Accéder au cluster
kubectl exec -it <pod-name> -n fastapi-ns -- /bin/bash
```

## 💰 Coûts Azure (estimation)

- **AKS** : ~50-70€/mois (2 nodes B1s)
- **PostgreSQL Flexible** : ~30€/mois (Basic, 2 vCPU)
- **ACR** : ~5€/mois (Basic)
- **VNET/PE** : Gratuit

**Total estimé : ~85-105€/mois**

---

**Repo** : https://github.com/julieparrot91-star/kubernetes-azure