#!/bin/bash

# ========================================
# Script de Configuration Complète VPS pour Evolution API v2
# ========================================
# Ce script configure automatiquement un serveur Ubuntu/Debian
# pour déployer l'API Evolution avec services externes

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier si le script est exécuté en tant que root
if [[ $EUID -eq 0 ]]; then
   log_warning "Script exécuté en tant que root"
   log_info "Création d'un utilisateur non-root pour Docker..."
   
   # Créer un utilisateur evolution si n'existe pas
   if ! id "evolution" &>/dev/null; then
       useradd -m -s /bin/bash evolution
       usermod -aG sudo evolution
       log_success "Utilisateur 'evolution' créé"
   fi
   
   # Copier les fichiers vers l'utilisateur evolution
   cp -r /root/evolution_api /home/evolution/
   chown -R evolution:evolution /home/evolution/evolution_api
   
   log_info "Basculement vers l'utilisateur 'evolution'..."
   sudo -u evolution bash -c "cd /home/evolution/evolution_api && ./production/setup-vps.sh"
   exit $?
fi

echo -e "${BLUE}"
echo "🚀 Configuration VPS pour Evolution API v2"
echo "=========================================="
echo "Ce script va configurer votre serveur avec:"
echo "- Docker et Docker Compose"
echo "- Configuration réseau et sécurité"
echo "- Hostname et DNS"
echo "- Evolution API avec services externes"
echo -e "${NC}"

# Demander les informations nécessaires avec valeurs par défaut
echo "📋 Configuration des paramètres (appuyez sur Entrée pour utiliser les valeurs par défaut)"
echo ""

# Domaine avec valeur par défaut
read -p "🌐 Nom de domaine [evolution.wazzap.fr]: " DOMAIN_NAME
DOMAIN_NAME=${DOMAIN_NAME:-evolution.wazzap.fr}

# Email avec valeur par défaut
read -p "📧 Email pour Let's Encrypt [contact@wazzap.ai]: " LETSENCRYPT_EMAIL
LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL:-contact@wazzap.ai}

# Clé API - vérifier la variable d'environnement globalApikey
echo ""
log_info "Vérification de la clé API..."
if [ -n "$globalApikey" ]; then
    log_success "Variable 'globalApikey' trouvée"
    API_KEY="$globalApikey"
    echo "🔑 Utilisation de la clé API depuis la variable d'environnement"
else
    log_warning "Variable 'globalApikey' non trouvée dans l'environnement"
    echo ""
    echo "Options:"
    echo "1. Utiliser la clé API par défaut (recommandé)"
    echo "2. Créer la variable 'globalApikey' automatiquement"
    echo "3. Entrer une clé API personnalisée"
    echo ""
    read -p "Choisissez une option [1]: " OPTION
    OPTION=${OPTION:-1}
    
    case $OPTION in
        1)
            API_KEY="B6D711FCDE4D4FD5936544120E713C37"
            log_info "Utilisation de la clé API par défaut"
            ;;
        2)
            API_KEY="B6D711FCDE4D4FD5936544120E713C37"
            export globalApikey="$API_KEY"
            echo "export globalApikey=$API_KEY" >> ~/.bashrc
            log_success "Variable 'globalApikey' créée et ajoutée à ~/.bashrc"
            ;;
        3)
            read -p "🔑 Entrez votre clé API personnalisée: " API_KEY
            if [ -z "$API_KEY" ]; then
                API_KEY="B6D711FCDE4D4FD5936544120E713C37"
                log_warning "Clé vide, utilisation de la clé par défaut"
            fi
            ;;
        *)
            API_KEY="B6D711FCDE4D4FD5936544120E713C37"
            log_info "Option invalide, utilisation de la clé par défaut"
            ;;
    esac
fi

if [ -z "$DOMAIN_NAME" ] || [ -z "$LETSENCRYPT_EMAIL" ] || [ -z "$API_KEY" ]; then
    log_error "Tous les champs sont obligatoires!"
    exit 1
fi

# Récapitulatif de la configuration
echo ""
echo -e "${BLUE}📋 Récapitulatif de la configuration:${NC}"
echo "🌐 Domaine: $DOMAIN_NAME"
echo "📧 Email: $LETSENCRYPT_EMAIL"
echo "🔑 Clé API: **********************$(echo $API_KEY | tail -c 5)"
echo ""
read -p "Continuer avec cette configuration ? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    log_info "Configuration annulée par l'utilisateur"
    exit 0
fi

log_info "Mise à jour du système..."
sudo apt-get update && sudo apt-get upgrade -y

