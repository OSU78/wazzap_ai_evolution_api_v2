# ⚙️ Configurations

Templates et fichiers de configuration pour l'API Evolution v2.

## 📁 Contenu du Dossier

| Fichier | Description | Usage |
|---------|-------------|-------|
| `config-template.env` | 📋 Template complet des variables | Base pour créer .env |
| `production.env` | 🌐 Configuration de base production | Copier et adapter |

## 📋 Template Principal

### `config-template.env`
Template complet avec toutes les variables d'environnement disponibles :

```bash
# Copier et adapter selon vos besoins
cp configs/config-template.env .env
# Puis éditer .env avec vos valeurs
```

**Sections incluses :**
- 🔐 Authentification & Sécurité
- 🐘 Base de données PostgreSQL
- 🔴 Cache Redis
- 🌐 Configuration réseau
- 📝 Logs et monitoring
- 🔗 Webhooks
- 💾 Stockage S3
- 🐰 RabbitMQ (optionnel)

### `production.env`
Configuration de base pour production avec vos services externes :

```bash
# Utiliser pour production
cp configs/production.env .env
# Modifier SERVER_URL et AUTHENTICATION_API_KEY
```

**Pré-configuré avec :**
- ✅ Neon PostgreSQL (vos credentials)
- ✅ Redis Cloud (vos credentials)
- ✅ Variables optimisées pour production

## 🔧 Variables Importantes

### 🔐 **Sécurité (OBLIGATOIRE à changer)**
```bash
AUTHENTICATION_API_KEY=your-secure-api-key-here
JWT_SECRET=your-super-secure-jwt-secret
```

### 🌐 **Réseau**
```bash
SERVER_URL=http://localhost:8080          # Local
SERVER_URL=https://your-domain.com        # Production
```

### 🐘 **Base de Données**
```bash
# Déjà configuré avec Neon PostgreSQL
DATABASE_CONNECTION_URI=postgresql://neondb_owner:...
```

### 🔴 **Cache Redis**
```bash
# Déjà configuré avec Redis Cloud
CACHE_REDIS_URI=redis://default:...
CACHE_REDIS_ENABLED=true  # OBLIGATOIRE pour le scaling
```

## 📊 Configurations par Environnement

### 🏠 **Local (Développement)**
```bash
NODE_ENV=development
LOG_LEVEL=INFO
LOG_COLOR=true
DEBUG=false
SERVER_URL=http://localhost:8080
```

### 🌐 **Production**
```bash
NODE_ENV=production
LOG_LEVEL=ERROR
LOG_COLOR=true
DEBUG=false
SERVER_URL=https://your-domain.com
```

### 🐳 **Docker Swarm**
```bash
# Mêmes variables que production +
CACHE_REDIS_SAVE_INSTANCES=true  # Synchronisation inter-instances
DATABASE_CONNECTION_CLIENT_NAME=evolution_swarm
```

## 🔒 Sécurité des Configurations

### ⚠️ **Variables Sensibles**
Ne jamais committer ces variables :
- `AUTHENTICATION_API_KEY`
- `JWT_SECRET`
- Mots de passe de base de données
- Clés API externes

### ✅ **Bonnes Pratiques**
```bash
# Utiliser des secrets Docker en production
echo "mon_secret" | docker secret create api_key -

# Générer des secrets forts
openssl rand -base64 32  # Pour JWT_SECRET
openssl rand -hex 16     # Pour API_KEY
```

### 🛡️ **Protection des Fichiers**
```bash
# Permissions restrictives
chmod 600 .env

# Ignorer dans Git
echo ".env" >> .gitignore
```

## 🔄 Migration des Configurations

### 📤 **Depuis l'ancien format**
```bash
# Si vous avez un ancien .env
cp .env .env.backup
cp configs/config-template.env .env
# Puis copier vos valeurs personnalisées
```

### 📥 **Vers un nouvel environnement**
```bash
# Copier la base
cp configs/production.env .env

# Adapter les variables spécifiques
sed -i 's/your-domain.com/wazzap.fr/g' .env
sed -i 's/your-secure-api-key/ma-cle-api/g' .env
```

## 🧪 Validation des Configurations

### ✅ **Vérifier la syntaxe**
```bash
# Charger les variables
source .env

# Vérifier les variables critiques
echo $AUTHENTICATION_API_KEY
echo $DATABASE_CONNECTION_URI
echo $CACHE_REDIS_URI
```

### 🔍 **Tester la connectivité**
```bash
# Test PostgreSQL
psql $DATABASE_CONNECTION_URI -c "SELECT 1;"

# Test Redis
redis-cli -u $CACHE_REDIS_URI ping
```

## 📚 Documentation des Variables

### 🔗 **Références Utiles**
- [Variables Evolution API](https://doc.evolution-api.com/v2/pt/install/env)
- [Configuration PostgreSQL](https://www.postgresql.org/docs/current/runtime-config.html)
- [Configuration Redis](https://redis.io/topics/config)

### 💡 **Variables Avancées**
Consultez `config-template.env` pour :
- Configuration des webhooks
- Paramètres de performance
- Options de monitoring
- Intégrations tierces (S3, RabbitMQ)

## 🆘 Dépannage Configuration

### ❓ **Problèmes Courants**

**Variables non chargées :**
```bash
# Vérifier le format
cat -A .env | head -10

# Pas d'espaces autour du =
VARIABLE=valeur  # ✅ Correct
VARIABLE = valeur  # ❌ Incorrect
```

**Erreurs de connexion :**
```bash
# Vérifier les URLs
echo $DATABASE_CONNECTION_URI
echo $CACHE_REDIS_URI

# Tester manuellement
curl -I $SERVER_URL
```

**Caractères spéciaux :**
```bash
# Utiliser des guillemets pour les valeurs complexes
JWT_SECRET="L=0YWt]b2w[WF>#>:&CWOMH2c<;Kn95jH"
```
