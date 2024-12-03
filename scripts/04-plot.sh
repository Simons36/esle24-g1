#!/bin/bash

data_dir=$1
results_dir=$2

gnuplot -e "test_suite='${data_dir}'" -e "output='${results_dir}'" gnuplot/graphs.gp

java -jar usm-calculator/esle-usl-1.0-SNAPSHOT.jar $data_dir/write/write_throughput.dat > $data_dir/usm-parameters-write.txt

# Extract the values and store them in variables
lambda_write=$(awk '/Lambda/ {print $2}' $data_dir/usm-parameters-write.txt)
delta_write=$(awk '/Lambda/ {print $4}' $data_dir/usm-parameters-write.txt)
kappa_write=$(awk '/Lambda/ {print $6}' $data_dir/usm-parameters-write.txt)

java -jar usm-calculator/esle-usl-1.0-SNAPSHOT.jar $data_dir/read/read_throughput.dat > $data_dir/usm-parameters-read.txt

# Extract the values and store them in variables
lambda_read=$(awk '/Lambda/ {print $2}' $data_dir/usm-parameters-read.txt)
delta_read=$(awk '/Lambda/ {print $4}' $data_dir/usm-parameters-read.txt)
kappa_read=$(awk '/Lambda/ {print $6}' $data_dir/usm-parameters-read.txt)

# Now run the gnuplot script to generate the USM graphs

gnuplot -e "output='$results_dir'" -e "sigma_write=$lambda_write" -e "sigma_read=$lambda_read" -e "alpha_write=$delta_write" -e "alpha_read=$delta_read" -e "beta_write=$kappa_write" -e "beta_read=$kappa_read" gnuplot/usm.gp
