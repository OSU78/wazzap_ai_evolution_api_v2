#!/bin/bash

# ========================================
# Script de Collecte de Logs pour Dépannage
# ========================================

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="logs_$TIMESTAMP"

echo "🔍 Collecte des logs de diagnostic..."
echo "=================================="

# Créer le dossier de logs
mkdir -p $LOG_DIR

# Informations système
echo "📊 Collecte des informations système..."
{
    echo "=== INFORMATIONS SYSTÈME ==="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime)"
    echo "OS: $(lsb_release -d 2>/dev/null || cat /etc/os-release | head -1)"
    echo "Kernel: $(uname -r)"
    echo ""
    
    echo "=== RESSOURCES ==="
    echo "CPU:"
    lscpu | grep -E "Model name|CPU\(s\):"
    echo ""
    echo "Mémoire:"
    free -h
    echo ""
    echo "Disque:"
    df -h
    echo ""
    
    echo "=== RÉSEAU ==="
    echo "Interfaces:"
    ip addr show | grep -E "inet |inet6"
    echo ""
    echo "Ports ouverts:"
    ss -tlnp | grep -E ":80|:443|:8080|:22"
} > $LOG_DIR/system_info.log

# Informations Docker
echo "🐳 Collecte des informations Docker..."
{
    echo "=== DOCKER VERSION ==="
    docker version
    echo ""
    
    echo "=== DOCKER COMPOSE VERSION ==="
    docker-compose version
    echo ""
    
    echo "=== CONTENEURS ==="
    docker ps -a
    echo ""
    
    echo "=== IMAGES ==="
    docker images
    echo ""
    
    echo "=== VOLUMES ==="
    docker volume ls
    echo ""
    
    echo "=== RÉSEAUX ==="
    docker network ls
} > $LOG_DIR/docker_info.log 2>&1

# Logs des services
echo "📝 Collecte des logs des services..."

# Logs Evolution API
if docker ps | grep -q evolution_api; then
    echo "Evolution API logs:" > $LOG_DIR/evolution_api.log
    docker logs evolution_api --tail 500 >> $LOG_DIR/evolution_api.log 2>&1
fi

# Logs Traefik
if docker ps | grep -q traefik; then
    echo "Traefik logs:" > $LOG_DIR/traefik.log
    docker logs traefik --tail 500 >> $LOG_DIR/traefik.log 2>&1
fi

# Configuration Docker Compose
echo "⚙️ Collecte des configurations..."
if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml $LOG_DIR/
fi

if [ -f ".env" ]; then
    # Copier .env en masquant les mots de passe
    sed 's/PASSWORD=.*/PASSWORD=***MASKED***/g; s/SECRET=.*/SECRET=***MASKED***/g; s/KEY=.*/KEY=***MASKED***/g' .env > $LOG_DIR/env_masked.txt
fi

# Tests de connectivité
echo "🌐 Tests de connectivité..."
{
    echo "=== TESTS DE CONNECTIVITÉ ==="
    echo "Test DNS Google:"
    nslookup google.com || echo "ÉCHEC DNS"
    echo ""
    
    echo "Test connectivité base de données Neon:"
    timeout 5 nc -z ep-soft-pine-adcz7qon-pooler.c-2.us-east-1.aws.neon.tech 5432 && echo "✅ Neon PostgreSQL accessible" || echo "❌ Neon PostgreSQL inaccessible"
    echo ""
    
    echo "Test connectivité Redis Cloud:"
    timeout 5 nc -z redis-19966.c10.us-east-1-2.ec2.redns.redis-cloud.com 19966 && echo "✅ Redis Cloud accessible" || echo "❌ Redis Cloud inaccessible"
    echo ""
    
    echo "Test API locale:"
    curl -s -o /dev/null -w "Code HTTP: %{http_code}\n" http://localhost:8080/ || echo "❌ API locale inaccessible"
} > $LOG_DIR/connectivity_tests.log

# Logs système
echo "🖥️ Collecte des logs système..."
{
    echo "=== LOGS SYSTÈME RÉCENTS ==="
    journalctl --since "1 hour ago" --no-pager | tail -200
} > $LOG_DIR/system_logs.log

# Firewall status
echo "🔥 Status du firewall..."
{
    echo "=== STATUS UFW ==="
    sudo ufw status verbose 2>/dev/null || echo "UFW non disponible"
    echo ""
    
    echo "=== IPTABLES ==="
    sudo iptables -L -n 2>/dev/null | head -50 || echo "iptables non accessible"
} > $LOG_DIR/firewall_status.log

# Processus en cours
echo "⚡ Processus en cours..."
{
    echo "=== PROCESSUS ==="
    ps aux | grep -E "docker|traefik|evolution" | grep -v grep
    echo ""
    
    echo "=== UTILISATION RESSOURCES ==="
    top -b -n1 | head -20
} > $LOG_DIR/processes.log

# Créer une archive
echo "📦 Création de l'archive..."
tar -czf "evolution_logs_$TIMESTAMP.tar.gz" $LOG_DIR/

# Nettoyer le dossier temporaire
rm -rf $LOG_DIR

echo ""
echo "✅ Collecte terminée!"
echo "📁 Archive créée: evolution_logs_$TIMESTAMP.tar.gz"
echo ""
echo "📋 Contenu de l'archive:"
echo "  - system_info.log (informations système)"
echo "  - docker_info.log (informations Docker)"
echo "  - evolution_api.log (logs API Evolution)"
echo "  - traefik.log (logs Traefik)"
echo "  - docker-compose.yml (configuration)"
echo "  - env_masked.txt (variables d'environnement masquées)"
echo "  - connectivity_tests.log (tests de connectivité)"
echo "  - system_logs.log (logs système)"
echo "  - firewall_status.log (status firewall)"
echo "  - processes.log (processus en cours)"
echo ""
echo "📤 Vous pouvez maintenant envoyer cette archive pour analyse."
