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
package com.yugabyte.sample.apps;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import com.yugabyte.sample.common.SimpleLoadGenerator.Key;
import org.apache.log4j.Logger;

/**
 * This workload only performs read operations on random string keys from a
 * PostgreSQL table.
 */
public class SqlRead extends AppBase {
  private static final Logger LOG = Logger.getLogger(SqlRead.class);

  // Static initialization of this workload's config.
  static {
    // Disable writes, only reads will happen.
    appConfig.readIOPSPercentage = 100; // Only reads.
    // Set the number of reader threads.
    appConfig.numReaderThreads = 2; // Adjust based on requirements.
    // The number of keys to read. Set to -1 for infinite reads or a positive number
    // for finite reads.
    appConfig.numKeysToRead = -1;
    appConfig.numKeysToWrite = -1;

    appConfig.runTimeSeconds = -1; // Time in seconds the test will be running (negative is no limit)

  }

  // The default table name to read from.
  private static final String DEFAULT_TABLE_NAME = "PostgresqlKeyValue";

  // The shared prepared select statement for reading the data.
  private volatile PreparedStatement preparedSelect = null;

  // Lock for initializing prepared statement objects.
  private static final Object prepareInitLock = new Object();

  private static final Long NUM_KEYS_TO_POPULATE_TABLE = 1000L;

  public SqlRead() {
    buffer = new byte[appConfig.valueSize];
  }

  @Override
  public void createTablesIfNeeded(TableOp tableOp) throws Exception {

    if (appConfig.uuid == null) {
      throw new IllegalArgumentException(
          "UUID is required for this workload. Please provide a UUID with --uuid <UUID> in the command line options.");
    }

    // Ensure the table exists.
    try (Connection connection = getPostgresConnection()) {
      ResultSet tables = connection.getMetaData().getTables(null, null, getTableName(), null);
      if (!tables.next()) {
        LOG.info("Table does not exist, creating table: " + getTableName());

        System.out.println("CREATE TABLE IF NOT EXISTS %s (k TEXT PRIMARY KEY, v TEXT)" + getTableName());
        connection.createStatement().executeUpdate(String.format(
            "CREATE TABLE IF NOT EXISTS %s (k TEXT PRIMARY KEY, v TEXT)", getTableName()));

      }
      // Truncate the table

      connection.createStatement().executeUpdate(String.format("TRUNCATE TABLE %s", getTableName()));

      populateTable(connection);
    } catch (Exception e) {
      LOG.error("Error configuring pre test configuration: ", e);
      throw e;
    }

    getSimpleLoadGenerator().setMaxWrittenKey(NUM_KEYS_TO_POPULATE_TABLE);

    createQueryString();
  }

  private void createQueryString() {
    StringBuilder query = new StringBuilder("SELECT k, v FROM " + getTableName() + " WHERE k IN (");
    for (int i = 0; i < appConfig.operationRowSize; i++) {
      query.append("?");
      if (i < appConfig.operationRowSize - 1) {
        query.append(", ");
      }
    }
    query.append(")");
    appConfig.preparedStatementString = query.toString();
  }

  private void populateTable(Connection connection) throws Exception {
    System.out.println("Populating table with keys");
    // Insert NUM_KEYS_TO_POPULATE_TABLE keys into the table.
    try (PreparedStatement statement = connection.prepareStatement(
        String.format("INSERT INTO %s (k, v) VALUES (?, ?)", getTableName()))) {
      for (long i = 0; i < NUM_KEYS_TO_POPULATE_TABLE; i++) {
        statement.setString(1, appConfig.uuid + ":" + i);
        statement.setString(2, "val:" + String.valueOf(i));
        statement.executeUpdate();
      }
    } catch (Exception e) {
      LOG.error("Failed to populate table: " + getTableName(), e);
      throw e;
    }
  }

  public String getTableName() {
    String tableName = appConfig.tableName != null ? appConfig.tableName : DEFAULT_TABLE_NAME;
    return tableName.toLowerCase();
  }

  private PreparedStatement getPreparedSelect() throws Exception {
    if (preparedSelect == null) {
      synchronized (prepareInitLock) {
        if (preparedSelect == null) {
          preparedSelect = getPostgresConnection().prepareStatement(
              String.format("SELECT k, v FROM %s WHERE k = ?;", getTableName()));
        }
      }
    }
    return preparedSelect;
  }

