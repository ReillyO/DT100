#!/bin/bash

# Script will:
#  - Run flexible DOCKing on all systems for each simplex random seed given

# assumes steps 000, 001, and 002 have already run successfully

# set some paths
dockdir="${DOCKHOME}/bin/"
rootdir="${MAINDIR}"
sysdir="${SYSDIR}"
paramdir="${rootdir}/zzz.parameters"
scriptdir="${rootdir}/zzz.scripts"
dtpref="DT${DT_MODE}"

# create list of random seeds (ADD OR EDIT HERE)
declare -a random_seeds=(1 2 4)

echo "Beginning DOCKing run for all systems with seeds ${random_seeds[*]}"

# run all systems for each set of random seeds
for seed in "${random_seeds[@]}"; do
	echo "Running seed ${seed}"
	bash ${scriptdir}/all_system_FLX.sh "seed${seed}" ${seed} 
	wait
done

echo -e "Finished running pose reproduction.\n"
echo "Next step is run.004.analyze.sh"
