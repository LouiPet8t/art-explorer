# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Configuration pour le serveur Jenkins
  config.vm.define "jenkins" do |jenkins|
    jenkins.vm.box = "ubuntu/jammy64"
    jenkins.vm.hostname = "jenkins-server"
    jenkins.vm.network "private_network", ip: "192.168.56.10"
    jenkins.vm.network "forwarded_port", guest: 8080, host: 8080
    jenkins.vm.network "forwarded_port", guest: 50000, host: 50000
    
    jenkins.vm.provider "virtualbox" do |vb|
      vb.name = "jenkins-server"
      vb.memory = "2048"
      vb.cpus = 2
    end
    
    jenkins.vm.provision "shell", path: "scripts/install_jenkins.sh"
  end

  # Configuration pour le serveur de production
  config.vm.define "production" do |prod|
    prod.vm.box = "ubuntu/jammy64"
    prod.vm.hostname = "production-server"
    prod.vm.network "private_network", ip: "192.168.56.20"
    prod.vm.network "forwarded_port", guest: 8000, host: 8000
    
    prod.vm.provider "virtualbox" do |vb|
      vb.name = "production-server"
      vb.memory = "1024"
      vb.cpus = 1
    end
    
    prod.vm.provision "shell", path: "scripts/install_docker.sh"
  end

  # Configuration commune
  config.vm.synced_folder ".", "/vagrant", disabled: false
end