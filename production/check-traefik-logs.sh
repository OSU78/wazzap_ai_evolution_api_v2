#!/bin/bash

# Script pour vérifier les logs Traefik sur le manager et worker
# Pour diagnostiquer les erreurs 502

set -e

MANAGER_HOST="89.116.38.18"
SSH_KEY="/Users/ousmanesalamatao/.ssh/id_whatsetter"
SSH_USER="root"

echo "======================================"
echo "🔍 Vérification des logs Traefik"
echo "======================================"
echo ""

# Fonction pour afficher les logs Traefik
check_traefik_logs() {
    local node_type=$1
    echo "📊 === Logs Traefik ($node_type) ==="
    
    if [ "$node_type" = "MANAGER" ]; then
        ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
            echo "Node: $(hostname)"
            echo "---"
            
            # Vérifier si Traefik existe dans Dokploy
            TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
            
            if [ -z "$TRAEFIK_CONTAINER" ]; then
                echo "⚠️  Aucun container Traefik trouvé"
            else
                echo "📦 Container Traefik trouvé: $TRAEFIK_CONTAINER"
                echo ""
                echo "🔴 Dernières erreurs 502:"
                docker logs $TRAEFIK_CONTAINER --tail 100 2>&1 | grep -i "502\|bad gateway\|error" || echo "Aucune erreur 502 récente"
                echo ""
                echo "📝 Derniers logs (20 lignes):"
                docker logs $TRAEFIK_CONTAINER --tail 20 2>&1
            fi
ENDSSH
    fi
    
    echo ""
}

# Fonction pour vérifier la configuration réseau
check_network() {
    echo "🌐 === Vérification réseau dokploy-network ==="
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        echo "Réseau dokploy-network:"
        docker network inspect dokploy-network --format '{{json .}}' 2>/dev/null | grep -o '"Name":"[^"]*"' | head -5 || echo "Réseau non trouvé"
        echo ""
        
        echo "Services sur dokploy-network:"
        docker network inspect dokploy-network -f '{{range $key, $value := .Containers}}{{$value.Name}} ({{$value.IPv4Address}}){{"\n"}}{{end}}' 2>/dev/null || echo "Aucun service"
ENDSSH
    echo ""
}

# Fonction pour vérifier les services Evolution API
check_evolution_services() {
    echo "🚀 === Services Evolution API ==="
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        echo "Services actifs:"
        docker service ls | grep evolution || echo "Aucun service evolution"
        echo ""
        
        echo "Détails du service evolution-api (si existe):"
        SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
        if [ ! -z "$SERVICE_NAME" ]; then
            echo "Service: $SERVICE_NAME"
            docker service ps $SERVICE_NAME --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
        fi
ENDSSH
    echo ""
}

# Exécution
check_traefik_logs "MANAGER"
check_network
check_evolution_services

echo "======================================"
echo "✅ Vérification terminée"
echo "======================================"


