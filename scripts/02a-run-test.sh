#!/bin/bash

set -e

TEST_TIME=$1
ROW_NUMBER=$2
RW=$3
IP_LIST=$4

echo "Running test ($RW) for $TEST_TIME seconds with $ROW_NUMBER rows and $IP_LIST"

if [ $RW == "write-only" ]; then

for k in $(seq 10 10 150); do
    java -jar yb-sample-apps/target/yb-sample-apps.jar \
        --workload SqlWrite \
        --nodes $IP_LIST \
        --num_threads_write $k \
        --run_time_seconds $TEST_TIME \
        --operation_row_size $ROW_NUMBER \
        --uuid 00000000-0000-0000-0000-000000000000 \
        --stats_output_file $k.json
done

else # if Read-only

for k in $(seq 10 10 150); do
    java -jar yb-sample-apps/target/yb-sample-apps.jar \
        --workload SqlRead \
        --nodes $IP_LIST \
        --num_threads_read $k \
        --run_time_seconds $TEST_TIME \
        --uuid 00000000-0000-0000-0000-000000000000 \
        --stats_output_file $k.json
done

fi

