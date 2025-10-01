# Utilise l’image officielle de l’app
FROM evoapicloud/evolution-api:v2.3.0

# Optionnel: healthcheck équivalent à ton compose
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

# Le port exposé par l’app
EXPOSE 8080

# L’image upstream a déjà son ENTRYPOINT/CMD, donc rien d’autre à faire.
