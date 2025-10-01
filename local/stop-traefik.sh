#!/bin/bash

echo "🛑 Arrêt de Evolution API v2 avec Traefik..."
docker-compose -f docker-compose-traefik.yml down

echo ""
echo "✅ Services arrêtés!"
echo ""
echo "💡 Note: Les entrées /etc/hosts restent configurées"
echo "   (evolution.localhost et api.localhost)"
echo ""
echo "🧹 Pour nettoyer complètement (optionnel):"
echo "   docker-compose -f docker-compose-traefik.yml down -v  # Supprime aussi les volumes"
echo "   docker system prune -f                               # Nettoie Docker"
