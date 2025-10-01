#!/bin/bash

# ========================================
# Script de déploiement Docker Swarm pour Evolution API v2
# ========================================

set -e

echo "🚀 Déploiement de Evolution API v2 avec Docker Swarm"
echo "=================================================="

# Vérifier si Docker Swarm est initialisé
if ! docker info --format '{{.Swarm.LocalNodeState}}' | grep -q "active"; then
    echo "❌ Docker Swarm n'est pas initialisé!"
    echo "Exécutez: docker swarm init --advertise-addr YOUR_IP"
    exit 1
fi

# Créer le réseau si nécessaire
echo "📡 Création du réseau public..."
docker network create --driver=overlay network_public 2>/dev/null || echo "Le réseau existe déjà"

# Créer les volumes externes
echo "💾 Création des volumes..."
docker volume create evolution_swarm_instances 2>/dev/null || echo "Volume instances existe déjà"
docker volume create evolution_swarm_postgres 2>/dev/null || echo "Volume postgres existe déjà"
docker volume create evolution_swarm_redis 2>/dev/null || echo "Volume redis existe déjà"
docker volume create volume_swarm_certificates 2>/dev/null || echo "Volume certificates existe déjà"
docker volume create volume_swarm_traefik_logs 2>/dev/null || echo "Volume traefik logs existe déjà"

# Créer le secret pour PostgreSQL
echo "🔐 Configuration des secrets..."
if ! docker secret ls | grep -q "evolution_postgres_password"; then
    echo "Veuillez entrer le mot de passe PostgreSQL:"
    read -s POSTGRES_PASSWORD
    echo "$POSTGRES_PASSWORD" | docker secret create evolution_postgres_password -
    echo "Secret PostgreSQL créé"
else
    echo "Secret PostgreSQL existe déjà"
fi

# Déployer Traefik
echo "🌐 Déploiement de Traefik..."
if [ -f "traefik.yml" ]; then
    docker stack deploy --prune --resolve-image always -c traefik.yml traefik
    echo "✅ Traefik déployé"
else
    echo "⚠️  Fichier traefik.yml non trouvé, Traefik non déployé"
fi

# Attendre que Traefik soit prêt
echo "⏳ Attente du démarrage de Traefik..."
sleep 10

# Déployer Evolution API
echo "🤖 Déploiement de Evolution API..."
if [ -f "docker-swarm.yml" ]; then
    docker stack deploy --prune --resolve-image always -c docker-swarm.yml evolution
    echo "✅ Evolution API déployée"
else
    echo "❌ Fichier docker-swarm.yml non trouvé!"
    exit 1
fi

echo ""
echo "🎉 Déploiement terminé!"
echo "=================================================="
echo "📊 Vérifiez le statut avec:"
echo "   docker stack ps evolution"
echo "   docker stack ps traefik"
echo ""
echo "📝 Consultez les logs avec:"
echo "   docker service logs evolution_evolution-api"
echo ""
echo "🌐 Accès à l'API: https://your-domain.com"
echo "🔧 Dashboard Traefik: https://traefik.your-domain.com"
echo ""
echo "⚠️  N'oubliez pas de:"
echo "   1. Configurer votre DNS pour pointer vers ce serveur"
echo "   2. Modifier les domaines dans docker-swarm.yml et traefik.yml"
echo "   3. Changer l'email dans traefik.yml pour Let's Encrypt"