log_info "Installation des paquets essentiels..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    wget \
    git \
    htop \
    nano \
    ufw \
    fail2ban \
    unzip

# Configuration du hostname
log_info "Configuration du hostname..."
CURRENT_HOSTNAME=$(hostname)
NEW_HOSTNAME="evolution-server"

if [ "$CURRENT_HOSTNAME" != "$NEW_HOSTNAME" ]; then
    sudo hostnamectl set-hostname $NEW_HOSTNAME
    sudo sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
    echo "127.0.0.1    $NEW_HOSTNAME" | sudo tee -a /etc/hosts
    log_success "Hostname configuré: $NEW_HOSTNAME"
fi

# Installation de Docker
log_info "Installation de Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    log_success "Docker installé"
else
    log_success "Docker déjà installé"
fi

# Installation de Docker Compose
log_info "Installation de Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    log_success "Docker Compose installé"
else
    log_success "Docker Compose déjà installé"
fi

# Configuration du firewall
log_info "Configuration du firewall UFW..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Autoriser SSH
sudo ufw allow ssh
sudo ufw allow 22

# Autoriser HTTP/HTTPS
sudo ufw allow 80
sudo ufw allow 443

# Autoriser le port de l'API pour les tests
sudo ufw allow 8080

# Activer le firewall
sudo ufw --force enable
log_success "Firewall configuré et activé"

# Configuration de Fail2Ban
log_info "Configuration de Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
log_success "Fail2Ban configuré"

# Répertoire de l'application
APP_DIR="/home/$USER/evolution_api"
log_info "Création du répertoire d'application: $APP_DIR"
mkdir -p $APP_DIR
cd $APP_DIR

# Création du fichier .env avec les vraies valeurs
log_info "Création du fichier de configuration..."
echo "📂 Répertoire courant: $(pwd)"
echo "📝 Création de: $(pwd)/.env"

cat > .env << EOF
# ========================================
# Configuration Evolution API v2 - Production
# ========================================

# Configuration de base
SERVER_URL=https://$DOMAIN_NAME
SERVER_TYPE=http
SERVER_PORT=8080

# Authentification & Sécurité
AUTHENTICATION_API_KEY=$API_KEY
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
LOG_LEVEL=ERROR
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

# Configuration Docker Swarm
DOMAIN_NAME=$DOMAIN_NAME
LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL

# Environnement
NODE_ENV=production
DEBUG=false
EOF

# Vérifier que le fichier .env a été créé
if [ -f ".env" ]; then
    log_success "Fichier .env créé avec succès ($(wc -l < .env) lignes)"
    echo "📄 Taille du fichier: $(du -h .env | cut -f1)"
else
    log_error "Échec de la création du fichier .env!"
    exit 1
fi

