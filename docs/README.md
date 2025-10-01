# 📚 Documentation

Guides complets et documentation détaillée pour l'API Evolution v2.

## 📁 Contenu du Dossier

| Fichier | Description | Audience |
|---------|-------------|----------|
| `GUIDE-DEPLOIEMENT.md` | 🚀 Guide de déploiement VPS | Administrateurs |
| `README-SCALING.md` | 📈 Guide de scaling avancé | DevOps |

## 📖 Guides Disponibles

### 🚀 **Guide de Déploiement VPS**
Guide complet pour déployer l'API Evolution sur un serveur VPS.

**Contenu :**
- ✅ Prérequis et configuration serveur
- ✅ Déploiement automatique vs manuel
- ✅ Configuration DNS et SSL
- ✅ Monitoring et maintenance
- ✅ Dépannage courant

**Pour qui :**
- Administrateurs système
- Développeurs déployant en production
- Utilisateurs configurant leur premier serveur

### 📈 **Guide de Scaling Avancé**
Documentation complète sur les options de scaling et d'optimisation.

**Contenu :**
- ✅ Configuration standalone optimisée
- ✅ Docker Swarm pour le clustering
- ✅ Load balancing avec Traefik
- ✅ Optimisations base de données
- ✅ Monitoring et métriques

**Pour qui :**
- Équipes DevOps
- Architectes système
- Utilisateurs avec forte charge

## 🎯 Choisir le Bon Guide

### 🏠 **Développement Local**
➡️ Consultez `/local/README.md`
- Configuration rapide
- Tests et développement
- Traefik dashboard

### 🌐 **Premier Déploiement Production**
➡️ Lisez `GUIDE-DEPLOIEMENT.md`
- Installation VPS complète
- Configuration sécurisée
- SSL automatique

### 📈 **Scaling et Performance**
➡️ Étudiez `README-SCALING.md`
- Docker Swarm
- Load balancing
- Optimisations avancées

## 🔗 Liens Rapides

### 📋 **Checklists**

**Avant déploiement :**
- [ ] Serveur VPS configuré
- [ ] Domaine pointant vers le serveur
- [ ] Clé API sécurisée générée
- [ ] Email pour Let's Encrypt

**Après déploiement :**
- [ ] SSL fonctionne (https://)
- [ ] API répond correctement
- [ ] Dashboard Traefik accessible
- [ ] Logs sans erreur

### 🛠️ **Commandes Rapides**

```bash
# Test local
./start-local

# Déploiement VPS
./production/setup-vps.sh

# Diagnostic
./production/collect-logs.sh

# Scaling Swarm
docker service scale evolution_evolution-api=3
```

## 📊 Architecture Documentée

### 🏗️ **Vue d'Ensemble**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Développement │    │   Production    │    │   Scaling       │
│     Local       │    │      VPS        │    │   Swarm         │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • Docker Simple │    │ • SSL Auto      │    │ • Multi-nœuds   │
│ • Traefik Opt.  │    │ • Traefik LB    │    │ • Load Balance  │
│ • Services Ext. │    │ • Firewall      │    │ • Auto-healing  │
│ • Debug Logs    │    │ • Monitoring    │    │ • Rolling Update│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 🔄 **Flux de Déploiement**
1. **Développement** : `./start-local` ou `./start-traefik`
2. **Test Production** : `production/setup-vps.sh`
3. **Scaling** : `production/deploy-swarm.sh`
4. **Monitoring** : Dashboard Traefik + logs

## 🔍 Index des Sujets

### 🏠 **Local & Développement**
- Configuration Docker Compose
- Traefik dashboard local
- Variables d'environnement développement
- Debugging et logs

### 🌐 **Production & VPS**
- Installation automatique serveur
- Configuration SSL Let's Encrypt
- Firewall et sécurité
- Monitoring production

### 🐳 **Docker & Containers**
- Docker Compose vs Swarm
- Configuration réseau
- Volumes et persistance
- Health checks

### 🌍 **Réseau & DNS**
- Configuration domaines
- Traefik routing
- SSL/TLS
- Load balancing

### 📊 **Monitoring & Logs**
- Dashboard Traefik
- Collecte de logs
- Métriques Prometheus
- Alertes et notifications

### 🔒 **Sécurité**
- Authentification API
- Secrets Docker
- Firewall UFW
- Bonnes pratiques

### 📈 **Performance & Scaling**
- Optimisation base de données
- Cache Redis
- Scaling horizontal
- Recommandations par charge

## 🆘 Support et Aide

### 📞 **Ressources Officielles**
- [Documentation Evolution API](https://doc.evolution-api.com/)
- [GitHub Evolution API](https://github.com/EvolutionAPI/evolution-api)
- [Discord Community](https://discord.gg/evolution-api)

### 🔧 **Diagnostic**
1. Consultez les logs : `production/collect-logs.sh`
2. Vérifiez la configuration : `configs/`
3. Testez la connectivité : guides de dépannage
4. Consultez les FAQ dans chaque guide

### 💡 **Contributions**
Pour améliorer cette documentation :
1. Identifiez les lacunes
2. Proposez des améliorations
3. Ajoutez des exemples concrets
4. Mettez à jour les procédures

---

## 🎓 Formation Recommandée

### 👶 **Débutant**
1. Lisez le README principal
2. Testez en local avec `./start-local`
3. Suivez le guide de déploiement VPS
4. Explorez le dashboard Traefik

### 🧑‍💻 **Intermédiaire**
1. Maîtrisez Traefik local avec `./start-traefik`
2. Configurez un VPS complet
3. Comprenez les logs et le monitoring
4. Optimisez les performances

### 🚀 **Avancé**
1. Déployez un cluster Docker Swarm
2. Configurez le load balancing avancé
3. Mettez en place le monitoring complet
4. Automatisez les déploiements

Bonne lecture et bon déploiement ! 📚🚀
