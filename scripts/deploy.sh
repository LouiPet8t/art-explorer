#!/bin/bash

# Script de déploiement automatique sur serveur de production
# Usage: ./deploy.sh <BUILD_NUMBER>

set -e

BUILD_NUMBER=$1
if [ -z "$BUILD_NUMBER" ]; then
    echo "Usage: $0 <BUILD_NUMBER>"
    exit 1
fi

DOCKER_IMAGE="chicago-art-explorer"
CONTAINER_NAME="art-explorer-prod"
APP_PORT=8000

echo "=== Déploiement de Chicago Art Explorer v${BUILD_NUMBER} ==="

# Arrêt de l'ancien conteneur s'il existe
echo "Arrêt de l'ancien conteneur..."
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

# Chargement de la nouvelle image
echo "Chargement de la nouvelle image Docker..."
gunzip -c /tmp/chicago-art-explorer-${BUILD_NUMBER}.tar.gz | docker load

# Tag de la nouvelle image comme latest
docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest

# Création du répertoire de logs s'il n'existe pas
mkdir -p /opt/art-explorer/logs

# Démarrage du nouveau conteneur
echo "Démarrage du nouveau conteneur..."
docker run -d \
    --name ${CONTAINER_NAME} \
    --restart unless-stopped \
    -p ${APP_PORT}:8000 \
    -v /opt/art-explorer/logs:/app/logs \
    ${DOCKER_IMAGE}:latest

# Vérification que le conteneur a démarré
echo "Vérification du démarrage..."
sleep 10

if docker ps | grep -q ${CONTAINER_NAME}; then
    echo "✅ Conteneur démarré avec succès"
    
    # Test de santé de l'application
    if curl -f http://localhost:${APP_PORT}/ >/dev/null 2>&1; then
        echo "✅ Application accessible sur le port ${APP_PORT}"
        
        # Nettoyage du fichier temporaire
        rm -f /tmp/chicago-art-explorer-${BUILD_NUMBER}.tar.gz
        
        echo "🎉 Déploiement réussi !"
        exit 0
    else
        echo "❌ Application non accessible après démarrage"
        docker logs ${CONTAINER_NAME}
        exit 1
    fi
else
    echo "❌ Échec du démarrage du conteneur"
    docker logs ${CONTAINER_NAME} 2>/dev/null || true
    exit 1
fi