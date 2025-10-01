#!/bin/bash

# ========================================
# Monitoring en Temps Réel pendant Test de Charge
# ========================================

API_URL="https://evolution.wazzap.fr"
API_KEY="B6D711FCDE4D4FD5936544120E713C37"

echo "📊 Monitoring en Temps Réel - Test de Charge"
echo "==========================================="
echo "⏰ Démarrage du monitoring (Ctrl+C pour arrêter)"
echo ""

# Fonction de monitoring
monitor_loop() {
    local counter=1
    
    while true; do
        clear
        echo "📊 Monitoring Evolution API - Cycle #$counter"
        echo "============================================="
        echo "⏰ $(date)"
        echo ""
        
        # 1. Instances WhatsApp
        echo "📱 INSTANCES WHATSAPP"
        echo "-------------------"
        INSTANCES_COUNT=$(curl -s -H "apikey: $API_KEY" "$API_URL/instance/fetchInstances" | jq length 2>/dev/null || echo "Erreur")
        echo "Total instances: $INSTANCES_COUNT"
        
        # Compter par status
        if [ "$INSTANCES_COUNT" != "Erreur" ] && [ "$INSTANCES_COUNT" -gt 0 ]; then
            CONNECTED=$(curl -s -H "apikey: $API_KEY" "$API_URL/instance/fetchInstances" | jq '[.[] | select(.connectionStatus=="open")] | length' 2>/dev/null || echo "0")
            CONNECTING=$(curl -s -H "apikey: $API_KEY" "$API_URL/instance/fetchInstances" | jq '[.[] | select(.connectionStatus=="connecting")] | length' 2>/dev/null || echo "0")
            CLOSED=$(curl -s -H "apikey: $API_KEY" "$API_URL/instance/fetchInstances" | jq '[.[] | select(.connectionStatus=="close")] | length' 2>/dev/null || echo "0")
            
            echo "  • Connectées: $CONNECTED"
            echo "  • En connexion: $CONNECTING"  
            echo "  • Fermées: $CLOSED"
        fi
        
        echo ""
        
        # 2. Ressources Système
        echo "💾 RESSOURCES SYSTÈME"
        echo "-------------------"
        
        # RAM
        if command -v free &> /dev/null; then
            RAM_INFO=$(free -h | grep "Mem:")
            RAM_USED=$(echo $RAM_INFO | awk '{print $3}')
            RAM_TOTAL=$(echo $RAM_INFO | awk '{print $2}')
            RAM_PERCENT=$(free | grep "Mem:" | awk '{printf "%.1f", $3/$2 * 100.0}')
            echo "RAM: $RAM_USED / $RAM_TOTAL ($RAM_PERCENT%)"
        fi
        
        # CPU
        if command -v top &> /dev/null; then
            CPU_USAGE=$(top -b -n1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
            echo "CPU: $CPU_USAGE%"
        fi
        
        # Disque
        DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
        echo "Disque: $DISK_USAGE%"
        
        echo ""
        
        # 3. Conteneurs Docker
        echo "🐳 CONTENEURS DOCKER"
        echo "------------------"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
        
        echo ""
        
        # 4. Performance API
        echo "⚡ PERFORMANCE API"
        echo "----------------"
        
        # Test de temps de réponse
        START_TIME=$(date +%s%N)
        API_RESPONSE=$(curl -s -w "%{http_code}" -H "apikey: $API_KEY" "$API_URL/" -o /dev/null)
        END_TIME=$(date +%s%N)
        RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))  # en millisecondes
        
        if [ "$API_RESPONSE" = "200" ]; then
            echo "Status: ✅ OK (${RESPONSE_TIME}ms)"
        else
            echo "Status: ❌ Erreur $API_RESPONSE"
        fi
        
        # Test Traefik
        TRAEFIK_STATUS=$(curl -s -w "%{http_code}" "http://localhost:8080/api/http/services" -o /dev/null 2>/dev/null || echo "Erreur")
        echo "Traefik: $([ "$TRAEFIK_STATUS" = "200" ] && echo "✅ OK" || echo "❌ $TRAEFIK_STATUS")"
        
        echo ""
        
        # 5. Alertes
        echo "🚨 ALERTES"
        echo "--------"
        
        # Alertes RAM
        if [ "${RAM_PERCENT%.*}" -gt 90 ] 2>/dev/null; then
            echo "⚠️  RAM critique: $RAM_PERCENT%"
        elif [ "${RAM_PERCENT%.*}" -gt 80 ] 2>/dev/null; then
            echo "⚠️  RAM élevée: $RAM_PERCENT%"
        else
            echo "✅ RAM OK: $RAM_PERCENT%"
        fi
        
        # Alertes CPU
        if [ "${CPU_USAGE%.*}" -gt 90 ] 2>/dev/null; then
            echo "⚠️  CPU critique: $CPU_USAGE%"
        elif [ "${CPU_USAGE%.*}" -gt 80 ] 2>/dev/null; then
            echo "⚠️  CPU élevé: $CPU_USAGE%"
        else
            echo "✅ CPU OK: $CPU_USAGE%"
        fi
        
        # Alertes instances
        if [ "$INSTANCES_COUNT" != "Erreur" ]; then
            if [ "$INSTANCES_COUNT" -gt 400 ]; then
                echo "⚠️  Beaucoup d'instances: $INSTANCES_COUNT"
            else
                echo "✅ Instances OK: $INSTANCES_COUNT"
            fi
        fi
        
        echo ""
        echo "🔄 Actualisation dans 10 secondes... (Ctrl+C pour arrêter)"
        echo "📊 Cycle #$counter terminé"
        
        sleep 10
        counter=$((counter + 1))
    done
}

# Démarrer le monitoring
monitor_loop
