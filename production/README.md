# 🌐 Production & VPS

Scripts et configurations pour le déploiement en production de l'API Evolution v2.

## 📁 Contenu du Dossier

| Fichier | Description | Usage |
|---------|-------------|-------|
| `setup-vps.sh` | 🛠️ Installation complète VPS | `./setup-vps.sh` |
| `deploy-swarm.sh` | 🐳 Déploiement Docker Swarm | `./deploy-swarm.sh` |
| `collect-logs.sh` | 🔍 Collecte de logs pour debug | `./collect-logs.sh` |
| `docker-swarm.yml` | ⚙️ Configuration Docker Swarm | - |
| `traefik.yml` | 🌐 Configuration Traefik production | - |

## 🚀 Déploiements Disponibles

### 🖥️ **VPS Standalone**
Configuration pour serveur unique avec SSL automatique.

```bash
# Sur votre serveur VPS
wget https://raw.githubusercontent.com/votre-repo/production/setup-vps.sh
chmod +x setup-vps.sh
./setup-vps.sh
```

**Fonctionnalités :**
- ✅ SSL automatique (Let's Encrypt)
- ✅ Traefik load balancer
- ✅ Firewall et sécurité
- ✅ Auto-démarrage

### 🐳 **Docker Swarm**
Configuration pour cluster multi-serveurs haute disponibilité.

```bash
# Initialiser Swarm sur le manager
docker swarm init --advertise-addr YOUR_IP

# Déployer
./deploy-swarm.sh
```

**Fonctionnalités :**
- ✅ Load balancing multi-instances
- ✅ Rolling updates sans downtime
- ✅ Auto-healing
- ✅ Scaling horizontal

## ⚙️ Configuration Requise

### 📋 **Prérequis VPS**
- **OS** : Ubuntu 20.04+ ou Debian 11+
- **RAM** : Minimum 2GB (recommandé 4GB+)
- **CPU** : Minimum 1 vCore (recommandé 2+)
- **Stockage** : Minimum 20GB SSD
- **Réseau** : IP publique fixe

### 🌐 **DNS Requis**
- Domaine principal : `your-domain.com` → IP serveur
- Traefik dashboard : `traefik.your-domain.com` → IP serveur

## 🔧 Scripts de Configuration

### 🛠️ **setup-vps.sh**
Script d'installation complète qui configure :
- Docker et Docker Compose
- Firewall UFW et Fail2Ban
- Hostname et DNS
- SSL avec Let's Encrypt
- Service auto-démarrage

**Variables demandées :**
- Nom de domaine
- Email Let's Encrypt
- Clé API sécurisée

### 🐳 **deploy-swarm.sh**
Script de déploiement Docker Swarm qui :
- Vérifie l'initialisation Swarm
- Crée les réseaux et volumes
- Configure les secrets
- Déploie Traefik et l'API
- Affiche les instructions finales

### 🔍 **collect-logs.sh**
Script de diagnostic qui collecte :
- Informations système
- Logs Docker
- Configuration réseau
- Tests de connectivité
- État des services

## 📊 Monitoring Production

### 🎛️ **Dashboard Traefik**
- **URL** : https://traefik.your-domain.com
- **Authentification** : Basique (configurée dans setup-vps.sh)
- **Fonctionnalités** : Métriques, santé, certificats SSL

### 📝 **Logs**
```bash
# Logs des services
docker-compose logs -f evolution-api
docker service logs evolution_evolution-api  # Swarm

# Logs système
journalctl -u evolution-api.service

# Collecte complète
./collect-logs.sh
```

### 📈 **Métriques**
- **Prometheus** : Port 8082
- **Health checks** : Automatiques
- **SSL monitoring** : Let's Encrypt auto-renewal

## 🛡️ Sécurité Production

### 🔥 **Firewall (UFW)**
Ports ouverts automatiquement :
- `22` : SSH
- `80` : HTTP (redirect vers HTTPS)
- `443` : HTTPS
- `8080` : API direct (tests uniquement)

### 🔐 **Authentification**
- Clé API sécurisée obligatoire
- JWT avec secret généré
- Authentification Traefik dashboard

### 🛡️ **Protection**
- Fail2Ban pour SSH
- Rate limiting Traefik
- Headers de sécurité
- CORS configuré

## 📈 Scaling Production

### 🔄 **Scaling Vertical**
```bash
# Augmenter les ressources du serveur
# Puis redémarrer les services
docker-compose restart evolution-api
```

### ↔️ **Scaling Horizontal (Swarm)**
```bash
# Augmenter les réplicas
docker service scale evolution_evolution-api=3

# Ajouter des nœuds
docker swarm join --token TOKEN MANAGER_IP:2377
```

### 📊 **Recommandations**
| Charge | Architecture | Instances | RAM/CPU |
|--------|--------------|-----------|---------|
| Légère | VPS Standalone | 1 | 4GB/2CPU |
| Moyenne | Swarm 3 nœuds | 3 | 8GB/4CPU |
| Lourde | Swarm 5+ nœuds | 5+ | 16GB/8CPU |

## 🆘 Dépannage Production

### 🔍 **Diagnostic Rapide**
```bash
# Collecte complète de logs
./collect-logs.sh

# État des services
docker-compose ps
docker service ps evolution_evolution-api  # Swarm

# Tests de connectivité
curl https://your-domain.com/
```

### ❓ **Problèmes Courants**

**SSL ne fonctionne pas :**
```bash
# Vérifier DNS
nslookup your-domain.com

# Logs Let's Encrypt
docker-compose logs traefik
```

**API inaccessible :**
```bash
# Vérifier firewall
sudo ufw status

# Tester ports
ss -tlnp | grep -E ":80|:443"
```

**Services ne démarrent pas :**
```bash
# Ressources système
free -h
df -h

# Logs détaillés
journalctl -u docker.service
```

## 🔄 Maintenance

### 📅 **Tâches Régulières**
```bash
# Mise à jour système (mensuel)
sudo apt update && sudo apt upgrade -y

# Nettoyage Docker (hebdomadaire)
docker system prune -f

# Vérification SSL (automatique)
# Let's Encrypt renouvelle automatiquement
```

### 💾 **Sauvegardes**
```bash
# Volumes Docker
docker run --rm -v evolution_instances:/data -v $(pwd):/backup alpine tar czf /backup/instances.tar.gz -C /data .

# Configuration
tar -czf config-backup.tar.gz docker-compose.yml .env
```

## 📞 Support Production

Pour obtenir de l'aide :
1. Exécutez `./collect-logs.sh`
2. Consultez les guides dans `../docs/`
3. Vérifiez les configurations dans `../configs/`
4. Envoyez l'archive de logs générée
