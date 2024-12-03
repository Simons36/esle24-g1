#!/bin/bash

NEGATIVE_FACTOR_MACHINE_TYPE="n1-standard-2"
POSITIVE_FACTOR_MACHINE_TYPE="n2-standard-4"
NEGATIVE_FACTOR_TSERVER_COUNT=3
POSITIVE_FACTOR_TSERVER_COUNT=5
NEGATIVE_FACTOR_SHARD_REPLICATION=false
POSITIVE_FACTOR_SHARD_REPLICATION=true
NEGATIVE_FACTOR_TRANSACTION_ISOLATION="read-committed"
POSITIVE_FACTOR_TRANSACTION_ISOLATION="snapshot"
NEGATIVE_FACTOR_WORKLOAD_TYPE="read-only"
POSITIVE_FACTOR_WORKLOAD_TYPE="write-only"
NEGATIVE_FACTOR_OPERATION_SIZE=1
POSITIVE_FACTOR_OPERATION_SIZE=100

ensure_vars() {
    if [ -z "$PROJECT_ID" ]; then
        echo "PROJECT_ID is not set"
        exit 1
    fi

    if [ -z "$FACTOR_MACHINE_TYPE" ]; then
        echo "FACTOR_MACHINE_TYPE is not set"
        echo "[-1] $NEGATIVE_FACTOR_MACHINE_TYPE"
        echo "[+1] $POSITIVE_FACTOR_MACHINE_TYPE"
        exit 1
    else
        if [ "$FACTOR_MACHINE_TYPE" == "-1" ]; then
            FACTOR_MACHINE_TYPE="$NEGATIVE_FACTOR_MACHINE_TYPE"
        elif [ "$FACTOR_MACHINE_TYPE" == "+1" ]; then
            FACTOR_MACHINE_TYPE="$POSITIVE_FACTOR_MACHINE_TYPE"
        fi
    fi

    if [ -z "$FACTOR_TSERVER_COUNT" ]; then
        echo "FACTOR_TSERVER_COUNT is not set"
        echo "[-1] $NEGATIVE_FACTOR_TSERVER_COUNT"
        echo "[+1] $POSITIVE_FACTOR_TSERVER_COUNT"
        exit 1
    else
        if [ "$FACTOR_TSERVER_COUNT" == "-1" ]; then
            FACTOR_TSERVER_COUNT=$NEGATIVE_FACTOR_TSERVER_COUNT
        elif [ "$FACTOR_TSERVER_COUNT" == "+1" ]; then
            FACTOR_TSERVER_COUNT=$POSITIVE_FACTOR_TSERVER_COUNT
        fi
    fi

    if [ -z "$FACTOR_SHARD_REPLICATION" ]; then
        echo "FACTOR_SHARD_REPLICATION is not set"
        echo "[-1] $NEGATIVE_FACTOR_SHARD_REPLICATION"
        echo "[+1] $POSITIVE_FACTOR_SHARD_REPLICATION"
        exit 1
    else
        if [ "$FACTOR_SHARD_REPLICATION" == "-1" ]; then
            FACTOR_SHARD_REPLICATION=$NEGATIVE_FACTOR_SHARD_REPLICATION
        elif [ "$FACTOR_SHARD_REPLICATION" == "+1" ]; then
            FACTOR_SHARD_REPLICATION=$POSITIVE_FACTOR_SHARD_REPLICATION
        fi
    fi

    if [ -z "$FACTOR_TRANSACTION_ISOLATION" ]; then
        echo "FACTOR_TRANSACTION_ISOLATION is not set"
        echo "[-1] $NEGATIVE_FACTOR_TRANSACTION_ISOLATION"
        echo "[+1] $POSITIVE_FACTOR_TRANSACTION_ISOLATION"
        exit 1
    else
        if [ "$FACTOR_TRANSACTION_ISOLATION" == "-1" ]; then
            FACTOR_TRANSACTION_ISOLATION=$NEGATIVE_FACTOR_TRANSACTION_ISOLATION
        elif [ "$FACTOR_TRANSACTION_ISOLATION" == "+1" ]; then
            FACTOR_TRANSACTION_ISOLATION=$POSITIVE_FACTOR_TRANSACTION_ISOLATION
        fi
    fi

    if [ -z "$FACTOR_WORKLOAD_TYPE" ]; then
        echo "FACTOR_WORKLOAD_TYPE is not set"
        echo "[-1] $NEGATIVE_FACTOR_WORKLOAD_TYPE"
        echo "[+1] $POSITIVE_FACTOR_WORKLOAD_TYPE"
        exit 1
    else
        if [ "$FACTOR_WORKLOAD_TYPE" == "-1" ]; then
            FACTOR_WORKLOAD_TYPE=$NEGATIVE_FACTOR_WORKLOAD_TYPE
        elif [ "$FACTOR_WORKLOAD_TYPE" == "+1" ]; then
            FACTOR_WORKLOAD_TYPE=$POSITIVE_FACTOR_WORKLOAD_TYPE
        fi
    fi

    if [ -z "$FACTOR_OPERATION_SIZE" ]; then
        echo "FACTOR_OPERATION_SIZE is not set"
        echo "[-1] $NEGATIVE_FACTOR_OPERATION_SIZE"
        echo "[+1] $POSITIVE_FACTOR_OPERATION_SIZE"
        exit 1
    else
        if [ "$FACTOR_OPERATION_SIZE" == "-1" ]; then
            FACTOR_OPERATION_SIZE=$NEGATIVE_FACTOR_OPERATION_SIZE
        elif [ "$FACTOR_OPERATION_SIZE" == "+1" ]; then
            FACTOR_OPERATION_SIZE=$POSITIVE_FACTOR_OPERATION_SIZE
        fi
    fi
}

