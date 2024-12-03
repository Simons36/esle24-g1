#!/bin/bash

set -e

# Check if the required arguments are provided
if [ "$#" -ne 7 ]; then
    echo "Usage: $0 <number_of_tests> <time_per_test_in_seconds> <max_number_of_write_threads> <max_number_of_read_threads> <row_number> <threshold_thread_number> <interval_thread_increase>"
    exit 1
fi

# Assign arguments to variables
export NUM_TESTS=$1
export TIME_PER_TEST=$2
export MAX_NUMBER_OF_WRITE_THREADS=$3
export MAX_NUMBER_OF_READ_THREADS=$4
export ROW_NUMBER=$5
export THRESHOLD_THREAD_NUMBER=$6
export INTERVAL_THREAD_INCREASE=$7
max_write_or_read_threads=$(($MAX_NUMBER_OF_WRITE_THREADS > $MAX_NUMBER_OF_READ_THREADS ? $MAX_NUMBER_OF_WRITE_THREADS : $MAX_NUMBER_OF_READ_THREADS))

# Create directories
export TEST_INPUT_DIR="$PWD/outputs/test-input"
export TEST_OUTPUT_DIR="$PWD/outputs/test-output"
export TEST_DATA_DIR="$PWD/outputs/test-data"
export TEST_RESULTS_DIR="$PWD/outputs/test-results"
mkdir -p $TEST_INPUT_DIR $TEST_OUTPUT_DIR $TEST_DATA_DIR $TEST_RESULTS_DIR

./scripts/01-build-workload-generator.sh

# Find next test suite id
# All test suits are stored in $TEST_OUTPUT_DIR/test-suite-<id>
TEST_SUITE_ID=1
for dir in $TEST_OUTPUT_DIR/test-suite-*; do
    if [ -d "$dir" ]; then
        suite_id=$(basename "$dir" | cut -d'-' -f3)
        if [ "$suite_id" -ge "$TEST_SUITE_ID" ]; then
            TEST_SUITE_ID=$((suite_id + 1))
        fi
    fi
done
export TEST_SUITE_ID=$(printf "%03d" $TEST_SUITE_ID)

# Create the new test suite folder
export TEST_SUITE_OUTPUT_DIR="$TEST_OUTPUT_DIR/test-suite-$TEST_SUITE_ID"
export TEST_SUITE_DATA_DIR="$TEST_DATA_DIR/test-suite-$TEST_SUITE_ID"
export TEST_SUITE_RESULTS_DIR="$TEST_RESULTS_DIR/test-suite-$TEST_SUITE_ID"
mkdir -p $TEST_SUITE_OUTPUT_DIR $TEST_SUITE_DATA_DIR $TEST_SUITE_RESULTS_DIR

# Log the test parameters
echo "./test.sh $@" > $TEST_INPUT_DIR/test-suite-$TEST_SUITE_ID.in

# Loop for each thread count
for ((n_threads=1; n_threads<=THRESHOLD_THREAD_NUMBER; n_threads++))
do
    ./scripts/02-run-n-thread-test.sh $n_threads $NUM_TESTS $TIME_PER_TEST $TEST_SUITE_OUTPUT_DIR $MAX_NUMBER_OF_WRITE_THREADS $MAX_NUMBER_OF_READ_THREADS $ROW_NUMBER
done

for ((n_threads=THRESHOLD_THREAD_NUMBER+INTERVAL_THREAD_INCREASE; n_threads<=max_write_or_read_threads; n_threads+=INTERVAL_THREAD_INCREASE))
do
    ./scripts/02-run-n-thread-test.sh $n_threads $NUM_TESTS $TIME_PER_TEST $TEST_SUITE_OUTPUT_DIR $MAX_NUMBER_OF_WRITE_THREADS $MAX_NUMBER_OF_READ_THREADS $ROW_NUMBER
done

echo "All tests completed."

# Generate data files for gnuplot
./scripts/03-generate-data-files.sh $TEST_SUITE_OUTPUT_DIR $TEST_DATA_DIR

# Now run gnuplot to get the graphs
./scripts/04-plot.sh $TEST_SUITE_DATA_DIR $TEST_RESULTS_DIR