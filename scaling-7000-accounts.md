# 🚀 Plan de Scaling pour 7000 Comptes WhatsApp

## 📊 Analyse des Besoins

### 💾 Consommation par Instance
- **RAM**: 30-55 MB par compte (moyenne 40 MB)
- **Stockage**: 50-100 MB par compte (messages, médias)
- **CPU**: 0.1-0.2 vCPU par compte actif

### 🧮 Calcul Total pour 7000 Comptes
- **RAM nécessaire**: 280-385 GB
- **Stockage nécessaire**: 350-700 GB
- **CPU nécessaire**: 700-1400 vCPU

## 🏗️ Architecture Distribuée Recommandée

### 📋 Option 1: Cluster Multi-Serveurs (Optimal)

```
┌─────────────────────────────────────────────────────────┐
│                    Load Balancer                        │
│                   (Traefik Master)                      │
└─────────────────────┬───────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼────┐        ┌───▼────┐        ┌───▼────┐
│Server 1│        │Server 2│        │Server 3│
│32GB RAM│        │32GB RAM│        │32GB RAM│
│8 vCPU  │        │8 vCPU  │        │8 vCPU  │
│        │        │        │        │        │
│~800    │        │~800    │        │~800    │
│comptes │        │comptes │        │comptes │
└────────┘        └────────┘        └────────┘

        ... (répéter jusqu'à 9 serveurs)

┌─────────────────────────────────────────────────────────┐
│                Services Partagés                        │
│  • PostgreSQL (Neon) - Base de données centralisée     │
│  • Redis Cluster - Cache et synchronisation            │
│  • Monitoring - Prometheus + Grafana                   │
└─────────────────────────────────────────────────────────┘
```

#### 🖥️ Configuration par Serveur
- **RAM**: 32 GB
- **CPU**: 8 vCPU
- **Stockage**: 200 GB SSD
- **Capacité**: ~800 comptes WhatsApp
- **Coût**: ~50-80€/mois par serveur

#### 📊 Cluster Complet
- **Nombre de serveurs**: 9 serveurs
- **Capacité totale**: 7200 comptes
- **Coût total**: 450-720€/mois
- **Redondance**: Haute disponibilité

### 📋 Option 2: Gros Serveurs (Alternative)

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Server 1     │    │    Server 2     │    │    Server 3     │
│   128 GB RAM    │    │   128 GB RAM    │    │   128 GB RAM    │
│   32 vCPU       │    │   32 vCPU       │    │   32 vCPU       │
│   1 TB SSD      │    │   1 TB SSD      │    │   1 TB SSD      │
│                 │    │                 │    │                 │
│  ~2300 comptes  │    │  ~2300 comptes  │    │  ~2400 comptes  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

#### 🖥️ Configuration par Serveur
- **RAM**: 128 GB
- **CPU**: 32 vCPU  
- **Stockage**: 1 TB SSD
- **Capacité**: ~2300 comptes WhatsApp
- **Coût**: ~300-500€/mois par serveur

#### 📊 Cluster Complet
- **Nombre de serveurs**: 3 serveurs
- **Capacité totale**: 7000 comptes
- **Coût total**: 900-1500€/mois
- **Redondance**: Moyenne

## 🔧 Configuration Docker Swarm pour 7000 Comptes

### 📄 docker-swarm-7k.yml

```yaml
version: "3.7"

services:
  evolution-api:
    image: evoapicloud/evolution-api:v2.3.0
    environment:
      # Base de données externe (Neon)
      DATABASE_CONNECTION_URI: postgresql://user:pass@neon-host/db
      
      # Cache Redis distribué
      CACHE_REDIS_ENABLED: true
      CACHE_REDIS_URI: redis://redis-cluster:6379/1
      
      # Configuration performance
      CLEAN_STORE_CLEANING_INTERVAL: 14400  # 4h au lieu de 2h
      CLEAN_STORE_MESSAGES: true
      
      # Webhook configuration
      WEBHOOK_GLOBAL_URL: https://wazzap.ngrok.app/api/webhook/v2/messageHandlers
      WEBHOOK_GLOBAL_ENABLED: true
      
    deploy:
      mode: replicated
      replicas: 20  # 20 instances par serveur
      placement:
        max_replicas_per_node: 20
        constraints:
          - node.labels.type == evolution-worker
      resources:
        limits:
          memory: 1.5G  # 1.5GB par instance
          cpus: '0.4'   # 0.4 CPU par instance
        reservations:
          memory: 800M  # 800MB réservé
          cpus: '0.2'   # 0.2 CPU réservé
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      update_config:
        parallelism: 2
        delay: 30s
        failure_action: rollback
        
    volumes:
      - evolution_instances:/evolution/instances
    networks:
      - evolution_network

volumes:
  evolution_instances:
    external: true
    
networks:
  evolution_network:
    external: true
```

