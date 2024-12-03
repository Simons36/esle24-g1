package esle.g1;

import esle.g1.model.ReadOrWrite;
import esle.g1.statistics.StatisticsCollector;
import esle.g1.util.MetricsParser;

import java.io.File;
import java.io.IOException;

/**
 * Main class for parsing JSON files in the specified test suite folder
 */
public class Main {
    public static void main(String[] args) {
        if (args.length != 2) {
            System.out.println("Usage: java -jar test-parser.jar <path-to-test-suite-folder> <path-to-data-output-folder>");
            for (String arg : args) {
                System.out.println("Argument: " + arg);
            }
            System.exit(1);
        }

        String testSuiteFolder = args[0];
        String testSuiteName = testSuiteFolder.split("/")[testSuiteFolder.split("/").length - 1];

        try {
            MetricsParser parser = new MetricsParser(); // Instantiate the parser
            StatisticsCollector writeStatsCollector = new StatisticsCollector(); // Instantiate the stats collector
            StatisticsCollector readStatsCollector = new StatisticsCollector(); // Instantiate the stats collector

            // Traverse the test-suite folder
            File testSuiteDir = new File(testSuiteFolder);

            if (testSuiteDir.exists() && testSuiteDir.isDirectory()) {


                // Need to figure out if it is read or write
                //testsuitename is of the type "-1.-1.+1.-1.+1.-1" for example
                // What determines the workload type is the fifth 1
                // -1 for read and +1 for write
                System.out.println("Test Suite Name: " + testSuiteName);
                System.out.println("Test Suite Folder: " + testSuiteFolder);
                String workloadType = testSuiteName.split("\\.")[1];
                if (workloadType.equals("-1")) {
                    processReadFolder(parser, testSuiteDir, readStatsCollector);
                    readStatsCollector.ProcessAndOutputToFolder(args[1] + "/" + testSuiteName);
                } else if (workloadType.equals("+1")) {
                    processWriteFolder(parser, testSuiteDir, writeStatsCollector);
                    writeStatsCollector.ProcessAndOutputToFolder(args[1] + "/" + testSuiteName);
                } else {
                    System.out.println("Invalid workload type: " + workloadType);
                }

                // File readDir = new File(testSuiteDir, "read");
                // File writeDir = new File(testSuiteDir, "write");

                // // Process the read folder
                // processReadFolder(parser, readDir, readStatsCollector);

                // // Process the write folder
                // processWriteFolder(parser, writeDir, writeStatsCollector);

                // // Output the statistics
                // readStatsCollector.ProcessAndOutputToFolder(args[1] + "/" + testSuiteName + "/read");
                // writeStatsCollector.ProcessAndOutputToFolder(args[1] + "/" + testSuiteName + "/write");
            } else {
                System.out.println("Invalid test-suite folder: " + testSuiteFolder);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void processReadFolder(MetricsParser parser, File readDir, StatisticsCollector statsCollector) {
        if (readDir.exists() && readDir.isDirectory()) {
            File[] threadFolders = readDir.listFiles(); // List all thread folders (e.g., "1_threads", "2_threads")
            if (threadFolders == null) return;
            
            File[] jsonFiles = readDir.listFiles((dir, name) -> name.endsWith(".json"));

            if (jsonFiles != null) {
                for (File jsonFile : jsonFiles) {
                    try {
                        ReadOrWrite readMetrics = parser.parseReadFromFile(jsonFile.getAbsolutePath());
                        
                        // Add the metrics to the collector
                        statsCollector.addMetrics(jsonFile.getName().split("\\.")[0], readMetrics);

                        System.out.println("Read Latency Mean from " + jsonFile.getName() + ": " + readMetrics.latency.mean);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }

    private static void processWriteFolder(MetricsParser parser, File writeDir, StatisticsCollector statsCollector) {
        if (writeDir.exists() && writeDir.isDirectory()) {
            
            System.out.println("eroignregne");


            File[] jsonFiles = writeDir.listFiles((dir, name) -> name.endsWith(".json"));
            if (jsonFiles != null) {
                for (File jsonFile : jsonFiles) {
                    try {
                        ReadOrWrite writeMetrics = parser.parseWriteFromFile(jsonFile.getAbsolutePath());

                        // Add the metrics to the collector
                        statsCollector.addMetrics(jsonFile.getName().split("\\.")[0], writeMetrics);

                        System.out.println("Write Throughput Mean from " + jsonFile.getName() + ": " + writeMetrics.throughput.mean);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
                
        }
    }
}
