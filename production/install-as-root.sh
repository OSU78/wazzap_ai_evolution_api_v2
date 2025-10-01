#!/bin/bash

# ========================================
# Installation Rapide en tant que Root
# ========================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo -e "${BLUE}"
echo "🚀 Installation Evolution API - Mode Root"
echo "========================================"
echo "Ce script configure automatiquement:"
echo "- Utilisateur non-root pour Docker"
echo "- Installation complète"
echo "- Déploiement de l'API"
echo -e "${NC}"

# Vérifier qu'on est bien root
if [[ $EUID -ne 0 ]]; then
   log_error "Ce script doit être exécuté en tant que root"
   log_info "Utilisez: sudo ./install-as-root.sh"
   exit 1
fi

# Demander les informations
log_info "Configuration du déploiement..."
read -p "🌐 Nom de domaine (ex: evolution.wazzap.fr): " DOMAIN_NAME
read -p "📧 Email pour Let's Encrypt: " LETSENCRYPT_EMAIL
read -p "🔢 Configuration (1=1serveur, 2=2serveurs, 3=cluster7k): " CONFIG_CHOICE

if [ -z "$DOMAIN_NAME" ] || [ -z "$LETSENCRYPT_EMAIL" ]; then
    log_error "Domaine et email sont obligatoires!"
    exit 1
fi

# Mise à jour du système
log_info "Mise à jour du système..."
apt-get update && apt-get upgrade -y

# Installation des paquets essentiels
log_info "Installation des paquets..."
apt-get install -y curl wget git nano htop ufw fail2ban

# Installation de Docker
log_info "Installation de Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    log_success "Docker installé"
fi

# Installation de Docker Compose
log_info "Installation de Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log_success "Docker Compose installé"
fi

# Créer l'utilisateur evolution
log_info "Création de l'utilisateur evolution..."
if ! id "evolution" &>/dev/null; then
    useradd -m -s /bin/bash evolution
    usermod -aG sudo,docker evolution
    log_success "Utilisateur 'evolution' créé"
else
    usermod -aG docker evolution
    log_info "Utilisateur 'evolution' existe déjà"
fi

# Configuration du firewall
log_info "Configuration du firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 8080
ufw --force enable
log_success "Firewall configuré"

# Copier les fichiers vers l'utilisateur evolution
log_info "Configuration des fichiers..."
cp -r /root/evolution_api /home/evolution/ 2>/dev/null || cp -r . /home/evolution/evolution_api
chown -R evolution:evolution /home/evolution/evolution_api

# Créer le fichier .env
log_info "Création de la configuration..."
sudo -u evolution bash -c "cd /home/evolution/evolution_api && cat > .env << EOF
# Configuration automatique
DOMAIN_NAME=$DOMAIN_NAME
LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL
AUTHENTICATION_API_KEY=B6D711FCDE4D4FD5936544120E713C37
JWT_SECRET=L=0YWt]b2w[WF>#>:&CWOMH2c<;Kn95jH
DATABASE_CONNECTION_URI=postgresql://neondb_owner:npg_cyOdLoBN0Z5T@ep-soft-pine-adcz7qon-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require
CACHE_REDIS_URI=redis://default:hUQnreFwfxJYV5VD2R6VmpJTu8angsP2@redis-19966.c10.us-east-1-2.ec2.redns.redis-cloud.com:19966/1
WEBHOOK_GLOBAL_URL=https://wazzap.ngrok.app/api/webhook/v2/messageHandlers
WEBHOOK_GLOBAL_ENABLED=true
WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true
WEBHOOK_GLOBAL_WEBHOOK_BASE64=true
WEBHOOK_GLOBAL_EVENTS=SEND_MESSAGE,QRCODE_UPDATED,REMOVE_INSTANCE,LOGOUT_INSTANCE,CONNECTION_UPDATE,MESSAGES_UPSERT
LOG_LEVEL=INFO
EOF"

# Déployer selon le choix
log_info "Déploiement de l'API Evolution..."

case $CONFIG_CHOICE in
    1)
        log_info "Déploiement 1 serveur 16GB..."
        sudo -u evolution bash -c "cd /home/evolution/evolution_api && ./production/deploy-single-16gb.sh"
        ;;
    2)
        log_warning "Configuration 2 serveurs nécessite Docker Swarm"
        log_info "Initialisez d'abord Swarm puis utilisez deploy-2servers.sh"
        ;;
    3)
        log_warning "Configuration cluster nécessite 10 serveurs et Docker Swarm"
        log_info "Consultez DEPLOYMENT-7K-GUIDE.md pour les étapes complètes"
        ;;
    *)
        log_info "Configuration par défaut: 1 serveur"
        sudo -u evolution bash -c "cd /home/evolution/evolution_api && ./production/deploy-single-16gb.sh"
        ;;
esac

echo ""
log_success "🎉 Installation terminée !"
echo ""
echo "🔧 Pour gérer votre installation :"
echo "   su - evolution"
echo "   cd evolution_api"
echo ""
echo "🌐 Accès :"
echo "   API: https://$DOMAIN_NAME"
echo "   Dashboard: https://traefik.$DOMAIN_NAME"
echo ""
echo "🔑 Clé API: B6D711FCDE4D4FD5936544120E713C37"
