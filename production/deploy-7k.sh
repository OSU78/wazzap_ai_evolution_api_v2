#!/bin/bash

# ========================================
# Script de Déploiement 7K Comptes WhatsApp
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
echo "🚀 Déploiement Evolution API v2 - 7000 Comptes WhatsApp"
echo "======================================================="
echo "Ce script va déployer 180 instances Evolution API"
echo "sur un cluster Docker Swarm de 9 workers"
echo -e "${NC}"

# Vérifications préalables
log_info "Vérification des prérequis..."

# Vérifier Docker Swarm
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
    log_error "Docker Swarm n'est pas initialisé!"
    echo "Initialisez Swarm avec: docker swarm init --advertise-addr YOUR_IP"
    exit 1
fi

# Vérifier le nombre de nœuds
NODE_COUNT=$(docker node ls --format "{{.Hostname}}" | wc -l)
if [ $NODE_COUNT -lt 10 ]; then
    log_warning "Seulement $NODE_COUNT nœuds détectés (recommandé: 10)"
    echo "Continuez-vous quand même? (y/N)"
    read -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Vérifier les workers étiquetés
WORKER_COUNT=$(docker node ls --filter role=worker --format "{{.Hostname}}" | wc -l)
log_info "Workers disponibles: $WORKER_COUNT"

# Créer le réseau si nécessaire
log_info "Configuration du réseau..."
docker network create --driver=overlay network_public 2>/dev/null && log_success "Réseau créé" || log_info "Réseau existe déjà"

# Créer les volumes pour 7K comptes
log_info "Création des volumes pour 7K comptes..."
docker volume create evolution_7k_instances 2>/dev/null && log_success "Volume instances créé" || log_info "Volume instances existe déjà"

# Test de connectivité services externes
log_info "Test de connectivité aux services externes..."

# Test Neon PostgreSQL
log_info "Test Neon PostgreSQL..."
if docker run --rm postgres:15-alpine psql "postgresql://neondb_owner:npg_cyOdLoBN0Z5T@ep-soft-pine-adcz7qon-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require" -c "SELECT 1;" >/dev/null 2>&1; then
    log_success "Neon PostgreSQL accessible"
else
    log_error "Neon PostgreSQL inaccessible!"
    exit 1
fi

# Test Redis Cloud
log_info "Test Redis Cloud..."
if docker run --rm redis:7-alpine redis-cli -u "redis://default:hUQnreFwfxJYV5VD2R6VmpJTu8angsP2@redis-19966.c10.us-east-1-2.ec2.redns.redis-cloud.com:19966" ping | grep -q PONG; then
    log_success "Redis Cloud accessible"
else
    log_error "Redis Cloud inaccessible!"
    exit 1
fi

# Déployer Traefik si pas déjà fait
log_info "Vérification de Traefik..."
if ! docker stack ls | grep -q traefik; then
    log_info "Déploiement de Traefik..."
    if [ -f "traefik.yml" ]; then
        docker stack deploy --prune --resolve-image always -c traefik.yml traefik
        log_success "Traefik déployé"
        sleep 10
    else
        log_error "Fichier traefik.yml non trouvé!"
        exit 1
    fi
else
    log_info "Traefik déjà déployé"
fi

# Confirmation finale
echo ""
log_warning "ATTENTION: Vous allez déployer 180 instances Evolution API"
log_warning "Cela va consommer environ 288GB de RAM sur le cluster"
log_warning "Êtes-vous sûr de vouloir continuer? (y/N)"
read -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Déploiement annulé"
    exit 0
fi

# Déploiement progressif
log_info "Déploiement progressif des instances..."

# Phase 1: Démarrer avec 20 instances
log_info "Phase 1: Déploiement de 20 instances..."
sed 's/replicas: 180/replicas: 20/' docker-swarm-7k.yml > docker-swarm-7k-phase1.yml
docker stack deploy --prune --resolve-image always -c docker-swarm-7k-phase1.yml evolution

# Attendre stabilisation
log_info "Attente de stabilisation (60s)..."
sleep 60