  private PreparedStatement getPreparedSelect(String query) throws Exception {
    if (preparedSelect == null) {
      synchronized (prepareInitLock) {
        if (preparedSelect == null) {
          preparedSelect = getPostgresConnection().prepareStatement(
              String.format(query, getTableName()));
        }
      }
    }
    return preparedSelect;
  }

  @Override
  public long doWrite(int threadIdx) {
    // Disable write operations. Return 0 to indicate no writes are performed.
    return 0;
  }

  @Override
  public long doRead() {
    int rowSize = appConfig.operationRowSize; // Get the number of rows to read
    List<Key> keysToRead = new ArrayList<>();

    // Collect the keys to read based on rowSize
    for (int i = 0; i < rowSize; i++) {
      Key key = getSimpleLoadGenerator().getKeyToRead();

      // Ensure that the key is not already in the list of keys to read.
      while (keyListContainsKey(keysToRead, key)) {
        key = getSimpleLoadGenerator().getKeyToRead();
        
      }
      
      if (key == null) {
        // No more keys available to read.
        return 0;
      }
      

      keysToRead.add(key);
    }

    // // Print keys to read
    // System.out.print("Keys to read: ");
    // for (Key key : keysToRead) {
    // System.out.print("| " + key.asString());
    // }
    // System.out.println();

    try {
      String queryString;

      if (appConfig.preparedStatementString == null) {
        queryString = "SELECT k, v FROM " + getTableName() + " WHERE k IN (?)"; // Default query
      } else {
        queryString = appConfig.preparedStatementString;
      }

      PreparedStatement statement = getPreparedSelect(queryString);

      // Set each key in the prepared statement.
      for (int i = 0; i < keysToRead.size(); i++) {
        statement.setString(i + 1, keysToRead.get(i).asString());
      }

      try (ResultSet rs = statement.executeQuery()) {
        int count = 0;
        while (rs.next()) {
          String resultKey = rs.getString("k");

          // Verify that the read key matches the expected key.
          if (keysToRead.stream().anyMatch(k -> k.asString().equals(resultKey))) {
            LOG.debug("Successfully read key: " + resultKey);
            // Optionally verify the value
            String resultValue = rs.getString("v");

            // Verify the value.

            keysToRead.stream()
                .filter(k -> k.asString().equals(resultKey))
                .findFirst()
                .ifPresent(k -> k.verify(resultValue));

            // Now remove
            // keysToRead.removeIf(k -> k.asString().equals(resultKey));

          } else {
            LOG.error("Read key mismatch: expected key not found,  got " + resultKey);
          }
          count++;
        }

        if (count != rowSize) {
          LOG.error("Expected " + rowSize + " rows, but got " + count);
          System.out.print("Keys to read: ");
          for (Key key : keysToRead) {
            System.out.print("| " + key.asString());
          }
          System.out.println();
          return 0;
        }
      }
    } catch (Exception e) {
      LOG.error("Error reading keys: ", e);
      return 0;
    }

    return 1; // Indicate a successful read.
  }

  private boolean keyListContainsKey(List<Key> keys, Key key) {
    return keys.stream().anyMatch(k -> k.asString().equals(key.asString()));
  }

  @Override
  public List<String> getWorkloadDescription() {
    return Arrays.asList(
        "Sample key-value app built on PostgreSQL that performs only read operations.",
        "This app queries keys that have already been written into the table.",
        "The keys are queried by their associated values that were inserted in prior operations.",
        "This workload is designed to test read-heavy scenarios with multiple reader threads.",
        "The number of reads can be configured, and it does not perform any write operations.",
        "Ensure that data is inserted before running this workload.");
  }

  @Override
  public List<String> getWorkloadRequiredArguments() {
    return Arrays.asList(
        "--uuid 'ffffffff-ffff-ffff-ffff-ffffffffffff'",
        "--max_written_key 100000"); // Adjust based on the number of keys written.
  }

  @Override
  public List<String> getWorkloadOptionalArguments() {
    return Arrays.asList(
        "--num_reads " + appConfig.numKeysToRead,
        "--num_threads_read " + appConfig.numReaderThreads,
        "--debug_driver " + appConfig.enableDriverDebug);
  }
}


