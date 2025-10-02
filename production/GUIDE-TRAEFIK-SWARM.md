# 🔧 Guide : Remplacer Traefik Dokploy par un Service Swarm

## 🎯 Objectif

Résoudre le problème de connectivité réseau overlay en déployant Traefik comme **service Swarm** au lieu d'un container standalone.

## ⚠️ Problème Actuel

```
Manager: [Traefik container] ──X──> Worker1: [Evolution containers]
                              (ping 100% loss)
```

**Traefik (container standalone)** ne peut pas atteindre les containers sur worker1 via le réseau overlay.

## ✅ Solution : Traefik en Service Swarm

```
Manager: [Traefik service Swarm] ──✅──> Worker1: [Evolution containers]
                                  (réseau overlay fonctionnel)
```

---

## 📋 Méthode 1 : Solution Rapide (Recommandée)

### Utiliser le Spread au Lieu de Forcer sur Worker1

**Le plus simple :** Gardez Traefik actuel et utilisez `spread: node.id` dans votre `docker-compose-single-16gb.yml` :

```yaml
deploy:
  placement:
    preferences:
      - spread: node.id  # 1 sur manager + 1 sur worker1
```

✅ **Avantages :**
- Pas besoin de toucher à Traefik
- Fonctionne immédiatement
- Haute disponibilité

❌ **Inconvénient :**
- 1 replica sur manager au lieu de 2 sur worker1

---

## 📋 Méthode 2 : Fixer le Réseau Overlay

### Étape 1 : Ouvrir les Ports Swarm sur Worker1

```bash
# Connectez-vous au worker1
ssh root@45.79.206.219

# Vérifiez si les ports Swarm sont ouverts
sudo netstat -tulpn | grep -E "2377|7946|4789"

# Si aucun résultat, ouvrez les ports :
sudo ufw status
sudo ufw allow from 89.116.38.18 to any port 2377 proto tcp
sudo ufw allow from 89.116.38.18 to any port 7946 proto tcp
sudo ufw allow from 89.116.38.18 to any port 7946 proto udp
sudo ufw allow from 89.116.38.18 to any port 4789 proto udp

# Redémarrer Docker
sudo systemctl restart docker
```

### Étape 2 : Tester la Connectivité

Depuis le **manager** :

```bash
# Tester les ports Swarm vers worker1
telnet 45.79.206.219 2377
telnet 45.79.206.219 7946

# Tester ping via overlay
docker exec dokploy-traefik ping -c 3 10.0.1.126
```

Si le ping fonctionne maintenant → **Le problème est résolu** ! 🎉

---

## 📋 Méthode 3 : Remplacer Traefik (Solution Avancée)

### ⚠️ ATTENTION : Cette méthode nécessite d'arrêter le Traefik actuel

### Étape 1 : Sauvegarder la Configuration Actuelle

```bash
ssh -i ~/.ssh/id_whatsetter root@89.116.38.18

# Sauvegarder les labels du Traefik actuel
docker inspect dokploy-traefik > /tmp/traefik-backup.json

# Lister tous les services qui utilisent Traefik
docker service ls
```

### Étape 2 : Déployer le Nouveau Traefik Swarm

```bash
# Copier le fichier traefik-swarm-service.yml sur le serveur
scp -i ~/.ssh/id_whatsetter \
  ./production/traefik-swarm-service.yml \
  root@89.116.38.18:/root/

# Sur le serveur
ssh -i ~/.ssh/id_whatsetter root@89.116.38.18

# Créer le fichier .env si nécessaire
echo "LETSENCRYPT_EMAIL=admin@wazzap.fr" > /root/.env

# Déployer Traefik comme service Swarm
docker stack deploy -c /root/traefik-swarm-service.yml traefik-stack

# Vérifier
docker service ls | grep traefik
docker service ps traefik-stack_traefik-swarm
```

### Étape 3 : Arrêter l'Ancien Traefik (Après Test)

```bash
# UNIQUEMENT si le nouveau fonctionne !
docker stop dokploy-traefik
docker rm dokploy-traefik
```

### Étape 4 : Tester

```bash
# Attendre 30 secondes que tout démarre
sleep 30

# Tester les requêtes
for i in {1..10}; do
  curl -s -o /dev/null -w "Test $i: HTTP %{http_code}\n" -k https://evolution.wazzap.fr/
  sleep 0.5
done
```

---

## 🎯 Ma Recommandation

**Ne remplacez PAS Traefik** car :
1. C'est géré par Dokploy
2. Ça va casser d'autres services Dokploy
3. C'est complexe et risqué

**Faites plutôt ceci :**

### Option A : Fixer le Firewall (Le Plus Probable)

Sur worker1, ouvrez les ports Swarm :

```bash
ssh root@45.79.206.219

# Ouvrir les ports pour le manager
sudo ufw allow from 89.116.38.18 to any port 2377 proto tcp
sudo ufw allow from 89.116.38.18 to any port 7946
sudo ufw allow from 89.116.38.18 to any port 4789 proto udp

# Recharger
sudo ufw reload
sudo systemctl restart docker
```

### Option B : Utiliser le Spread (Le Plus Simple)

Changez juste votre `docker-compose-single-16gb.yml` :

```yaml
placement:
  preferences:
    - spread: node.id  # Répartir automatiquement
```

Redéployez → **Ça marchera immédiatement** ! ✅

---

## 🤔 Quelle Option Préférez-Vous ?

1. **Option A** : Fixer le firewall sur worker1 (je vous guide)
2. **Option B** : Utiliser le spread (changement déjà fait, il suffit de redéployer)
3. **Option C** : Créer un nouveau Traefik Swarm (risqué, je vous guide)

Dites-moi laquelle vous voulez et je vous aide ! 🚀
