# 🚀 Evolution API v2 - Configuration Complète

Une configuration complète et organisée pour déployer l'API Evolution v2 dans tous les environnements, du développement local au cluster Docker Swarm en production.

## 📁 Architecture du Projet

```
evolution_wazzap_api/
├── 📂 local/                          # 🏠 Développement Local
│   ├── start-local.sh                 # Démarrage simple (standalone)
│   ├── start-traefik.sh              # Démarrage avec Traefik + Dashboard
│   ├── stop-local.sh                 # Arrêt des services locaux
│   ├── stop-traefik.sh               # Arrêt avec Traefik
│   ├── logs-local.sh                 # Logs en temps réel
│   └── docker-compose-traefik.yml    # Config Docker avec Traefik local
│
├── 📂 production/                     # 🌐 Production & VPS
│   ├── setup-vps.sh                  # Installation complète VPS
│   ├── deploy-swarm.sh               # Déploiement Docker Swarm
│   ├── collect-logs.sh               # Collecte de logs pour debug
│   ├── docker-swarm.yml              # Configuration Swarm
│   └── traefik.yml                   # Configuration Traefik production
│
├── 📂 configs/                       # ⚙️ Configurations
│   ├── config-template.env           # Template complet des variables
│   └── production.env                # Variables pour production
│
├── 📂 docs/                          # 📚 Documentation
│   ├── GUIDE-DEPLOIEMENT.md          # Guide de déploiement VPS
│   └── README-SCALING.md             # Guide de scaling avancé
│
├── 📄 docker-compose.yml             # Config Docker principale (standalone)
├── 🚀 start-local                    # Raccourci démarrage local
├── 🚀 start-traefik                  # Raccourci démarrage Traefik
├── 🛑 stop-local                     # Raccourci arrêt local
└── 📖 README.md                      # Ce fichier
```

## 🎯 Démarrage Rapide

### 🏠 **Développement Local**

```bash
# Démarrage simple (recommandé)
./start-local

# Ou avec Traefik + Dashboard
./start-traefik

# Arrêt
./stop-local
```

### 🌐 **Production - Choisissez votre Configuration**

#### **🖥️ Option 1 : 1 Serveur 16GB (Débutant)**
```bash
# Capacité : 400 comptes WhatsApp
# Coût : 70€/mois
# Temps : 2 heures

./production/setup-vps.sh
./production/deploy-single-16gb.sh
```

#### **🐳 Option 2 : 2 Serveurs 16GB (Recommandé)**
```bash
# Capacité : 800 comptes WhatsApp  
# Coût : 105€/mois
# Temps : 1 journée

# Voir : DEPLOYMENT-7K-GUIDE.md
./production/deploy-2servers.sh
```

#### **🚀 Option 3 : Cluster 10 Serveurs (Entreprise)**
```bash
# Capacité : 7000 comptes WhatsApp
# Coût : 560€/mois  
# Temps : 1 semaine

# Voir : scaling-7000-accounts.md
./production/deploy-7k.sh
```

## 🔧 Environnements Disponibles

### 🏠 **Local - Développement**

| Mode | Commande | Description | Accès |
|------|----------|-------------|-------|
| **Simple** | `./start-local` | API seule avec services externes | http://localhost:8080 |
| **Traefik** | `./start-traefik` | API + Dashboard Traefik | http://evolution.localhost<br>Dashboard: http://localhost:8080 |

**Caractéristiques :**
- ✅ Utilise Neon PostgreSQL (cloud)
- ✅ Utilise Redis Cloud
- ✅ Logs colorés et détaillés
- ✅ Rechargement automatique
- ✅ Configuration optimisée pour le debug

### 🌐 **Production - VPS**

| Mode | Description | Capacity | Coût | SSL |
|------|-------------|----------|------|-----|
| **Single 16GB** | 1 serveur avec 10 instances | 400 comptes | 70€/mois | ✅ Let's Encrypt |
| **Dual 16GB** | 2 serveurs avec 20 instances | 800 comptes | 105€/mois | ✅ Let's Encrypt |
| **Cluster 7K** | 10 serveurs avec 180 instances | 7000 comptes | 560€/mois | ✅ Let's Encrypt |

