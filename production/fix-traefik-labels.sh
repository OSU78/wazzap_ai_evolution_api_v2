#!/bin/bash

# Script pour corriger les labels Traefik sur le service Evolution API
# Résout le problème "both Docker and Swarm labels are defined"

set -e

MANAGER_HOST="89.116.38.18"
SSH_KEY="/Users/ousmanesalamatao/.ssh/id_whatsetter"
SSH_USER="root"

echo "======================================"
echo "🔧 CORRECTION DES LABELS TRAEFIK"
echo "======================================"
echo ""

# Fonction pour nettoyer et recréer le service avec les bons labels
fix_service_labels() {
    echo "🔍 Recherche et correction du service Evolution API..."
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
        
        if [ -z "$SERVICE_NAME" ]; then
            echo "❌ Aucun service Evolution API trouvé"
            exit 1
        fi
        
        echo "✅ Service trouvé: $SERVICE_NAME"
        echo ""
        
        # Récupérer l'image actuelle
        IMAGE=$(docker service inspect $SERVICE_NAME --format='{{.Spec.TaskTemplate.ContainerSpec.Image}}')
        echo "📦 Image: $IMAGE"
        
        # Récupérer le réseau
        NETWORK=$(docker service inspect $SERVICE_NAME --format='{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}')
        echo "🌐 Réseau: $NETWORK"
        
        # Récupérer les variables d'environnement
        echo "💾 Sauvegarde des variables d'environnement..."
        docker service inspect $SERVICE_NAME --format='{{range .Spec.TaskTemplate.ContainerSpec.Env}}{{println .}}{{end}}' > /tmp/evolution_env_backup.txt
        
        echo ""
        echo "⚠️  ATTENTION: Le service va être mis à jour avec les labels corrects"
        echo "Cette opération ne causera pas de downtime grâce au rolling update"
        echo ""
        
        # Supprimer TOUS les labels existants
        echo "🧹 Nettoyage des anciens labels..."
        docker service update --label-rm traefik.enable $SERVICE_NAME 2>/dev/null || true
        docker service update --label-rm traefik.http.routers.evolution_v2.rule $SERVICE_NAME 2>/dev/null || true
        docker service update --label-rm traefik.http.routers.evolution_v2.entrypoints $SERVICE_NAME 2>/dev/null || true
        docker service update --label-rm traefik.http.routers.evolution_v2.tls.certresolver $SERVICE_NAME 2>/dev/null || true
        docker service update --label-rm traefik.http.routers.evolution_v2.service $SERVICE_NAME 2>/dev/null || true
        docker service update --label-rm traefik.http.services.evolution_v2.loadbalancer.server.port $SERVICE_NAME 2>/dev/null || true
        docker service update --label-rm traefik.http.services.evolution_v2.loadbalancer.passHostHeader $SERVICE_NAME 2>/dev/null || true
        docker service update --label-rm traefik.http.services.evolution_v2.loadbalancer.responseForwarding.flushInterval $SERVICE_NAME 2>/dev/null || true
        
        # Supprimer les labels de container (si présents)
        docker service update --container-label-rm traefik.enable $SERVICE_NAME 2>/dev/null || true
        docker service update --container-label-rm traefik.http.routers.evolution_v2.rule $SERVICE_NAME 2>/dev/null || true
        
        echo "✅ Labels nettoyés"
        echo ""
        
        # Ajouter les nouveaux labels corrects (UNIQUEMENT au niveau service)
        echo "✨ Ajout des nouveaux labels Traefik..."
        docker service update \
            --label-add traefik.enable=true \
            --label-add "traefik.http.routers.evolution_v2.rule=Host(\`evolution.wazzap.fr\`)" \
            --label-add traefik.http.routers.evolution_v2.entrypoints=websecure \
            --label-add traefik.http.routers.evolution_v2.tls.certresolver=letsencrypt \
            --label-add traefik.http.routers.evolution_v2.service=evolution_v2 \
            --label-add traefik.http.services.evolution_v2.loadbalancer.server.port=8080 \
            --label-add traefik.http.services.evolution_v2.loadbalancer.passHostHeader=true \
            --label-add traefik.http.services.evolution_v2.loadbalancer.responseForwarding.flushInterval=100ms \
            --label-add traefik.docker.network=dokploy-network \
            $SERVICE_NAME
        
        if [ $? -eq 0 ]; then
            echo "✅ Labels mis à jour avec succès!"
            echo ""
            echo "📊 Vérification du déploiement..."
            sleep 5
            docker service ps $SERVICE_NAME --filter "desired-state=running" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
        else
            echo "❌ Erreur lors de la mise à jour des labels"
            exit 1
        fi
ENDSSH
    echo ""
}

# Fonction pour redémarrer Traefik pour qu'il recharge la configuration
restart_traefik() {
    echo "🔄 Redémarrage de Traefik pour recharger la configuration..."
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
        
        if [ ! -z "$TRAEFIK_CONTAINER" ]; then
            # Forcer Traefik à recharger sa configuration
            docker kill -s HUP $TRAEFIK_CONTAINER 2>/dev/null || docker restart $TRAEFIK_CONTAINER
            echo "✅ Traefik redémarré"
            sleep 3
        else
            echo "⚠️  Container Traefik non trouvé"
        fi
ENDSSH
    echo ""
}

# Fonction de vérification post-correction
verify_fix() {
    echo "✅ === Vérification de la correction ==="
    ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
        SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
        TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
        
        echo "📋 Nouveaux labels du service:"
        docker service inspect $SERVICE_NAME --format='{{json .Spec.Labels}}' | python3 -m json.tool
        echo ""
        
        echo "🔍 Erreurs Traefik (dernières 20 lignes):"
        docker logs $TRAEFIK_CONTAINER --tail 20 2>&1 | grep -i "ERR\|error" || echo "✅ Aucune erreur détectée"
        echo ""
        
        echo "🌐 Test de connectivité:"
        for i in {1..5}; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" -k https://evolution.wazzap.fr/manager 2>/dev/null || echo "000")
            echo "  Tentative $i: HTTP $STATUS"
            sleep 1
        done
ENDSSH
    echo ""
}

# Exécution
echo "Ce script va:"
echo "1. Nettoyer tous les labels Traefik existants"
echo "2. Ajouter les labels corrects UNIQUEMENT au niveau service (Swarm)"
echo "3. Redémarrer Traefik pour recharger la configuration"
echo "4. Vérifier que tout fonctionne"
echo ""
read -p "Continuer? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Annulé"
    exit 1
fi

fix_service_labels
restart_traefik
verify_fix

echo "======================================"
echo "✅ CORRECTION TERMINÉE"
echo "======================================"
echo ""
echo "🧪 Testez maintenant votre service:"
echo "curl -k https://evolution.wazzap.fr/manager"
echo ""
echo "Si le problème persiste, lancez le diagnostic:"
echo "./production/diagnose-traefik-issue.sh"
echo ""

