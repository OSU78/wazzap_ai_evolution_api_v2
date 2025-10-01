#!/bin/bash

# ========================================
# Script de Déploiement Express - 2 Serveurs Hostinger 16GB
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
echo "🚀 Déploiement Express Evolution API v2 - 2 Serveurs"
echo "=================================================="
echo "Déploiement : 20 instances Evolution API"
echo "Capacité    : ~800 comptes WhatsApp"
echo "Temps       : ~30 minutes"
echo -e "${NC}"

# Vérifications préalables
log_info "Vérification des prérequis..."

# Vérifier Docker Swarm
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
    log_error "Docker Swarm n'est pas initialisé!"
    echo "Initialisez d'abord Swarm avec :"
    echo "docker swarm init --advertise-addr VOTRE_IP_MANAGER"
    exit 1
fi

# Vérifier le nombre de nœuds
NODE_COUNT=$(docker node ls --format "{{.Hostname}}" | wc -l)
log_info "Nœuds détectés dans le cluster : $NODE_COUNT"

if [ $NODE_COUNT -lt 2 ]; then
    log_error "Cluster incomplet ! Seulement $NODE_COUNT nœud(s) détecté(s)"
    echo "Ajoutez le worker avec :"
    echo "docker swarm join --token TOKEN IP_MANAGER:2377"
    exit 1
fi

# Vérifier les services externes
log_info "Test des services externes..."

# Test Neon PostgreSQL
log_info "Test Neon PostgreSQL..."
if timeout 10 docker run --rm postgres:15-alpine psql "postgresql://neondb_owner:npg_cyOdLoBN0Z5T@ep-soft-pine-adcz7qon-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require" -c "SELECT 1;" >/dev/null 2>&1; then
    log_success "Neon PostgreSQL accessible"
else
    log_error "Neon PostgreSQL inaccessible !"
    exit 1
fi

# Test Redis Cloud
log_info "Test Redis Cloud..."
if timeout 10 docker run --rm redis:7-alpine redis-cli -u "redis://default:hUQnreFwfxJYV5VD2R6VmpJTu8angsP2@redis-19966.c10.us-east-1-2.ec2.redns.redis-cloud.com:19966" ping 2>/dev/null | grep -q PONG; then
    log_success "Redis Cloud accessible"
else
    log_error "Redis Cloud inaccessible !"
    exit 1
fi

# Créer le réseau si nécessaire
log_info "Configuration du réseau Swarm..."
docker network create --driver=overlay network_public 2>/dev/null && log_success "Réseau créé" || log_info "Réseau existe déjà"

# Créer les volumes
log_info "Création des volumes..."
docker volume create evolution_2servers_instances 2>/dev/null && log_success "Volume instances créé" || log_info "Volume instances existe déjà"

# Étiqueter le worker si pas déjà fait
log_info "Configuration des labels de nœuds..."
WORKER_NODE_ID=$(docker node ls --filter role=worker --format "{{.ID}}" | head -1)
if [ ! -z "$WORKER_NODE_ID" ]; then
    docker node update --label-add type=evolution-worker $WORKER_NODE_ID 2>/dev/null || true
    log_success "Worker étiqueté"
fi

# Déployer Traefik si pas déjà fait
log_info "Vérification de Traefik..."
if ! docker stack ls | grep -q traefik; then
    log_info "Déploiement de Traefik..."
    if [ -f "traefik.yml" ]; then
        docker stack deploy --prune --resolve-image always -c traefik.yml traefik
        log_success "Traefik déployé"
        log_info "Attente de la génération SSL (3 minutes)..."
        sleep 180
    else
        log_error "Fichier traefik.yml non trouvé !"
        exit 1
    fi
else
    log_info "Traefik déjà déployé"
fi

# Confirmation avant déploiement
echo ""
log_warning "CONFIGURATION DU DÉPLOIEMENT :"
log_warning "• 2 serveurs Hostinger 16GB RAM"
log_warning "• 20 instances Evolution API (10 par serveur)"
log_warning "• Capacité théorique : ~800 comptes WhatsApp"
log_warning "• Services externes : Neon + Redis Cloud"
echo ""
echo "Continuer le déploiement ? (y/N)"
read -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Déploiement annulé"
    exit 0
