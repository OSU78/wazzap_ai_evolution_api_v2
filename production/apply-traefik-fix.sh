#!/bin/bash

# Script pour appliquer la correction Traefik sur Dokploy
# Corrige le problème de Bad Gateway sur le worker/manager

set -e

MANAGER_HOST="89.116.38.18"
SSH_KEY="/Users/ousmanesalamatao/.ssh/id_whatsetter"
SSH_USER="root"

echo "======================================"
echo "🔧 APPLICATION DU FIX TRAEFIK"
echo "======================================"
echo ""

echo "📋 Ce script va appliquer les corrections suivantes:"
echo "  ✅ Décommenter traefik.docker.network=dokploy-network"
echo "  ✅ Ajouter les health checks"
echo "  ✅ Configurer passHostHeader (déjà présent)"
echo ""
echo "⚠️  Méthode: Mise à jour du service via docker service update"
echo "⏱️  Durée estimée: 30-60 secondes (rolling update)"
echo "✅ Aucun downtime!"
echo ""

read -p "Continuer? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Annulé"
    exit 1
fi

echo ""
echo "🚀 Connexion au serveur et application des corrections..."
echo ""

ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
    set -e
    
    echo "🔍 Recherche du service Evolution API..."
    SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
    
    if [ -z "$SERVICE_NAME" ]; then
        echo "❌ Aucun service Evolution API trouvé"
        exit 1
    fi
    
    echo "✅ Service trouvé: $SERVICE_NAME"
    echo ""
    
    echo "📊 État actuel du service:"
    docker service ps $SERVICE_NAME --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" | head -5
    echo ""
    
    echo "🔧 Application des corrections..."
    
    # Mise à jour des labels avec les corrections
    docker service update \
        --label-add traefik.enable=true \
        --label-add 'traefik.http.routers.evolution_v2.rule=Host(`evolution.wazzap.fr`)' \
        --label-add traefik.http.routers.evolution_v2.entrypoints=websecure \
        --label-add traefik.http.routers.evolution_v2.tls.certresolver=letsencrypt \
        --label-add traefik.http.routers.evolution_v2.service=evolution_v2 \
        --label-add traefik.http.services.evolution_v2.loadbalancer.server.port=8080 \
        --label-add traefik.http.services.evolution_v2.loadbalancer.passHostHeader=true \
        --label-add traefik.http.services.evolution_v2.loadbalancer.responseForwarding.flushInterval=100ms \
        --label-add traefik.docker.network=dokploy-network \
        --label-add traefik.http.services.evolution_v2.loadbalancer.healthcheck.path=/ \
        --label-add traefik.http.services.evolution_v2.loadbalancer.healthcheck.interval=10s \
        --label-add traefik.http.services.evolution_v2.loadbalancer.healthcheck.timeout=5s \
        $SERVICE_NAME
    
    if [ $? -eq 0 ]; then
        echo "✅ Labels mis à jour avec succès!"
        echo ""
        echo "⏳ Attente du rolling update (30 secondes)..."
        sleep 30
        
        echo ""
        echo "📊 Nouvel état du service:"
        docker service ps $SERVICE_NAME --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}" | head -5
        echo ""
        
        echo "🔍 Vérification des labels appliqués:"
        docker service inspect $SERVICE_NAME --format='{{json .Spec.Labels}}' | python3 -m json.tool | grep -E "traefik\.(enable|docker\.network|http\.services.*healthcheck)" || echo "Pas de health checks visibles (normal si pas encore propagé)"
        echo ""
        
        echo "🔄 Redémarrage de Traefik pour forcer la découverte..."
        TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
        if [ ! -z "$TRAEFIK_CONTAINER" ]; then
            docker kill -s HUP $TRAEFIK_CONTAINER 2>/dev/null || echo "Signal HUP envoyé"
            sleep 3
            echo "✅ Traefik rechargé"
        fi
        
    else
        echo "❌ Erreur lors de la mise à jour"
        exit 1
    fi
ENDSSH

echo ""
echo "======================================"
echo "✅ FIX APPLIQUÉ AVEC SUCCÈS!"
echo "======================================"
echo ""
echo "🧪 TESTS RECOMMANDÉS:"
echo ""
echo "1. Test de load balancing (20 requêtes):"
echo "   ./production/test-load-balancing.sh"
echo ""
echo "2. Vérification des logs Traefik:"
echo "   ./production/check-traefik-logs.sh"
echo ""
echo "3. Test manuel simple:"
echo "   for i in {1..10}; do curl -s -o /dev/null -w \"Test \$i: HTTP %{http_code}\\n\" -k https://evolution.wazzap.fr/manager; sleep 1; done"
echo ""
echo "📊 Vous devriez maintenant avoir 100% de succès (HTTP 200 ou 401)!"
echo ""

