# We will take 7 arguments now: output folder; sigma, alpha and beta of write throughput test, and sigma, alpha and beta of read throughput test

set terminal pngcairo

# Set title and labels
set xlabel "Number of Resources (N)"
set ylabel "Capacity (C(N))"
set key at graph 0.95, graph 0.2 spacing 1.5
set grid

# Set the xrange for number of resources (e.g., from 1 to 100)
set xrange [1:100]

# The formula for the Universal Scalability Model
sigma_one = sigma_write_one
alpha_one = alpha_write_one
beta_one  = beta_write_one

sigma_two = sigma_write_two
alpha_two = alpha_write_two
beta_two  = beta_write_two

# Define the USM equation as a function
C_ONE(N) = (sigma_one * N) / (1 + alpha_one * (N - 1) + beta_one * N * (N - 1))
C_TWO(N) = (sigma_two * N) / (1 + alpha_two * (N - 1) + beta_two * N * (N - 1))

set output output.'/usm_write.png'

# Plot the function with a solid line
plot C_ONE(x) with lines lw 2 title "3 Replicas" \
, C_TWO(x) with lines lw 2 title "5 Replicas"

# Now, let's do the same for the read throughput test
set output output.'/usm_read.png'

sigma_one = sigma_read_one
alpha_one = alpha_read_one
beta_one  = beta_read_one

sigma_two = sigma_read_two
alpha_two = alpha_read_two
beta_two  = beta_read_two

plot C_ONE(x) with lines lw 2 title "3 Replicas" \
, C_TWO(x) with lines lw 2 title "5 Replicas"


