#!/bin/bash

gcloud auth login

cd esle24-g1/gcp-deploy
terraform init

ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
