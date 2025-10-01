# Evolution API v2 - Configuration Optimisée pour le Scaling

Ce repository contient des configurations Docker optimisées pour déployer l'API Evolution v2 avec différents niveaux de scaling, du déploiement standalone au cluster Docker Swarm haute disponibilité.

## 📁 Fichiers de Configuration

### Configuration Standalone (Serveur unique)
- `docker-compose.yml` - Configuration optimisée avec PostgreSQL et Redis
- Idéal pour: développement, petites installations, tests

### Configuration Docker Swarm (Cluster multi-serveurs)
- `docker-swarm.yml` - Configuration pour cluster avec load balancing
- `traefik.yml` - Load balancer avec SSL automatique
- `deploy-swarm.sh` - Script de déploiement automatisé
- Idéal pour: production, haute disponibilité, scaling horizontal

### Configuration et Templates
- `config-template.env` - Template complet des variables d'environnement
- `README-SCALING.md` - Ce guide d'utilisation

## 🚀 Déploiement Standalone

### Prérequis
- Docker et Docker Compose installés
- Ports 8080, 5432, 6379 disponibles

### Étapes

1. **Configuration des variables d'environnement**
   ```bash
   cp config-template.env .env
   # Éditez .env avec vos valeurs
   ```

2. **Démarrage des services**
   ```bash
   docker compose up -d
   ```

3. **Vérification**
   ```bash
   docker logs evolution_api
   curl http://localhost:8080
   ```

### Fonctionnalités Standalone
- ✅ PostgreSQL optimisé (200 connexions max)
- ✅ Redis pour cache et sessions
- ✅ Health checks automatiques
- ✅ Réseau isolé sécurisé
- ✅ Volumes persistants
- ✅ Configuration par variables d'environnement

## 🌐 Déploiement Docker Swarm

### Prérequis
- Cluster Docker Swarm configuré
- DNS pointant vers vos serveurs
- Ports 80, 443, 8080 ouverts

### Configuration du Cluster

#### Serveur Manager
```bash
# Installer Docker
curl -fsSL https://get.docker.com | bash

# Initialiser Swarm
docker swarm init --advertise-addr YOUR_MANAGER_IP

# Créer le réseau
docker network create --driver=overlay network_public
```

#### Serveurs Workers
```bash
# Installer Docker
curl -fsSL https://get.docker.com | bash

# Rejoindre le cluster (commande fournie par le manager)
docker swarm join --token TOKEN MANAGER_IP:2377
```

### Déploiement Automatisé

1. **Utiliser le script de déploiement**
   ```bash
   chmod +x deploy-swarm.sh
   ./deploy-swarm.sh
   ```

2. **Ou déploiement manuel**
   ```bash
   # Créer les volumes et secrets
   docker volume create evolution_swarm_instances
   docker volume create evolution_swarm_postgres
   docker volume create evolution_swarm_redis
   
   # Créer le secret PostgreSQL
   echo "votre_mot_de_passe" | docker secret create evolution_postgres_password -
   
   # Déployer Traefik
   docker stack deploy -c traefik.yml traefik
   
   # Déployer Evolution API
   docker stack deploy -c docker-swarm.yml evolution
   ```

