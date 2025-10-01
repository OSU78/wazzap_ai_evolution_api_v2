#!/bin/bash

# ========================================
# Nettoyage Avancé des Instances Evolution API
# ========================================

API_URL="https://evolution.wazzap.fr"
API_KEY="B6D711FCDE4D4FD5936544120E713C37"

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo "🧹 Nettoyage Avancé des Instances"
echo "================================"

# Récupérer toutes les instances
log_info "Récupération des instances..."
INSTANCES_JSON=$(curl -s -H "apikey: $API_KEY" "$API_URL/instance/fetchInstances" 2>/dev/null)

if [ -z "$INSTANCES_JSON" ] || [ "$INSTANCES_JSON" = "null" ]; then
    log_error "Impossible de récupérer les instances!"
    exit 1
fi

TOTAL_INSTANCES=$(echo "$INSTANCES_JSON" | jq length 2>/dev/null || echo "0")
log_info "Total instances: $TOTAL_INSTANCES"

if [ "$TOTAL_INSTANCES" -eq 0 ]; then
    log_info "Aucune instance trouvée"
    exit 0
fi

# Afficher toutes les instances
echo ""
echo "📋 TOUTES LES INSTANCES:"
echo "======================"
echo "$INSTANCES_JSON" | jq -r '.[] | "• \(.name) (Status: \(.connectionStatus), Créée: \(.createdAt[0:10]))"' 2>/dev/null

# Menu de choix
echo ""
echo "🎯 OPTIONS DE NETTOYAGE:"
echo "======================="
echo "1. 🧹 Supprimer TOUT sauf TEST4"
echo "2. 🗑️  Supprimer seulement les instances de test (LOAD_TEST_*, PROG_TEST_*, SIMPLE_TEST_*)"
echo "3. 🎯 Supprimer par pattern personnalisé"
echo "4. 📋 Supprimer par liste manuelle"
echo "5. ❌ Annuler"

echo ""
read -p "Choisissez une option (1-5): " CHOICE

case $CHOICE in
    1)
        # Supprimer tout sauf TEST4
        log_warning "Suppression de tout sauf TEST4..."
        INSTANCES_TO_DELETE=$(echo "$INSTANCES_JSON" | jq -r '.[] | select(.name != "TEST4") | .name' 2>/dev/null)
        ;;
    2)
        # Supprimer seulement les instances de test
        log_warning "Suppression des instances de test uniquement..."
        INSTANCES_TO_DELETE=$(echo "$INSTANCES_JSON" | jq -r '.[] | select(.name | test("(LOAD_TEST_|PROG_TEST_|SIMPLE_TEST_)")) | .name' 2>/dev/null)
        ;;
    3)
        # Pattern personnalisé
        echo ""
        read -p "🔍 Entrez le pattern à supprimer (ex: LOAD_TEST): " PATTERN
        if [ ! -z "$PATTERN" ]; then
            log_warning "Suppression des instances contenant '$PATTERN'..."
            INSTANCES_TO_DELETE=$(echo "$INSTANCES_JSON" | jq -r --arg pattern "$PATTERN" '.[] | select(.name | contains($pattern)) | .name' 2>/dev/null)
        else
            log_error "Pattern vide!"
            exit 1
        fi
        ;;
    4)
        # Liste manuelle
        echo ""
        echo "📝 Entrez les noms des instances à supprimer (séparés par des espaces):"
        read -p "Instances: " MANUAL_LIST
        INSTANCES_TO_DELETE="$MANUAL_LIST"
        ;;
    5)
        log_info "Nettoyage annulé"
        exit 0
        ;;
    *)
        log_error "Option invalide!"
        exit 1
        ;;
esac

# Vérifier qu'il y a des instances à supprimer
if [ -z "$INSTANCES_TO_DELETE" ]; then
    log_info "Aucune instance correspondante trouvée"
    exit 0
fi

# Afficher les instances à supprimer
DELETE_COUNT=$(echo "$INSTANCES_TO_DELETE" | wc -w)
echo ""
echo "🗑️  INSTANCES À SUPPRIMER ($DELETE_COUNT):"
echo "=============================="
echo "$INSTANCES_TO_DELETE" | tr ' ' '\n' | while read instance_name; do
    if [ ! -z "$instance_name" ]; then
        echo "   • $instance_name"
    fi
done

# Confirmation finale
echo ""
log_warning "⚠️  Confirmer la suppression de $DELETE_COUNT instances? (y/N)"
read -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Suppression annulée"
    exit 0
fi

# Suppression
log_info "🗑️  Suppression en cours..."
DELETED_COUNT=0
ERROR_COUNT=0

echo "$INSTANCES_TO_DELETE" | tr ' ' '\n' | while read instance_name; do
    if [ ! -z "$instance_name" ]; then
        echo -n "   Suppression $instance_name... "
        
        DELETE_RESPONSE=$(curl -s -X DELETE -H "apikey: $API_KEY" "$API_URL/instance/delete/$instance_name" 2>/dev/null)
        
        if echo "$DELETE_RESPONSE" | grep -q "deleted\|success" || [ -z "$DELETE_RESPONSE" ]; then
            echo "✅"
        else
            echo "❌"
        fi
        
        sleep 0.5
    fi
done

# Vérification finale
echo ""
log_info "📊 Vérification finale..."
sleep 2

FINAL_INSTANCES=$(curl -s -H "apikey: $API_KEY" "$API_URL/instance/fetchInstances" | jq length 2>/dev/null || echo "0")
log_info "Instances restantes: $FINAL_INSTANCES"

echo ""
log_success "🎉 Nettoyage terminé!"
echo "📊 Résumé: $DELETE_COUNT instances traitées, $FINAL_INSTANCES restantes"
