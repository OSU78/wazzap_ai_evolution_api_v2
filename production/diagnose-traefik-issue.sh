#!/bin/bash

# Script de diagnostic approfondi pour le problème Traefik
# Vérifie les labels, la configuration réseau, et les healthchecks

set -e

MANAGER_HOST="89.116.38.18"
SSH_KEY="/Users/ousmanesalamatao/.ssh/id_whatsetter"
SSH_USER="root"

echo "======================================"
echo "🔬 DIAGNOSTIC TRAEFIK APPROFONDI"
echo "======================================"
echo ""

# Fonction pour vérifier les labels du service
check_service_labels() {
    echo "📋 === Inspection des labels du service Evolution API ==="
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        echo "🔍 Recherche du service Evolution API..."
        SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
        
        if [ -z "$SERVICE_NAME" ]; then
            echo "❌ Aucun service Evolution API trouvé"
            exit 1
        fi
        
        echo "✅ Service trouvé: $SERVICE_NAME"
        echo ""
        echo "📌 Labels du service (deploy.labels):"
        docker service inspect $SERVICE_NAME --format='{{json .Spec.Labels}}' | python3 -m json.tool || echo "Erreur lecture labels"
        echo ""
        echo "📌 Labels des tâches (container labels):"
        docker service inspect $SERVICE_NAME --format='{{json .Spec.TaskTemplate.ContainerSpec.Labels}}' | python3 -m json.tool || echo "Pas de labels container"
        echo ""
        
        echo "🔍 Réplicas et placement:"
        docker service ps $SERVICE_NAME --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}\t{{.DesiredState}}\t{{.Error}}"
        echo ""
ENDSSH
    echo ""
}

# Fonction pour vérifier la configuration Traefik
check_traefik_config() {
    echo "⚙️  === Configuration Traefik ==="
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
        
        if [ -z "$TRAEFIK_CONTAINER" ]; then
            echo "❌ Container Traefik non trouvé"
            exit 1
        fi
        
        echo "✅ Container Traefik: $TRAEFIK_CONTAINER"
        echo ""
        
        echo "📡 Providers actifs:"
        docker logs $TRAEFIK_CONTAINER --tail 200 2>&1 | grep -i "provider" | grep -i "configuration" | tail -5
        echo ""
        
        echo "🔴 Erreurs récentes:"
        docker logs $TRAEFIK_CONTAINER --tail 200 2>&1 | grep -i "ERR\|error" | tail -10
        echo ""
        
        echo "🌐 Routers détectés par Traefik:"
        docker logs $TRAEFIK_CONTAINER --tail 500 2>&1 | grep -i "router" | grep -i "evolution" | tail -5
        echo ""
ENDSSH
    echo ""
}

# Fonction pour tester la connectivité réseau
check_network_connectivity() {
    echo "🌐 === Test de connectivité réseau ==="
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        echo "📊 Réseau dokploy-network:"
        docker network inspect dokploy-network --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null || echo "Erreur réseau"
        echo ""
        
        echo "🔍 Test de connectivité depuis Traefik vers Evolution API:"
        TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
        SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
        
        if [ ! -z "$SERVICE_NAME" ]; then
            # Obtenir les IPs des tâches Evolution
            TASK_IPS=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.Name}}" | while read task; do
                docker inspect $(docker ps -q --filter "name=$task") --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null
            done)
            
            echo "IPs des tâches Evolution:"
            echo "$TASK_IPS"
            echo ""
            
            for IP in $TASK_IPS; do
                echo "Test vers $IP:8080..."
                docker exec $TRAEFIK_CONTAINER wget -q -O- --timeout=2 http://$IP:8080/ > /dev/null 2>&1 && echo "✅ $IP:8080 OK" || echo "❌ $IP:8080 FAIL"
            done
        fi
        echo ""
ENDSSH
    echo ""
}

# Fonction pour vérifier les healthchecks
check_healthchecks() {
    echo "🏥 === Vérification des Health Checks ==="
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
        
        if [ ! -z "$SERVICE_NAME" ]; then
            echo "📋 Tâches et leur état de santé:"
            TASKS=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.Name}}")
            
            for TASK in $TASKS; do
                CONTAINER_ID=$(docker ps -q --filter "name=$TASK")
                if [ ! -z "$CONTAINER_ID" ]; then
                    NODE=$(docker inspect $CONTAINER_ID --format '{{.Config.Hostname}}')
                    HEALTH=$(docker inspect $CONTAINER_ID --format '{{.State.Health.Status}}' 2>/dev/null || echo "no healthcheck")
                    echo "  - $TASK ($NODE): $HEALTH"
                fi
            done
        fi
        echo ""
ENDSSH
    echo ""
}

# Fonction pour récupérer la configuration Dokploy
check_dokploy_config() {
    echo "📦 === Configuration Dokploy ==="
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        echo "🔍 Services gérés par Dokploy:"
        docker service ls --format "table {{.Name}}\t{{.Mode}}\t{{.Replicas}}\t{{.Image}}"
        echo ""
        
        echo "📋 Labels Traefik sur Dokploy:"
        DOKPLOY_SERVICE=$(docker service ls --filter name=dokploy --format "{{.Name}}" | grep -v traefik | head -1)
        if [ ! -z "$DOKPLOY_SERVICE" ]; then
            docker service inspect $DOKPLOY_SERVICE --format='{{json .Spec.Labels}}' | python3 -m json.tool 2>/dev/null || echo "Pas de labels"
        fi
        echo ""
ENDSSH
    echo ""
}

# Exécution du diagnostic
check_service_labels
check_traefik_config
check_network_connectivity
check_healthchecks
check_dokploy_config

echo "======================================"
echo "✅ DIAGNOSTIC TERMINÉ"
echo "======================================"
echo ""
echo "🔧 ANALYSE DES PROBLÈMES:"
echo "1. Si vous voyez des labels à la fois dans Spec.Labels ET ContainerSpec.Labels"
echo "   -> C'est la cause de l'erreur 'both Docker and Swarm labels are defined'"
echo ""
echo "2. Si l'erreur 'middleware evo-strip@swarm does not exist' apparaît"
echo "   -> Il faut supprimer la référence à ce middleware dans les labels"
echo ""
echo "3. Si un replica est inaccessible depuis Traefik"
echo "   -> Problème de réseau ou de healthcheck"
echo ""

