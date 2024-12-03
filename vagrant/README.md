# Vagrant

This is a simple Vagrant setup for a management node.
With it, you don't need to install locally all the tools needed to deploy and manage the Kubernetes cluster.

Alternatively, if you have a debian-based system, you can execute the `bootstrap-mgmt.sh` script to install the necessary tools. Use with caution since it wasn't tested to be used this way.

## Requirements
- Vagrant
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```

- VirtualBox
```bash
sudo apt install fasttrack-archive-keyring
echo "deb https://fasttrack.debian.net/debian-fasttrack/ bullseye-fasttrack main contrib" | sudo tee -a /etc/apt/sources.list
echo "deb https://fasttrack.debian.net/debian-fasttrack/ bullseye-backports-staging main contrib" | sudo tee -a /etc/apt/sources.list
sudo apt install virtualbox
```