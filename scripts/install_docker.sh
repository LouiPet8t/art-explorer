#!/bin/bash

# Script d'installation de Docker sur le serveur de production
echo "=== Installation de Docker sur serveur de production ==="

# Mise à jour du système
apt-get update -y
apt-get upgrade -y

# Installation des prérequis
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Ajout de la clé GPG Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Ajout du repository Docker
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Mise à jour et installation de Docker
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Installation de Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Création d'un utilisateur pour le déploiement
useradd -m -s /bin/bash deploy
usermod -aG docker deploy

# Configuration SSH pour le déploiement automatique
mkdir -p /home/deploy/.ssh
chown deploy:deploy /home/deploy/.ssh
chmod 700 /home/deploy/.ssh

# Génération de clés SSH pour Jenkins
sudo -u deploy ssh-keygen -t rsa -b 4096 -f /home/deploy/.ssh/id_rsa -N ""

# Configuration du répertoire de déploiement
mkdir -p /opt/art-explorer
chown deploy:deploy /opt/art-explorer

# Démarrage et activation de Docker
systemctl enable docker
systemctl start docker

# Configuration du firewall
ufw allow 8000
ufw allow 22

echo "=== INFORMATIONS DE CONNEXION ==="
echo "IP du serveur: 192.168.56.20"
echo "Utilisateur: deploy"
echo "Clé publique SSH:"
cat /home/deploy/.ssh/id_rsa.pub
echo "================================="

echo "Installation Docker terminée sur le serveur de production !"