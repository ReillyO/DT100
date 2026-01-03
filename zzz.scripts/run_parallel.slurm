#!/bin/bash
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --job-name=dockpllel
#SBATCH --output=dockpllel.out
#SBATCH -p long-40core
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=owen.oreilly@stonybrook.edu

# testing script where all grid and docking processes are sent
# to background so that they run in "parallel"

cd /gpfs/projects/rizzo/ooreilly/active/DT100/test_parallel

source run.000.prepare_env.sh

# generate all grids (script waits until all grid instances have
# stopped before moving to next step)
bash run.002.generate_grid.sh 

echo `date`

# dock all ligands
bash run.003.pose_reproduction.sh

echo `date`
