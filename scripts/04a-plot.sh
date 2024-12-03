#!/bin/bash

data_dir_one=$1
data_dir_two=$2
results_dir=$3

gnuplot -e "test_suite_one='${data_dir_one}'" -e "test_suite_two='${data_dir_two}'" -e "output='${results_dir}'" gnuplot/graphs_a.gp

java -jar usm-calculator/esle-usl-1.0-SNAPSHOT.jar $data_dir_one/write/write_throughput.dat > $data_dir_one/usm-parameters-write.txt
java -jar usm-calculator/esle-usl-1.0-SNAPSHOT.jar $data_dir_two/write/write_throughput.dat > $data_dir_two/usm-parameters-write.txt

# Extract the values and store them in variables
lambda_write_one=$(awk '/Lambda/ {print $2}' $data_dir_one/usm-parameters-write.txt)
delta_write_one=$(awk '/Lambda/ {print $4}' $data_dir_one/usm-parameters-write.txt)
kappa_write_one=$(awk '/Lambda/ {print $6}' $data_dir_one/usm-parameters-write.txt)

lambda_write_two=$(awk '/Lambda/ {print $2}' $data_dir_two/usm-parameters-write.txt)
delta_write_two=$(awk '/Lambda/ {print $4}' $data_dir_two/usm-parameters-write.txt)
kappa_write_two=$(awk '/Lambda/ {print $6}' $data_dir_two/usm-parameters-write.txt)

java -jar usm-calculator/esle-usl-1.0-SNAPSHOT.jar $data_dir_one/read/read_throughput.dat > $data_dir_one/usm-parameters-read.txt
java -jar usm-calculator/esle-usl-1.0-SNAPSHOT.jar $data_dir_two/read/read_throughput.dat > $data_dir_two/usm-parameters-read.txt

# Extract the values and store them in variables
lambda_read_one=$(awk '/Lambda/ {print $2}' $data_dir_one/usm-parameters-read.txt)
delta_read_one=$(awk '/Lambda/ {print $4}' $data_dir_one/usm-parameters-read.txt)
kappa_read_one=$(awk '/Lambda/ {print $6}' $data_dir_one/usm-parameters-read.txt)

lambda_read_two=$(awk '/Lambda/ {print $2}' $data_dir_two/usm-parameters-read.txt)
delta_read_two=$(awk '/Lambda/ {print $4}' $data_dir_two/usm-parameters-read.txt)
kappa_read_two=$(awk '/Lambda/ {print $6}' $data_dir_two/usm-parameters-read.txt)

# Now run the gnuplot script to generate the USM graphs

gnuplot -e "output='$results_dir'" \
    -e "sigma_write_one=$lambda_write_one" -e "sigma_read_one=$lambda_read_one" \
    -e "alpha_write_one=$delta_write_one" -e "alpha_read_one=$delta_read_one" \
    -e "beta_write_one=$kappa_write_one" -e "beta_read_one=$kappa_read_one" \
    -e "sigma_write_two=$lambda_write_two" -e "sigma_read_two=$lambda_read_two" \
    -e "alpha_write_two=$delta_write_two" -e "alpha_read_two=$delta_read_two" \
    -e "beta_write_two=$kappa_write_two" -e "beta_read_two=$kappa_read_two" \
    gnuplot/usm_a.gp
