# We will take 7 arguments now: output folder; sigma, alpha and beta of write throughput test, and sigma, alpha and beta of read throughput test

set terminal pngcairo

# Set title and labels
set title "Universal Scalability Model (Write Operations)"
set xlabel "Number of Resources (N)"
set ylabel "Capacity (C(N))"
set grid

# Set the xrange for number of resources (e.g., from 1 to 100)
set xrange [1:100]

# The formula for the Universal Scalability Model
sigma = sigma_write
alpha = alpha_write
beta  = beta_write

# Define the USM equation as a function
C(N) = (sigma * N) / (1 + alpha * (N - 1) + beta * N * (N - 1))

set output output.'/usm_write.png'

# Plot the function with a solid line
plot C(x) with lines lw 2 notitle


set title "Universal Scalability Model (Read Operations)"
set output output.'/usm_read.png'

sigma = sigma_read
alpha = alpha_read
beta  = beta_read

plot C(x) with lines lw 2 notitle


