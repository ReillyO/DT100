#!/bin/bash
#SBATCH --time=48:00:00
#SBATCH --nodes=INSERT_N_NODES
#SBATCH --ntasks=INSERT_N_TASKS
#SBATCH --job-name=DT
#SBATCH --output=DT.out
#SBATCH -p INSERT_QUEUE_NAME

# Script for Slurm-based computing nodes for the full DT100 benchmark

# set necessary environment variables
source run.000.prepare_env.sh
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
bash run.003.experiments.sh
wait

echo `date`

# analyze results (will be written to verbose files)
bash run.004.analyze.sh
wait

echo `date`
