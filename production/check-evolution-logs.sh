#!/bin/bash

# Script pour vérifier les logs Evolution API sur le manager et worker
# Pour diagnostiquer les erreurs 502

set -e

MANAGER_HOST="89.116.38.18"
SSH_KEY="/Users/ousmanesalamatao/.ssh/id_whatsetter"
SSH_USER="root"

echo "======================================"
echo "🔍 Vérification des logs Evolution API"
echo "======================================"
echo ""

# Fonction pour afficher les logs Evolution
check_evolution_logs() {
    echo "📊 === Logs Evolution API ==="
    
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        echo "Node: $(hostname)"
        echo "---"
        
        # Trouver le service Evolution API
        SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
        
        if [ -z "$SERVICE_NAME" ]; then
            echo "⚠️  Aucun service Evolution trouvé"
            echo ""
            echo "Services Docker Swarm actifs:"
            docker service ls
        else
            echo "📦 Service Evolution trouvé: $SERVICE_NAME"
            echo ""
            
            # État des réplicas
            echo "📍 État des réplicas:"
            docker service ps $SERVICE_NAME --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}\t{{.Error}}"
            echo ""
            
            # Logs du service (dernières 50 lignes)
            echo "📝 Logs récents du service (50 lignes):"
            docker service logs $SERVICE_NAME --tail 50 --timestamps 2>&1
            echo ""
            
            # Recherche d'erreurs spécifiques
            echo "🔴 Erreurs récentes:"
            docker service logs $SERVICE_NAME --tail 200 2>&1 | grep -i "error\|exception\|failed\|timeout" | tail -10 || echo "Aucune erreur trouvée"
        fi
ENDSSH
    
    echo ""
}

# Fonction pour vérifier la santé des containers
check_containers_health() {
    echo "🏥 === État de santé des containers ==="
    
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        echo "Containers Evolution sur ce node:"
        docker ps --filter "name=evolution" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        
        # Vérifier la connectivité de chaque container
        echo "🔌 Test de connectivité des containers:"
        for container in $(docker ps --filter "name=evolution" --format "{{.Names}}"); do
            echo "Container: $container"
            
            # Vérifier si le port 8080 répond
            CONTAINER_IP=$(docker inspect $container --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
            echo "  IP: $CONTAINER_IP"
            
            # Test HTTP simple
            docker exec $container wget -q -O- http://localhost:8080/health 2>/dev/null && echo "  ✅ Health check OK" || echo "  ❌ Health check FAILED"
            echo ""
        done
ENDSSH
    
    echo ""
}

# Exécution
check_evolution_logs
check_containers_health

echo "======================================"
echo "✅ Vérification terminée"
echo "======================================"


