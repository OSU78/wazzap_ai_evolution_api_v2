#!/bin/bash

# ========================================
# Script de Vérification des Variables dans le Conteneur
# ========================================

echo "🐳 Vérification des variables d'environnement dans le conteneur"
echo "=============================================================="

# Vérifier si le conteneur est en cours d'exécution
if ! docker ps | grep -q evolution_api; then
    echo "❌ Le conteneur evolution_api n'est pas en cours d'exécution"
    echo "💡 Démarrez-le avec: docker-compose up -d"
    exit 1
fi

echo "✅ Conteneur evolution_api trouvé"
echo ""

# Fonction pour vérifier une variable dans le conteneur
check_var() {
    local var_name="$1"
    local expected_value="$2"
    local actual_value=$(docker exec evolution_api env | grep "^$var_name=" | cut -d'=' -f2- | head -n1)
    
    if [ -n "$actual_value" ]; then
        # Masquer les valeurs sensibles
        case $var_name in
            *API_KEY*|*SECRET*|*PASSWORD*|*URI*)
                local masked_actual="**********************$(echo "$actual_value" | tail -c 5)"
                local masked_expected="**********************$(echo "$expected_value" | tail -c 5)"
                if [ "$actual_value" = "$expected_value" ]; then
                    echo "✅ $var_name=$masked_actual (CORRECT)"
                else
                    echo "❌ $var_name=$masked_actual (ATTENDU: $masked_expected)"
                fi
                ;;
            *)
                if [ "$actual_value" = "$expected_value" ]; then
                    echo "✅ $var_name=$actual_value (CORRECT)"
                else
                    echo "❌ $var_name=$actual_value (ATTENDU: $expected_value)"
                fi
                ;;
        esac
    else
        echo "❌ $var_name=NON DÉFINIE"
    fi
}

echo "🔍 Vérification des variables importantes:"
echo "=========================================="

# Variables à vérifier (ajustez selon vos besoins)
check_var "SERVER_URL" "http://localhost:8080"
check_var "AUTHENTICATION_API_KEY" "B6D711FCDE4D4FD5936544120E713C37"
check_var "WEBHOOK_GLOBAL_URL" "https://wazzap.ngrok.app/api/webhook/v2/messageHandlers"
check_var "WEBHOOK_GLOBAL_ENABLED" "true"
check_var "WEBHOOK_EVENTS_QRCODE_UPDATED" "true"
check_var "WEBHOOK_EVENTS_SEND_MESSAGE" "true"
check_var "DATABASE_CONNECTION_CLIENT_NAME" "evolution_vps_wazzap_ai"
check_var "CACHE_REDIS_PREFIX_KEY" "evolution_vps_wazzap_ai"

echo ""
echo "🔧 Variables de configuration dans le conteneur:"
echo "=============================================="

# Afficher toutes les variables importantes
docker exec evolution_api env | grep -E "^(SERVER_URL|AUTHENTICATION_API_KEY|WEBHOOK_|DATABASE_|CACHE_)" | sort

echo ""
echo "📋 Comparaison avec le fichier .env local:"
echo "=========================================="

if [ -f ".env" ]; then
    echo "Variables dans votre .env local:"
    grep -E "^(SERVER_URL|AUTHENTICATION_API_KEY|WEBHOOK_GLOBAL_URL)" .env | head -5
else
    echo "❌ Fichier .env local non trouvé"
fi

echo ""
echo "💡 Pour voir toutes les variables du conteneur:"
echo "   docker exec evolution_api env | sort"
echo ""
echo "💡 Pour redémarrer avec vos nouvelles variables:"
echo "   docker-compose down && docker-compose up -d"
