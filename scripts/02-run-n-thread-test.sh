#!/bin/bash

# Check arguments
if [ "$#" -ne 8 ]; then
    echo "Usage: $0 <number_of_threads> <number_of_tests_per_thread> <time_per_test> <output_dir> <max_write_threads> <max_read_threads> <row_number> <ip_list>"
    exit 1
fi


n_threads=$1
n_tests=$2
time_per_test=$3
output_dir=$4
max_write_threads=$5
max_read_threads=$6
row_number=$7
yb_service_address=$8
echo "./$0 $@" >> $output_dir/in.log

test_output_folder="yb-sample-apps/test-output"
uuid='00000000-0000-0000-0000-000000000000'
folder_name="${n_threads}_threads"
thread_folder_write="$output_dir/write/$folder_name"
thread_folder_read="$output_dir/read/$folder_name"

if [ $n_threads -le $max_write_threads ]; then
    mkdir -p "$thread_folder_write"
    # Run the tests (Write)
    for ((k=1; k<=n_tests; k=k+5))
    do
        echo "Running write test $k for $time_per_test seconds..."

        # Run the test command
        java -jar yb-sample-apps/target/yb-sample-apps.jar --workload SqlWrite --nodes 34.76.221.139:5433,35.205.133.158:5433,35.205.185.82:5433,34.140.158.53:5433,34.38.1.115:5433 --num_threads_write $n_threads --run_time_seconds $time_per_test --uuid $uuid --operation_row_size $row_number --stats_output_file test_$k.json

        # Move the output file to the test suite folder
        mv "${test_output_folder}/test_$k.json" "$thread_folder_write"
        
        echo "Test $k completed."
    done
fi
if [ $n_threads -le $max_read_threads ]; then
    mkdir -p "$thread_folder_read"
    # Now the read tests
    for ((k=1; k<=n_tests; k=k+5))
    do
        echo "Running read test $k for $time_per_test seconds..."

        java -jar yb-sample-apps/target/yb-sample-apps.jar --workload SqlRead  --nodes 34.76.221.139:5433,35.205.133.158:5433,35.205.185.82:5433,34.140.158.53:5433,34.38.1.115:5433 --num_threads_read $n_threads --run_time_seconds $time_per_test  --stats_output_file test_$k.json  --uuid $uuid

        # Move the output file to the test suite folder
        mv "${test_output_folder}/test_$k.json" "$thread_folder_read"

        echo "Test $k completed."
    done
fi