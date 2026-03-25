# Documentation du Projet - Pipeline CI/CD sur AKS

## Table des Matières
1. [Architecture Globale](#architecture-globale)
2. [Structure du Projet](#structure-du-projet)
3. [Application FastAPI](#application-fastapi)
4. [Infrastructure Terraform](#infrastructure-terraform)
5. [Kubernetes (K8s)](#kubernetes-k8s)
6. [CI/CD avec GitHub Actions](#cicd-avec-github-actions)
7. [Flux de Déploiement](#flux-de-déploiement)

---

## 1. Architecture Globale

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Azure Cloud                                 │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    Virtual Network (10.0.0.0/16)             │  │
│  │                                                               │  │
│  │  ┌─────────────────────┐    ┌─────────────────────────────┐ │  │
│  │  │   Subnet AKS        │    │    Subnet PostgreSQL        │ │  │
│  │  │   10.0.1.0/24       │    │    10.0.2.0/24              │ │  │
│  │  │                     │    │                             │ │  │
│  │  │  ┌───────────────┐  │    │  ┌───────────────────────┐  │ │  │
│  │  │  │ AKS Cluster   │  │    │  │ PostgreSQL Flexible  │  │ │  │
│  │  │  │ 10.1.0.0/16   │  │    │  │ (Private Endpoint)   │  │ │  │
│  │  │  │               │  │    │  │                       │  │ │  │
│  │  │  │ Pod: FastAPI  │  │    │  └───────────────────────┘  │ │  │
│  │  │  └───────────────┘  │    │                             │ │  │
│  │  └─────────────────────┘    └─────────────────────────────┘ │  │
│  │                                                               │  │
│  │  ┌───────────────────────────────────────────────────────┐   │  │
│  │  │              ACR (Container Registry)                 │   │  │
│  │  │              acrjul24.azurecr.io                      │   │  │
│  │  └───────────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

                              ▲
                              │ GitHub Actions
                              │ (CI/CD Pipeline)
                              │
┌─────────────────────────────────────────────────────────────────────┐
│                     GitHub Repository                                │
│   - Code source (app/)                                              │
│   - K8s manifests (k8s/)                                            │
│   - Terraform (terraform/)                                          │
│   - Workflows (.github/workflows/)                                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. Structure du Projet

```
kubernetes-azure/
├── app/                      # Application FastAPI
│   ├── main.py              # Code de l'API
│   ├── Dockerfile           # Image Docker
│   └── requirements.txt     # Dépendances Python
│
├── terraform/                # Infrastructure as Code
│   ├── main.tf              # Orchestration des modules
│   ├── variables.tf         # Variables (location, passwords...)
│   ├── provider.tf          # Provider Azure
│   ├── outputs.tf           # Sorties
│   └── modules/
│       ├── network/         # VNET, Subnets, Private Endpoint
│       ├── aks/             # Cluster Kubernetes
│       ├── acr/             # Container Registry
│       └── postgres/        # PostgreSQL Flexible Server
│
├── k8s/                     # Manifests Kubernetes
│   ├── namespace.yaml       # Namespace du projet
│   ├── deployment.yaml      # Déploiement de l'app
│   ├── service.yaml        # Service ClusterIP
│   ├── ingress.yaml        # Point d'entrée (optionnel)
│   └── secret.yaml         # Secrets (BDD, etc.)
│
├── .github/
│   └── workflows/
│       └── deploy.yml       # Pipeline CI/CD GitHub Actions
│
└── README.md                # Documentation originale
```

---

## 3. Application FastAPI

### 3.1 Fichier principal (`app/main.py`)

```python
from fastapi import FastAPI
from pydantic import BaseModel
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, declarative_base

app = FastAPI()

# Connexion à PostgreSQL (via Private Endpoint)
DATABASE_URL = "postgresql://appuser:changeme123@10.0.2.4:5432/appdb"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

# Création automatique de la table
try:
    with engine.connect() as conn:
        conn.execute(text("CREATE TABLE IF NOT EXISTS items (...)"))
        conn.commit()
    print("Connected to PostgreSQL")
except Exception as e:
    # Fallback: base de données en mémoire si PostgreSQL indisponible
    print(f"PostgreSQL not available, using in-memory DB: {e}")
    db = []

# Modèle de données avec Pydantic
class Item(BaseModel):
    name: str
    description: str | None = None

# Endpoints
@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/hello/{name}")
def hello(name: str):
    return {"message": f"Hello {name} !"}

@app.post("/items")
def create_item(item: Item):
    db.append(item.model_dump())
    return item

@app.get("/items")
def get_items():
    return db
```

### 3.2 Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Points clés :**
- `python:3.11-slim` → Image légère
- `uvicorn` → Server ASGI pour FastAPI
- `--no-cache-dir` → Reduce la taille de l'image

### 3.3 Dépendances (`requirements.txt`)

```
fastapi
uvicorn
sqlalchemy
psycopg2-binary
pydantic
```

---

## 4. Infrastructure Terraform

### 4.1 Fichier principal (`main.tf`)

```hcl
# Resource Group
resource "azurerm_resource_group" "aks" {
  name     = var.rg_name
  location = var.location
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "postgresql" {
  name                = "psql-jul24"
  location            = var.location
  resource_group_name = var.rg_name
  
  administrator_login    = "psqladmin"
  administrator_password = var.admin_password
  
  sku_name   = "B_Standard_B1ms"  # Tier Basic, petit et économique
  version     = "15"                # PostgreSQL 15
  storage_mb  = 32768               # 32 Go minimum
}

# Modules
module "network" {
  source = "./modules/network"
  # Crée: VNET, Subnets, Private Endpoint
}

module "acr" {
  source = "./modules/acr"
  # Crée: Azure Container Registry
}

module "aks-cluster" {
  source = "./modules/aks"
  # Crée: AKS Cluster
}
```

### 4.2 Module Network

```hcl
# Virtual Network
resource "azurerm_virtual_network" "aks" {
  name          = "aks-vnet"
  address_space = ["10.0.0.0/16"]
}

# Subnet AKS
resource "azurerm_subnet" "sub_aks" {
  name                 = "AksSubnet"
  address_prefixes     = ["10.0.1.0/24"]
}

# Subnet PostgreSQL
resource "azurerm_subnet" "sub_psql" {
  name                 = "PsqlSubnet"
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}

# Private Endpoint pour PostgreSQL
resource "azurerm_private_endpoint" "psql_endpoint" {
  name = "PrivateEndpointPSQL"
  # Connecte PostgreSQL au subnet privé
  private_service_connection {
    private_connection_resource_id = var.psql_id
    subresource_names              = ["postgresqlServer"]
  }
}
```

**Pourquoi un Private Endpoint ?**
- PostgreSQL n'est pas exposé sur Internet
- Only accessible depuis le VNET Azure
- Plus sécurisé

### 4.3 Module AKS

```hcl
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name       = "aks_cluster"
  dns_prefix = "mon-cluster"

  # Configuration réseau Azure CNI
  network_profile {
    network_plugin    = "azure"
    service_cidr      = "10.1.0.0/16"   # IP des services K8s
    dns_service_ip    = "10.1.0.10"
  }

  # Node pool par défaut
  default_node_pool {
    name       = "defaultpool"
    node_count = 1           # 1 nœud pour réduire les coûts
    vm_size    = "Standard_D2s_v3"
  }

  # Identity gérée par Azure
  identity {
    type = "SystemAssigned"
  }
}

# Autoriser AKS à pull des images depuis ACR
resource "azurerm_role_assignment" "aks_to_acr" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id
  role_definition_name = "AcrPull"
  scope                = var.acr_id
}
```

---

## 5. Kubernetes (K8s)

### 5.1 Namespace (`namespace.yaml`)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fastapi-app
```

### 5.2 Deployment (`deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fastapi
  namespace: fastapi-app
spec:
  replicas: 2                    # 2 pods pour la haute disponibilité
  selector:
    matchLabels:
      app: fastapi
  template:
    metadata:
      labels:
        app: fastapi
    spec:
      imagePullSecrets:
      - name: acr-secret        # Secret pour pull depuis ACR
      containers:
      - name: fastapi
        image: acrjul24.azurecr.io/fastapi-app:v1
        ports:
        - containerPort: 8000
        env:
          - name: DATABASE_URL
            valueFrom:
              secretKeyRef:
                name: postgres-secret
                key: connection-string
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        # Health checks
        livenessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8000
          initialDelaySeconds: 5
```

**Concepts clés :**

| Concept | Description |
|---------|-------------|
| **Deployment** | Gère les pods et assure le nombre de replicas |
| **ReplicaSet** | Garantit le nombre de pods running |
| **Liveness Probe** | Vérifie si le pod est "vivant" → restart si échec |
| **Readiness Probe** | Vérifie si le pod est prêt à recevoir du traffic |
| **Resources** | Limite mémoire/CPU par conteneur |

---

## 6. CI/CD avec GitHub Actions

### 6.1 Workflow (`deploy.yml`)

```yaml
name: Deploy to AKS

on:
  push:
    branches: [main]
    paths: ['app/**', 'k8s/**', '.github/workflows/**']

env:
  REGISTRY: acrjul24.azurecr.io
  IMAGE_NAME: fastapi-app

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    # 1. Récupère le code
    - name: Checkout code
      uses: actions/checkout@v4

    # 2. Se connecte à ACR
    - name: Login to ACR
      run: |
        docker login ${{ env.REGISTRY }} -u ${{ secrets.AZURE_CR_USERNAME }} -p ${{ secrets.AZURE_CR_PASSWORD }}

    # 3. Build et push l'image Docker
    - name: Build and push Docker image
      run: |
        docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} app/
        docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest app/
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest

    # 4. Configure kubectl pour AKS
    - name: Set up kubectl
      uses: azure/k8s-set-context@v4
      with:
        kubeconfig: ${{ secrets.KUBECONFIG }}

    # 5. Met à jour le déploiement
    - name: Update Kubernetes deployment image
      run: |
        kubectl set image deployment/fastapi fastapi=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} -n fastapi-app
        kubectl rollout status deployment/fastapi -n fastapi-app --timeout=300s
```

### 6.2 Secrets à configurer dans GitHub

| Secret | Description |
|--------|-------------|
| `AZURE_CR_USERNAME` | Username ACR |
| `AZURE_CR_PASSWORD` | Password ACR |
| `KUBECONFIG` | Config K8s (output de `az aks get-credentials`) |

---

## 7. Flux de Déploiement

```
┌─────────────────────────────────────────────────────────────────────┐
│                      DÉVELOPPEUR                                    │
│                                                                      │
│   1. git push sur main                                             │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    GITHUB ACTIONS                                    │
│                                                                      │
│   2. Checkout du code                                              │
│   3. Login ACR (docker login)                                      │
│   4. Build image: docker build -t acr/...                          │
│   5. Push image: docker push acr/...                                │
│   6. kubectl set image → Met à jour le déploiement                 │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        AKS CLUSTER                                   │
│                                                                      │
│   7. K8s pulls la nouvelle image depuis ACR                       │
│   8. Nouveau pod démarre                                           │
│   9. Health checks passent                                         │
│  10. Ancien pod est terminé (rolling update)                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Rolling Update

AKS fait un **rolling update** automatiquement :
- Nouveau pod démarre
- Si health check OK → ancien pod supprimé
- Répète pour chaque replica

---

## Commandes Utiles

### Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
terraform destroy  # ⚠️ Supprime tout !
```

### Docker
```bash
# Build local
docker build -t fastapi-app app/

# Run local
docker run -p 8000:8000 fastapi-app

# Push vers ACR
docker push acrjul24.azurecr.io/fastapi-app:latest
```

### Kubernetes
```bash
# Voir les pods
kubectl get pods -n fastapi-app

# Voir les logs
kubectl logs -n fastapi-app -l app=fastapi

# Rolling restart
kubectl rollout restart deployment/fastapi -n fastapi-app

# Debug
kubectl describe pod <pod-name> -n fastapi-app
```

---

## Coûts Estimés (Azure)

| Service | SKU | Coût estimatif |
|---------|-----|----------------|
| AKS (1 node D2s_v3) | Standard | ~50€/mois |
| PostgreSQL Flexible | Basic B1ms | ~15€/mois |
| ACR | Basic | ~5€/mois |
| VNET/Storage | - | ~5€/mois |
| **Total** | | **~75€/mois** |

⚠️ **Penser à détruire l'infra après utilisation !**

---

## Améliorations Possibles

1. **Ingress Controller** → Exposition sur Internet avec domaine personnalisé
2. **Helm** → Gestion des manifests avec templates
3. **Terraform Remote State** → State dans Azure Blob Storage
4. **GitOps (ArgoCD/Flux)** → Déploiement automatique depuis Git
5. **Monitoring** → Azure Monitor, Prometheus, Grafana
6. **Secrets** → Azure Key Vault au lieu de secrets K8s