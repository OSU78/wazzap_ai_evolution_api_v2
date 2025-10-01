#!/bin/bash

# ========================================
# Nettoyage des Instances - Préserve TEST4
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

echo "🧹 Nettoyage des Instances Evolution API"
echo "======================================="
echo "⚠️  Ce script supprime TOUTES les instances SAUF 'TEST4'"
echo ""

# Récupérer toutes les instances
log_info "Récupération de la liste des instances..."
INSTANCES_JSON=$(curl -s -H "apikey: $API_KEY" "$API_URL/instance/fetchInstances" 2>/dev/null)

if [ -z "$INSTANCES_JSON" ] || [ "$INSTANCES_JSON" = "null" ]; then
    log_error "Impossible de récupérer les instances!"
    exit 1
fi

# Compter les instances
TOTAL_INSTANCES=$(echo "$INSTANCES_JSON" | jq length 2>/dev/null || echo "0")
log_info "Total instances trouvées: $TOTAL_INSTANCES"

if [ "$TOTAL_INSTANCES" -eq 0 ]; then
    log_info "Aucune instance à supprimer"
    exit 0
fi

# Lister les instances avec détails
echo ""
echo "📋 INSTANCES DÉTECTÉES:"
echo "====================="
echo "$INSTANCES_JSON" | jq -r '.[] | "• \(.name) (Status: \(.connectionStatus), ID: \(.id[0:8])...)"' 2>/dev/null || echo "Erreur parsing JSON"

# Identifier les instances à supprimer (toutes sauf TEST4)
INSTANCES_TO_DELETE=$(echo "$INSTANCES_JSON" | jq -r '.[] | select(.name != "TEST4") | .name' 2>/dev/null)
INSTANCES_TO_PRESERVE=$(echo "$INSTANCES_JSON" | jq -r '.[] | select(.name == "TEST4") | .name' 2>/dev/null)

# Compter
DELETE_COUNT=$(echo "$INSTANCES_TO_DELETE" | wc -l | tr -d ' ')
PRESERVE_COUNT=$(echo "$INSTANCES_TO_PRESERVE" | wc -l | tr -d ' ')

# Si INSTANCES_TO_DELETE est vide, DELETE_COUNT sera 1 (ligne vide), on corrige
if [ -z "$INSTANCES_TO_DELETE" ]; then
    DELETE_COUNT=0
fi

echo ""
echo "📊 ANALYSE:"
log_success "Instances à préserver: $PRESERVE_COUNT (TEST4)"
log_warning "Instances à supprimer: $DELETE_COUNT"

if [ "$DELETE_COUNT" -eq 0 ]; then
    log_info "Aucune instance à supprimer (seul TEST4 existe)"
    exit 0
fi

# Afficher les instances à supprimer
echo ""
echo "🗑️  INSTANCES À SUPPRIMER:"
echo "========================"
if [ ! -z "$INSTANCES_TO_DELETE" ]; then
    echo "$INSTANCES_TO_DELETE" | while read instance_name; do
        if [ ! -z "$instance_name" ]; then
            echo "   • $instance_name"
        fi
    done
else
    echo "   (Aucune)"
fi

# Afficher les instances préservées
echo ""
echo "🛡️  INSTANCES PRÉSERVÉES:"
echo "======================="
if [ ! -z "$INSTANCES_TO_PRESERVE" ]; then
    echo "$INSTANCES_TO_PRESERVE" | while read instance_name; do
        if [ ! -z "$instance_name" ]; then
            echo "   • $instance_name ✅"
        fi
    done
else
    echo "   (Aucune instance TEST4 trouvée)"
fi

# Confirmation
echo ""
log_warning "⚠️  ATTENTION: Vous allez supprimer $DELETE_COUNT instances"
log_warning "   TEST4 sera préservée"
echo ""
echo "Continuer? (y/N)"
read -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Nettoyage annulé"
    exit 0
fi

# Nettoyage
log_info "🗑️  Début du nettoyage..."
DELETED_COUNT=0
ERROR_COUNT=0

if [ ! -z "$INSTANCES_TO_DELETE" ]; then
    echo "$INSTANCES_TO_DELETE" | while read instance_name; do
        if [ ! -z "$instance_name" ]; then
            echo -n "   Suppression $instance_name... "
            
            DELETE_RESPONSE=$(curl -s -X DELETE -H "apikey: $API_KEY" "$API_URL/instance/delete/$instance_name" 2>/dev/null)
            
            # Vérifier si la suppression a réussi
            if echo "$DELETE_RESPONSE" | grep -q "deleted\|success" || [ -z "$DELETE_RESPONSE" ]; then
                echo "✅"
                # Note: Dans un sous-shell, on ne peut pas modifier les variables du parent
            else
                echo "❌ ($(echo "$DELETE_RESPONSE" | jq -r '.message // .error // "Erreur inconnue"' 2>/dev/null || echo "Erreur"))"
            fi
            
            sleep 0.5  # Éviter de surcharger l'API
        fi
    done
fi

# Vérification finale
echo ""
log_info "📊 Vérification finale..."
sleep 2  # Laisser le temps aux suppressions de se propager

FINAL_INSTANCES_JSON=$(curl -s -H "apikey: $API_KEY" "$API_URL/instance/fetchInstances" 2>/dev/null)
FINAL_COUNT=$(echo "$FINAL_INSTANCES_JSON" | jq length 2>/dev/null || echo "0")
TEST4_EXISTS=$(echo "$FINAL_INSTANCES_JSON" | jq -r '.[] | select(.name == "TEST4") | .name' 2>/dev/null)

echo "Instances restantes: $FINAL_COUNT"

if [ ! -z "$TEST4_EXISTS" ]; then
    log_success "✅ TEST4 préservée avec succès"
else
    log_warning "⚠️  TEST4 non trouvée (peut-être n'existait pas)"
fi

# Lister les instances restantes
if [ "$FINAL_COUNT" -gt 0 ]; then
    echo ""
    echo "📋 INSTANCES RESTANTES:"
    echo "====================="
    echo "$FINAL_INSTANCES_JSON" | jq -r '.[] | "• \(.name) (Status: \(.connectionStatus))"' 2>/dev/null || echo "Erreur parsing"
fi

# Statistiques
DELETED_ACTUAL=$((TOTAL_INSTANCES - FINAL_COUNT))

echo ""
echo "📊 RÉSUMÉ DU NETTOYAGE"
echo "===================="
log_info "Instances initiales: $TOTAL_INSTANCES"
log_info "Instances supprimées: $DELETED_ACTUAL"
log_info "Instances restantes: $FINAL_COUNT"

if [ ! -z "$TEST4_EXISTS" ]; then
    log_success "🛡️  TEST4 préservée comme demandé"
fi

echo ""
log_success "🎉 Nettoyage terminé!"

# Proposer de vérifier TEST4
if [ ! -z "$TEST4_EXISTS" ]; then
    echo ""
    echo "🔍 Voulez-vous vérifier l'état de TEST4? (y/N)"
    read -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "📱 Informations sur TEST4:"
        echo "$FINAL_INSTANCES_JSON" | jq '.[] | select(.name == "TEST4")' 2>/dev/null || echo "Erreur"
    fi
fi
