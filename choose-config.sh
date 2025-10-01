#!/bin/bash

# ========================================
# Assistant de Choix de Configuration Evolution API
# ========================================

echo "🎯 Assistant de Configuration Evolution API v2"
echo "=============================================="
echo ""

# Questions pour déterminer les besoins
echo "📋 Quelques questions pour vous aider à choisir :"
echo ""

read -p "📱 Combien de comptes WhatsApp prévoyez-vous ? " COMPTES
read -p "💰 Quel est votre budget mensuel (en €) ? " BUDGET
read -p "🚀 Quand voulez-vous démarrer ? (1=Aujourd'hui, 2=Cette semaine, 3=Ce mois) " TIMING
read -p "🛡️ Avez-vous besoin de haute disponibilité ? (y/N) " HA_NEEDED

echo ""
echo "🤖 Analyse de vos besoins..."
echo ""

# Logique de recommandation
RECOMMENDATION=""
GUIDE=""
COMMAND=""

if [ "$COMPTES" -le 400 ] && [ "$BUDGET" -le 100 ] && [ "$TIMING" -eq 1 ]; then
    RECOMMENDATION="🖥️ 1 Serveur Hostinger 16GB"
    GUIDE="SINGLE-SERVER-GUIDE.md"
    COMMAND="./deploy-single"
    COST="70€/mois"
    CAPACITY="400 comptes"
    TIME="2 heures"
elif [ "$COMPTES" -le 800 ] && [ "$BUDGET" -le 200 ]; then
    RECOMMENDATION="🐳 2 Serveurs Hostinger 16GB"
    GUIDE="DEPLOYMENT-7K-GUIDE.md"
    COMMAND="./production/deploy-2servers.sh"
    COST="105€/mois"
    CAPACITY="800 comptes"
    TIME="1 journée"
elif [ "$COMPTES" -gt 800 ] || [ "$BUDGET" -gt 400 ]; then
    RECOMMENDATION="🚀 Cluster 10 Serveurs"
    GUIDE="scaling-7000-accounts.md"
    COMMAND="./production/deploy-7k.sh"
    COST="560€/mois"
    CAPACITY="7000+ comptes"
    TIME="1 semaine"
else
    RECOMMENDATION="🐳 2 Serveurs Hostinger 16GB"
    GUIDE="DEPLOYMENT-7K-GUIDE.md"
    COMMAND="./production/deploy-2servers.sh"
    COST="105€/mois"
    CAPACITY="800 comptes"
    TIME="1 journée"
fi

# Afficher la recommandation
echo "🎯 RECOMMANDATION POUR VOUS :"
echo "============================="
echo "📊 Configuration : $RECOMMENDATION"
echo "💰 Coût estimé   : $COST"
echo "📱 Capacité      : $CAPACITY"
echo "⏰ Temps setup   : $TIME"
echo ""

# Afficher les détails
echo "📋 DÉTAILS DE CETTE CONFIGURATION :"
echo ""

if [[ "$RECOMMENDATION" == *"1 Serveur"* ]]; then
    echo "✅ Avantages :"
    echo "   • Setup ultra-rapide (2h)"
    echo "   • Coût minimal (70€/mois)"
    echo "   • Parfait pour débuter"
    echo "   • 10 instances API avec load balancing"
    echo ""
    echo "⚠️ Limitations :"
    echo "   • Pas de haute disponibilité"
    echo "   • Capacité limitée à 400 comptes"
    echo "   • Downtime pendant maintenance"
    echo ""
    echo "🔄 Migration future :"
    echo "   • Facile vers 2 serveurs (Docker Swarm)"
    echo "   • Services externes déjà configurés"

elif [[ "$RECOMMENDATION" == *"2 Serveurs"* ]]; then
    echo "✅ Avantages :"
    echo "   • Haute disponibilité"
    echo "   • 20 instances distribuées"
    echo "   • Rolling updates sans downtime"
    echo "   • Bon équilibre coût/performance"
    echo ""
    echo "⚠️ Limitations :"
    echo "   • Setup plus complexe (1 jour)"
    echo "   • Coût plus élevé"
    echo ""
    echo "🔄 Migration future :"
    echo "   • Scaling facile vers cluster"
    echo "   • Ajout de serveurs transparent"

else
    echo "✅ Avantages :"
    echo "   • Performance maximale"
    echo "   • Scaling illimité"
    echo "   • Haute disponibilité garantie"
    echo "   • Architecture professionnelle"
    echo ""
    echo "⚠️ Limitations :"
    echo "   • Setup complexe (1 semaine)"
    echo "   • Coût élevé"
    echo "   • Équipe technique requise"
fi

echo ""
echo "📖 Guide détaillé : $GUIDE"
echo "🚀 Commande de déploiement : $COMMAND"
echo ""

# Proposer de démarrer
echo "Voulez-vous consulter le guide maintenant ? (y/N)"
read -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v code &> /dev/null; then
        code "$GUIDE"
    elif command -v nano &> /dev/null; then
        nano "$GUIDE"
    else
        cat "$GUIDE"
    fi
fi

echo ""
echo "🎉 Bonne configuration et bon déploiement !"
echo ""
echo "💡 Rappel des commandes :"
echo "   Développement : ./start-local ou ./start-traefik"
echo "   Production    : $COMMAND"
echo "   Structure     : ./show-structure.sh"
