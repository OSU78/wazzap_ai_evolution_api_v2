#!/bin/bash

# ========================================
# Script de Test des Variables d'Environnement
# ========================================

echo "🧪 Test des variables d'environnement"
echo "====================================="

# Vérifier si le fichier .env existe
if [ -f ".env" ]; then
    echo "✅ Fichier .env trouvé"
    echo "📄 Taille: $(du -h .env | cut -f1)"
    echo "📊 Lignes: $(wc -l < .env)"
else
    echo "❌ Fichier .env non trouvé!"
    exit 1
fi

echo ""
echo "🔍 Variables importantes dans .env:"
echo "=================================="

# Fonction pour afficher une variable de manière sécurisée
show_var() {
    local var_name="$1"
    local var_value=$(grep "^$var_name=" .env | cut -d'=' -f2- | head -n1)
    
    if [ -n "$var_value" ]; then
        # Masquer les valeurs sensibles
        case $var_name in
            *API_KEY*|*SECRET*|*PASSWORD*|*URI*)
                echo "🔐 $var_name=**********************$(echo "$var_value" | tail -c 5)"
                ;;
            *)
                echo "📝 $var_name=$var_value"
                ;;
        esac
    else
        echo "❌ $var_name=NON DÉFINIE"
    fi
}

# Variables importantes à vérifier
show_var "SERVER_URL"
show_var "AUTHENTICATION_API_KEY"
show_var "DATABASE_CONNECTION_URI"
show_var "CACHE_REDIS_URI"
show_var "WEBHOOK_GLOBAL_URL"
show_var "WEBHOOK_GLOBAL_ENABLED"
show_var "LOG_LEVEL"

echo ""
echo "🐳 Test Docker Compose:"
echo "======================="

# Test de validation du fichier docker-compose.yml
if docker-compose config >/dev/null 2>&1; then
    echo "✅ docker-compose.yml valide"
else
    echo "❌ Erreur dans docker-compose.yml:"
    docker-compose config
    exit 1
fi

# Afficher les variables que Docker Compose va utiliser
echo ""
echo "🔧 Variables que Docker Compose va utiliser:"
echo "==========================================="

docker-compose config --services | while read service; do
    echo "📦 Service: $service"
    # Afficher quelques variables importantes
    docker-compose config | grep -A 5 -B 5 "AUTHENTICATION_API_KEY\|SERVER_URL\|WEBHOOK_GLOBAL_URL" | head -20
    break  # Juste le premier service pour ne pas polluer
done

echo ""
echo "✅ Test terminé!"
echo ""
echo "💡 Pour démarrer avec debug:"
echo "   docker-compose up --build"
echo ""
echo "💡 Pour voir les variables d'environnement dans le conteneur:"
echo "   docker-compose exec evolution-api env | grep -E 'SERVER_URL|API_KEY|WEBHOOK'"
