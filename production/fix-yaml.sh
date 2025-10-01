#!/bin/bash

# ========================================
# Script de Correction YAML - Evolution API
# ========================================

echo "🔧 Correction de l'erreur YAML"
echo "=============================="

# Arrêter les services
echo "🛑 Arrêt des services..."
docker-compose down 2>/dev/null || true

# Sauvegarder le fichier original
echo "💾 Sauvegarde du fichier original..."
cp docker-compose.yml docker-compose.yml.backup

# Corriger la ligne problématique (JWT_SECRET)
echo "🔧 Correction du JWT_SECRET..."
sed -i 's/AUTHENTICATION_JWT_SECRET: ${JWT_SECRET:-L=0YWt\]b2w\[WF>#>:&CWOMH2c<;Kn95jH}/AUTHENTICATION_JWT_SECRET: "L0YWtb2wWF-CWOMH2c-Kn95jH-SECURE"/g' docker-compose.yml

# Vérifier d'autres problèmes potentiels
echo "🔍 Vérification des autres caractères spéciaux..."

# Corriger les autres variables avec caractères spéciaux si nécessaire
sed -i 's/CORS_ORIGIN: \*/CORS_ORIGIN: "*"/g' docker-compose.yml

# Vérifier la syntaxe YAML
echo "✅ Vérification de la syntaxe YAML..."
if docker-compose config > /dev/null 2>&1; then
    echo "✅ Fichier YAML valide"
else
    echo "❌ Erreur YAML persistante, affichage des détails :"
    docker-compose config
    echo ""
    echo "💡 Restauration du fichier original..."
    cp docker-compose.yml.backup docker-compose.yml
    exit 1
fi

# Redémarrer les services
echo "🚀 Redémarrage des services..."
docker-compose up -d

# Attendre que l'API soit prête
echo "⏳ Attente de l'API (60 secondes)..."
sleep 60

# Test final
echo "🧪 Test de l'API..."
if curl -s https://evolution.wazzap.fr/ | grep -q "Welcome"; then
    echo "✅ API Evolution accessible !"
    echo "🌐 https://evolution.wazzap.fr"
    echo "🎛️ Dashboard: https://traefik.evolution.wazzap.fr"
    echo "🔑 Clé API: B6D711FCDE4D4FD5936544120E713C37"
else
    echo "⚠️ API pas encore prête"
    echo "📝 Vérifiez les logs :"
    echo "   docker-compose logs evolution-api"
fi

echo ""
echo "✅ Correction terminée !"
echo ""
echo "📋 Commandes utiles :"
echo "   docker-compose ps                    # Status"
echo "   docker-compose logs -f evolution-api # Logs"
echo "   docker-compose restart evolution-api # Redémarrer"