### Fonctionnalités Swarm
- ✅ 3 instances Evolution API avec load balancing
- ✅ Traefik avec SSL automatique (Let's Encrypt)
- ✅ Base de données PostgreSQL haute performance
- ✅ Redis pour synchronisation inter-instances
- ✅ Health checks et auto-healing
- ✅ Rolling updates sans downtime
- ✅ Sticky sessions pour WebSocket
- ✅ Monitoring et métriques Prometheus

## 📊 Monitoring et Maintenance

### Commandes utiles Standalone
```bash
# Logs
docker logs evolution_api
docker logs evolution_postgres
docker logs evolution_redis

# Statut des conteneurs
docker ps

# Redémarrage
docker compose restart evolution-api
```

### Commandes utiles Swarm
```bash
# Statut des services
docker stack ps evolution
docker stack ps traefik

# Logs des services
docker service logs evolution_evolution-api
docker service logs traefik_traefik

# Scaling manuel
docker service scale evolution_evolution-api=5

# Mise à jour rolling
docker service update --image atendai/evolution-api:v2.1.2 evolution_evolution-api
```

## 🔧 Configuration Avancée

### Variables d'environnement importantes

#### Authentification
- `AUTHENTICATION_API_KEY` - Clé API (OBLIGATOIRE à changer)
- `JWT_SECRET` - Secret JWT pour les tokens

#### Base de données
- `POSTGRES_PASSWORD` - Mot de passe PostgreSQL
- `DATABASE_CONNECTION_URI` - URI de connexion complète

#### Cache Redis
- `CACHE_REDIS_ENABLED=true` - Obligatoire pour Swarm
- `CACHE_REDIS_URI` - URI de connexion Redis

#### Stockage S3 (Recommandé pour production)
- `S3_ENABLED=true`
- `S3_ACCESS_KEY`, `S3_SECRET_KEY` - Credentials S3
- `S3_BUCKET`, `S3_ENDPOINT` - Configuration bucket

### Optimisations PostgreSQL

La configuration inclut des optimisations pour:
- 200-300 connexions simultanées
- Cache mémoire optimisé
- Checkpoints efficaces
- I/O performant pour SSD

### Optimisations Redis

Configuration pour:
- Persistance avec AOF
- Politique d'éviction LRU
- Keepalive TCP optimisé
- Limite mémoire configurée

## 🚨 Sécurité

### Recommandations
1. **Changez tous les mots de passe par défaut**
2. **Utilisez des secrets Docker pour les mots de passe**
3. **Configurez un firewall approprié**
4. **Activez l'authentification basique pour Traefik**
5. **Utilisez HTTPS uniquement en production**
6. **Limitez l'accès aux ports de base de données**

### Configuration Firewall (exemple UFW)
```bash
# Autoriser SSH
ufw allow 22

# Autoriser HTTP/HTTPS
ufw allow 80
ufw allow 443

# Bloquer l'accès direct aux bases de données
ufw deny 5432
ufw deny 6379

# Activer le firewall
ufw enable
```

## 🔄 Sauvegarde et Restauration

### Sauvegarde PostgreSQL
```bash
docker exec evolution_postgres pg_dump -U evolution evolution > backup.sql
```

### Sauvegarde volumes
```bash
docker run --rm -v evolution_instances:/data -v $(pwd):/backup alpine tar czf /backup/instances.tar.gz -C /data .
```

### Restauration
```bash
# Restaurer base de données
docker exec -i evolution_postgres psql -U evolution evolution < backup.sql

# Restaurer volumes
docker run --rm -v evolution_instances:/data -v $(pwd):/backup alpine tar xzf /backup/instances.tar.gz -C /data
```

## 📈 Scaling Recommandations

### Petite installation (< 100 instances WhatsApp)
- Configuration standalone
- 2-4 CPU cores
- 8GB RAM
- SSD 100GB

### Installation moyenne (100-500 instances)
- Docker Swarm 3 nœuds
- 4-8 CPU cores par nœud
- 16GB RAM par nœud
- SSD 200GB par nœud

### Grande installation (500+ instances)
- Docker Swarm 5+ nœuds
- 8+ CPU cores par nœud
- 32GB+ RAM par nœud
- SSD 500GB+ par nœud
- Considérer PostgreSQL dédié
- Considérer Redis Cluster

## 🆘 Dépannage

### Problèmes courants

#### "Database provider invalid"
- Vérifiez la variable `DATABASE_PROVIDER=postgresql`
- Vérifiez la connexion à PostgreSQL

#### Instances non synchronisées en Swarm
- Vérifiez `CACHE_REDIS_ENABLED=true`
- Vérifiez la connexion Redis

#### SSL/HTTPS ne fonctionne pas
- Vérifiez la configuration DNS
- Vérifiez l'email Let's Encrypt dans traefik.yml
- Consultez les logs Traefik

### Logs de débogage
```bash
# Activer les logs debug
LOG_LEVEL=DEBUG

# Logs détaillés Traefik
--log.level=DEBUG
```

## 📞 Support

Pour plus d'informations:
- [Documentation officielle Evolution API](https://doc.evolution-api.com/)
- [Repository GitHub](https://github.com/EvolutionAPI/evolution-api)
- [Community Discord](https://discord.gg/evolution-api)
