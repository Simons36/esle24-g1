# we will take two arguments as input: test-suite folder (inside the test-data folder) and output folder

read_throughput_file_one = test_suite_one.'/read/read_throughput.dat'
write_throughput_file_one = test_suite_one.'/write/write_throughput.dat'
read_latency_file_one = test_suite_one.'/read/read_latency.dat'
write_latency_file_one = test_suite_one.'/write/write_latency.dat'
read_latency_throughput_one = test_suite_one.'/read/read_latency_throughput.dat'
write_latency_throughput_one = test_suite_one.'/write/write_latency_throughput.dat'

read_throughput_file_two = test_suite_two.'/read/read_throughput.dat'
write_throughput_file_two = test_suite_two.'/write/write_throughput.dat'
read_latency_file_two = test_suite_two.'/read/read_latency.dat'
write_latency_file_two = test_suite_two.'/write/write_latency.dat'
read_latency_throughput_two = test_suite_two.'/read/read_latency_throughput.dat'
write_latency_throughput_two = test_suite_two.'/write/write_latency_throughput.dat'


# First, let's do the throughput and latency graphs
set terminal pngcairo
set output output.'/throughput_read_graph.png'
set offsets graph 0, 0.05, 0.05, 0.05
set xlabel 'Clients'
set ylabel 'Throughput (Op/s)'
set key at graph 0.95, graph 0.2 spacing 1.5
plot read_throughput_file_one using 1:2 with linespoints title "3 Replicas" pt 6 \
, read_throughput_file_two using 1:2 with linespoints title "5 Replicas" pt 7

set output output.'/throughput_write_graph.png'
plot write_throughput_file_one using 1:2 with linespoints title "3 Replicas" pt 6 \
, write_throughput_file_two using 1:2 with linespoints title "5 Replicas" pt 7

set output output.'/latency_read_graph.png'
set xlabel 'Clients'
set ylabel 'Latency (ms)'
plot read_latency_file_one using 1:2 with linespoints title "3 Replicas" pt 6 \
, read_latency_file_two using 1:2 with linespoints title "5 Replicas" pt 7

set output output.'/latency_write_graph.png'
plot write_latency_file_one using 1:2 with linespoints title "3 Replicas" pt 6 \
, write_latency_file_two using 1:2 with linespoints title "5 Replicas" pt 7

set output output.'/read_latency_throughput_one.png'
set xlabel 'Throughput (Op/s)'
set ylabel 'Latency (ms)'
set key at graph 1, graph 0.15 spacing 1
plot read_latency_throughput_one using 2:1 with points title "3 Replicas" pt 6 ps 1 \
, read_latency_throughput_two using 2:1 with points title "5 Replicas" pt 7 ps 1
set output output.'/write_latency_throughput_one.png'
plot write_latency_throughput_one using 2:1 with points title "3 Replicas" pt 6 ps 1 \
, write_latency_throughput_two using 2:1 with points title "5 Replicas" pt 7 ps 1