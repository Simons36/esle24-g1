// Copyright (c) YugaByte, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.  You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under the License
// is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
// or implied.  See the License for the specific language governing permissions and limitations
// under the License.
//

package com.yugabyte.sample.common.metrics;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.net.URISyntaxException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonObject;
import org.apache.log4j.Logger;

public class MetricsTracker extends Thread {
  private static final Logger LOG = Logger.getLogger(MetricsTracker.class);
  private final boolean outputJsonMetrics;
  private final String statsOutputFile;

  // Interface to print custom messages.
  public interface StatusMessageAppender {
    String appenderName();
    void appendMessage(StringBuilder sb);
  }

  // The type of metrics supported.
  public enum MetricName {
    Read,
    Write,
  }
  // Map to store all the metrics objects.
  Map<MetricName, Metric> metrics = new ConcurrentHashMap<MetricName, Metric>();
  // State variable to make sure this thread is started exactly once.
  boolean hasStarted = false;
  // Map of custom appenders.
  Map<String, StatusMessageAppender> appenders = new ConcurrentHashMap<String, StatusMessageAppender>();

  //Filewriter for writing metrics to a file
  File outputFile;

  public MetricsTracker(String statsOutputFile) {
    this.setDaemon(true);
    this.outputJsonMetrics = true;
    this.statsOutputFile = statsOutputFile;
    
    initOutputDirectoryAndFile(statsOutputFile);

  }

  public MetricsTracker() {
    this.setDaemon(true);
    this.outputJsonMetrics = false;
    this.statsOutputFile = null;
    outputFile = null;
  }

  public void registerStatusMessageAppender(StatusMessageAppender appender) {
    appenders.put(appender.appenderName(), appender);
  }

  public synchronized void createMetric(MetricName metricName) {
    if (!metrics.containsKey(metricName)) {
      metrics.put(metricName, new Metric(metricName.name(), outputJsonMetrics));
    }
  }

  public Metric getMetric(MetricName metricName) {
    return metrics.get(metricName);
  }

  public void getReadableMetricsAndReset(StringBuilder sb) {
    for (MetricName metricName : MetricName.values()) {
      sb.append(String.format("%s  |  ", metrics.get(metricName).getReadableMetricsAndReset()));
    }
  }

  private void initOutputDirectoryAndFile(String filepath){
    // Directory yb-sample-apps/test-output
      // Get the location of the JAR file
      Path jarDir;
      try {
        jarDir = Paths.get(MetricsTracker.class.getProtectionDomain().getCodeSource().getLocation().toURI()).getParent().getParent();

        // Construct the test-output directory path
        Path outputDir = jarDir.resolve("test-output");
        File dir = new File(outputDir.toString());
        
        // Create the directory if it doesn't exist
        if (!dir.exists()) {
            dir.mkdirs();
        }

        System.out.println("Output filepath: " + dir.toString() + "/" + filepath);

        // Set up the file writer for output
        outputFile = new File(dir, filepath);

      } catch (URISyntaxException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      }

  }

  @Override
  public synchronized void start() {
    if (!hasStarted) {
      hasStarted = true;
      super.start();
    }
  }

  @Override
  public void run() {
    while (true) {
      try {
        Thread.sleep(5000);
        StringBuilder sb = new StringBuilder();
        getReadableMetricsAndReset(sb);
        for (StatusMessageAppender appender : appenders.values()) {
          appender.appendMessage(sb);
        }
        LOG.info(sb.toString());
        if (this.outputJsonMetrics) {
          JsonObject json = new JsonObject();
          for (MetricName metricName : MetricName.values()) {
            if(!Double.isNaN(metrics.get(metricName).getJsonMetrics().getAsJsonObject("latency").get("mean").getAsDouble())){
              json.add(metricName.name(), metrics.get(metricName).getJsonMetrics());
            }
          }

          // CLEAR FILE HERE
          FileWriter fileWriter = new FileWriter(outputFile, false);
          
          // Write the JSON to a file with pretty printing
          Gson gson = new GsonBuilder().setPrettyPrinting().create();
          gson.toJson(json, fileWriter);

          fileWriter.flush();
          
          System.out.println("Metrics written to file");
        }
      } catch (InterruptedException e) { e.printStackTrace();} catch (IOException e) {
        // TODO Auto-generated catch block
        e.printStackTrace();
      } 
    }
  }
}
