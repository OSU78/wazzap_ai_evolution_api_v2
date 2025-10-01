# 🏠 Développement Local

Scripts et configurations pour le développement local de l'API Evolution v2.

## 📁 Contenu du Dossier

| Fichier | Description | Usage |
|---------|-------------|-------|
| `start-local.sh` | 🚀 Démarrage simple (standalone) | `./start-local.sh` |
| `start-traefik.sh` | 🎛️ Démarrage avec Traefik + Dashboard | `./start-traefik.sh` |
| `stop-local.sh` | 🛑 Arrêt des services locaux | `./stop-local.sh` |
| `stop-traefik.sh` | 🛑 Arrêt avec Traefik | `./stop-traefik.sh` |
| `logs-local.sh` | 📝 Logs en temps réel | `./logs-local.sh` |
| `docker-compose-traefik.yml` | ⚙️ Configuration Docker avec Traefik | - |

## 🚀 Démarrage Rapide

### Mode Simple (Recommandé)
```bash
./start-local.sh
```
- API accessible sur : http://localhost:8080
- Clé API : `B6D711FCDE4D4FD5936544120E713C37`

### Mode Traefik (Avec Dashboard)
```bash
./start-traefik.sh
```
- API accessible sur : http://evolution.localhost
- Dashboard Traefik : http://localhost:8080

## 🔧 Configuration

### Services Utilisés
- **Base de données** : Neon PostgreSQL (externe)
- **Cache** : Redis Cloud (externe)
- **Stockage** : Volumes Docker locaux

### Variables d'Environnement
Les fichiers `.env` sont générés automatiquement par les scripts avec :
- `LOG_LEVEL=INFO` (logs détaillés)
- `LOG_COLOR=true` (logs colorés)
- `NODE_ENV=development`

## 🛠️ Commandes Utiles

```bash
# Voir les logs en temps réel
./logs-local.sh

# Statut des conteneurs
docker-compose ps

# Redémarrer un service
docker-compose restart evolution-api

# Nettoyer
docker-compose down -v
```

## 🧪 Tests

```bash
# Tester l'API (mode simple)
curl http://localhost:8080/

# Tester l'API (mode Traefik)
curl http://evolution.localhost/

# Tester le dashboard Traefik
curl http://localhost:8080/api/http/routers
```

## 🔍 Dépannage

### Problèmes courants

**Port 8080 déjà utilisé :**
```bash
# Voir qui utilise le port
lsof -i :8080

# Changer de port dans docker-compose.yml
ports:
  - "8081:8080"  # Utiliser 8081 à la place
```

**Traefik ne trouve pas evolution.localhost :**
```bash
# Vérifier /etc/hosts
cat /etc/hosts | grep evolution.localhost

# Ajouter manuellement si nécessaire
echo "127.0.0.1    evolution.localhost" | sudo tee -a /etc/hosts
```

**API ne démarre pas :**
```bash
# Vérifier Docker
docker info

# Voir les logs détaillés
./logs-local.sh
```
