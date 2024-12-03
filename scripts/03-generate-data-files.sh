#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <test_suite_output_dir> <target_data_dir>"
    exit 1
fi
test_suite_output_dir=$1
target_data_dir=$2

cd test-parser
mvn compile exec:java -Dexec.args="${test_suite_output_dir} ${target_data_dir}"
cd ..

echo "Data files generated in test-data folder."
