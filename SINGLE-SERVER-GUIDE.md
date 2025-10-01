# 🖥️ Guide Déploiement - 1 Serveur Hostinger 16GB

## 🎯 **Configuration Serveur Unique**

### 📊 **Pourquoi 10 Instances sur 1 Serveur ?**

```
┌─────────────────────────────────────────────────────────┐
│                Serveur Hostinger 16GB                   │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │Instance #1  │  │Instance #2  │  │Instance #3  │     │
│  │40 comptes WA│  │40 comptes WA│  │40 comptes WA│     │
│  │~800MB RAM   │  │~800MB RAM   │  │~800MB RAM   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │Instance #4  │  │Instance #5  │  │Instance #6  │     │
│  │40 comptes WA│  │40 comptes WA│  │40 comptes WA│     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │Instance #7  │  │Instance #8  │  │Instance #9  │     │
│  │40 comptes WA│  │40 comptes WA│  │40 comptes WA│     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
│                                                         │
│                    ┌─────────────┐                     │
│                    │Instance #10 │                     │
│                    │40 comptes WA│                     │
│                    └─────────────┘                     │
│                                                         │
│  📊 Total: 400 comptes WhatsApp                        │
│  💾 RAM utilisée: ~10GB / 16GB disponibles             │
│  ⚡ CPU utilisée: ~4 vCPU / 8 vCPU disponibles         │
└─────────────────────────────────────────────────────────┘
```

### ✅ **Avantages du Serveur Unique**

| Aspect | Avantage | Explication |
|--------|----------|-------------|
| **💰 Coût** | 75€/mois | Le moins cher pour commencer |
| **🔧 Simplicité** | Setup rapide | 1 seul serveur à gérer |
| **🚀 Performance** | Bonne | 400 comptes supportés |
| **📈 Évolution** | Facile | Ajout de serveurs simple |

### ⚠️ **Limites du Serveur Unique**

| Aspect | Limitation | Solution |
|--------|------------|----------|
| **🛡️ Disponibilité** | Single point of failure | Ajouter un 2ème serveur |
| **📊 Capacité** | 400 comptes max | Scaling horizontal |
| **🔄 Maintenance** | Downtime nécessaire | Docker Swarm plus tard |

## ⏰ **Déploiement Express - 2 Heures**

### 🕐 **Planning Ultra-Rapide**

| Heure | Étape | Durée | Action |
|-------|-------|-------|--------|
| **14h-15h** | Installation | 1h | `setup-vps.sh` |
| **15h-16h** | Déploiement | 1h | `deploy-single-16gb.sh` |
| **16h-16h30** | Tests | 30min | Validation |

### 🚀 **Commandes de Déploiement**

#### **Étape 1 : Installation Serveur (1h)**
```bash
# Sur votre serveur Hostinger
scp -r production/ root@IP_SERVEUR:/root/evolution_api/
ssh root@IP_SERVEUR

cd evolution_api
chmod +x production/setup-vps.sh
./production/setup-vps.sh

# Répondre aux questions :
# 🌐 Domaine : evolution.wazzap.fr
# 📧 Email : votre@email.com
# 🔑 API Key : B6D711FCDE4D4FD5936544120E713C37
```

#### **Étape 2 : Déploiement API (1h)**
```bash
# Déploiement automatique
./production/deploy-single-16gb.sh

# Le script va :
# ✅ Tester les services externes
# ✅ Configurer les variables d'environnement
# ✅ Démarrer Traefik + SSL
# ✅ Démarrer 10 instances Evolution API
# ✅ Tester la connectivité
```

#### **Étape 3 : Validation (30min)**
```bash
# Tests rapides
curl https://evolution.wazzap.fr/
curl https://traefik.wazzap.fr/

# Créer une instance de test
curl -X POST \
  -H "apikey: B6D711FCDE4D4FD5936544120E713C37" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "test-single", "qrcode": true}' \
  https://evolution.wazzap.fr/instance/create
```

## 📊 **Utilisation des Ressources**

### 💾 **Répartition RAM (16GB Total)**

```
┌─────────────────────────────────────┐
│ Système Ubuntu        │ 2GB   │ 12% │
├─────────────────────────────────────┤
│ Docker Engine         │ 1GB   │ 6%  │
├─────────────────────────────────────┤
│ Traefik              │ 512MB │ 3%  │
├─────────────────────────────────────┤
│ 10 Instances API     │ 10GB  │ 62% │
├─────────────────────────────────────┤
│ Cache Local          │ 1GB   │ 6%  │
├─────────────────────────────────────┤
│ Marge Sécurité       │ 1.5GB │ 9%  │
└─────────────────────────────────────┘
Total Utilisé : ~14.5GB / 16GB ✅
```

### ⚡ **Répartition CPU (8 vCPU Total)**

```
┌─────────────────────────────────────┐
│ Système              │ 1 vCPU │ 12% │
├─────────────────────────────────────┤
│ Docker + Traefik     │ 1 vCPU │ 12% │
├─────────────────────────────────────┤
│ 10 Instances API     │ 4 vCPU │ 50% │
├─────────────────────────────────────┤
│ Marge Disponible     │ 2 vCPU │ 25% │
└─────────────────────────────────────┘
Total Utilisé : ~6 vCPU / 8 vCPU ✅
```

## 🔧 **Gestion Post-Déploiement**

### 📈 **Scaling sur 1 Serveur**

```bash
# Augmenter les instances (prudent)
docker-compose -f docker-compose-single-16gb.yml scale evolution-api=12

# Maximum recommandé sur 16GB
docker-compose -f docker-compose-single-16gb.yml scale evolution-api=14

# Revenir à l'optimal
docker-compose -f docker-compose-single-16gb.yml scale evolution-api=10
```