# Création du docker-compose.yml (labels Traefik corrigés)
log_info "Création du fichier Docker Compose..."
cat > docker-compose.yml << 'EOF'
services:
  # Traefik - Load Balancer et SSL
  traefik:
    image: traefik:2.11.2
    container_name: traefik
    restart: always
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencryptresolver.acme.email=${LETSENCRYPT_EMAIL}"
      - "--certificatesresolvers.letsencryptresolver.acme.storage=/letsencrypt/acme.json"
      - "--log.level=INFO"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Dashboard Traefik
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "traefik_letsencrypt:/letsencrypt"
    labels:
      - traefik.enable=true
      - traefik.http.routers.traefik.rule=Host(`traefik.${DOMAIN_NAME}`)
      - traefik.http.routers.traefik.entrypoints=websecure
      - traefik.http.routers.traefik.tls.certresolver=letsencryptresolver
      - traefik.http.routers.traefik.service=api@internal
    networks:
      - evolution_network

  # API Evolution
  evolution-api:
    image: evoapicloud/evolution-api:v2.3.0
    container_name: evolution_api
    restart: always
    environment:
      - SERVER_TYPE=http
      - SERVER_PORT=8080
      - SERVER_URL=https://${DOMAIN_NAME}
      - DATABASE_ENABLED=true
      - CONFIG_SESSION_PHONE_VERSION=${CONFIG_SESSION_PHONE_VERSION:-2.3000.1023204200}
      - CONFIG_SESSION_PHONE_NAME=${CONFIG_SESSION_PHONE_NAME:-Chrome}
      - CONFIG_SESSION_PHONE_CLIENT=${CONFIG_SESSION_PHONE_CLIENT:-Wazzap AI}
      
      - DATABASE_PROVIDER=postgresql
      - DATABASE_CONNECTION_URI=${DATABASE_CONNECTION_URI}
      - DATABASE_CONNECTION_CLIENT_NAME=evolution_vps
      - DATABASE_SAVE_DATA_INSTANCE=true
      - DATABASE_SAVE_DATA_NEW_MESSAGE=true
      - DATABASE_SAVE_MESSAGE_UPDATE=true
      - DATABASE_SAVE_DATA_CONTACTS=true
      - DATABASE_SAVE_DATA_CHATS=true
      - DATABASE_SAVE_DATA_LABELS=true
      - DATABASE_SAVE_DATA_HISTORIC=true
      - CACHE_REDIS_ENABLED=true
      - CACHE_REDIS_URI=${CACHE_REDIS_URI}
      - CACHE_REDIS_PREFIX_KEY=evolution_vps_wazzap_ai
      - CACHE_REDIS_SAVE_INSTANCES=true
      - CACHE_LOCAL_ENABLED=false
      - AUTHENTICATION_API_KEY=${AUTHENTICATION_API_KEY}
      - AUTHENTICATION_JWT_EXPIRES_IN=0
      - AUTHENTICATION_JWT_SECRET=${JWT_SECRET}
      - DEL_INSTANCE=false
      - CLEAN_STORE_CLEANING_INTERVAL=7200
      - CLEAN_STORE_MESSAGES=true
      - CLEAN_STORE_CONTACTS=true
      - CLEAN_STORE_CHATS=true
      - WEBHOOK_GLOBAL_URL=https://wazzap.ngrok.app/api/webhook/v2/messageHandlers
      - WEBHOOK_GLOBAL_ENABLED=true
      - WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true
      - WEBHOOK_GLOBAL_WEBHOOK_BASE64=true
      - WEBHOOK_EVENTS_APPLICATION_STARTUP=false
      - WEBHOOK_EVENTS_QRCODE_UPDATED=true
      - WEBHOOK_EVENTS_MESSAGES_SET=false
      - WEBHOOK_EVENTS_MESSAGES_UPSERT=true
      - WEBHOOK_EVENTS_MESSAGES_UPDATE=false
      - WEBHOOK_EVENTS_MESSAGES_DELETE=false
      - WEBHOOK_EVENTS_SEND_MESSAGE=true
      - WEBHOOK_EVENTS_CONTACTS_SET=false
      - WEBHOOK_EVENTS_CONTACTS_UPSERT=false
      - WEBHOOK_EVENTS_CONTACTS_UPDATE=false
      - WEBHOOK_EVENTS_PRESENCE_UPDATE=false
      - WEBHOOK_EVENTS_CHATS_SET=false
      - WEBHOOK_EVENTS_CHATS_UPSERT=false
      - WEBHOOK_EVENTS_CHATS_UPDATE=false
      - WEBHOOK_EVENTS_CHATS_DELETE=false
      - WEBHOOK_EVENTS_GROUPS_UPSERT=false
      - WEBHOOK_EVENTS_GROUPS_UPDATE=false
      - WEBHOOK_EVENTS_GROUP_PARTICIPANTS_UPDATE=false
      - WEBHOOK_EVENTS_CONNECTION_UPDATE=true
      - WEBHOOK_EVENTS_LABELS_EDIT=false
      - WEBHOOK_EVENTS_LABELS_ASSOCIATION=false
      - WEBHOOK_EVENTS_CALL=false
      - WEBHOOK_EVENTS_NEW_JWT_TOKEN=false
      - WEBHOOK_EVENTS_TYPEBOT_START=true
      - WEBHOOK_EVENTS_TYPEBOT_CHANGE_STATUS=true
      - WEBHOOK_EVENTS_CHAMA_AI_ACTION=false
      - WEBHOOK_EVENTS_ERRORS=false
      - WEBHOOK_EVENTS_ERRORS_WEBHOOK=false
      - LOG_LEVEL=${LOG_LEVEL:-ERROR}
      - LOG_COLOR=true
      - LOG_BAILEYS=error
      - CORS_ORIGIN=*
      - CORS_METHODS=POST,GET,PUT,DELETE
      - CORS_CREDENTIALS=true
      - S3_ENABLED=false
      - STORE_MESSAGES=true
      - STORE_CONTACTS=true
      - STORE_CHATS=true
    volumes:
      - evolution_instances:/evolution/instances
    labels:
      - traefik.enable=true
      - traefik.http.routers.evolution.rule=Host(`${DOMAIN_NAME}`)
      - traefik.http.routers.evolution.entrypoints=websecure
      - traefik.http.routers.evolution.tls.certresolver=letsencryptresolver
      - traefik.http.services.evolution.loadbalancer.server.port=8080
    networks:
      - evolution_network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    depends_on:
      - traefik

