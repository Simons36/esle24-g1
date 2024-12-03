#!/bin/bash

cd yb-sample-apps/
mvn -DskipTests -DskipDockerBuild package

# Create the test output directory
cd ..