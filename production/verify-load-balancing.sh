#!/bin/bash

# Script de vérification du load balancing Traefik
# Vérifie que le trafic est bien réparti entre manager et worker

set -e

MANAGER_HOST="89.116.38.18"
SSH_KEY="/Users/ousmanesalamatao/.ssh/id_whatsetter"
SSH_USER="root"
DOMAIN="https://evolution.wazzap.fr"
TEST_COUNT=20

echo "======================================"
echo "🔍 VÉRIFICATION LOAD BALANCING"
echo "======================================"
echo ""

# Étape 1: Vérifier l'état des replicas
echo "📊 === ÉTAPE 1: État des Replicas ==="
ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
    SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
    
    if [ -z "$SERVICE_NAME" ]; then
        echo "❌ Service non trouvé"
        exit 1
    fi
    
    echo "✅ Service: $SERVICE_NAME"
    echo ""
    
    echo "📋 Replicas actifs:"
    docker service ps $SERVICE_NAME --filter "desired-state=running" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
    echo ""
    
    echo "🌐 Mapping IP → Node:"
    TASKS=$(docker service ps $SERVICE_NAME --filter "desired-state=running" --format "{{.Name}}")
    
    for TASK in $TASKS; do
        CONTAINER_ID=$(docker ps -q --filter "name=$TASK" 2>/dev/null)
        if [ ! -z "$CONTAINER_ID" ]; then
            TASK_IP=$(docker inspect $CONTAINER_ID --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
            NODE=$(docker inspect $CONTAINER_ID --format '{{.Config.Hostname}}' 2>/dev/null)
            echo "  - $TASK_IP → $NODE"
        fi
    done
    echo ""
ENDSSH

echo ""
echo "🧪 === ÉTAPE 2: Test de Load Balancing ($TEST_COUNT requêtes) ==="
echo ""

# Créer un fichier temporaire pour stocker les résultats
TEMP_FILE=$(mktemp)

# Faire plusieurs requêtes et capturer les résultats
echo "Envoi de $TEST_COUNT requêtes vers $DOMAIN/..."

for i in $(seq 1 $TEST_COUNT); do
    # Ajouter un header unique pour tracer la requête
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k $DOMAIN/ --max-time 5 -H "X-Request-ID: test-$i" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "401" ] || [ "$HTTP_CODE" == "304" ]; then
        echo "✅" >> $TEMP_FILE
    elif [ "$HTTP_CODE" == "502" ]; then
        echo "❌" >> $TEMP_FILE
    else
        echo "⚠️" >> $TEMP_FILE
    fi
    
    # Petit délai pour ne pas surcharger
    sleep 0.2
done

echo ""
echo "📈 === ÉTAPE 3: Résultats ==="
echo ""

SUCCESS=$(grep -c "✅" $TEMP_FILE || echo "0")
ERRORS_502=$(grep -c "❌" $TEMP_FILE || echo "0")
OTHER=$(grep -c "⚠️" $TEMP_FILE || echo "0")

SUCCESS_PERCENT=$(( SUCCESS * 100 / TEST_COUNT ))

echo "Résumé des tests:"
echo "  ✅ Succès: $SUCCESS/$TEST_COUNT ($SUCCESS_PERCENT%)"
echo "  ❌ Erreurs 502: $ERRORS_502/$TEST_COUNT"
echo "  ⚠️  Autres: $OTHER/$TEST_COUNT"
echo ""

# Nettoyer
rm -f $TEMP_FILE

