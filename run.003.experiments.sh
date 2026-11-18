#!/bin/bash

# Script will:
#  - Run flexible DOCKing on all systems for each simplex random seed given

# assumes steps 000, 001, and 002 have already run successfully

# set some paths
rootdir="${DT_MAINDIR}"
scriptdir="${rootdir}/zzz.scripts"

# track if at least one run occurred
ran_something="false"

# read in random seeds to array $random_seeds
IFS=' ' read -r -a random_seeds <<< "${DT_SEEDS}"

echo "Beginning ${DT_MODE} run for all systems in ${DT_SYS} with seeds ${random_seeds[*]}"

if [[ ${DT_MODE} =~ "FDPR" ]]; then
	
	# run all systems for each set of random seeds
	for seed in "${random_seeds[@]}"; do
		echo "Running seed ${seed}"
		bash ${scriptdir}/all_system_FLX.sh "seed${seed}" ${seed} 
		wait
	done
	
	echo -e "Finished FDPR run.\n"
	echo "`date`"

	ran_something="true"
	
fi # end FDPR

if [[ ${DT_MODE} =~ "GAFL" ]]; then
		
	echo "Generating focused fragment libraries for all systems..."
	# for all systems, run through and create the fragment libraries
	# generally a fast step
	bash ${scriptdir}/FL_gen_fraglib.sh
	
	echo "Running Roulette shuffle and Elitism for all systems..."
	# then, 10 generations of roulette mutations using STANDARD fragment libs
	#   NOTE that after the final round, we check if the parent is present, and if
	#   it is we delete it 	
	# then, 10 generations of elitism mutations using FOCUSED fragment libs
	for seed in ${random_seeds[@]}; do
	        echo "Running roulette for seed ${seed}"
	        bash ${scriptdir}/all_system_GA_roul.sh "seed${seed}" ${seed}
	        wait
	        
		echo "Running elitism for seed ${seed}"
	        bash ${scriptdir}/all_system_GA_elite.sh "seed${seed}" ${seed}
	        wait
	done
	echo "Finished GAFL run."
	echo "`date`"

	ran_something="true"
	
fi # end GAFL
	
if [[ ${DT_MODE} =~ "DNFL" ]]; then

	echo "DNFL is under construction!"
	exit
	# insert Di's code here

	echo "Finished DNFL run."
	echo "`date`"

	ran_something="true"
	
fi # end DNFL

if [ ${ran_something} = "false" ]; then

	echo "ERROR: DT_MODE env variable is set to an unrecognized value! Please address."
	exit

fi

echo "Next step is run.004.analyze.sh"

