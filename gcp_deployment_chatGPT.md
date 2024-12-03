Deploying **YugabyteDB** on **Google Compute Engine (GCE)** using **Kubernetes** (without relying on Google Kubernetes Engine, GKE) and managing the infrastructure with **Terraform** involves several steps. This comprehensive guide will walk you through the entire process, from setting up the Kubernetes cluster on GCE to deploying YugabyteDB and managing the infrastructure using Terraform.

## **Table of Contents**

- [**Table of Contents**](#table-of-contents)
- [**Prerequisites**](#prerequisites)
- [**Overview of the Deployment Process**](#overview-of-the-deployment-process)
- [**Setting Up Kubernetes on GCE Using Compute Engine**](#setting-up-kubernetes-on-gce-using-compute-engine)
  - [**1. Provisioning Compute Engine Instances**](#1-provisioning-compute-engine-instances)
  - [**2. Setting Up Kubernetes Cluster**](#2-setting-up-kubernetes-cluster)
  - [**3. Configuring Networking and Security**](#3-configuring-networking-and-security)
- [**Managing Infrastructure with Terraform**](#managing-infrastructure-with-terraform)
  - [**1. Installing Terraform**](#1-installing-terraform)
  - [**2. Writing Terraform Configuration Files**](#2-writing-terraform-configuration-files)
  - [**3. Initializing and Applying Terraform Configurations**](#3-initializing-and-applying-terraform-configurations)
- [**Deploying YugabyteDB on Kubernetes**](#deploying-yugabytedb-on-kubernetes)
  - [**1. Preparing Kubernetes for YugabyteDB Deployment**](#1-preparing-kubernetes-for-yugabytedb-deployment)
  - [**2. Deploying YugabyteDB**](#2-deploying-yugabytedb)
  - [**3. Verifying the Deployment**](#3-verifying-the-deployment)
- [**Automating the Entire Process**](#automating-the-entire-process)
- [**Best Practices and Considerations**](#best-practices-and-considerations)
- [**Conclusion**](#conclusion)

---

## **Prerequisites**

Before proceeding, ensure you have the following:

- **Google Cloud Account:** Access to Google Cloud Platform with permissions to create Compute Engine instances, networking components, etc.
- **Terraform Installed:** [Download and install Terraform](https://www.terraform.io/downloads).
- **Kubectl Installed:** [Download and install kubectl](https://kubernetes.io/docs/tasks/tools/).
- **SSH Keys:** Set up SSH keys for accessing Compute Engine instances.
- **Basic Knowledge:** Familiarity with Kubernetes, Terraform, and Google Cloud Platform.

---

## **Overview of the Deployment Process**

1. **Provision Infrastructure with Terraform:**
    - Create a Virtual Private Cloud (VPC) network.
    - Provision Compute Engine instances to serve as Kubernetes master and worker nodes.
    - Configure firewall rules and networking.

2. **Set Up Kubernetes Cluster:**
    - Initialize Kubernetes on master node.
    - Join worker nodes to the cluster.
    - Configure kubectl to interact with the cluster.

3. **Deploy YugabyteDB:**
    - Create necessary Kubernetes manifests or use Helm charts.
    - Deploy YugabyteDB services and StatefulSets.
    - Verify the deployment and ensure cluster health.

4. **Manage and Scale:**
    - Use Terraform to manage infrastructure changes.
    - Scale Kubernetes nodes as needed.
    - Monitor YugabyteDB performance and scalability.

---

## **Setting Up Kubernetes on GCE Using Compute Engine**

Since you’re not using GKE, you’ll need to manually set up Kubernetes on Compute Engine instances. Here’s how to do it:

### **1. Provisioning Compute Engine Instances**

You need to create VM instances that will act as Kubernetes masters and workers.

**Using Terraform:**

Create a Terraform configuration file (`main.tf`) to define the Compute Engine instances.

```hcl
provider "google" {
  project = "your-gcp-project-id"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_network" "k8s_network" {
  name = "k8s-network"
}

resource "google_compute_firewall" "k8s_firewall" {
  name    = "k8s-firewall"
  network = google_compute_network.k8s_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "2379-2380", "10250", "10251", "10252", "30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "k8s_master" {
  name         = "k8s-master"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-jammy-v20230810"
    }
  }

  network_interface {
    network    = google_compute_network.k8s_network.name
    subnetwork = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Install Docker
    apt-get update
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker

    # Install Kubernetes components
    apt-get update && apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF2 > /etc/apt/sources.list.d/kubernetes.list
    deb https://apt.kubernetes.io/ kubernetes-xenial main
    EOF2
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl

    # Initialize Kubernetes master
    kubeadm init --pod-network-cidr=10.244.0.0/16

    # Configure kubectl for the ubuntu user
    mkdir -p /home/ubuntu/.kube
    cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
    chown ubuntu:ubuntu /home/ubuntu/.kube/config

    # Install Flannel network
    sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  EOF
}

resource "google_compute_instance" "k8s_worker" {
  count        = 3
  name         = "k8s-worker-${count.index + 1}"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-jammy-v20230810"
    }
  }

  network_interface {
    network    = google_compute_network.k8s_network.name
    subnetwork = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    # Install Docker
    apt-get update
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker

    # Install Kubernetes components
    apt-get update && apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF2 > /etc/apt/sources.list.d/kubernetes.list
    deb https://apt.kubernetes.io/ kubernetes-xenial main
    EOF2
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl

    # Wait for master to initialize
    while ! nc -z k8s-master 6443; do
      sleep 1
    done

    # Join the cluster (replace <JOIN_COMMAND> with the actual join command)
    kubeadm join k8s-master:6443 --token <YOUR_TOKEN> --discovery-token-ca-cert-hash sha256:<YOUR_HASH>
  EOF
}
```

**Notes:**

- **Replace Placeholders:**
    - `<YOUR_TOKEN>` and `<YOUR_HASH>` in the worker `metadata_startup_script` need to be replaced with the actual token and hash generated by `kubeadm init`. This can be automated by fetching these values from the master node, but for simplicity, you might need to perform this step manually or enhance the Terraform script with more automation.

- **Pod Network:**
    - This example uses **Flannel** as the pod network. You can choose other network plugins like Calico based on your requirements.

- **Security Considerations:**
    - The firewall rule in the example is open to all IPs (`0.0.0.0/0`). For a production environment, restrict access to trusted IP ranges.

### **2. Setting Up Kubernetes Cluster**

If you choose to set up Kubernetes manually instead of using Terraform's `metadata_startup_script`, follow these steps:

1. **Initialize Master Node:**

   SSH into the master node and run:

   ```bash
   sudo kubeadm init --pod-network-cidr=10.244.0.0/16
   ```

2. **Configure kubectl:**

   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

3. **Install Pod Network (e.g., Flannel):**

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
   ```

4. **Join Worker Nodes:**

   On each worker node, run the `kubeadm join` command obtained from the master initialization step.

### **3. Configuring Networking and Security**

Ensure that:

- **Firewall Rules** are correctly set to allow necessary Kubernetes traffic.
- **SSH Access** is secured using SSH keys.
- **Service Accounts** and **RBAC** are configured as needed for Kubernetes operations.

---

## **Managing Infrastructure with Terraform**

Terraform is a powerful tool for infrastructure as code (IaC), allowing you to define and manage your cloud resources declaratively.

### **1. Installing Terraform**

If you haven't installed Terraform yet, follow these steps:

1. **Download Terraform:**

   Visit the [Terraform Downloads](https://www.terraform.io/downloads) page and download the appropriate package for your OS.

2. **Install Terraform:**

   - **On Linux/Mac:**

     ```bash
     sudo unzip terraform_<VERSION>_linux_amd64.zip -d /usr/local/bin/
     ```

   - **On Windows:**

     Extract the executable and add it to your system PATH.

3. **Verify Installation:**

   ```bash
   terraform version
   ```

### **2. Writing Terraform Configuration Files**

Create a Terraform configuration that defines all necessary resources. Here's an extended version of the earlier `main.tf` with variables and better structuring.

**Directory Structure:**

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
└── scripts/
    ├── master_setup.sh
    └── worker_setup.sh
```

**variables.tf:**

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  default     = "us-central1-a"
}

variable "network_name" {
  description = "Name of the VPC network"
  default     = "k8s-network"
}

variable "machine_type_master" {
  description = "Machine type for master node"
  default     = "n1-standard-2"
}

variable "machine_type_worker" {
  description = "Machine type for worker nodes"
  default     = "n1-standard-2"
}

variable "image_family" {
  description = "OS Image family"
  default     = "ubuntu-2204-lts"
}

variable "image_project" {
  description = "OS Image project"
  default     = "ubuntu-os-cloud"
}

variable "num_workers" {
  description = "Number of worker nodes"
  default     = 3
}
```

**main.tf:**

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "k8s_network" {
  name = var.network_name
}

resource "google_compute_firewall" "k8s_firewall" {
  name    = "k8s-firewall"
  network = google_compute_network.k8s_network.name

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "2379-2380", "10250", "10251", "10252", "30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["k8s"]
}

resource "google_compute_instance" "k8s_master" {
  name         = "k8s-master"
  machine_type = var.machine_type_master
  zone         = var.zone

  tags = ["k8s"]

  boot_disk {
    initialize_params {
      image = var.image_family
      project = var.image_project
    }
  }

  network_interface {
    network    = google_compute_network.k8s_network.name
    subnetwork = "default"
    access_config {}
  }

  metadata_startup_script = file("scripts/master_setup.sh")
}

resource "google_compute_instance" "k8s_workers" {
  count        = var.num_workers
  name         = "k8s-worker-${count.index + 1}"
  machine_type = var.machine_type_worker
  zone         = var.zone

  tags = ["k8s"]

  boot_disk {
    initialize_params {
      image = var.image_family
      project = var.image_project
    }
  }

  network_interface {
    network    = google_compute_network.k8s_network.name
    subnetwork = "default"
    access_config {}
  }

  metadata_startup_script = file("scripts/worker_setup.sh")
}

output "master_ip" {
  description = "External IP of the Kubernetes master"
  value       = google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip
}

output "worker_ips" {
  description = "External IPs of the Kubernetes workers"
  value       = [for instance in google_compute_instance.k8s_workers : instance.network_interface[0].access_config[0].nat_ip]
}
```

**scripts/master_setup.sh:**

```bash
#!/bin/bash
# Update and install dependencies
apt-get update -y
apt-get install -y docker.io apt-transport-https curl

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Install Kubernetes components
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Initialize Kubernetes master
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

# Configure kubectl for ubuntu user
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Install Flannel network
sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Generate join token and save to file
kubeadm token create --print-join-command > /var/lib/kubeadm/join_command.sh
chmod +x /var/lib/kubeadm/join_command.sh
```

**scripts/worker_setup.sh:**

```bash
#!/bin/bash
# Update and install dependencies
apt-get update -y
apt-get install -y docker.io apt-transport-https curl

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Install Kubernetes components
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Wait for master to initialize
while ! nc -z <MASTER_IP> 6443; do
  echo "Waiting for master to be ready..."
  sleep 5
done

# Fetch join command from master
JOIN_COMMAND=$(ssh -o StrictHostKeyChecking=no ubuntu@<MASTER_IP> 'sudo cat /var/lib/kubeadm/join_command.sh')

# Join the Kubernetes cluster
eval $JOIN_COMMAND
```

**Notes:**

- **Master IP in Worker Script:**
    - Replace `<MASTER_IP>` with the actual master node's IP. You can automate this by using Terraform templates or other dynamic methods.

- **Automating Join Command:**
    - To fully automate, consider using Terraform's remote-exec or other provisioning tools to fetch the join command dynamically.

**outputs.tf:**

```hcl
output "master_external_ip" {
  description = "The external IP of the Kubernetes master node"
  value       = google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip
}

output "worker_external_ips" {
  description = "The external IPs of the Kubernetes worker nodes"
  value       = google_compute_instance.k8s_workers.*.network_interface[0].access_config[0].nat_ip
}
```

### **3. Initializing and Applying Terraform Configurations**

1. **Set Up Variables:**

   Create a `terraform.tfvars` file to define your variables.

   ```hcl
   project_id          = "your-gcp-project-id"
   region              = "us-central1"
   zone                = "us-central1-a"
   network_name        = "k8s-network"
   machine_type_master = "n1-standard-2"
   machine_type_worker = "n1-standard-2"
   num_workers         = 3
   ```

2. **Initialize Terraform:**

   ```bash
   cd terraform
   terraform init
   ```

3. **Plan Terraform Deployment:**

   ```bash
   terraform plan -out=plan.out
   ```

4. **Apply Terraform Configuration:**

   ```bash
   terraform apply "plan.out"
   ```

5. **Post-Deployment Steps:**

   - **Retrieve Master IP:**

     ```bash
     terraform output master_external_ip
     ```

   - **Access Master Node:**

     SSH into the master node:

     ```bash
     gcloud compute ssh k8s-master --zone us-central1-a
     ```

   - **Retrieve Join Command:**

     On the master node, retrieve the join command:

     ```bash
     sudo cat /var/lib/kubeadm/join_command.sh
     ```

   - **Update Worker Scripts:**

     Ensure that the worker nodes have the correct join command to join the cluster.

---

## **Deploying YugabyteDB on Kubernetes**

With your Kubernetes cluster up and running on GCE, the next step is to deploy YugabyteDB.

### **1. Preparing Kubernetes for YugabyteDB Deployment**

Before deploying YugabyteDB, ensure that:

- **Persistent Storage:** YugabyteDB requires persistent volumes. Configure a storage class or use existing GCE Persistent Disks.
  
- **Resource Allocation:** Ensure that your nodes have sufficient CPU, memory, and storage to handle YugabyteDB workloads.

- **Networking:** Ensure that necessary ports are open and network policies allow communication between YugabyteDB pods.

### **2. Deploying YugabyteDB**

You can deploy YugabyteDB using Kubernetes manifests or Helm charts. Using Helm simplifies the process.

**Using Helm:**

1. **Install Helm:**

   If Helm is not installed, install it on your local machine or master node.

   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

2. **Add Yugabyte Helm Repository:**

   ```bash
   helm repo add yugabytedb https://charts.yugabyte.com
   helm repo update
   ```

3. **Create Namespace:**

   ```bash
   kubectl create namespace yugabyte
   ```

4. **Install YugabyteDB Cluster:**

   ```bash
   helm install yb-operator yugabytedb/yugabyte --namespace yugabyte
   ```

   **Customizing the Deployment:**

   You can customize the deployment by creating a `values.yaml` file with desired configurations.

   Example `values.yaml`:

   ```yaml
   image:
     repository: yugabytedb/yugabyte
     tag: 2.16.0.0-b3

   master:
     replicas: 3
     resources:
       requests:
         cpu: "500m"
         memory: "1Gi"
       limits:
         cpu: "1"
         memory: "2Gi"

   tserver:
     replicas: 3
     resources:
       requests:
         cpu: "500m"
         memory: "1Gi"
       limits:
         cpu: "1"
         memory: "2Gi"

   storage:
     persistentVolume:
       enabled: true
       size: 20Gi
       storageClass: "standard"
   ```

   Install with custom values:

   ```bash
   helm install yb-operator yugabytedb/yugabyte --namespace yugabyte -f values.yaml
   ```

**Using Kubernetes Manifests:**

Alternatively, deploy YugabyteDB using YAML manifests. Refer to the [YugabyteDB Kubernetes Deployment Guide](https://docs.yugabyte.com/latest/deploy/kubernetes/) for detailed steps.

### **3. Verifying the Deployment**

1. **Check Pods Status:**

   ```bash
   kubectl get pods -n yugabyte
   ```

   Ensure all YugabyteDB pods are running.

2. **Access YugabyteDB UI:**

   Expose the YugabyteDB UI service and access it via browser.

   ```bash
   kubectl port-forward svc/yb-ui -n yugabyte 7000:7000
   ```

   Access `http://localhost:7000` in your browser.

3. **Run Test Queries:**

   Use `ysqlsh` or `ycqlsh` to connect to YugabyteDB and run test queries to ensure it's functioning correctly.

---

## **Automating the Entire Process**

To streamline the deployment process, you can integrate Terraform and Kubernetes automation scripts. Here's how:

1. **Terraform Provisioning:**

   - Ensure Terraform scripts handle the provisioning of all necessary infrastructure.
   - Use Terraform `null_resource` with `remote-exec` or `local-exec` to run Kubernetes setup scripts after VM creation.

2. **Helm Automation:**

   - After Kubernetes is set up, use Terraform's `helm` provider to deploy YugabyteDB directly from Terraform.

   **Example:**

   Add the Helm provider in `main.tf`:

   ```hcl
   provider "helm" {
     kubernetes {
       host                   = "https://${google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip}:6443"
       client_certificate     = base64decode(google_compute_instance.k8s_master.metadata[0].kube_config_client_certificate)
       client_key             = base64decode(google_compute_instance.k8s_master.metadata[0].kube_config_client_key)
       cluster_ca_certificate = base64decode(google_compute_instance.k8s_master.metadata[0].kube_config_cluster_ca_certificate)
     }
   }

   resource "helm_release" "yugabytedb" {
     name       = "yb-operator"
     repository = "https://charts.yugabyte.com"
     chart      = "yugabyte"
     namespace  = "yugabyte"
     create_namespace = true

     values = [
       file("values.yaml")
     ]
   }
   ```

   **Note:** Properly configure the Kubernetes provider with the necessary credentials and certificates. This may require outputting the kubeconfig from the master node and passing it to Terraform, which can be complex and may require additional scripting or Terraform modules.

3. **CI/CD Integration:**

   - Integrate the Terraform scripts into a CI/CD pipeline (e.g., Jenkins, GitHub Actions) to automate deployments.

---

## **Best Practices and Considerations**

1. **Security:**

   - **Restrict Firewall Rules:** Limit access to necessary ports and trusted IP ranges.
   - **Use Service Accounts:** Assign minimal permissions required for services.
   - **SSH Keys Management:** Securely manage SSH keys and avoid using default or shared keys.

2. **Scalability:**

   - **Horizontal Scaling:** Design the Kubernetes cluster to allow adding more worker nodes as needed.
   - **Resource Limits:** Set appropriate resource requests and limits to prevent resource contention.

3. **High Availability:**

   - **Master Node Redundancy:** For production, consider setting up multiple master nodes for Kubernetes.
   - **YugabyteDB Replication:** Configure YugabyteDB replication to ensure data durability and availability.

4. **Monitoring and Logging:**

   - Implement monitoring tools (e.g., Prometheus, Grafana) to monitor cluster and YugabyteDB health.
   - Set up centralized logging for easier troubleshooting.

5. **Backup and Recovery:**

   - Regularly backup YugabyteDB data.
   - Plan for disaster recovery scenarios.

6. **Cost Management:**

   - Monitor resource usage to optimize costs.
   - Use Terraform’s modularity to manage resources efficiently.

7. **Automation and Idempotency:**

   - Ensure Terraform scripts are idempotent and can be reapplied without adverse effects.
   - Automate repetitive tasks to reduce manual intervention and errors.

---

## **Conclusion**

Deploying **YugabyteDB** on **Google Compute Engine** using **Kubernetes** and managing the infrastructure with **Terraform** is a robust solution that offers flexibility and control over your database deployment. By following the steps outlined above, you can set up a scalable, secure, and highly available YugabyteDB cluster tailored to your specific needs.

**Key Takeaways:**

- **Infrastructure as Code:** Using Terraform ensures that your infrastructure is version-controlled, repeatable, and scalable.
- **Manual Kubernetes Setup:** While more involved than using GKE, setting up Kubernetes manually offers deeper insights and customization.
- **Automation:** Combining Terraform with Helm and CI/CD practices can streamline deployments and updates.
- **Best Practices:** Prioritize security, scalability, and maintainability to ensure a reliable deployment.

By adhering to these guidelines and best practices, you can effectively deploy and manage YugabyteDB on GCE, leveraging the full power of Kubernetes and Terraform for a resilient and efficient database solution.