# Analyser les logs Traefik pour voir la distribution
echo "📊 === ÉTAPE 4: Distribution du Trafic (dernières 50 requêtes) ==="
echo ""

ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
    TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
    
    if [ -z "$TRAEFIK_CONTAINER" ]; then
        echo "❌ Traefik non trouvé"
        exit 0
    fi
    
    echo "Analyse des logs Traefik (backend utilisé)..."
    echo ""
    
    # Extraire les IPs des backends des derniers logs
    BACKEND_IPS=$(docker logs $TRAEFIK_CONTAINER --tail 100 2>&1 | \
                  grep -o '"ServiceAddr":"10.0.1.[0-9]*:8080"' | \
                  sed 's/"ServiceAddr":"//;s:":/' | \
                  sed 's/:8080//' | \
                  tail -50)
    
    if [ -z "$BACKEND_IPS" ]; then
        echo "⚠️  Pas de logs de requêtes récents"
    else
        echo "Distribution des 50 dernières requêtes par backend:"
        echo "$BACKEND_IPS" | sort | uniq -c | while read count ip; do
            percent=$(( count * 100 / 50 ))
            echo "  - $ip : $count requêtes ($percent%)"
        done
        echo ""
        
        # Compter le nombre d'IPs uniques (= nombre de replicas actifs)
        UNIQUE_BACKENDS=$(echo "$BACKEND_IPS" | sort -u | wc -l | tr -d ' ')
        echo "📦 Nombre de replicas actifs détectés: $UNIQUE_BACKENDS"
    fi
ENDSSH

echo ""
echo "🔍 === ÉTAPE 5: Vérification de la Configuration Traefik ==="
echo ""

ssh -i "$SSH_KEY" "$SSH_USER@$MANAGER_HOST" << 'ENDSSH'
    TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
    SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
    
    echo "🔧 Labels Traefik du service:"
    docker service inspect $SERVICE_NAME --format='{{range $key, $value := .Spec.Labels}}{{$key}}={{$value}}{{"\n"}}{{end}}' | grep traefik | head -10
    echo ""
    
    echo "📡 Configuration réseau:"
    docker service inspect $SERVICE_NAME --format='{{range .Spec.TaskTemplate.Networks}}Network: {{.Target}}{{"\n"}}{{end}}'
    echo ""
    
    echo "⚙️  Mode de déploiement:"
    docker service inspect $SERVICE_NAME --format='Mode: {{.Spec.Mode.Replicated.Replicas}} replicas'
    docker service inspect $SERVICE_NAME --format='Placement: {{range .Spec.TaskTemplate.Placement.Preferences}}{{.Spread.SpreadDescriptor}}{{end}}'
ENDSSH

echo ""
echo "======================================"
echo "📋 CONCLUSION"
echo "======================================"
echo ""

if [ $SUCCESS_PERCENT -ge 95 ]; then
    echo "🎉 EXCELLENT! Le load balancing fonctionne parfaitement!"
    echo ""
    echo "✅ Votre configuration est optimale:"
    echo "  - Les 2 replicas répondent correctement"
    echo "  - Traefik distribue le trafic entre manager et worker"
    echo "  - Taux de succès: $SUCCESS_PERCENT%"
    echo ""
elif [ $SUCCESS_PERCENT -ge 50 ]; then
    echo "⚠️  PROBLÈME PARTIEL détecté"
    echo ""
    echo "Un replica semble avoir des problèmes:"
    echo "  - Taux de succès: $SUCCESS_PERCENT%"
    echo "  - Un des 2 replicas ne répond probablement pas"
    echo ""
    echo "Actions recommandées:"
    echo "  1. Vérifiez l'état des replicas:"
    echo "     ssh root@$MANAGER_HOST 'docker service ps \$(docker service ls --filter name=evolution --format \"{{.Name}}\" | head -1)'"
    echo ""
    echo "  2. Consultez les logs du replica défaillant"
    echo ""
    echo "  3. Forcez un rolling update:"
    echo "     ssh root@$MANAGER_HOST 'docker service update --force \$(docker service ls --filter name=evolution --format \"{{.Name}}\" | head -1)'"
else
    echo "🔴 PROBLÈME MAJEUR!"
    echo ""
    echo "Le load balancing ne fonctionne pas correctement:"
    echo "  - Taux de succès: $SUCCESS_PERCENT%"
    echo ""
    echo "Actions immédiates:"
    echo "  1. Vérifiez que le service est bien déployé:"
    echo "     ssh root@$MANAGER_HOST 'docker service ls'"
    echo ""
    echo "  2. Vérifiez les logs Traefik:"
    echo "     ./production/check-traefik-logs.sh"
    echo ""
    echo "  3. Redéployez si nécessaire"
fi

echo ""

