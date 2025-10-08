#!/bin/bash

# ========================================
# Script de Démarrage Local avec Traefik - Evolution API v2
# ========================================

echo "🚀 Démarrage local de Evolution API v2 avec Traefik"
echo "=================================================="

# Créer le fichier .env pour le local
echo "📝 Configuration du fichier .env pour le local avec Traefik..."

# Détecter le répertoire de travail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📂 Répertoire du script: $SCRIPT_DIR"
echo "📂 Racine du projet: $PROJECT_ROOT"
echo "📝 Création de: $PROJECT_ROOT/.env"

cat > "$PROJECT_ROOT/.env" << 'EOF'
# Configuration de base - LOCAL avec Traefik
SERVER_URL=http://evolution.localhost
SERVER_TYPE=http
SERVER_PORT=8080

# Authentification & Sécurité
AUTHENTICATION_API_KEY=B6D711FCDE4D4FD5936544120E713C37
JWT_SECRET=L=0YWt]b2w[WF>#>:&CWOMH2c<;Kn95jH
AUTHENTICATION_JWT_EXPIRES_IN=0

# Base de données Neon PostgreSQL
DATABASE_CONNECTION_URI=postgresql://neondb_owner:npg_cyOdLoBN0Z5T@ep-soft-pine-adcz7qon-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require

# Cache Redis Cloud
CACHE_REDIS_URI=redis://default:hUQnreFwfxJYV5VD2R6VmpJTu8angsP2@redis-19966.c10.us-east-1-2.ec2.redns.redis-cloud.com:19966/1

# Configuration WebHook - Wazzap Integration
WEBHOOK_GLOBAL_URL=https://wazzap.ngrok.app/api/webhook/v2/messageHandlers
WEBHOOK_GLOBAL_ENABLED=true
WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true
WEBHOOK_GLOBAL_WEBHOOK_BASE64=true

# Webhook Events (nouvelles variables individuelles)
WEBHOOK_EVENTS_APPLICATION_STARTUP=false
WEBHOOK_EVENTS_QRCODE_UPDATED=true
WEBHOOK_EVENTS_MESSAGES_SET=false
WEBHOOK_EVENTS_MESSAGES_UPSERT=true
WEBHOOK_EVENTS_MESSAGES_UPDATE=false
WEBHOOK_EVENTS_MESSAGES_DELETE=false
WEBHOOK_EVENTS_SEND_MESSAGE=true
WEBHOOK_EVENTS_CONTACTS_SET=false
WEBHOOK_EVENTS_CONTACTS_UPSERT=false
WEBHOOK_EVENTS_CONTACTS_UPDATE=false
WEBHOOK_EVENTS_PRESENCE_UPDATE=false
WEBHOOK_EVENTS_CHATS_SET=false
WEBHOOK_EVENTS_CHATS_UPSERT=false
WEBHOOK_EVENTS_CHATS_UPDATE=false
WEBHOOK_EVENTS_CHATS_DELETE=false
WEBHOOK_EVENTS_GROUPS_UPSERT=false
WEBHOOK_EVENTS_GROUPS_UPDATE=false
WEBHOOK_EVENTS_GROUP_PARTICIPANTS_UPDATE=false
WEBHOOK_EVENTS_CONNECTION_UPDATE=true
WEBHOOK_EVENTS_LABELS_EDIT=false
WEBHOOK_EVENTS_LABELS_ASSOCIATION=false
WEBHOOK_EVENTS_CALL=false
WEBHOOK_EVENTS_NEW_JWT_TOKEN=false
WEBHOOK_EVENTS_TYPEBOT_START=true
WEBHOOK_EVENTS_TYPEBOT_CHANGE_STATUS=true
WEBHOOK_EVENTS_CHAMA_AI_ACTION=false
WEBHOOK_EVENTS_ERRORS=false
WEBHOOK_EVENTS_ERRORS_WEBHOOK=false

# Configuration des logs
LOG_LEVEL=INFO
LOG_COLOR=true
LOG_BAILEYS=error

# Configuration CORS
CORS_ORIGIN=*
CORS_METHODS=POST,GET,PUT,DELETE
CORS_CREDENTIALS=true

# Gestion des instances
DEL_INSTANCE=false
CLEAN_STORE_CLEANING_INTERVAL=7200
CLEAN_STORE_MESSAGES=true
CLEAN_STORE_CONTACTS=true
CLEAN_STORE_CHATS=true

# Configuration S3 (désactivé)
S3_ENABLED=false

# Environnement
NODE_ENV=development
DEBUG=false
EOF

# Vérifier que le fichier .env a été créé
if [ -f "$PROJECT_ROOT/.env" ]; then
    echo "✅ Fichier .env créé avec succès ($(wc -l < "$PROJECT_ROOT/.env") lignes)"
    echo "📄 Taille du fichier: $(du -h "$PROJECT_ROOT/.env" | cut -f1)"
else
    echo "❌ Échec de la création du fichier .env!"
    exit 1
fi

# Vérifier si Docker est en cours d'exécution
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker n'est pas en cours d'exécution!"
    echo "🔧 Démarrez Docker Desktop et relancez ce script"
    exit 1
fi

echo "🐳 Docker est prêt"

# Arrêter les anciens conteneurs s'ils existent
echo "🛑 Arrêt des anciens conteneurs..."
docker-compose -f local/docker-compose-traefik.yml down 2>/dev/null || true
docker-compose down 2>/dev/null || true

# Télécharger les images si nécessaire
echo "📥 Vérification des images Docker..."
docker-compose -f local/docker-compose-traefik.yml pull

# Démarrer les services avec Traefik
echo "🚀 Démarrage des services avec Traefik..."
docker-compose -f local/docker-compose-traefik.yml up -d

# Configuration des hosts locaux
echo "🌐 Configuration des domaines locaux..."
echo "   Ajout des entrées dans /etc/hosts..."

# Vérifier si les entrées existent déjà
if ! grep -q "evolution.localhost" /etc/hosts; then
    echo "127.0.0.1    evolution.localhost" | sudo tee -a /etc/hosts
    echo "   ✅ evolution.localhost ajouté"
else
    echo "   ✅ evolution.localhost déjà configuré"
fi

if ! grep -q "api.localhost" /etc/hosts; then
    echo "127.0.0.1    api.localhost" | sudo tee -a /etc/hosts
    echo "   ✅ api.localhost ajouté"
else
    echo "   ✅ api.localhost déjà configuré"
fi

# Attendre que Traefik soit prêt
echo "⏳ Attente du démarrage de Traefik..."
sleep 5

# Fonction pour attendre que l'API réponde via Traefik
wait_for_api() {
    local max_attempts=30
    local attempt=1
    
    echo "   Test via Traefik (evolution.localhost)..."
    while [ $attempt -le $max_attempts ]; do
        echo -n "   Tentative $attempt/$max_attempts... "
        
        if curl -s -f http://evolution.localhost/ > /dev/null 2>&1; then
            echo "✅ API prête via Traefik!"
            return 0
        else
            echo "⏳ En attente..."
            sleep 10
            attempt=$((attempt + 1))
        fi
    done
    
    echo "❌ Timeout - L'API ne répond toujours pas via Traefik"
    return 1
}

# Attendre que l'API soit prête
if wait_for_api; then
    echo ""
    echo "🎉 Evolution API v2 avec Traefik démarrée avec succès!"
    echo "====================================================="
    echo "🌐 Accès à l'API:"
    echo "   • Via Traefik: http://evolution.localhost"
    echo "   • Alternative: http://api.localhost" 
    echo "   • Direct:      http://localhost:8081 (si port libre)"
    echo ""
    echo "📊 Dashboard Traefik:"
    echo "   • Interface:   http://localhost:8080"
    echo "   • API:         http://localhost:8080/api"
    echo ""
    echo "🔑 Clé API: B6D711FCDE4D4FD5936544120E713C37"
    echo ""
    echo "📊 Statut des conteneurs:"
    docker-compose -f local/docker-compose-traefik.yml ps
    echo ""
    echo "✅ Tout fonctionne correctement!"
else
    echo ""
    echo "⚠️  L'API n'a pas démarré dans les temps impartis"
    echo "📊 Statut des conteneurs:"
    docker-compose -f local/docker-compose-traefik.yml ps
    echo ""
    echo "🔍 Vérifiez les logs pour diagnostiquer:"
    echo "   docker-compose -f local/docker-compose-traefik.yml logs evolution-api"
    echo "   docker-compose -f local/docker-compose-traefik.yml logs traefik"
fi

echo ""
echo "📋 Commandes utiles:"
echo "  docker-compose -f local/docker-compose-traefik.yml logs -f evolution-api  # Logs API"
echo "  docker-compose -f local/docker-compose-traefik.yml logs -f traefik        # Logs Traefik"
echo "  docker-compose -f local/docker-compose-traefik.yml ps                     # Statut"
echo "  docker-compose -f local/docker-compose-traefik.yml down                   # Arrêter"
echo ""
echo "🧪 Tests rapides:"
echo "  curl http://evolution.localhost/      # Tester l'API via Traefik"
echo "  curl http://localhost:8080/api/http/routers  # API Traefik"
echo ""
echo "🌐 Ouvrir dans le navigateur:"
echo "  • API Evolution: http://evolution.localhost"
echo "  • Dashboard Traefik: http://localhost:8080"
