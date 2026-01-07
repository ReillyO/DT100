#!/bin/bash

# Script for a bash command line run of the full DT100 benchmark
# Should be run from the directory indicated by MAINDIR in run.000

# set necessary environment variables
source run.000.prepare_env.sh
cd ${MAINDIR}
wait

# get files and unpack
bash run.001.fetch_and_organize.sh
wait

echo `date`

# generate all grids (script waits until all grid instances have
# stopped before moving to next step)
bash run.002.generate_grids.sh 
wait

echo `date`

# dock all ligands
bash run.003.pose_reproduction.sh
wait

echo `date`

# analyze results (will be written to verbose files)
bash run.004.analyze.sh
wait

echo `date`