## 📈 Optimisations pour 7000 Comptes

### ⚡ Optimisations Performance

#### 1. Base de Données
```bash
# PostgreSQL optimisé pour 7000 connexions
max_connections = 1000
shared_buffers = 8GB
effective_cache_size = 24GB
work_mem = 16MB
maintenance_work_mem = 2GB
```

#### 2. Redis Configuration
```bash
# Redis optimisé pour cache distribué
maxmemory 16gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

#### 3. Variables d'Environnement
```bash
# Réduction de la fréquence de nettoyage
CLEAN_STORE_CLEANING_INTERVAL=14400  # 4h
CLEAN_STORE_MESSAGES=true
CLEAN_STORE_MESSAGE_UP_TO=7  # 7 jours au lieu de défaut

# Optimisation logs
LOG_LEVEL=ERROR  # Réduire les logs
LOG_BAILEYS=error

# Cache optimisé
CACHE_REDIS_SAVE_INSTANCES=true
CACHE_LOCAL_ENABLED=false
```

## 💰 Analyse des Coûts

### 🏷️ Option 1: Multi-Serveurs (32GB)
| Composant | Quantité | Prix/mois | Total |
|-----------|----------|-----------|-------|
| Serveurs 32GB | 9 | 60€ | 540€ |
| Load Balancer | 1 | 30€ | 30€ |
| Neon PostgreSQL | 1 | 50€ | 50€ |
| Redis Cloud | 1 | 40€ | 40€ |
| **Total** | | | **660€/mois** |

### 🏷️ Option 2: Gros Serveurs (128GB)
| Composant | Quantité | Prix/mois | Total |
|-----------|----------|-----------|-------|
| Serveurs 128GB | 3 | 400€ | 1200€ |
| Load Balancer | 1 | 30€ | 30€ |
| Neon PostgreSQL | 1 | 100€ | 100€ |
| Redis Cloud | 1 | 60€ | 60€ |
| **Total** | | | **1390€/mois** |

## 🚀 Plan de Déploiement

### Phase 1: Infrastructure (Semaine 1)
1. Provisionner les serveurs
2. Configurer Docker Swarm
3. Déployer Traefik + monitoring

### Phase 2: Services Core (Semaine 2)
1. Configurer PostgreSQL (Neon)
2. Déployer Redis Cluster
3. Tests de connectivité

### Phase 3: Evolution API (Semaine 3)
1. Déployer Evolution API
2. Configuration load balancing
3. Tests de charge

### Phase 4: Migration Progressive (Semaine 4)
1. Migrer 1000 comptes par jour
2. Monitoring performance
3. Ajustements configuration

## 📊 Monitoring 7000 Comptes

### 🎯 KPIs à Surveiller
- **RAM usage** par serveur (< 80%)
- **CPU usage** par serveur (< 70%)
- **Connexions DB** (< 800/1000)
- **Response time** API (< 500ms)
- **Instances actives** vs total
- **Messages/seconde** traités

### 🚨 Alertes Critiques
- RAM > 90% sur un serveur
- Plus de 50 instances déconnectées
- Response time > 2 secondes
- Erreurs webhook > 5%

## ✅ Recommandation Finale

**Option Recommandée**: Multi-serveurs 32GB
- ✅ Meilleur rapport qualité/prix
- ✅ Haute disponibilité
- ✅ Scaling facile
- ✅ Maintenance sans downtime
- ✅ Coût maîtrisé (660€/mois)

**Éviter**: Serveur unique 16GB
- ❌ Impossible techniquement
- ❌ Single point of failure
- ❌ Pas de scaling possible
