#!/bin/bash

# Script d'installation de Jenkins sur Ubuntu
echo "=== Installation de Jenkins ==="

# Mise à jour du système
apt-get update -y
apt-get upgrade -y

# Installation de Java 11
apt-get install -y openjdk-11-jdk

# Installation de Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Installation de Git
apt-get install -y git

# Ajout de la clé GPG de Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Ajout du repository Jenkins
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Installation de Jenkins
apt-get update -y
apt-get install -y jenkins

# Ajout de l'utilisateur jenkins au groupe docker
usermod -aG docker jenkins

# Configuration du firewall pour Jenkins
ufw allow 8080
ufw allow 50000

# Démarrage et activation de Jenkins
systemctl enable jenkins
systemctl start jenkins

# Attendre que Jenkins démarre
echo "Attente du démarrage de Jenkins..."
sleep 30

# Affichage du mot de passe initial de Jenkins
echo "=== MOT DE PASSE INITIAL JENKINS ==="
cat /var/lib/jenkins/secrets/initialAdminPassword
echo "================================="

echo "Installation terminée !"
echo "Jenkins: http://192.168.56.10:8080"