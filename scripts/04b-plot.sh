#!/bin/bash

data_dir=$1
results_dir=$2

gnuplot -e "test_suite='${data_dir}'" -e "output='${results_dir}'" gnuplot/graphs_b.gp

java -jar usm-calculator/esle-usl-1.0-SNAPSHOT.jar $data_dir/throughput.dat > $data_dir/usm-parameters.txt

# Extract the values and store them in variables
lambda=$(awk '/Lambda/ {print $2}' $data_dir/usm-parameters.txt)
delta=$(awk '/Lambda/ {print $4}' $data_dir/usm-parameters.txt)
kappa=$(awk '/Lambda/ {print $6}' $data_dir/usm-parameters.txt)

# Now run the gnuplot script to generate the USM graphs

gnuplot -e "output='$results_dir'" -e "sigma=$lambda" -e "alpha=$delta" -e "beta=$kappa" gnuplot/usm_b.gp