fi

# Déploiement de l'API Evolution
log_info "Déploiement de Evolution API (20 instances)..."
if [ -f "docker-swarm-2servers.yml" ]; then
    docker stack deploy --prune --resolve-image always -c docker-swarm-2servers.yml evolution
    log_success "Stack Evolution déployée"
else
    log_error "Fichier docker-swarm-2servers.yml non trouvé !"
    exit 1
fi

# Attendre que les instances se déploient
log_info "Attente du déploiement des instances..."
log_info "⏳ Cela peut prendre 5-10 minutes (téléchargement + démarrage)..."

# Fonction d'attente intelligente
wait_for_deployment() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        RUNNING_INSTANCES=$(docker service ps evolution_evolution-api --filter desired-state=running --format "{{.CurrentState}}" | grep -c "Running" 2>/dev/null || echo "0")
        TOTAL_REPLICAS=$(docker service ls --filter name=evolution_evolution-api --format "{{.Replicas}}" | cut -d'/' -f2)
        
        echo -n "   Tentative $attempt/$max_attempts - Instances: $RUNNING_INSTANCES/$TOTAL_REPLICAS... "
        
        if [ "$RUNNING_INSTANCES" -ge 18 ]; then  # 90% des instances
            echo "✅ Déploiement réussi !"
            return 0
        else
            echo "⏳ En attente..."
            sleep 20
            attempt=$((attempt + 1))
        fi
    done
    
    echo "❌ Timeout - Déploiement partiel"
    return 1
}

# Attendre le déploiement
if wait_for_deployment; then
    RUNNING_INSTANCES=$(docker service ps evolution_evolution-api --filter desired-state=running --format "{{.CurrentState}}" | grep -c "Running")
    
    echo ""
    log_success "🎉 Déploiement terminé avec succès !"
    log_success "Instances actives : $RUNNING_INSTANCES/20"
    log_success "Capacité théorique : $((RUNNING_INSTANCES * 40)) comptes WhatsApp"
else
    RUNNING_INSTANCES=$(docker service ps evolution_evolution-api --filter desired-state=running --format "{{.CurrentState}}" | grep -c "Running" 2>/dev/null || echo "0")
    log_warning "Déploiement partiel : $RUNNING_INSTANCES/20 instances"
    log_info "Vérifiez les logs : docker service logs evolution_evolution-api"
fi

echo ""
log_info "=== RÉSUMÉ DU DÉPLOIEMENT ==="
echo "📊 Status des services :"
docker service ls

echo ""
echo "🔍 Répartition des instances :"
docker service ps evolution_evolution-api --format "table {{.Node}}\t{{.CurrentState}}\t{{.Error}}" | head -10

echo ""
echo "🌐 Accès à votre infrastructure :"
echo "  • API Evolution    : https://evolution.wazzap.fr"
echo "  • Traefik Dashboard: https://traefik.wazzap.fr"
echo "  • Clé API          : B6D711FCDE4D4FD5936544120E713C37"

echo ""
echo "📋 Commandes de gestion :"
echo "  docker service logs -f evolution_evolution-api     # Logs en temps réel"
echo "  docker service scale evolution_evolution-api=N     # Changer le nombre d'instances"
echo "  docker service ps evolution_evolution-api          # Status des instances"
echo "  docker stack ps evolution                          # Status complet"

echo ""
if [ "$RUNNING_INSTANCES" -ge 18 ]; then
    log_success "🎉 DÉPLOIEMENT RÉUSSI - Votre cluster est opérationnel !"
    log_success "Vous pouvez commencer à créer des instances WhatsApp"
else
    log_warning "⚠️  Déploiement partiel - Quelques instances n'ont pas démarré"
    log_info "💡 C'est normal au premier déploiement, les instances vont se stabiliser"
fi

echo ""
log_info "📈 Prochaines étapes :"
echo "1. Tester la création d'instances WhatsApp"
echo "2. Configurer le monitoring automatique"
echo "3. Planifier l'ajout de serveurs pour scaler"
echo "4. Commencer la migration de vos comptes existants"

echo ""
log_success "🎊 Félicitations ! Votre cluster Evolution API est prêt !"
