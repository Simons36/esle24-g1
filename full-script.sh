#!/bin/bash
# Factors that don't need re-deployment: Operation Size, Workload Type (A, B)
# Factors that need re-deployment: The rest (C, D, E, F)
set -e

#run2
./single-run.sh -1 -1 -1 +1 +1 +1
#run3
./single-run.sh -1 -1 +1 -1 -1 +1
#run4
./single-run.sh -1 -1 +1 +1 -1 +1
#run5
./single-run.sh -1 +1 -1 -1 -1 -1
#run6
./single-run.sh -1 +1 -1 +1 -1 -1
#run7
./single-run.sh -1 +1 +1 -1 +1 -1
#run8
./single-run.sh -1 +1 +1 +1 +1 -1
#run9
./single-run.sh +1 -1 -1 -1 +1 -1
#run10
./single-run.sh +1 -1 -1 +1 +1 -1
#run11
./single-run.sh +1 -1 +1 -1 -1 -1
#run12
./single-run.sh +1 -1 +1 +1 -1 -1
#run13
./single-run.sh +1 +1 -1 -1 -1 +1
#run14
./single-run.sh +1 +1 -1 +1 -1 +1
#run15
./single-run.sh +1 +1 +1 -1 +1 +1
#run16
./single-run.sh +1 +1 +1 +1 +1 +1

# ./single-run.sh -1 -1 -1 -1 +1 +1