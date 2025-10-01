# 🚀 Guide de Déploiement Rapide - 1 Jour avec 2 Serveurs 16GB

## 🎯 **Déploiement Express : De 0 à Production en 1 Jour**

Ce guide vous permet de déployer l'Evolution API avec 2 serveurs Hostinger 16GB RAM en une journée, avec possibilité de scaler vers 7000 comptes plus tard.

## ✅ **Votre Situation Actuelle**

### 🖥️ **Infrastructure Disponible**
- **2 serveurs Hostinger** : 16GB RAM chacun
- **Capacité initiale** : ~800 comptes WhatsApp (400 par serveur)
- **Services externes** : Neon PostgreSQL + Redis Cloud ✅
- **Webhook** : Wazzap integration ✅

### 🔍 **Ce qui est déjà prêt :**

✅ **Configuration Docker Swarm** (adaptable 2 serveurs)
✅ **Scripts de déploiement automatisé** 
✅ **Load balancer Traefik** avec SSL
✅ **Base de données externe** (Neon PostgreSQL)
✅ **Cache externe** (Redis Cloud)
✅ **Configuration webhook** (Wazzap integration)
✅ **Scripts d'installation VPS**

### 🎯 **Plan de Scaling Progressif :**

**Phase 1** (Aujourd'hui) : 2 serveurs → 800 comptes
**Phase 2** (Semaine 2) : 4 serveurs → 1600 comptes  
**Phase 3** (Mois 2) : 10 serveurs → 7000+ comptes

## 🏗️ **Architecture Déploiement 1 Jour (2 Serveurs)**

### 📊 **Phase 1 : Configuration Initiale**

```
┌─────────────────────────────────────────────────────────────────┐
│                     Serveur Manager                             │
│                 (Hostinger 16GB RAM)                            │
│  • Traefik Load Balancer + SSL                                 │
│  • Docker Swarm Manager                                        │  
│  • 10 instances Evolution API                                  │
│  • Monitoring intégré                                          │
│  • ~400 comptes WhatsApp                                       │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      │ Docker Swarm Network
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                     Serveur Worker                              │
│                 (Hostinger 16GB RAM)                            │
│  • 10 instances Evolution API                                  │
│  • Auto-healing + Rolling updates                              │
│  • ~400 comptes WhatsApp                                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Services Externes                            │
│  • Neon PostgreSQL (Déjà configuré) ✅                        │
│  • Redis Cloud (Déjà configuré) ✅                            │
│  • Wazzap Webhook (Déjà configuré) ✅                         │
└─────────────────────────────────────────────────────────────────┘
```

### 🔮 **Evolution Future (Scaling)**

```
Phase 2 (Semaine 2): +2 serveurs → 4 serveurs → 1600 comptes
Phase 3 (Mois 2):    +6 serveurs → 10 serveurs → 7000+ comptes
```

## ⏰ **Planning Déploiement 1 Jour**

```
🌅 MATIN (9h-12h)    : Préparation et installation serveurs
🌞 MIDI (12h-14h)    : Configuration Docker Swarm
🌇 APRÈS-MIDI (14h-17h): Déploiement et tests
🌃 SOIR (17h-19h)    : Monitoring et validation
```

## 📋 **Déploiement Express - 1 Jour**

### 🌅 **ÉTAPE 1 : Préparation (9h00 - 10h00)**

#### **1.1 Vérifier vos Serveurs Hostinger**

```bash
# Vous devez avoir 2 serveurs Hostinger avec :
# - 16GB RAM
# - 4-8 vCPU  
# - 200GB SSD
# - Ubuntu 20.04+
# - IP publiques fixes

# Notez les IPs :
IP_MANAGER=XXX.XXX.XXX.XXX    # Serveur 1 (Manager)
IP_WORKER=YYY.YYY.YYY.YYY     # Serveur 2 (Worker)
```

#### **1.2 Configuration DNS (10 minutes)**

```bash
# Configurez vos DNS pour pointer vers le Manager :
evolution.wazzap.fr → IP_MANAGER
traefik.wazzap.fr → IP_MANAGER
api.wazzap.fr → IP_MANAGER
```

### 🌞 **ÉTAPE 2 : Installation Serveurs (10h00 - 11h30)**

#### **2.1 Installation Manager (45 minutes)**

```bash
# 1. Transférer les fichiers sur le Manager
scp -r production/ root@$IP_MANAGER:/root/evolution_api/
ssh root@$IP_MANAGER

# 2. Installation automatique
cd evolution_api
chmod +x production/setup-vps.sh
./production/setup-vps.sh

# 3. Répondre aux questions du script :
# 🌐 Domaine : evolution.wazzap.fr
# 📧 Email : votre@email.com  
# 🔑 API Key : B6D711FCDE4D4FD5936544120E713C37

# ⏱️ Temps d'installation : ~30-45 minutes
```

#### **2.2 Installation Worker (parallèle - 45 minutes)**

```bash
# 1. Dans un autre terminal, installer le Worker
scp -r production/ root@$IP_WORKER:/root/evolution_api/
ssh root@$IP_WORKER

# 2. Installation automatique
cd evolution_api
chmod +x production/setup-vps.sh
./production/setup-vps.sh

# 3. Répondre aux questions (même domaine, même email, même clé)
# ⏱️ Les deux serveurs s'installent en parallèle
```

### 🌞 **ÉTAPE 3 : Configuration Swarm (11h30 - 12h30)**

#### **3.1 Initialiser Docker Swarm (10 minutes)**

```bash
# Sur le Manager
ssh root@$IP_MANAGER
docker swarm init --advertise-addr $IP_MANAGER

# 📋 Noter le token affiché (ressemble à ça) :
# SWMTKN-1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx-yyyyyyyyyyyyyyyyyy

# Récupérer le token proprement
WORKER_TOKEN=$(docker swarm join-token worker -q)
echo "🔑 Token Worker: $WORKER_TOKEN"
```

#### **3.2 Joindre le Worker (5 minutes)**

```bash
# Sur le Worker
ssh root@$IP_WORKER
docker swarm join --token $WORKER_TOKEN $IP_MANAGER:2377

# ✅ Vous devriez voir : "This node joined a swarm as a worker"
```

#### **3.3 Vérifier le Cluster (5 minutes)**

```bash
# Retour sur le Manager
ssh root@$IP_MANAGER
docker node ls

# ✅ Vous devriez voir quelque chose comme :
# ID        HOSTNAME    STATUS  AVAILABILITY  MANAGER STATUS
# abc123*   manager1    Ready   Active        Leader
# def456    worker1     Ready   Active        

# Étiqueter le worker
WORKER_NODE_ID=$(docker node ls --filter role=worker --format "{{.ID}}")
docker node update --label-add type=evolution-worker $WORKER_NODE_ID

echo "✅ Cluster Swarm configuré avec 2 nœuds !"
```

### 🌇 **ÉTAPE 4 : Déploiement (12h30 - 17h00)**

#### **4.1 Créer les Volumes et Réseaux (5 minutes)**

```bash
# Sur le Manager
ssh root@$IP_MANAGER
cd evolution_api

# Créer le réseau overlay pour Swarm
docker network create --driver=overlay network_public

# Créer le volume pour les instances
docker volume create evolution_2servers_instances

echo "✅ Infrastructure Swarm prête"
```

#### **4.2 Déployer Traefik (15 minutes)**

```bash
# Modifier traefik.yml pour votre domaine
sed -i 's/your-domain.com/wazzap.fr/g' production/traefik.yml
sed -i 's/your@email.com/votre@email.com/g' production/traefik.yml

# Déployer Traefik
docker stack deploy --prune --resolve-image always -c production/traefik.yml traefik

# Attendre que Traefik soit prêt
echo "⏳ Attente de Traefik (2-3 minutes)..."
sleep 180

# Vérifier Traefik
docker stack ps traefik
curl -s https://traefik.wazzap.fr/ || echo "⏳ SSL en cours de génération..."

echo "✅ Traefik déployé avec SSL"
```

#### **4.3 Déployer Evolution API - 2 Serveurs (30 minutes)**

```bash
# Déployer avec la configuration 2 serveurs
docker stack deploy --prune --resolve-image always -c production/docker-swarm-2servers.yml evolution

echo "⏳ Attente du déploiement des 20 instances..."
echo "   Cela peut prendre 5-10 minutes..."

# Suivre le déploiement en temps réel
watch "docker service ps evolution_evolution-api"
# Appuyez sur Ctrl+C quand vous voyez 20/20 instances Running

# Vérification finale
echo "📊 Vérification du déploiement..."
docker service ls
docker service ps evolution_evolution-api

echo "✅ Evolution API déployée sur 2 serveurs"
```

### 🌃 **ÉTAPE 5 : Tests et Validation (17h00 - 19h00)**

#### **5.1 Tests de Connectivité (15 minutes)**

```bash
# Test 1: API accessible via HTTPS
curl -s https://evolution.wazzap.fr/ | jq '.'

# Test 2: Dashboard Traefik
curl -s https://traefik.wazzap.fr/api/http/services | jq '.[] | select(.name | contains("evolution"))'

# Test 3: Webhook configuré
curl -s -H "apikey: B6D711FCDE4D4FD5936544120E713C37" https://evolution.wazzap.fr/webhook | jq '.'

# Test 4: Load balancing (plusieurs requêtes)
for i in {1..10}; do
  curl -s https://evolution.wazzap.fr/ | jq -r '.clientName'
  sleep 1
done
```

#### **5.2 Créer une Instance de Test (15 minutes)**

```bash
# Créer une instance WhatsApp de test
curl -X POST \
  -H "apikey: B6D711FCDE4D4FD5936544120E713C37" \
  -H "Content-Type: application/json" \
  -d '{
    "instanceName": "test-production",
    "token": "test-prod-token",
    "qrcode": true,
    "webhookUrl": "https://wazzap.ngrok.app/api/webhook/v2/messageHandlers",
    "webhookByEvents": true,
    "events": ["QRCODE_UPDATED", "CONNECTION_UPDATE", "MESSAGES_UPSERT"]
  }' \
  https://evolution.wazzap.fr/instance/create | jq '.'

echo "📱 Instance de test créée - Scannez le QR code avec WhatsApp"
```

#### **5.3 Configuration du Monitoring (30 minutes)**

```bash
# Créer le script de monitoring
cat > monitor-2servers.sh << 'EOF'
#!/bin/bash

echo "📊 Monitoring Cluster 2 Serveurs"
echo "================================"

# Informations cluster
echo "🖥️ Nœuds du cluster :"
docker node ls

echo ""
echo "📦 Services déployés :"
docker service ls

echo ""
echo "⚡ Instances Evolution API :"
RUNNING=$(docker service ps evolution_evolution-api --filter desired-state=running --format "{{.CurrentState}}" | grep -c "Running" 2>/dev/null || echo "0")
TOTAL=$(docker service ls --filter name=evolution_evolution-api --format "{{.Replicas}}" | cut -d'/' -f2)
echo "   Actives : $RUNNING/$TOTAL"

echo ""
echo "🌐 Répartition par serveur :"
docker service ps evolution_evolution-api --format "table {{.Node}}\t{{.CurrentState}}\t{{.Error}}" | head -25

echo ""
echo "💾 Utilisation ressources estimée :"
echo "   RAM utilisée : ~$((RUNNING * 40))MB par serveur"
echo "   Comptes supportés : ~$((RUNNING * 40)) comptes WhatsApp"

echo ""
echo "🔗 Accès :"
echo "   API : https://evolution.wazzap.fr"
echo "   Traefik : https://traefik.wazzap.fr"

echo ""
echo "🧪 Tests rapides :"
echo "   curl https://evolution.wazzap.fr/"
echo "   curl https://traefik.wazzap.fr/api/http/services"
EOF

chmod +x monitor-2servers.sh
./monitor-2servers.sh

echo "✅ Monitoring configuré"
```

## 💰 **Coûts Réels - 2 Serveurs**

### 🏷️ **Coût Mensuel Phase 1**

| Composant | Quantité | Prix/mois | Total |
|-----------|----------|-----------|-------|
| **Serveurs Hostinger 16GB** | 2 | 25€ | 50€ |
| **Neon PostgreSQL** | Plan Scale | 25€ | 25€ |
| **Redis Cloud** | 8GB | 30€ | 30€ |
| **Domaine + SSL** | Let's Encrypt | 0€ | 0€ |
| **Total Phase 1** | | | **105€/mois** |

### 📊 **Capacité Phase 1**
- **Serveurs** : 2 × 16GB RAM
- **Instances API** : 20 (10 par serveur)
- **Comptes WhatsApp** : ~800 comptes
- **Coût par compte** : 0.13€/mois

### 📈 **Evolution des Coûts**

| Phase | Serveurs | Coût/mois | Comptes | Coût/compte |
|-------|----------|-----------|---------|-------------|
| **Phase 1** | 2 × 16GB | 105€ | 800 | 0.13€ |
| **Phase 2** | 4 × 16GB | 180€ | 1600 | 0.11€ |
| **Phase 3** | 10 × 32GB | 560€ | 7000 | 0.08€ |

## ⚡ **Commandes de Gestion Post-Déploiement**

### 🔧 **Scaling Rapide**

```bash
# Augmenter les instances (dans la limite de vos 2 serveurs)
docker service scale evolution_evolution-api=25  # Max ~30 sur 2 serveurs 16GB

# Voir la répartition
docker service ps evolution_evolution-api

# Revenir au nombre optimal
docker service scale evolution_evolution-api=20
```

### 📊 **Monitoring Quotidien**

```bash
# Status rapide
./monitor-2servers.sh

# Logs en temps réel
docker service logs -f evolution_evolution-api

# Performance par nœud
docker node ps $(docker node ls -q)
```

### 🔄 **Maintenance**

```bash
# Mise à jour rolling (sans downtime)
docker service update --image atendai/evolution-api:v2.1.2 evolution_evolution-api

# Redémarrer un service
docker service update --force evolution_evolution-api

# Nettoyer Docker
docker system prune -f
```

## 🚀 **Plan de Scaling Future**

### 📅 **Semaine 2 : Passer à 4 Serveurs**

```bash
# 1. Provisionner 2 serveurs supplémentaires
# 2. Les joindre au cluster :
#    docker swarm join --token TOKEN IP_MANAGER:2377
# 3. Étiqueter les nouveaux workers
# 4. Scaler à 40 instances :
#    docker service scale evolution_evolution-api=40
```

### 📅 **Mois 2 : Passer à 10 Serveurs (7000 comptes)**

```bash
# 1. Provisionner 6 serveurs 32GB supplémentaires
# 2. Utiliser docker-swarm-7k.yml
# 3. Scaler à 180 instances :
#    docker service scale evolution_evolution-api=180
```

## ✅ **Checklist Déploiement 1 Jour**

### 📋 **Matin (9h-12h)**
- [ ] 2 serveurs Hostinger provisionnés
- [ ] DNS configuré (evolution.wazzap.fr)
- [ ] `setup-vps.sh` exécuté sur les 2 serveurs
- [ ] Docker Swarm initialisé
- [ ] Worker joint au cluster

### 📋 **Après-midi (12h-17h)**
- [ ] Réseau overlay créé
- [ ] Traefik déployé avec SSL
- [ ] Evolution API déployée (20 instances)
- [ ] Tests de connectivité OK

### 📋 **Soir (17h-19h)**
- [ ] Instance WhatsApp de test créée
- [ ] Monitoring configuré
- [ ] Webhook Wazzap testé
- [ ] Documentation équipe mise à jour

## 🎊 **Résultat Final**

À la fin de la journée, vous aurez :

✅ **Cluster opérationnel** avec 2 serveurs
✅ **20 instances Evolution API** distribuées
✅ **SSL automatique** avec Let's Encrypt
✅ **Load balancing** avec Traefik
✅ **Webhook Wazzap** intégré
✅ **Monitoring** automatique
✅ **Capacité** : ~800 comptes WhatsApp
✅ **Haute disponibilité** (si un serveur tombe, l'autre continue)

## 🆘 **Dépannage Express**

### ❓ **Si une instance ne démarre pas**

```bash
# Voir les logs
docker service logs evolution_evolution-api

# Redémarrer le service
docker service update --force evolution_evolution-api
```

### ❓ **Si SSL ne fonctionne pas**

```bash
# Vérifier Traefik
docker stack ps traefik

# Logs Let's Encrypt
docker service logs traefik_traefik

# Vérifier DNS
nslookup evolution.wazzap.fr
```

### ❓ **Si les instances ne se répartissent pas**

```bash
# Vérifier les contraintes
docker service inspect evolution_evolution-api --format '{{.Spec.TaskTemplate.Placement}}'

# Forcer la redistribution
docker service update --force evolution_evolution-api
```

---

## 🎯 **Commande de Déploiement Finale**

**Une fois vos 2 serveurs installés et Swarm configuré :**

```bash
./production/deploy-2servers.sh
```

**Temps total estimé : 1 journée de travail** ⏰

**Résultat : Cluster professionnel prêt pour 800 comptes WhatsApp** 🚀