process_args() {
    while [ "$#" -ne 0 ]; do
        case $1 in
            --skip-deploy)
                SKIP_DEPLOY=true
                shift
                ;;
            --skip-takedown)
                SKIP_TAKEDOWN=true
                shift
                ;;
            --skip-test)
                SKIP_TEST=true
                shift
                ;;
            --skip-terraform)
                SKIP_TERRAFORM=true
                shift
                ;;
            --start-step)
                START_STEP=$2
                shift
                shift
                ;;
            *)
                echo "Unknown argument: $arg"
                echo "Possible arguments: --skip-test, --skip-deploy, --skip-takedown"
                exit 1
                ;;
        esac
    done
}

setup_test() {
    if ! grep -q "\[test\]" inventory.ini; then
        cat <<EOF >> inventory.ini
[test]
testing_instance ansible_host=$TESTING_INSTANCE_IP ansible_user=vagrant ansible_connection=ssh ansible_ssh_private_key_file=/home/vagrant/.ssh/id_rsa_testing
EOF
        ssh $TESTING_INSTANCE_IP "rm -rf /home/vagrant/yb-sample-apps/"
        ssh $TESTING_INSTANCE_IP "rm -rf /home/vagrant/scripts/"
        scp -r /home/vagrant/esle24-g1/yb-sample-apps/ $TESTING_INSTANCE_IP:~/
        scp -r /home/vagrant/esle24-g1/scripts/ $TESTING_INSTANCE_IP:~/
    fi
}

# exit on error
set -e

source esle24-g1/.env

outdir="$FACTOR_OPERATION_SIZE.$FACTOR_WORKLOAD_TYPE.$FACTOR_TSERVER_COUNT.$FACTOR_TRANSACTION_ISOLATION.$FACTOR_SHARD_REPLICATION.$FACTOR_MACHINE_TYPE"
ensure_vars

gcloud config set project $PROJECT_ID

SKIP_DEPLOY=false
SKIP_TAKEDOWN=false
SKIP_TEST=false
SKIP_TERRAFORM=false
START_STEP=1
process_args "$@"

cd esle24-g1/gcp-deploy/

if [ "$SKIP_DEPLOY" == "false" ]; then
    echo "[DEPLOY]
    PROJECT_ID=$PROJECT_ID,
    FACTOR_MACHINE_TYPE=$FACTOR_MACHINE_TYPE,
    FACTOR_TSERVER_COUNT=$FACTOR_TSERVER_COUNT,
    FACTOR_SHARD_REPLICATION=$FACTOR_SHARD_REPLICATION,
    FACTOR_TRANSACTION_ISOLATION=$FACTOR_TRANSACTION_ISOLATION"
    
    if [ "$SKIP_TERRAFORM" == "false" ]; then
        terraform apply -auto-approve \
            -var="GCP_PROJECT_ID=$PROJECT_ID" \
            -var="GCP_MACHINE_TYPE=$FACTOR_MACHINE_TYPE" \
            -var="YB_TSERVER_COUNT=$FACTOR_TSERVER_COUNT" \
            -var="YB_SHARD_REPLICATION=$FACTOR_SHARD_REPLICATION" \
            -var="YB_TRANSACTION_ISOLATION=$FACTOR_TRANSACTION_ISOLATION"
        sleep 30
    fi


    if [ "$START_STEP" -le 1 ]; then
        ansible-playbook ansible-system-configuration.yaml
    fi

    if [ "$START_STEP" -le 2 ]; then
        ansible-playbook ansible-install-software.yaml
    fi

    if [ "$START_STEP" -le 3 ]; then
        ansible-playbook ansible-deploy-yb-master.yaml
    fi

    if [ "$START_STEP" -le 4 ]; then
        ansible-playbook ansible-deploy-yb-tserver.yaml
    fi
fi

ip_list=$(terraform output -json yb_tworker_IPs | grep -oP '\d+\.\d+\.\d+\.\d+' | sed 's/$/:5433/' | paste -sd ',' | sed 's/\n//g')

if [ "$SKIP_TEST" == "false" ]; then
    if [ -z "$TESTING_REMOTE" -o "$TESTING_REMOTE" == "false" ]; then   
        ansible-playbook ansible-test-yb.yaml
    else
        setup_test
        ssh $TESTING_INSTANCE_IP "/home/vagrant/scripts/02a-run-test.sh 25 $FACTOR_OPERATION_SIZE $FACTOR_WORKLOAD_TYPE $ip_list"
        mkdir -p /home/vagrant/esle24-g1/testing-out/$outdir/
        scp -r $TESTING_INSTANCE_IP:/home/vagrant/yb-sample-apps/test-output/ /home/vagrant/esle24-g1/testing-out/$outdir/
    fi
fi

if [ "$SKIP_TAKEDOWN" == "false" ]; then
    terraform destroy -auto-approve \
        -var="GCP_PROJECT_ID=$PROJECT_ID" \
        -var="GCP_MACHINE_TYPE=$FACTOR_MACHINE_TYPE" \
        -var="YB_TSERVER_COUNT=$FACTOR_TSERVER_COUNT" \
        -var="YB_SHARD_REPLICATION=$FACTOR_SHARD_REPLICATION" \
        -var="YB_TRANSACTION_ISOLATION=$FACTOR_TRANSACTION_ISOLATION"
fi

exit 0