### 📊 **Monitoring Simple**

```bash
# Script de monitoring serveur unique
cat > monitor-single.sh << 'EOF'
#!/bin/bash

echo "📊 Monitoring Serveur Unique 16GB"
echo "================================="

echo "💾 Utilisation RAM :"
free -h

echo ""
echo "⚡ Utilisation CPU :"
top -b -n1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

echo ""
echo "📦 Conteneurs Evolution API :"
docker-compose -f docker-compose-single-16gb.yml ps evolution-api

echo ""
echo "🌐 Test connectivité :"
curl -s https://evolution.wazzap.fr/ | jq -r '.message' || echo "API inaccessible"

echo ""
echo "📊 Instances WhatsApp actives :"
curl -s -H "apikey: B6D711FCDE4D4FD5936544120E713C37" \
  https://evolution.wazzap.fr/instance/fetchInstances | jq length

echo ""
echo "💽 Espace disque :"
df -h | grep -E "/$|/var"
EOF

chmod +x monitor-single.sh
```

## 📈 **Plan d'Évolution**

### 🔄 **Quand Ajouter un 2ème Serveur ?**

**Indicateurs :**
- ✅ RAM > 80% utilisée constamment
- ✅ Plus de 300 comptes WhatsApp connectés
- ✅ Temps de réponse API > 2 secondes
- ✅ Besoin de haute disponibilité

### 🚀 **Migration vers 2 Serveurs**

```bash
# 1. Provisionner le 2ème serveur
# 2. Installer avec setup-vps.sh
# 3. Configurer Docker Swarm :

# Sur serveur actuel (devient Manager)
docker swarm init --advertise-addr IP_SERVEUR_1

# Sur nouveau serveur (Worker)
docker swarm join --token TOKEN IP_SERVEUR_1:2377

# 4. Migrer vers configuration Swarm
docker stack deploy -c production/docker-swarm-2servers.yml evolution
```

## 💰 **Coût Serveur Unique**

### 🏷️ **Coût Mensuel**

| Composant | Prix/mois | Description |
|-----------|-----------|-------------|
| **Hostinger VPS 16GB** | 25€ | Serveur principal |
| **Neon PostgreSQL** | 20€ | Base de données |
| **Redis Cloud** | 25€ | Cache |
| **Domaine + SSL** | 0€ | Let's Encrypt |
| **Total** | **70€/mois** | **Pour 400 comptes** |

### 📊 **ROI**
- **Coût par compte** : 0.175€/mois
- **Rentabilité** : Excellent pour commencer
- **Évolution** : Coût/compte diminue avec le scaling

## 🆘 **Dépannage Serveur Unique**

### ❓ **Problèmes Courants**

**RAM insuffisante :**
```bash
# Réduire les instances
docker-compose -f docker-compose-single-16gb.yml scale evolution-api=8

# Surveiller
free -h
docker stats
```

**Performance lente :**
```bash
# Vérifier la charge
top
htop

# Optimiser les logs
# Changer LOG_LEVEL=ERROR dans .env
docker-compose -f docker-compose-single-16gb.yml restart evolution-api
```

**SSL ne fonctionne pas :**
```bash
# Logs Traefik
docker-compose -f docker-compose-single-16gb.yml logs traefik

# Vérifier DNS
nslookup evolution.wazzap.fr
```

## ✅ **Checklist Serveur Unique**

### 📋 **Avant Déploiement**
- [ ] 1 serveur Hostinger 16GB provisionné
- [ ] DNS configuré (evolution.wazzap.fr)
- [ ] Accès SSH au serveur
- [ ] Neon PostgreSQL accessible
- [ ] Redis Cloud accessible

### 📋 **Pendant Déploiement**
- [ ] `setup-vps.sh` exécuté avec succès
- [ ] `deploy-single-16gb.sh` exécuté
- [ ] SSL généré automatiquement
- [ ] 10 instances API démarrées

### 📋 **Après Déploiement**
- [ ] API accessible via HTTPS
- [ ] Dashboard Traefik fonctionnel
- [ ] Instance WhatsApp de test créée
- [ ] Webhook Wazzap testé

## 🎊 **Résultat Final**

À la fin du déploiement (2h), vous aurez :

✅ **1 serveur** optimisé et sécurisé
✅ **10 instances Evolution API** avec load balancing
✅ **SSL automatique** avec Let's Encrypt
✅ **Dashboard Traefik** pour monitoring
✅ **Webhook Wazzap** intégré
✅ **Capacité** : 400 comptes WhatsApp
✅ **Coût** : 70€/mois

## 🚀 **Commande Magique**

**Après avoir configuré DNS et provisionné le serveur :**

```bash
# Sur votre serveur Hostinger
./production/setup-vps.sh
./production/deploy-single-16gb.sh
```

**Et voilà ! API prête en 2 heures !** ⚡

---

## 🔍 **Comparaison des Options**

| Configuration | Serveurs | RAM Total | Comptes | Coût/mois | Complexité |
|---------------|----------|-----------|---------|-----------|------------|
| **1 Serveur** | 1 × 16GB | 16GB | 400 | 70€ | ⭐ Simple |
| **2 Serveurs** | 2 × 16GB | 32GB | 800 | 105€ | ⭐⭐ Moyen |
| **Cluster 7K** | 10 × 32GB | 320GB | 7000 | 560€ | ⭐⭐⭐ Avancé |

**Recommandation : Commencez par 1 serveur, puis scalez selon vos besoins !** 📈
