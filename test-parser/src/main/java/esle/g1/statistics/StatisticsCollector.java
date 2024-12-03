package esle.g1.statistics;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.Buffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import esle.g1.model.Latency;
import esle.g1.model.ReadOrWrite;
import esle.g1.model.Throughput;

public class StatisticsCollector {
    
    private HashMap<String, List<ReadOrWrite>> metricsMapRaw; //key: number of threads, value: Metrics



    public StatisticsCollector() {
        this.metricsMapRaw = new HashMap<>();
    }

    public void addMetrics(String numThreads, ReadOrWrite metrics) {
        if(metricsMapRaw.containsKey(numThreads)) {
            metricsMapRaw.get(numThreads).add(metrics);
        } else {
            List<ReadOrWrite> metricsList = new ArrayList<>();
            metricsList.add(metrics);
            metricsMapRaw.put(numThreads, metricsList);
        }
    }

    public void ProcessAndOutputToFolder(String outputFolder) {

        String readOrWrite = outputFolder.split("/")[outputFolder.split("/").length - 1];
        
        if (!new java.io.File(outputFolder).exists()) {
            new java.io.File(outputFolder).mkdirs();
        }

        String throughputFilepath = outputFolder + "/" + readOrWrite + "_throughput.dat";
        String latencyFilepath = outputFolder + "/" + readOrWrite + "_latency.dat";
        String latencyThroughputFilepath = outputFolder + "/" + readOrWrite + "_latency_throughput.dat";

        // Process the metricsMapRaw and output the statistics to the outputFolder
        HashMap<String, ReadOrWrite> processedMetricsMap = processMetrics();

        // Output the processed metrics to the output file
        // The scheme of the output should be the following
        // #Clients, Throughput, Latency
        // 1, 100, 10

        // Output the processed metrics to the output file in CSV format (throughput)
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(throughputFilepath))) {
            // Write the header
            writer.write("#Clients Throughput");
            writer.newLine();

            // Write each entry in processedMetricsMap
            String[] sortedNumThreads = processedMetricsMap.keySet().stream().mapToInt(Integer::parseInt).sorted().mapToObj(String::valueOf).toArray(String[]::new);
            for (String numThreads : sortedNumThreads) {
                ReadOrWrite metrics = processedMetricsMap.get(numThreads);
                writer.write(numThreads + ", " + metrics.throughput.mean);
                writer.newLine();
            }

            writer.flush();
        } catch (IOException e) {
            System.err.println("Error writing to output file: " + e.getMessage());
        }

        // Output the processed metrics to the output file in CSV format (latency)
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(latencyFilepath))) {
            // Write the header
            writer.write("#Clients Latency");
            writer.newLine();

            // Write each entry in processedMetricsMap
            String[] sortedNumThreads = processedMetricsMap.keySet().stream().mapToInt(Integer::parseInt).sorted().mapToObj(String::valueOf).toArray(String[]::new);
            for (String numThreads : sortedNumThreads) {
                ReadOrWrite metrics = processedMetricsMap.get(numThreads);
                writer.write(numThreads + ", " + metrics.latency.mean);
                writer.newLine();
            }

            writer.flush();
        } catch (IOException e) {
            System.err.println("Error writing to output file: " + e.getMessage());
        }
        
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(latencyThroughputFilepath))) {
            writer.write("Latency Throughput");
            writer.newLine();

            String[] sortedNumThreads = processedMetricsMap.keySet().stream().mapToInt(Integer::parseInt).sorted().mapToObj(String::valueOf).toArray(String[]::new);
            for (String numThreads : sortedNumThreads) {
                ReadOrWrite metrics = processedMetricsMap.get(numThreads);
                writer.write(metrics.latency.mean + ", " + metrics.throughput.mean);
                writer.newLine();
            }

            writer.flush();
        } catch (IOException e) {
            System.err.println("Error writing to output file: " + e.getMessage());
        }

    }

    private HashMap<String, ReadOrWrite> processMetrics() {
        // Process the metricsRawMap and return the processed metrics

        HashMap<String, ReadOrWrite> processedMetricsMap = new HashMap<>();
        
        
        //Iterate over the metricsMapRaw, give me the code
        for (String key : metricsMapRaw.keySet()) {
            List<ReadOrWrite> metricsList = metricsMapRaw.get(key);
            ReadOrWrite processedMetrics = ReadOrWrite.getNewReadOrWrite();

            double totalLatency = 0;
            double totalThroughput = 0;

            for (ReadOrWrite metrics : metricsList) {
                totalLatency += metrics.latency.mean;
                totalThroughput += metrics.throughput.mean;
            }

            processedMetrics.latency.mean = totalLatency / metricsList.size();
            processedMetrics.throughput.mean = totalThroughput / metricsList.size();

            processedMetricsMap.put(key, processedMetrics);
        }

        return processedMetricsMap;

    }

}
