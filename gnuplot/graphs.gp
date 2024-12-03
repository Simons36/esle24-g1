# we will take two arguments as input: test-suite folder (inside the test-data folder) and output folder

read_throughput_file = test_suite.'/read/read_throughput.dat'
write_throughput_file = test_suite.'/write/write_throughput.dat'
read_latency_file = test_suite.'/read/read_latency.dat'
write_latency_file = test_suite.'/write/write_latency.dat'
read_latency_throughput = test_suite.'/read/read_latency_throughput.dat'
write_latency_throughput = test_suite.'/write/write_latency_throughput.dat'


# First, let's do the throughput and latency graphs
set terminal pngcairo
set output output.'/throughput_read_graph.png'
set offsets graph 0, 0.05, 0.05, 0.05
set xlabel 'Clients'
set ylabel 'Throughput'
#set xrange [0:16]
#set yrange [0:7000]
plot read_throughput_file using 1:2 with linespoints notitle pt 6

set output output.'/throughput_write_graph.png'
#set xrange [0:26]
#set yrange [0:5000]
plot write_throughput_file using 1:2 with linespoints notitle pt 6

set output output.'/latency_read_graph.png'
set xlabel 'Clients'
set ylabel 'Latency (ms)'
#set xrange [0:16]
#set yrange [0:4]
plot read_latency_file using 1:2 with linespoints notitle pt 6

set output output.'/latency_write_graph.png'
#set xrange [0:26]
#set yrange [0:8]
plot write_latency_file using 1:2 with linespoints notitle pt 6

set output output.'/read_latency_throughput.png'
set xlabel 'Throughput (Op/s)'
set ylabel 'Latency (ms)'
#set xrange [0:7000]
#set yrange [0:4]
plot read_latency_throughput using 2:1 with points notitle pt 6 ps 1
set output output.'/write_latency_throughput.png'
#set xrange [0:5000]
#set yrange [0:8]
plot write_latency_throughput using 2:1 with points notitle pt 6 ps 1