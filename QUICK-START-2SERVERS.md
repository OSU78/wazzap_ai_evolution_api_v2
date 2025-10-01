# ⚡ Quick Start - 2 Serveurs Hostinger en 1 Jour

## 🎯 **Résumé Express**

Déployez votre cluster Evolution API avec 2 serveurs Hostinger 16GB en une journée !

### 📊 **Résultat Final**
- ✅ **2 serveurs** Hostinger 16GB RAM
- ✅ **20 instances** Evolution API distribuées  
- ✅ **800 comptes** WhatsApp supportés
- ✅ **SSL automatique** avec Let's Encrypt
- ✅ **Load balancing** avec Traefik
- ✅ **Coût** : 105€/mois

## ⏰ **Planning 1 Jour**

| Heure | Étape | Durée | Action |
|-------|-------|-------|--------|
| **9h-10h** | Préparation | 1h | DNS + Vérifications |
| **10h-11h30** | Installation | 1h30 | `setup-vps.sh` sur 2 serveurs |
| **11h30-12h30** | Swarm | 1h | Configuration cluster |
| **12h30-17h** | Déploiement | 4h30 | Traefik + Evolution API |
| **17h-19h** | Tests | 2h | Validation + Monitoring |

## 🚀 **Commandes Essentielles**

### 📋 **Préparation**
```bash
# 1. Configurer DNS
evolution.wazzap.fr → IP_MANAGER
traefik.wazzap.fr → IP_MANAGER

# 2. Noter vos IPs
IP_MANAGER=XXX.XXX.XXX.XXX
IP_WORKER=YYY.YYY.YYY.YYY
```

### 🛠️ **Installation (Parallèle)**
```bash
# Terminal 1 - Manager
scp -r production/ root@$IP_MANAGER:/root/evolution_api/
ssh root@$IP_MANAGER
cd evolution_api && ./production/setup-vps.sh

# Terminal 2 - Worker  
scp -r production/ root@$IP_WORKER:/root/evolution_api/
ssh root@$IP_WORKER
cd evolution_api && ./production/setup-vps.sh
```

### 🐳 **Configuration Swarm**
```bash
# Sur Manager
docker swarm init --advertise-addr $IP_MANAGER
WORKER_TOKEN=$(docker swarm join-token worker -q)

# Sur Worker
docker swarm join --token $WORKER_TOKEN $IP_MANAGER:2377

# Retour Manager - Étiqueter
WORKER_ID=$(docker node ls --filter role=worker --format "{{.ID}}")
docker node update --label-add type=evolution-worker $WORKER_ID
```

### 🚀 **Déploiement Final**
```bash
# Sur Manager
./production/deploy-2servers.sh
```

## 📊 **Monitoring Post-Déploiement**

### 🔍 **Vérifications Rapides**
```bash
# Status cluster
docker node ls
docker service ls

# Test API
curl https://evolution.wazzap.fr/

# Instances actives
docker service ps evolution_evolution-api | grep Running | wc -l
```

### 📈 **Scaling Immédiat**
```bash
# Augmenter dans la limite des 2 serveurs
docker service scale evolution_evolution-api=25  # Max ~30

# Monitoring
./monitor-2servers.sh
```

## 🔮 **Evolution Future**

### 📅 **Semaine 2 : +2 Serveurs → 1600 comptes**
```bash
# 1. Commander 2 serveurs supplémentaires
# 2. Les joindre au cluster
# 3. Scaler : docker service scale evolution_evolution-api=40
```

### 📅 **Mois 2 : 10 Serveurs → 7000 comptes**
```bash
# 1. Passer aux serveurs 32GB
# 2. Utiliser docker-swarm-7k.yml
# 3. Scaler : docker service scale evolution_evolution-api=180
```

## 🆘 **Dépannage Express**

### ❓ **Problèmes Courants**

**Swarm ne s'initialise pas :**
```bash
# Vérifier firewall
sudo ufw status
sudo ufw allow 2377
```

**Instances ne démarrent pas :**
```bash
# Logs détaillés
docker service logs evolution_evolution-api

# Vérifier ressources
docker node ls
```

**SSL ne fonctionne pas :**
```bash
# Vérifier DNS
nslookup evolution.wazzap.fr

# Logs Traefik
docker service logs traefik_traefik
```

## 🎊 **Commande Magique**

**Pour tout faire d'un coup après installation des serveurs :**

```bash
# Sur le Manager, après setup-vps.sh
./production/deploy-2servers.sh
```

**Et voilà ! Cluster prêt en 1 jour !** 🚀

---

## 📞 **Support Rapide**

- 📖 Guide détaillé : `DEPLOYMENT-7K-GUIDE.md`
- 🔧 Configuration : `production/docker-swarm-2servers.yml`
- 📊 Monitoring : `./monitor-2servers.sh`
- 🧪 Tests : `./test-webhook.sh`

**Bon déploiement !** 🎉
