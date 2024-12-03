# We will take 7 arguments now: output folder; sigma, alpha and beta of write throughput test, and sigma, alpha and beta of read throughput test

set terminal pngcairo

# Set title and labels
set title "Universal Scalability Model"
set xlabel "Number of Nodes (N)"
set ylabel "Capacity (C(N))"
set grid

# Set the xrange for number of resources (e.g., from 1 to 100)
set xrange [1:1000]

# The formula for the Universal Scalability Model
# sigma = sigma
# alpha = alpha
# beta  = beta

# Define the USM equation as a function
C(N) = (sigma * N) / (1 + alpha * (N - 1) + beta * N * (N - 1))

set output output.'/usm.png'

# Plot the function with a solid line
plot C(x) with lines lw 2 notitle


