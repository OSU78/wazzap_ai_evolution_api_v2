#!/bin/bash

# Script pour surveiller en temps réel les logs et détecter les erreurs 502
# Utile pour reproduire le problème intermittent

set -e

MANAGER_HOST="89.116.38.18"
SSH_KEY="/Users/ousmanesalamatao/.ssh/id_whatsetter"
SSH_USER="root"

echo "======================================"
echo "📡 Surveillance en temps réel"
echo "======================================"
echo ""
echo "Appuyez sur Ctrl+C pour arrêter"
echo ""

# Surveillance en temps réel
ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
    # Trouver le container Traefik
    TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
    
    # Trouver le service Evolution
    SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
    
    echo "🔍 Surveillance active..."
    echo "  Traefik: $TRAEFIK_CONTAINER"
    echo "  Service: $SERVICE_NAME"
    echo ""
    echo "--- Logs en temps réel (filtrés sur erreurs) ---"
    echo ""
    
    # Surveiller les logs en temps réel
    (
        if [ ! -z "$TRAEFIK_CONTAINER" ]; then
            docker logs -f $TRAEFIK_CONTAINER 2>&1 | grep --line-buffered -i "502\|bad gateway\|error\|timeout" | sed 's/^/[TRAEFIK] /' &
        fi
        
        if [ ! -z "$SERVICE_NAME" ]; then
            docker service logs -f $SERVICE_NAME 2>&1 | grep --line-buffered -i "error\|exception\|timeout\|failed" | sed 's/^/[EVOLUTION] /' &
        fi
        
        wait
    )
ENDSSH