**Caractéristiques :**
- ✅ SSL automatique (Let's Encrypt)
- ✅ Load balancing (Traefik)
- ✅ Auto-healing et rolling updates
- ✅ Monitoring et métriques
- ✅ Backups automatiques

## 📊 Services Externes Configurés

### 🐘 **Base de Données - Neon PostgreSQL**
- **Provider** : Neon (serverless PostgreSQL)
- **Avantages** : Scaling automatique, backups, haute disponibilité
- **Configuration** : SSL requis, connection pooling

### 🔴 **Cache - Redis Cloud**
- **Provider** : Redis Labs Cloud
- **Usage** : Cache, sessions, synchronisation inter-instances
- **Configuration** : Persistance, éviction LRU

## 🚀 Commandes Principales

### 🏠 **Local**
```bash
./start-local           # Démarrage simple
./start-traefik         # Démarrage avec Traefik
./stop-local            # Arrêt des services

# Commandes avancées
./local/logs-local.sh   # Logs en temps réel
docker-compose ps       # Statut des conteneurs
```

### 🌐 **Production**
```bash
# Installation VPS
./production/setup-vps.sh

# Déploiement Swarm
./production/deploy-swarm.sh

# Diagnostic
./production/collect-logs.sh
```

## ⚙️ Configuration

### 🔧 **Variables d'Environnement**

Les principales variables à configurer :

```bash
# Authentification
AUTHENTICATION_API_KEY=your-secure-api-key
JWT_SECRET=your-jwt-secret

# Base de données (déjà configurée)
DATABASE_CONNECTION_URI=postgresql://...

# Cache Redis (déjà configuré)
CACHE_REDIS_URI=redis://...

# Domaine (production uniquement)
SERVER_URL=https://your-domain.com
```

### 📝 **Fichiers de Configuration**

- `configs/config-template.env` : Template complet avec toutes les variables
- `configs/production.env` : Configuration de base pour production
- `.env` : Généré automatiquement par les scripts

## 🔍 Monitoring et Logs

### 📊 **Dashboard Traefik**

En local avec Traefik :
- **URL** : http://localhost:8080
- **Fonctionnalités** : Routes, services, métriques, health checks

En production :
- **URL** : https://traefik.your-domain.com
- **Sécurisé** : Authentification basique

### 📝 **Logs**

```bash
# Local
./local/logs-local.sh

# Production
docker-compose logs -f evolution-api
docker service logs evolution_evolution-api  # Swarm
```

### 🔍 **Diagnostic**

```bash
# Collecte complète de logs
./production/collect-logs.sh

# Tests de connectivité
curl http://localhost:8080/              # Local
curl https://your-domain.com/            # Production
```

## 🛡️ Sécurité

### 🔐 **Authentification**
- Clé API sécurisée obligatoire
- JWT avec secret fort
- CORS configuré

### 🌐 **Réseau**
- Firewall UFW configuré automatiquement
- SSL/TLS avec Let's Encrypt
- Fail2Ban pour la protection SSH

### 🔒 **Données**
- Connexions chiffrées (PostgreSQL SSL, Redis TLS)
- Secrets Docker pour les mots de passe
- Variables d'environnement sécurisées

## 📈 Scaling

### 🔄 **Scaling Vertical**
- Augmenter RAM/CPU du serveur
- Optimiser les variables d'environnement
- Ajuster les limites Docker

### ↔️ **Scaling Horizontal**
```bash
# Docker Swarm - Augmenter les réplicas
docker service scale evolution_evolution-api=5

# Ajouter des nœuds au cluster
docker swarm join --token TOKEN MANAGER_IP:2377
```

### 📊 **Recommandations par Charge**

| Instances WhatsApp | Architecture | RAM | CPU | Nœuds |
|-------------------|--------------|-----|-----|-------|
| < 50 | Local/Standalone | 4GB | 2 cores | 1 |
| 50-200 | VPS Standalone | 8GB | 4 cores | 1 |
| 200-500 | Docker Swarm | 16GB | 8 cores | 3 |
| 500+ | Swarm + Load Balancer | 32GB+ | 16+ cores | 5+ |

## 🆘 Dépannage

### ❓ **Problèmes Courants**

**API ne démarre pas :**
```bash
# Vérifier les logs
./local/logs-local.sh
# ou
docker-compose logs evolution-api
```

**Traefik ne fonctionne pas :**
```bash
# Vérifier les domaines locaux
cat /etc/hosts | grep localhost

# Tester Traefik
curl http://localhost:8080/api/http/routers
```

**SSL ne fonctionne pas en production :**
```bash
# Vérifier DNS
nslookup your-domain.com

# Logs Let's Encrypt
docker-compose logs traefik
```

### 🔧 **Outils de Diagnostic**

```bash
# Santé générale
docker ps
docker-compose ps

# Ressources système
htop
df -h

# Réseau
ss -tlnp | grep -E ":80|:443|:8080"
```

## 🤝 Contribution

### 📁 **Structure pour Nouvelles Fonctionnalités**

- **Local** : Ajoutez dans `local/`
- **Production** : Ajoutez dans `production/`
- **Documentation** : Ajoutez dans `docs/`
- **Configuration** : Ajoutez dans `configs/`

### 🔄 **Workflow de Développement**

1. Développez en local avec `./start-local`
2. Testez avec Traefik : `./start-traefik`
3. Validez en production avec `production/setup-vps.sh`
4. Scalez avec `production/deploy-swarm.sh`

## 📞 Support

### 🔗 **Liens Utiles**
- [Documentation Evolution API](https://doc.evolution-api.com/)
- [Guide de déploiement détaillé](docs/GUIDE-DEPLOIEMENT.md)
- [Guide de scaling avancé](docs/README-SCALING.md)

### 📧 **Aide**
- Collectez les logs avec `production/collect-logs.sh`
- Consultez les guides dans le dossier `docs/`
- Vérifiez les configurations dans `configs/`

---

## 🎉 Félicitations !

Vous avez maintenant une configuration complète et professionnelle pour déployer l'API Evolution v2 dans tous les environnements ! 🚀

**Démarrez maintenant :**
```bash
./start-local    # Pour le développement
# ou
./start-traefik  # Pour tester avec Traefik
```