# Vérifier que les 20 premières instances sont OK
RUNNING_INSTANCES=$(docker service ps evolution_evolution-api --filter desired-state=running --format "{{.CurrentState}}" | grep -c Running)
log_info "Instances en cours d'exécution: $RUNNING_INSTANCES/20"

if [ $RUNNING_INSTANCES -lt 18 ]; then
    log_error "Pas assez d'instances démarrées ($RUNNING_INSTANCES/20)"
    log_error "Vérifiez les logs: docker service logs evolution_evolution-api"
    exit 1
fi

# Phase 2: Passer à 60 instances
log_info "Phase 2: Scaling à 60 instances..."
sed 's/replicas: 180/replicas: 60/' docker-swarm-7k.yml > docker-swarm-7k-phase2.yml
docker stack deploy --prune --resolve-image always -c docker-swarm-7k-phase2.yml evolution

# Attendre stabilisation
log_info "Attente de stabilisation (90s)..."
sleep 90

# Vérifier
RUNNING_INSTANCES=$(docker service ps evolution_evolution-api --filter desired-state=running --format "{{.CurrentState}}" | grep -c Running)
log_info "Instances en cours d'exécution: $RUNNING_INSTANCES/60"

if [ $RUNNING_INSTANCES -lt 54 ]; then
    log_error "Pas assez d'instances démarrées ($RUNNING_INSTANCES/60)"
    log_error "Arrêt du déploiement pour investigation"
    exit 1
fi

# Phase 3: Déploiement complet à 180 instances
log_info "Phase 3: Déploiement complet à 180 instances..."
docker stack deploy --prune --resolve-image always -c docker-swarm-7k.yml evolution

# Attendre stabilisation finale
log_info "Attente de stabilisation finale (120s)..."
sleep 120

# Vérification finale
log_info "Vérification finale du déploiement..."
RUNNING_INSTANCES=$(docker service ps evolution_evolution-api --filter desired-state=running --format "{{.CurrentState}}" | grep -c Running)
TOTAL_REPLICAS=$(docker service ls --filter name=evolution_evolution-api --format "{{.Replicas}}")

echo ""
log_info "=== RÉSULTATS DU DÉPLOIEMENT ==="
log_info "Instances cibles: 180"
log_info "Instances déployées: $TOTAL_REPLICAS"
log_info "Instances en cours d'exécution: $RUNNING_INSTANCES"

if [ $RUNNING_INSTANCES -ge 162 ]; then  # 90% de 180
    log_success "Déploiement réussi! (>90% des instances actives)"
else
    log_warning "Déploiement partiel ($RUNNING_INSTANCES/180 instances actives)"
fi

# Nettoyage des fichiers temporaires
rm -f docker-swarm-7k-phase*.yml

echo ""
log_info "=== INFORMATIONS DE MONITORING ==="
echo "📊 Status des services:"
docker service ls

echo ""
echo "🔍 Répartition des instances par nœud:"
docker service ps evolution_evolution-api --format "table {{.Node}}\t{{.CurrentState}}" | head -20

echo ""
echo "📋 Commandes utiles:"
echo "  docker service logs -f evolution_evolution-api  # Logs"
echo "  docker service ps evolution_evolution-api       # Status instances"
echo "  docker service scale evolution_evolution-api=N  # Scaling"
echo "  docker stack ps evolution                       # Status stack"

echo ""
echo "🌐 Accès à l'API:"
echo "  API: https://evolution.wazzap.fr"
echo "  Traefik Dashboard: https://traefik.wazzap.fr"
echo "  Clé API: B6D711FCDE4D4FD5936544120E713C37"

echo ""
if [ $RUNNING_INSTANCES -ge 162 ]; then
    log_success "🎉 Déploiement 7K comptes terminé avec succès!"
    log_success "Capacité théorique: $((RUNNING_INSTANCES * 40)) comptes WhatsApp"
else
    log_warning "⚠️  Déploiement partiel - Vérifiez les logs pour optimiser"
fi

echo ""
log_info "📈 Prochaines étapes:"
echo "1. Tester la connectivité API"
echo "2. Configurer le monitoring"
echo "3. Commencer la migration progressive des comptes"
echo "4. Surveiller les performances"
