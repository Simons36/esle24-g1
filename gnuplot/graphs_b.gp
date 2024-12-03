# we will take two arguments as input: test-suite folder (inside the test-data folder) and output folder

throughput_file = test_suite.'/throughput.dat'
latency_file = test_suite.'/latency.dat'
latency_throughput = test_suite.'/latency_throughput.dat'


# First, let's do the throughput and latency graphs
set terminal pngcairo
set output output.'/throughput_graph.png'
set offsets graph 0, 0.05, 0.05, 0.05
set xlabel 'Clients'
set ylabel 'Throughput'
plot throughput_file using 1:2 with linespoints notitle pt 6

set output output.'/latency_graph.png'
set xlabel 'Clients'
set ylabel 'Latency (ms)'
plot latency_file using 1:2 with linespoints notitle pt 6

set output output.'/latency_throughput.png'
set xlabel 'Throughput (Op/s)'
set ylabel 'Latency (ms)'
plot latency_throughput using 2:1 with points notitle pt 6 ps 1