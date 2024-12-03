# Deployment

To deploy YugabyteDB on GCP, we use Terraform (to deploy the infrastructure) and Ansible (to configure the servers, and deploy Yugabyte).

## Terraform

Our Terraform files are currently written to deploy **6 VMs**, of the type `n1-standard-2`, in the `europe-central2-a` zone.

> __Note:__ We should try to change to a closer region (europe-west) to reduce latency, but the VM type N1 were unavailable in this region when I tried to deploy.

## Ansible

The Ansible playbooks were created based on the following documentation: [https://docs.yugabyte.com/preview/deploy/manual-deployment/](https://docs.yugabyte.com/preview/deploy/manual-deployment/)

## How to Deploy

1. Firstly, you need to place your GCP credentials file (`.json` file provided by Google) in the [secrets](./secrets/) folder.
2. Then, replace the name of the credentials file in [this terraform file](./terraform-gcp-provider.tf) (replace \<NAME_OF_CREDENTIALS_FILE> with the actual filename).
3. We can now proceed to **booting the management VM:**
   1. Open a terminal, and go to the [vagrant/](../vagrant/) folder
   2. Now start the VM by running:
      ```bash
      vagrant up
      ```
   3. Once it finishes booting up, ssh into it by running:
      ```bash
      vagrant ssh mgmt-esle
      ```
4. The following steps need to be run inside the management VM. Please follow the commands in [this script](../vagrant/guide.sh)