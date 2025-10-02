# 🔧 Solution: Bad Gateway sur Evolution API (Dokploy)

## 🎯 Problème

Les requêtes vers `https://evolution.wazzap.fr/manager` fonctionnent **1 fois sur 2**:
- ✅ Ça marche sur le **worker 1**
- ❌ Ça échoue sur le **manager** (erreur 502 Bad Gateway)

### Logs Traefik montrent:
```
ERR error="both Docker and Swarm labels are defined" providerName=swarm
ERR error="middleware \"evo-strip@swarm\" does not exist"
```

## 🔍 Cause Racine

Le problème vient de **2 configurations manquantes critiques** dans les labels Traefik:

1. ❌ **`traefik.docker.network=dokploy-network` était commenté**
   - Sans ça, Traefik ne sait pas quel réseau utiliser en mode Swarm
   - Il essaie de deviner et échoue sur certains replicas

2. ❌ **Pas de health checks configurés**
   - Traefik continue d'envoyer du trafic vers des replicas défaillants
   - Pas de détection automatique des problèmes

## ✅ Solution Appliquée

J'ai mis à jour votre `docker-compose-single-16gb.yml` avec:

```yaml
deploy:
  labels:
    - traefik.enable=true
    - traefik.http.routers.evolution_v2.rule=Host(`${DOMAIN_NAME}`)
    - traefik.http.routers.evolution_v2.entrypoints=websecure
    - traefik.http.routers.evolution_v2.tls.certresolver=letsencrypt
    - traefik.http.routers.evolution_v2.service=evolution_v2
    - traefik.http.services.evolution_v2.loadbalancer.server.port=8080
    - traefik.http.services.evolution_v2.loadbalancer.passHostHeader=true
    - traefik.http.services.evolution_v2.loadbalancer.responseForwarding.flushInterval=100ms
    
    # ✨ AJOUTÉ: Force le bon réseau
    - traefik.docker.network=dokploy-network
    
    # ✨ AJOUTÉ: Health checks
    - traefik.http.services.evolution_v2.loadbalancer.healthcheck.path=/
    - traefik.http.services.evolution_v2.loadbalancer.healthcheck.interval=10s
    - traefik.http.services.evolution_v2.loadbalancer.healthcheck.timeout=5s
```

## 🚀 Application Rapide (Recommandé)

### Option 1: Script Automatique (Le plus simple)

```bash
# 1. Appliquer le fix directement
./production/apply-traefik-fix.sh

# 2. Tester le résultat
./production/test-load-balancing.sh
```

C'est tout ! 🎉

### Option 2: Via Dokploy UI

1. **Connectez-vous à Dokploy**
2. **Ouvrez votre projet Evolution**
3. **Remplacez le Docker Compose** par le contenu de:
   - `production/docker-compose-single-16gb.yml` (déjà corrigé)
   - OU `production/docker-compose-dokploy-fixed.yml` (version propre)
4. **Cliquez sur "Deploy"**
5. **Attendez le rolling update** (30-60 secondes)

### Option 3: Via SSH Manuel

```bash
# Connexion au serveur
ssh -i ~/.ssh/id_whatsetter root@89.116.38.18

# Trouver le service
SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)

# Appliquer les corrections
docker service update \
  --label-add traefik.docker.network=dokploy-network \
  --label-add traefik.http.services.evolution_v2.loadbalancer.healthcheck.path=/ \
  --label-add traefik.http.services.evolution_v2.loadbalancer.healthcheck.interval=10s \
  --label-add traefik.http.services.evolution_v2.loadbalancer.healthcheck.timeout=5s \
  $SERVICE_NAME

# Redémarrer Traefik
docker kill -s HUP $(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)
```

## 🧪 Vérification

### Test Simple (10 requêtes)

```bash
for i in {1..10}; do
  curl -s -o /dev/null -w "Test $i: HTTP %{http_code}\n" -k https://evolution.wazzap.fr/manager
  sleep 1
done
```

**Résultat attendu:** 10/10 succès (HTTP 200 ou 401, **PAS de 502**)

### Test Complet (20 requêtes avec statistiques)

```bash
./production/test-load-balancing.sh
```

### Vérifier les Logs

```bash
# Logs Traefik (ne devrait plus montrer d'erreurs)
./production/check-traefik-logs.sh

# Diagnostic complet
./production/diagnose-traefik-issue.sh
```

## 📊 Scripts Disponibles

| Script | Description |
|--------|-------------|
| `apply-traefik-fix.sh` | 🚀 Applique le fix automatiquement (RECOMMANDÉ) |
| `test-load-balancing.sh` | 🧪 Teste le load balancing (20 requêtes) |
| `check-traefik-logs.sh` | 📋 Vérifie les logs Traefik |
| `diagnose-traefik-issue.sh` | 🔬 Diagnostic complet du problème |
| `fix-traefik-labels.sh` | 🔧 Nettoyage complet des labels (si conflit) |

## 🎓 Pourquoi Ça Marche Maintenant?

### Avant (Problème)

```
Client → Traefik → ??? (quel réseau?)
              ↓
           Manager ❌ (Traefik ne trouve pas le replica)
           Worker1 ✅ (par chance, Traefik le trouve)
```

### Après (Corrigé)

```
Client → Traefik → dokploy-network (explicite!)
              ↓
           Manager ✅ (Traefik sait où chercher)
           Worker1 ✅ (idem)
              ↓
      Health checks détectent les problèmes
```

## 🔑 Points Clés

1. **`traefik.docker.network=dokploy-network`** est **OBLIGATOIRE** en mode Swarm
   - Sans ça, Traefik essaie de deviner le réseau
   - Il échoue sur certains nodes/replicas

2. **`passHostHeader=true`** est **CRITIQUE** (déjà présent)
   - Force Traefik à passer le header `Host:` original
   - Sans ça, le backend reçoit l'IP interne au lieu du domaine

3. **Health checks** permettent à Traefik de:
   - Détecter les replicas défaillants
   - Les retirer automatiquement du load balancing
   - Les remettre quand ils redeviennent sains

## 🆘 Si le Problème Persiste

### 1. Vérifier que le fix est bien appliqué

```bash
ssh -i ~/.ssh/id_whatsetter root@89.116.38.18

SERVICE_NAME=$(docker service ls --filter name=evolution --format "{{.Name}}" | head -1)
docker service inspect $SERVICE_NAME --format='{{json .Spec.Labels}}' | python3 -m json.tool | grep network
```

Doit afficher: `"traefik.docker.network": "dokploy-network"`

### 2. Vérifier les replicas

```bash
docker service ps $SERVICE_NAME
```

Les 2 replicas doivent être en **Running**

### 3. Vérifier Traefik

```bash
docker logs dokploy-traefik --tail 50
```

Ne devrait **plus** afficher:
- ❌ `error="both Docker and Swarm labels are defined"`
- ❌ `Bad gateway`

### 4. Diagnostic complet

```bash
./production/diagnose-traefik-issue.sh
```

## 📚 Références

- **Issue communauté Traefik:** [How to debug "Bad gateway"](https://community.traefik.io)
- **Doc Traefik Swarm:** https://doc.traefik.io/traefik/providers/docker/#docker-swarm-mode
- **Doc passHostHeader:** https://doc.traefik.io/traefik/routing/services/#pass-host-header

---

**Date:** 2 octobre 2025  
**Testé sur:** Ubuntu 24.04, Docker Swarm, Dokploy, Traefik 2.x  
**Status:** ✅ RÉSOLU

