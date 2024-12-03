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
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;

import com.yugabyte.sample.common.SimpleLoadGenerator.Key;


import org.apache.log4j.Logger;

/**
 * This workload only writes random string keys into a PostgreSQL table.
 */
public class SqlWrite extends AppBase {
  private static final Logger LOG = Logger.getLogger(SqlWrite.class);

  // Static initialization of this workload's config.
  static {
    // Disable reads, only writes will happen.
    appConfig.readIOPSPercentage = 0;  // No reads.
    // Set the number of writer threads.
    appConfig.numWriterThreads = 2;  // You can adjust the number of threads based on needs.
    // The number of keys to write.
    appConfig.numKeysToWrite = -1;
    // The number of unique keys to write (only inserts, no updates).
    appConfig.numUniqueKeysToWrite = 3000;

    // Time of seconds the test will be running (negative is no limit).
    appConfig.runTimeSeconds = -1;
  }

  // The default table name to create and use for insert operations.
  private static final String DEFAULT_TABLE_NAME = "postgresqlkeyvalue";

  // The shared prepared insert statement for inserting the data.
  private volatile PreparedStatement preparedInsert = null;

  // Lock for initializing prepared statement objects.
  private static final Object prepareInitLock = new Object();

  public SqlWrite() {
    buffer = new byte[appConfig.valueSize];
  }

  @Override
  public void createTablesIfNeeded(TableOp tableOp) throws Exception {
    // Create table if it doesn't exist already.
    try (Connection connection = getPostgresConnection()) {
      connection.createStatement().executeUpdate(String.format(
          "CREATE TABLE IF NOT EXISTS %s (k TEXT PRIMARY KEY, v TEXT)", getTableName()));
    } catch (Exception e) {
      LOG.error("Error creating table: " + getTableName(), e);
      throw e;
    }



    // Clear Table
    try (Connection connection = getPostgresConnection()) {
      connection.createStatement().executeUpdate(String.format("TRUNCATE TABLE %s;", getTableName()));
    } catch (Exception e) {
      LOG.error("Error truncating table: " + getTableName(), e);
      throw e;
    }

    createInsertQueryString();
  }

  private void createInsertQueryString() {
    StringBuilder query = new StringBuilder("INSERT INTO " + getTableName() + " (k, v) VALUES ");
    for (int i = 0; i < appConfig.operationRowSize; i++) {
        query.append("(?, ?)");
        if (i < appConfig.operationRowSize - 1) {
            query.append(", ");
        }
    }
    query.append(";");
    appConfig.preparedStatementString = query.toString();
}

  public String getTableName() {
    String tableName = appConfig.tableName != null ? appConfig.tableName : DEFAULT_TABLE_NAME;
    return tableName.toLowerCase();
  }

  private PreparedStatement getPreparedInsert() throws Exception {
    if (preparedInsert == null) {
      synchronized (prepareInitLock) {
        if (preparedInsert == null) {
          preparedInsert = getPostgresConnection().prepareStatement(
              String.format("INSERT INTO %s (k, v) VALUES (?, ?);", getTableName()));
        }
      }
    }
    return preparedInsert;
  }

  private PreparedStatement getPreparedInsert(String queryString) throws Exception {
    if (preparedInsert == null) {
      synchronized (prepareInitLock) {
        if (preparedInsert == null) {
          preparedInsert = getPostgresConnection().prepareStatement(queryString);
        }
      }
    }
    return preparedInsert;
  }


  @Override
  public long doWrite(int threadIdx) {
    // // Get a new key to write.
    // Key key = getSimpleLoadGenerator().getKeyToWrite();
    // if (key == null) {
    //   return 0;
    // }

    // Get the key(s) to write.
    List<Key> keys = new ArrayList<>();
    while (keys.size() < appConfig.operationRowSize) {
      Key key = getSimpleLoadGenerator().getKeyToWrite();
      if (key == null) {
        break;
      }
      if(keys.contains(key)){
        continue;
      }
      keys.add(key);
      
    }
    
    String queryString;

    if(appConfig.preparedStatementString == null){
      queryString = "INSERT INTO " + getTableName() + " (k, v) VALUES (?, ?);";
    }else{
      queryString = appConfig.preparedStatementString;
    }
    int result = 0;
    try {
      PreparedStatement statement = getPreparedInsert(queryString);
      // statement.setString(1, key.asString());
      // statement.setString(2, key.getValueStr());
      // result = statement.executeUpdate();
      // LOG.debug("Inserted key: " + key.asString());
      for(int i = 0; i < keys.size(); i++){
        statement.setString(2*i + 1, keys.get(i).asString());
        statement.setString(2*i + 2, keys.get(i).getValueStr());
      }
      result = statement.executeUpdate();
      LOG.debug("Inserted keys: " + keys);
    } catch (Exception e) {
      LOG.error("Failed writing key: " + keys, e);
      preparedInsert = null;
    }
    return result;
  }

  @Override
  public long doRead() {
    // Disable read operations. We can return 0 to indicate no reads are done.
    return 0;
  }

  @Override
  public List<String> getWorkloadDescription() {
    return Arrays.asList(
        "Sample key-value app built on PostgreSQL that performs only writes (inserts). ",
        "This app inserts unique string keys into the table with random values, and no read ",
        "operations are performed. The keys and values are generated by the load generator.",
        "This workload is designed to test write-heavy scenarios, with multiple writer threads.",
        "You can configure the number of writes and threads using parameters.");
  }

  @Override
  public List<String> getWorkloadRequiredArguments() {
    return Arrays.asList("--uuid 'ffffffff-ffff-ffff-ffff-ffffffffffff'");
  }

  @Override
  public List<String> getWorkloadOptionalArguments() {
    return Arrays.asList(
        "--num_writes " + appConfig.numKeysToWrite,
        "--num_threads_write " + appConfig.numWriterThreads,
        "--debug_driver " + appConfig.enableDriverDebug);
  }
}
