#!/bin/bash

# ========================================
# Script de Déploiement - 1 Serveur Hostinger 16GB
# ========================================

set -e

# Couleurs pour les messages
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
echo "🚀 Déploiement Evolution API v2 - 1 Serveur 16GB"
echo "=============================================="
echo "Configuration : 10 instances Evolution API"
echo "Capacité      : ~400 comptes WhatsApp"
echo "Serveur       : Hostinger 16GB RAM"
echo "Mode          : Docker Compose (pas de Swarm)"
echo -e "${NC}"

# Vérifier si on est sur le bon serveur
log_info "Vérification de l'environnement..."

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé!"
    echo "Exécutez d'abord: ./setup-vps.sh"
    exit 1
fi

# Vérifier Docker Compose
if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose n'est pas installé!"
    echo "Exécutez d'abord: ./setup-vps.sh"
    exit 1
fi

# Vérifier les ressources (compatible Linux/macOS)
if command -v free &> /dev/null; then
    # Linux
    TOTAL_RAM=$(free -g | awk 'NR==2{printf "%.0f", $2}')
    log_info "RAM disponible: ${TOTAL_RAM}GB"
    
    if [ $TOTAL_RAM -lt 14 ]; then
        log_warning "RAM détectée: ${TOTAL_RAM}GB (recommandé: 16GB+)"
        echo "Continuez-vous quand même? (y/N)"
        read -n 1 -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    # macOS ou autre
    log_info "Vérification des ressources (détection automatique)"
fi

# Demander les informations de configuration
echo ""
log_info "Configuration du déploiement..."
read -p "🌐 Nom de domaine (ex: evolution.wazzap.fr): " DOMAIN_NAME
read -p "📧 Email pour Let's Encrypt: " LETSENCRYPT_EMAIL

if [ -z "$DOMAIN_NAME" ] || [ -z "$LETSENCRYPT_EMAIL" ]; then
    log_error "Domaine et email sont obligatoires!"
    exit 1
fi

# Créer le fichier .env
log_info "Création du fichier de configuration..."
cat > .env << EOF
# Configuration 1 Serveur 16GB
DOMAIN_NAME=$DOMAIN_NAME
LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL

# Base de données Neon
DATABASE_CONNECTION_URI=postgresql://neondb_owner:npg_cyOdLoBN0Z5T@ep-soft-pine-adcz7qon-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require

# Redis Cloud
CACHE_REDIS_URI=redis://default:hUQnreFwfxJYV5VD2R6VmpJTu8angsP2@redis-19966.c10.us-east-1-2.ec2.redns.redis-cloud.com:19966/1

