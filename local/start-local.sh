#!/bin/bash

# ========================================
# Script de Démarrage Local - Evolution API v2
# ========================================

echo "🚀 Démarrage local de Evolution API v2"
echo "======================================"

# Créer le fichier .env pour le local
echo "📝 Configuration du fichier .env pour le local..."

# Détecter le répertoire de travail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📂 Répertoire du script: $SCRIPT_DIR"
echo "📂 Racine du projet: $PROJECT_ROOT"
echo "📝 Création de: $PROJECT_ROOT/.env"

cat > "$PROJECT_ROOT/.env" << 'EOF'
# Configuration de base - LOCAL
SERVER_URL=http://localhost:8080
SERVER_TYPE=http
SERVER_PORT=8080

# Authentification & Sécurité
AUTHENTICATION_API_KEY=B6D711FCDE4D4FD5936544120E713C37
JWT_SECRET=L=0YWt]b2w[WF>#>:&CWOMH2c<;Kn95jH
AUTHENTICATION_JWT_EXPIRES_IN=0

# Base de données Neon PostgreSQL
DATABASE_CONNECTION_URI=postgresql://neondb_owner:npg_cyOdLoBN0Z5T@ep-soft-pine-adcz7qon-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&connection_limit=15&pool_timeout=20&connect_timeout=15

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
docker-compose down 2>/dev/null || true

# Télécharger les images si nécessaire
echo "📥 Vérification des images Docker..."
docker-compose pull

# Démarrer les services
echo "🚀 Démarrage des services..."
docker-compose up -d

# Attendre que l'API soit prête
echo "⏳ Attente du démarrage de l'API (migrations + démarrage du serveur)..."
echo "   Cela peut prendre 30-60 secondes au premier démarrage..."

# Fonction pour attendre que l'API réponde
wait_for_api() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -n "   Tentative $attempt/$max_attempts... "
        
        if curl -s -f http://localhost:8080/ > /dev/null 2>&1; then
            echo "✅ API prête!"
            return 0
        else
            echo "⏳ En attente..."
            sleep 10
            attempt=$((attempt + 1))
        fi
    done
    
    echo "❌ Timeout - L'API ne répond toujours pas"
    return 1
}

# Attendre que l'API soit prête
if wait_for_api; then
    echo ""
    echo "🎉 Evolution API v2 démarrée avec succès!"
    echo "=================================="
    echo "🌐 API disponible sur: http://localhost:8080"
    echo "🔑 Clé API: B6D711FCDE4D4FD5936544120E713C37"
    echo ""
    echo "📊 Statut des conteneurs:"
    docker-compose ps
    echo ""
    echo "✅ API répond correctement!"
else
    echo ""
    echo "⚠️  L'API n'a pas démarré dans les temps impartis"
    echo "📊 Statut des conteneurs:"
    docker-compose ps
    echo ""
    echo "🔍 Vérifiez les logs pour diagnostiquer:"
    echo "   docker-compose logs evolution-api"
    echo ""
    echo "💡 L'API peut encore démarrer, patientez quelques minutes de plus"
fi

echo ""
echo "📋 Commandes utiles:"
echo "  docker-compose logs -f evolution-api  # Voir les logs en temps réel"
echo "  docker-compose ps                     # Statut des services"
echo "  docker-compose down                   # Arrêter"
echo "  curl http://localhost:8080/           # Tester l'API"

echo ""
echo "🔍 Pour voir les logs en temps réel:"
echo "   docker-compose logs -f evolution-api"
