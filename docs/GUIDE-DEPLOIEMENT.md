# 🚀 Guide de Déploiement Evolution API v2 - VPS

Ce guide vous accompagne pour déployer rapidement l'API Evolution v2 sur votre serveur VPS avec vos services externes (Neon PostgreSQL et Redis Cloud).

## 🎯 Configuration Actuelle

### Services Externes Configurés
- **Base de données**: Neon PostgreSQL (SSL requis)
- **Cache**: Redis Cloud 
- **Stockage**: Local (volumes Docker)
- **SSL**: Let's Encrypt automatique via Traefik

### Avantages de cette Configuration
- ✅ **Aucune maintenance** de base de données locale
- ✅ **Haute disponibilité** avec services cloud managés
- ✅ **SSL automatique** avec renouvellement
- ✅ **Scaling facile** (ajout d'instances)
- ✅ **Backups automatiques** (Neon)

## 📋 Prérequis

### Serveur VPS
- **OS**: Ubuntu 20.04+ ou Debian 11+
- **RAM**: Minimum 2GB (recommandé 4GB+)
- **CPU**: Minimum 1 vCore (recommandé 2+)
- **Stockage**: Minimum 20GB SSD
- **Réseau**: IP publique fixe

### DNS
- Domaine configuré pointant vers votre VPS
- Sous-domaine pour Traefik (optionnel)

## 🚀 Déploiement Automatique

### Étape 1: Connexion au VPS
```bash
ssh root@votre-ip-vps
# ou
ssh votre-utilisateur@votre-ip-vps
```

### Étape 2: Téléchargement du script
```bash
# Créer un utilisateur non-root si nécessaire
adduser evolution
usermod -aG sudo evolution
su - evolution

# Télécharger les fichiers de configuration
wget https://raw.githubusercontent.com/votre-repo/setup-vps.sh
chmod +x setup-vps.sh
```

### Étape 3: Exécution du script
```bash
./setup-vps.sh
```

Le script vous demandera:
- 🌐 **Nom de domaine** (ex: api.wazzap.fr)
- 📧 **Email Let's Encrypt** (pour les certificats SSL)
- 🔑 **Clé API sécurisée** (générez une clé forte)

### Étape 4: Configuration DNS
Pendant que le script s'exécute, configurez vos DNS:

```
A    api.wazzap.fr       → IP_DE_VOTRE_VPS
A    traefik.wazzap.fr   → IP_DE_VOTRE_VPS  (optionnel)
```

### Étape 5: Redémarrage
```bash
sudo reboot
```

### Étape 6: Démarrage final
```bash
cd /home/evolution/evolution_api
./start.sh
```

## 🛠️ Gestion des Services

### Commandes de base
```bash
cd /home/evolution/evolution_api

# Démarrer
./start.sh

# Arrêter
./stop.sh

# Voir les logs
./logs.sh

# Statut
./status.sh
```

### Commandes Docker avancées
```bash
# Redémarrer un service spécifique
docker-compose restart evolution-api

# Voir tous les logs
docker-compose logs -f

# Mettre à jour l'image
docker-compose pull evolution-api
docker-compose up -d evolution-api

# Nettoyer les images inutilisées
docker system prune -f
```

## 🔧 Configuration Personnalisée

### Modifier les variables d'environnement
```bash
cd /home/evolution/evolution_api
nano .env
# Modifier les valeurs nécessaires
docker-compose restart evolution-api
```

### Variables importantes à personnaliser:
- `AUTHENTICATION_API_KEY` - Votre clé API
- `SERVER_URL` - URL de votre domaine
- `WEBHOOK_GLOBAL_URL` - URL de webhook si nécessaire
- `LOG_LEVEL` - Niveau de logs (ERROR, INFO, DEBUG)

## 📊 Monitoring et Maintenance

### Vérification de santé
```bash
# Test API
curl https://votre-domaine.com/

# Vérifier les certificats SSL
curl -I https://votre-domaine.com/

# Statut des conteneurs
docker ps
```

### Logs importants
```bash
# Logs Evolution API
docker logs evolution_api

# Logs Traefik
docker logs traefik

# Logs système
sudo journalctl -u evolution-api.service
```

### Maintenance périodique
```bash
# Nettoyer Docker (hebdomadaire)
docker system prune -f

# Vérifier l'espace disque
df -h

# Vérifier la RAM
free -h

# Mettre à jour le système
sudo apt update && sudo apt upgrade -y
```

## 🔒 Sécurité

### Firewall configuré automatiquement
- ✅ SSH (port 22)
- ✅ HTTP (port 80) - redirection vers HTTPS
- ✅ HTTPS (port 443)
- ✅ API direct (port 8080) - pour tests uniquement

### Recommandations sécurité
1. **Changez le port SSH par défaut**
2. **Utilisez des clés SSH** au lieu de mots de passe
3. **Activez 2FA** si possible
4. **Surveillez les logs** régulièrement
5. **Mettez à jour** le système régulièrement

### Configuration SSH sécurisée
```bash
sudo nano /etc/ssh/sshd_config
# Port 2222
# PasswordAuthentication no
# PubkeyAuthentication yes
sudo systemctl restart ssh
```

## 🚨 Dépannage

### API ne démarre pas
```bash
# Vérifier les logs
docker logs evolution_api

# Vérifier la connectivité base de données
docker exec evolution_api ping ep-soft-pine-adcz7qon-pooler.c-2.us-east-1.aws.neon.tech

# Tester Redis
docker exec evolution_api redis-cli -u redis://default:hUQnreFwfxJYV5VD2R6VmpJTu8angsP2@redis-19966.c10.us-east-1-2.ec2.redns.redis-cloud.com:19966 ping
```

### SSL ne fonctionne pas
```bash
# Vérifier les logs Traefik
docker logs traefik

# Vérifier la configuration DNS
nslookup votre-domaine.com

# Forcer le renouvellement SSL
docker-compose restart traefik
```

### Problèmes de performance
```bash
# Vérifier les ressources
htop
docker stats

# Optimiser si nécessaire
# Augmenter la RAM du VPS
# Optimiser les variables d'environnement
```

## 📈 Scaling

### Scaling vertical (plus de ressources)
- Augmenter RAM/CPU du VPS
- Modifier les limites Docker si nécessaire

### Scaling horizontal (plus d'instances)
- Utiliser Docker Swarm (voir docker-swarm.yml)
- Load balancer avec plusieurs serveurs
- Base de données externe déjà configurée ✅

## 📞 Support

### Logs pour le support
```bash
# Collecter les informations système
./collect-logs.sh  # Si disponible

# Ou manuellement:
docker logs evolution_api > evolution.log
docker logs traefik > traefik.log
docker-compose ps > services.log
```

### Informations utiles
- Version Evolution API: v2.2.3
- Configuration: Services externes (Neon + Redis Cloud)
- Proxy: Traefik avec SSL automatique
- OS: Ubuntu/Debian

---

🎉 **Félicitations!** Votre API Evolution v2 est maintenant déployée avec une configuration professionnelle et sécurisée!
