# 🔧 Guide de Correction - Problème Traefik 502

## 📊 Symptômes

- Les requêtes vers `https://evolution.wazzap.fr/manager` fonctionnent 1 fois sur 2
- Ça marche sur le worker 1 mais pas sur le manager
- Logs Traefik montrent:
  - ❌ `error="both Docker and Swarm labels are defined"`
  - ❌ `error="middleware \"evo-strip@swarm\" does not exist"`

## 🔍 Cause du Problème

Dokploy déploie des services en mode Swarm, mais des labels Traefik sont définis à la fois:
1. Au niveau **top-level** du service (labels Docker standalone)
2. Au niveau **deploy.labels** (labels Swarm)

Traefik détecte ce conflit et refuse de router correctement vers certains replicas.

## 🚀 Solution Rapide (Recommandée)

### Étape 1: Diagnostic

```bash
chmod +x ./production/diagnose-traefik-issue.sh
./production/diagnose-traefik-issue.sh
```

Ce script va identifier:
- ✅ Les labels en conflit
- ✅ Les erreurs Traefik
- ✅ L'état des replicas
- ✅ La connectivité réseau

### Étape 2: Correction Automatique

```bash
chmod +x ./production/fix-traefik-labels.sh
./production/fix-traefik-labels.sh
```

Ce script va:
1. 🧹 Nettoyer tous les labels Docker existants
2. ✨ Ajouter uniquement les labels Swarm corrects
3. 🔄 Redémarrer Traefik pour recharger la configuration
4. ✅ Vérifier que tout fonctionne

**Note:** Le rolling update garantit zéro downtime!

### Étape 3: Test

```bash
# Test depuis votre machine locale
for i in {1..10}; do
  curl -s -o /dev/null -w "Test $i: HTTP %{http_code}\n" -k https://evolution.wazzap.fr/manager
  sleep 1
done
```

Vous devriez avoir **10/10 succès** (HTTP 200 ou 401, pas 502)

## 📝 Solution Manuelle (Si vous préférez comprendre)

### Option A: Via l'interface Dokploy

1. **Accédez à Dokploy** → votre projet Evolution
2. **Modifiez le Docker Compose** → utilisez `./production/docker-compose-dokploy-fixed.yml`
3. **Important:** Assurez-vous que les labels Traefik sont **uniquement** dans `deploy.labels`
4. **Redéployez** le service

### Option B: Via CLI

```bash
# Connectez-vous au manager
ssh -i ~/.ssh/id_whatsetter root@89.116.38.18

# Trouvez le nom du service
docker service ls | grep evolution

# Mettez à jour les labels (un par un)
SERVICE_NAME="votre_service_evolution"

# Supprimez les anciens labels
docker service update --label-rm traefik.enable $SERVICE_NAME
docker service update --container-label-rm traefik.enable $SERVICE_NAME

# Ajoutez les nouveaux labels corrects
docker service update \
  --label-add traefik.enable=true \
  --label-add "traefik.http.routers.evolution_v2.rule=Host(\`evolution.wazzap.fr\`)" \
  --label-add traefik.http.routers.evolution_v2.entrypoints=websecure \
  --label-add traefik.http.routers.evolution_v2.tls.certresolver=letsencrypt \
  --label-add traefik.http.routers.evolution_v2.service=evolution_v2 \
  --label-add traefik.http.services.evolution_v2.loadbalancer.server.port=8080 \
  --label-add traefik.http.services.evolution_v2.loadbalancer.passHostHeader=true \
  --label-add traefik.docker.network=dokploy-network \
  $SERVICE_NAME

# Redémarrez Traefik
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
docker kill -s HUP $TRAEFIK_CONTAINER
```

## 🎯 Points Clés à Retenir

### ✅ Ce qu'il FAUT faire (Swarm Mode)

```yaml
services:
  evolution-api:
    image: evoapicloud/evolution-api:v2.3.0
    # PAS de labels ici!
    
    deploy:
      labels:
        # Labels Traefik ICI uniquement
        - traefik.enable=true
        - traefik.http.routers.xxx.rule=...
```

### ❌ Ce qu'il NE FAUT PAS faire

```yaml
services:
  evolution-api:
    image: evoapicloud/evolution-api:v2.3.0
    labels:  # ❌ NE PAS mettre les labels Traefik ici en Swarm!
      - traefik.enable=true
    
    deploy:
      labels:  # ❌ Et aussi ici = CONFLIT!
        - traefik.enable=true
```

## 🔍 Vérifications Post-Correction

### 1. Vérifier les logs Traefik

```bash
./production/check-traefik-logs.sh
```

Vous **ne devriez plus voir**:
- ❌ `error="both Docker and Swarm labels are defined"`
- ❌ `error="middleware \"evo-strip@swarm\" does not exist"`

### 2. Vérifier les replicas

```bash
ssh -i ~/.ssh/id_whatsetter root@89.116.38.18 \
  'docker service ps $(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)'
```

Les 2 replicas doivent être en état **Running**

### 3. Tester la répartition de charge

```bash
# Ce test doit montrer que Traefik route vers les 2 replicas
for i in {1..20}; do
  curl -s -k https://evolution.wazzap.fr/manager -H "X-Test: $i" | head -c 50
  echo " - Request $i"
done
```

## 📚 Fichiers de Référence

- `docker-compose-dokploy-fixed.yml` - Configuration corrigée pour Dokploy
- `diagnose-traefik-issue.sh` - Script de diagnostic complet
- `fix-traefik-labels.sh` - Script de correction automatique
- `check-traefik-logs.sh` - Vérification rapide des logs

## 🆘 Besoin d'Aide?

Si le problème persiste après la correction:

1. **Lancez le diagnostic complet:**
   ```bash
   ./production/diagnose-traefik-issue.sh > diagnostic.log
   ```

2. **Vérifiez que Traefik est en mode Swarm:**
   ```bash
   ssh -i ~/.ssh/id_whatsetter root@89.116.38.18 \
     'docker logs dokploy-traefik 2>&1 | grep -i "swarmMode"'
   ```
   Doit afficher: `"swarmMode":true`

3. **Vérifiez la connectivité réseau:**
   - Tous les services doivent être sur `dokploy-network`
   - Les replicas doivent être accessibles depuis Traefik

## 🎓 Pourquoi Ça Marche Maintenant?

1. **Un seul type de labels:** Uniquement `deploy.labels` pour Swarm
2. **Pas de middleware manquant:** Suppression de la référence à `evo-strip@swarm`
3. **Network explicite:** `traefik.docker.network=dokploy-network`
4. **Health checks:** Traefik peut détecter les replicas défaillants
5. **Rolling updates:** Les mises à jour se font sans downtime

---

**Date:** 2025-10-02  
**Version:** 1.0  
**Maintainer:** Evolution API Team