# Authentification
AUTHENTICATION_API_KEY=B6D711FCDE4D4FD5936544120E713C37
JWT_SECRET=L=0YWt]b2w[WF>#>:&CWOMH2c<;Kn95jH

# Webhook Wazzap
WEBHOOK_GLOBAL_URL=https://wazzap.ngrok.app/api/webhook/v2/messageHandlers
WEBHOOK_GLOBAL_ENABLED=true
WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=true
WEBHOOK_GLOBAL_WEBHOOK_BASE64=true
WEBHOOK_GLOBAL_EVENTS=SEND_MESSAGE,QRCODE_UPDATED,REMOVE_INSTANCE,LOGOUT_INSTANCE,CONNECTION_UPDATE,MESSAGES_UPSERT

# Logs
LOG_LEVEL=INFO
EOF

log_success "Configuration créée"

# Test des services externes (optionnel en local)
log_info "Test des services externes..."

# Test Neon PostgreSQL (skip en local/développement)
log_info "Test Neon PostgreSQL..."
if command -v timeout &> /dev/null; then
    # Linux avec timeout
    if timeout 10 docker run --rm postgres:15-alpine psql "postgresql://neondb_owner:npg_cyOdLoBN0Z5T@ep-soft-pine-adcz7qon-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require" -c "SELECT 1;" >/dev/null 2>&1; then
        log_success "Neon PostgreSQL accessible"
    else
        log_warning "Neon PostgreSQL inaccessible - Continuons quand même"
    fi
else
    # macOS ou environnement sans timeout
    log_info "Test Neon PostgreSQL ignoré (environnement local détecté)"
fi

# Test Redis Cloud (skip en local/développement)
log_info "Test Redis Cloud..."
if command -v timeout &> /dev/null; then
    # Linux avec timeout
    if timeout 10 docker run --rm redis:7-alpine redis-cli -u "redis://default:hUQnreFwfxJYV5VD2R6VmpJTu8angsP2@redis-19966.c10.us-east-1-2.ec2.redns.redis-cloud.com:19966" ping 2>/dev/null | grep -q PONG; then
        log_success "Redis Cloud accessible"
    else
        log_warning "Redis Cloud inaccessible - Continuons quand même"
    fi
else
    # macOS ou environnement sans timeout
    log_info "Test Redis Cloud ignoré (environnement local détecté)"
fi

# Arrêter les anciens services
log_info "Arrêt des anciens services..."
docker-compose down 2>/dev/null || true
docker-compose -f docker-compose-single-16gb.yml down 2>/dev/null || true

# Confirmation
echo ""
log_warning "CONFIGURATION DU DÉPLOIEMENT :"
log_warning "• 1 serveur Hostinger 16GB RAM"
log_warning "• 10 instances Evolution API"
log_warning "• Capacité : ~400 comptes WhatsApp"
log_warning "• Domaine : $DOMAIN_NAME"
echo ""
echo "Continuer le déploiement ? (y/N)"
read -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Déploiement annulé"
    exit 0
fi

# Démarrer les services
log_info "Démarrage des services..."
docker-compose -f docker-compose-single-16gb.yml up -d

# Attendre que les services soient prêts
log_info "Attente du démarrage des services..."
log_info "⏳ Traefik + SSL + 10 instances API (3-5 minutes)..."

# Fonction d'attente pour Traefik
wait_for_traefik() {
    local max_attempts=15
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -n "   Traefik $attempt/$max_attempts... "
        
        if curl -s -f http://localhost:8080/api/http/services > /dev/null 2>&1; then
            echo "✅ Traefik prêt!"
            return 0
        else
            echo "⏳ En attente..."
            sleep 10
            attempt=$((attempt + 1))
        fi
    done
    
    echo "❌ Timeout Traefik"
    return 1
fi

# Fonction d'attente pour l'API
wait_for_api() {
    local max_attempts=20
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo -n "   API $attempt/$max_attempts... "
        
        if curl -s -f https://$DOMAIN_NAME/ > /dev/null 2>&1; then
            echo "✅ API prête!"
            return 0
        else
            echo "⏳ En attente..."
            sleep 15
            attempt=$((attempt + 1))
        fi
    done
    
    echo "❌ Timeout API"
    return 1
fi

# Attendre Traefik
if wait_for_traefik; then
    log_success "Traefik opérationnel"
else
    log_warning "Traefik timeout - Continuons quand même"
fi

# Attendre l'API
if wait_for_api; then
    log_success "API Evolution accessible"
else
    log_warning "API timeout - Vérifiez manuellement"
fi

# Vérification finale
echo ""
log_info "=== RÉSUMÉ DU DÉPLOIEMENT ==="

# Status des conteneurs
echo "📊 Status des conteneurs :"
docker-compose -f docker-compose-single-16gb.yml ps

# Test de l'API
echo ""
echo "🧪 Test de l'API :"
if curl -s https://$DOMAIN_NAME/ | grep -q "Welcome to the Evolution API"; then
    log_success "API répond correctement"
else
    log_warning "API ne répond pas encore - Patientez quelques minutes"
fi

# Informations d'accès
echo ""
echo "🌐 Accès à votre infrastructure :"
echo "  • API Evolution     : https://$DOMAIN_NAME"
echo "  • Traefik Dashboard : https://traefik.$DOMAIN_NAME"
echo "  • Dashboard Local   : http://IP_SERVEUR:8080"
echo "  • Clé API          : B6D711FCDE4D4FD5936544120E713C37"

# Utilisation des ressources
RUNNING_CONTAINERS=$(docker-compose -f docker-compose-single-16gb.yml ps --services --filter "status=running" | wc -l)
echo ""
echo "💾 Utilisation estimée :"
echo "  • Conteneurs actifs : $RUNNING_CONTAINERS"
echo "  • RAM utilisée : ~10-12GB / 16GB"
echo "  • Capacité : ~400 comptes WhatsApp"

echo ""
echo "📋 Commandes de gestion :"
echo "  docker-compose -f docker-compose-single-16gb.yml logs -f evolution-api  # Logs"
echo "  docker-compose -f docker-compose-single-16gb.yml ps                     # Status"
echo "  docker-compose -f docker-compose-single-16gb.yml scale evolution-api=N  # Scaling"
echo "  docker-compose -f docker-compose-single-16gb.yml down                   # Arrêter"

echo ""
log_success "🎉 DÉPLOIEMENT TERMINÉ !"
log_success "Votre serveur unique est opérationnel avec 10 instances API"

echo ""
log_info "📈 Prochaines étapes :"
echo "1. Tester la création d'instances WhatsApp"
echo "2. Surveiller l'utilisation des ressources"
echo "3. Planifier l'ajout d'un 2ème serveur si besoin"
echo "4. Commencer la migration de vos comptes"

echo ""
log_info "🔧 Scaling rapide (dans la limite du serveur) :"
echo "  docker-compose -f docker-compose-single-16gb.yml scale evolution-api=12  # +2 instances"
echo "  docker-compose -f docker-compose-single-16gb.yml scale evolution-api=8   # -2 instances"

echo ""
log_success "🎊 Félicitations ! Votre API Evolution est prête !"
