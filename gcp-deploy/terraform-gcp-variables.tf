# How to define variables in terraform:
# https://www.terraform.io/docs/configuration/variables.html

# ID of the project, find it in the GCP console when clicking 
# on the project name (on the top dropdown)
variable "GCP_PROJECT_ID" {
    description = "ID of the project, find it in the GCP console when clicking on the project name (on the top dropdown)"
}

# Regions list is found at:
# https://cloud.google.com/compute/docs/regions-zones/regions-zones?hl=en_US
# For prices of your deployment check:
# Compute Engine dashboard -> VM instances -> Zone
variable "GCP_ZONE" {
    default = "europe-west1-b"
}

# Minimum required
variable "DISK_SIZE" {
    default = "15"
}


variable "YB_MASTER_COUNT" {
    default = 3
}

### Experimental Factors

variable "GCP_MACHINE_TYPE" {
    description = "Low: n1-standard-2, High: n2-standard-4"
}

variable "YB_TSERVER_COUNT" {
    description = "Low: 3, High: 5"
}

variable "YB_SHARD_REPLICATION" {
    description = "Low: false, High: true"
}

variable "YB_TRANSACTION_ISOLATION" {
    description = "Low: read-committed, High: snapshot"
}
