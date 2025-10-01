#!/bin/bash

# ========================================
# Script de Validation des Ports - Production
# ========================================

echo "🔍 Validation des Configurations de Ports"
echo "=========================================="

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "📋 Vérification des configurations..."
echo ""

# Fonction pour analyser les ports dans un fichier
analyze_ports() {
    local file=$1
    local config_name=$2
    
    echo "🔍 Analyse: $config_name"
    echo "   Fichier: $file"
    
    if [ ! -f "$file" ]; then
        log_error "Fichier non trouvé: $file"
        return
    fi
    
    # Chercher les expositions de ports
    EXPOSED_PORTS=$(grep -n "ports:" "$file" 2>/dev/null || true)
    PORT_MAPPINGS=$(grep -n "- \".*:.*\"" "$file" 2>/dev/null || true)
    
    if [ -z "$EXPOSED_PORTS" ] && [ -z "$PORT_MAPPINGS" ]; then
        log_success "Aucun port exposé directement (correct pour Swarm)"
    else
        echo "   Ports exposés détectés:"
        echo "$EXPOSED_PORTS" | while read line; do
            echo "     $line"
        done
        echo "$PORT_MAPPINGS" | while read line; do
            echo "     $line"
        done
        
        # Vérifier si c'est Traefik (OK) ou API (problème potentiel)
        if echo "$PORT_MAPPINGS" | grep -q "8080:8080" && grep -q "traefik" "$file"; then
            log_success "Port 8080 pour Traefik (correct)"
        elif echo "$PORT_MAPPINGS" | grep -q "8080:8080"; then
            log_warning "Port 8080 exposé pour API - Conflit potentiel avec Traefik"
        fi
        
        if echo "$PORT_MAPPINGS" | grep -q "80:80\|443:443"; then
            log_success "Ports HTTP/HTTPS pour Traefik (correct)"
        fi
    fi
    
    echo ""
}

# Analyser chaque configuration
analyze_ports "production/docker-compose-single-16gb.yml" "1 Serveur 16GB"
analyze_ports "production/docker-swarm-2servers.yml" "2 Serveurs Swarm"
analyze_ports "production/docker-swarm-7k.yml" "Cluster 7K Swarm"
analyze_ports "production/docker-swarm.yml" "Swarm Standard"
analyze_ports "production/traefik.yml" "Traefik Production"

# Vérifier les labels Traefik
echo "🏷️ Vérification des Labels Traefik"
echo "=================================="

check_traefik_labels() {
    local file=$1
    local config_name=$2
    
    echo "🔍 $config_name:"
    
    if grep -q "traefik.enable=true" "$file" 2>/dev/null; then
        log_success "Traefik activé"
    else
        log_warning "Traefik non configuré"
    fi
    
    if grep -q "traefik.http.routers" "$file" 2>/dev/null; then
        ROUTER_RULE=$(grep "traefik.http.routers.*rule" "$file" | head -1)
        echo "   Router: ${ROUTER_RULE##*=}"
    fi
    
    if grep -q "loadbalancer.server.port=8080" "$file" 2>/dev/null; then
        log_success "Port backend configuré (8080)"
    else
        log_warning "Port backend non configuré"
    fi
    
    echo ""
}

check_traefik_labels "production/docker-compose-single-16gb.yml" "1 Serveur"
check_traefik_labels "production/docker-swarm-2servers.yml" "2 Serveurs" 
check_traefik_labels "production/docker-swarm-7k.yml" "Cluster 7K"

# Résumé des bonnes pratiques
echo "📋 Résumé des Bonnes Pratiques"
echo "=============================="
echo ""
log_success "✅ Configurations Swarm : Pas de ports exposés (Traefik gère)"
log_success "✅ Traefik : Ports 80, 443, 8080 exposés (correct)"
log_warning "⚠️  Docker Compose : Éviter l'exposition directe de l'API"
echo ""
echo "🎯 Règles à suivre :"
echo "   • Swarm : Jamais de 'ports:' pour l'API Evolution"
echo "   • Compose : Seulement si pas de Traefik"
echo "   • Traefik : Toujours ports 80, 443, 8080"
echo "   • Load balancing : Via labels Traefik uniquement"
echo ""
echo "✅ Validation terminée"
