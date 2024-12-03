#!/usr/bin/env bash


### TODO:  REMOVE KUBERNETES RELATED INSTALLATIONS ###
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get -y upgrade

sudo apt-get -y install nano less iptables iputils-ping

# install tools for managing ppa repositories
sudo apt-get -y install software-properties-common
sudo apt-get -y install unzip
sudo apt-get -y install build-essential
# 
sudo apt-get -y install libssl-dev 
sudo apt-get -y install libffi-dev 
# required for Openstack SDK
sudo apt-get -y install python3-dev 
sudo apt-get -y install python3-pip

# Add graph builder tool for Terraform
sudo apt-get -y install graphviz

# add repositories
## Ansible
sudo apt-add-repository -y -u ppa:ansible/ansible
# install GNU Privacy Guard
sudo apt-get install -y gnupg
# add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
## Kubectl
sudo mkdir -p /etc/apt/keyrings
sudo apt-get install -y apt-transport-https ca-certificates
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
## Google Cloud CLI
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

sudo apt-get update

# install Ansible (http://docs.ansible.com/intro_installation.html)
sudo apt-get -y install ansible

# install Terraform
sudo apt-get -y install terraform

# install OpenStack SDK modules
pip install python-openstackclient

# Install Google Cloud SDK
sudo apt-get -y install google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin

# Install Kubernetes Controller
sudo apt-get -y install kubectl

# Clean up cached packages
sudo apt-get clean all
