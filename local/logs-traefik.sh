#!/bin/bash

echo "📝 Logs de Traefik (Ctrl+C pour quitter):"
echo "=========================================="

# Vérifier si Traefik est en cours d'exécution
if ! docker ps | grep -q traefik_local; then
    echo "❌ Traefik n'est pas en cours d'exécution"
    echo "💡 Démarrez Traefik avec: ./start-traefik"
    exit 1
fi

echo "🎛️ Traefik Dashboard: http://localhost:8080"
echo "📊 API Traefik: http://localhost:8080/api"
echo ""

# Afficher les logs en temps réel
docker-compose -f local/docker-compose-traefik.yml logs -f traefik
