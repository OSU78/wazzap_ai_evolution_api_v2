#!/bin/bash

# Script pour tester le load balancing entre les replicas
# Vérifie que Traefik route correctement vers les 2 instances

echo "======================================"
echo "🧪 TEST DE LOAD BALANCING"
echo "======================================"
echo ""

DOMAIN="https://evolution.wazzap.fr"
ENDPOINT="/manager"
TESTS=20

echo "🎯 Test de $TESTS requêtes vers $DOMAIN$ENDPOINT"
echo "Si le load balancing fonctionne, vous devriez voir:"
echo "  - Des codes HTTP 200 ou 401 (pas 502!)"
echo "  - Les requêtes réparties entre les replicas"
echo ""

SUCCESS=0
FAILED=0
ERROR_502=0
ERROR_OTHER=0

echo "📊 Résultats des requêtes:"
echo "---"

for i in $(seq 1 $TESTS); do
    # Envoyer la requête et capturer le code HTTP
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k $DOMAIN$ENDPOINT --max-time 5 2>/dev/null)
    
    # Afficher le résultat avec couleur
    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "401" ]; then
        echo "✅ Test $i: HTTP $HTTP_CODE"
        ((SUCCESS++))
    elif [ "$HTTP_CODE" == "502" ]; then
        echo "❌ Test $i: HTTP 502 Bad Gateway"
        ((ERROR_502++))
        ((FAILED++))
    elif [ "$HTTP_CODE" == "000" ]; then
        echo "⚠️  Test $i: Timeout/Connexion échouée"
        ((ERROR_OTHER++))
        ((FAILED++))
    else
        echo "⚠️  Test $i: HTTP $HTTP_CODE"
        ((ERROR_OTHER++))
        ((FAILED++))
    fi
    
    sleep 0.5
done

echo ""
echo "======================================"
echo "📈 STATISTIQUES"
echo "======================================"
echo "✅ Succès: $SUCCESS/$TESTS ($(( SUCCESS * 100 / TESTS ))%)"
echo "❌ Erreurs 502: $ERROR_502/$TESTS"
echo "⚠️  Autres erreurs: $ERROR_OTHER/$TESTS"
echo ""

if [ $ERROR_502 -gt 0 ]; then
    echo "🔴 PROBLÈME DÉTECTÉ!"
    echo "---"
    echo "Des erreurs 502 sont toujours présentes."
    echo ""
    echo "Actions recommandées:"
    echo "1. Lancez le diagnostic:"
    echo "   ./production/diagnose-traefik-issue.sh"
    echo ""
    echo "2. Appliquez le fix:"
    echo "   ./production/fix-traefik-labels.sh"
    echo ""
    echo "3. Vérifiez les logs:"
    echo "   ./production/check-traefik-logs.sh"
elif [ $SUCCESS -eq $TESTS ]; then
    echo "🎉 PARFAIT!"
    echo "---"
    echo "Tous les tests ont réussi."
    echo "Le load balancing fonctionne correctement!"
    echo "Les 2 replicas sont opérationnels."
else
    echo "⚠️  ATTENTION"
    echo "---"
    echo "Quelques erreurs détectées, mais pas de 502."
    echo "Cela peut être normal (authentification, etc.)"
    echo ""
    echo "Vérifiez les logs si nécessaire:"
    echo "   ./production/check-traefik-logs.sh"
fi

echo ""

