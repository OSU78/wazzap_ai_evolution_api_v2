#!/bin/bash

echo "🛑 Arrêt de Evolution API v2..."
docker-compose down

echo "✅ Services arrêtés!"
echo ""
echo "🧹 Pour nettoyer complètement (optionnel):"
echo "   docker-compose down -v  # Supprime aussi les volumes"
echo "   docker system prune -f  # Nettoie Docker"