networks:
  evolution_network:
    driver: bridge

volumes:
  evolution_instances:
    driver: local
  traefik_letsencrypt:
    driver: local
EOF

log_success "Docker Compose créé avec Traefik et SSL automatique"

# Scripts de gestion
log_info "Création des scripts de gestion..."
cat > start.sh << EOF
#!/bin/bash

echo "🚀 Démarrage de Evolution API..."
docker-compose up -d


echo "⏳ Attente du démarrage de l'API (migrations + démarrage du serveur)..."
echo "   Cela peut prendre 30-60 secondes au premier démarrage..."

wait_for_api() {
    local max_attempts=30
    local attempt=1
    while [ \$attempt -le \$max_attempts ]; do
        echo -n "   Tentative \$attempt/\$max_attempts... "
        if curl -s -f https://$DOMAIN_NAME/ > /dev/null 2>&1; then
            echo "✅ API prête!"
            return 0
        else
            echo "⏳ En attente..."
            sleep 10
            attempt=\$((attempt + 1))
        fi
    done
    echo "❌ Timeout - L'API ne répond toujours pas"
    return 1
}

if wait_for_api; then
    echo ""
    echo "🎉 Evolution API v2 démarrée avec succès!"
    echo "=================================="
    echo "🌐 API disponible sur: https://$DOMAIN_NAME"
    echo "📊 Traefik dashboard: https://traefik.$DOMAIN_NAME"
    echo "🔑 Clé API: **********************$(echo $API_KEY | tail -c 5)"
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
    echo "🌐 Testez manuellement: curl https://$DOMAIN_NAME/"
fi

echo ""
echo "📋 Commandes utiles:"
echo "  docker-compose logs -f evolution-api  # Voir les logs en temps réel"
echo "  docker-compose ps                     # Statut des services"
echo "  docker-compose down                   # Arrêter"
echo "  curl https://$DOMAIN_NAME/            # Tester l'API"
EOF

cat > stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Arrêt de Evolution API..."
docker-compose down
echo "✅ Services arrêtés!"
EOF

cat > logs.sh << 'EOF'
#!/bin/bash
echo "📝 Logs de Evolution API:"
docker-compose logs -f evolution-api
EOF

cat > status.sh << 'EOF'
#!/bin/bash
echo "📊 Statut des services:"
docker-compose ps
echo ""
echo "🔍 Santé des conteneurs:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOF

chmod +x start.sh stop.sh logs.sh status.sh

log_success "Scripts de gestion créés"

# Limites système
log_info "Configuration des limites système..."
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "root soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "root hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Swappiness
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

log_success "Limites système configurées"

# Service systemd
log_info "Configuration du service auto-démarrage..."
sudo tee /etc/systemd/system/evolution-api.service > /dev/null << EOF
[Unit]
Description=Evolution API Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0
User=$USER
Group=docker

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable evolution-api.service

log_success "Service auto-démarrage configuré"

# Instructions finales
echo -e "${GREEN}"
echo "🎉 Configuration VPS terminée avec succès!"
echo "=========================================="
echo -e "${NC}"
echo -e "${BLUE}📋 Prochaines étapes:${NC}"
echo "1. 🌐 Configurez vos DNS:"
echo "   - $DOMAIN_NAME → IP de ce serveur"
echo "   - traefik.$DOMAIN_NAME → IP de ce serveur"
echo ""
echo "2. 🔄 Redémarrez le serveur pour appliquer toutes les configurations:"
echo "   sudo reboot"
echo ""
echo "3. 🚀 Après redémarrage, démarrez l'API:"
echo "   cd $APP_DIR"
echo "   ./start.sh"
echo ""
echo -e "${BLUE}🛠️  Commandes utiles:${NC}"
echo "   ./start.sh   - Démarrer les services"
echo "   ./stop.sh    - Arrêter les services"
echo "   ./logs.sh    - Voir les logs"
echo "   ./status.sh  - Statut des services"
echo ""
echo -e "${BLUE}🌐 Accès après démarrage:${NC}"
echo "   API Evolution: https://$DOMAIN_NAME"
echo "   Traefik Dashboard: https://traefik.$DOMAIN_NAME"
echo ""
echo -e "${BLUE}🔑 Clé API configurée:${NC} **********************$(echo $API_KEY | tail -c 5)"
echo ""
echo -e "${YELLOW}⚠️  Important:${NC}"
echo "   - Gardez votre clé API en sécurité"
echo "   - Les certificats SSL seront générés automatiquement"
echo "   - Les services démarrent automatiquement au boot"
echo ""
echo -e "${GREEN}✅ Configuration terminée!${NC}"
