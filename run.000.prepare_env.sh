#!/bin/bash

# Environment variables should be set according to user's environment

# THIS SHOULD BE RUN USING source ./run.000.prepare_env 

##########################################################
#        START user editing section                      #
##########################################################

# DT_MODE options:
#
#   FDPR: Flexible Docking Pose Reproduction - re-docks the ligand of
#         each system to its receptor and checks accuracy
#   DNFL: De Novo Focused Library - generates a fragment library from the
#         system ligand, then attempts to reconstruct it
#   GAFL: Genetic Algorithm Focused Library - shuffles the original ligand
#         via 10 rounds of roulette, then attempts to reconstruct it with
#         10 rounds of elitism
# 
# Multiple modes can be selected by separating each mode by an underscore
# For example, DT_MODE="DNFL_GAFL" to run both DN and GA focused-library tests

export DT_MODE="FDPR"

# DT_SYS options:
#
#   100R: 100 systems blending high, middling, and low rates of 
#         success across multiple seeds ("100-Representative")
#   100S: 100 systems with high rates of success across multiple seeds
#         ("100-Successful")
#   1244: the 1,244 systems in the SB2025 test set (intensive)
#

export DT_SYS="100R"

# Series of random seeds to use in runs (space-separated)
export DT_SEEDS="1 2 4"

# Directory where results will be provided
export DT_MAINDIR="/absolute/path/to/directory/for/testset/"

# System directory (nested in testset directory unless storage is a concern)
export DT_SYSDIR="${DT_MAINDIR}/zzz.DT${DT_SYS}_systems/"

# Path to DOCK6 folder (NOT the bin folder)
export DT_DOCKHOME="/absolute/path/to/dock/installation/"

# Number of processors available for DT; defaults to maximum number available
export DT_NPROC="`nproc`"



#################################################################
#        END user editing section                               #
#################################################################

# sanity check user input and return errors if a path does not exist

if [ ! -e ${DT_MAINDIR} ]; then 
	echo "ERROR: DT_MAINDIR path does not exist! Please correct and try again. DT_MAINDIR path will not be set."
	unset DT_MAINDIR
fi

if [ ! -e ${DOCKHOME} ]; then
	echo "ERROR: DOCKHOME path does not exist! Please correct and try again. DOCKHOME path will not be set."
	unset DOCKHOME
fi

if [ -e ${DT_SYSDIR} ]; then
	echo "ERROR: SYSDIR path already exists! Please save any important data or delete it before re-trying. SYSDIR path will not be set."
	unset DT_SYSDIR
else
	echo "Attempting to create zzz.DT_systems directory in `realpath --relative-to=./ ${DT_MAINDIR}`"
	mkdir ${DT_SYSDIR} && echo "Successful!"
fi

# URL to download testset from Rizzo lab page
if [ ${DT_SYS} = "100S" ]; then 
	export DT_URL="https://ringo.ams.stonybrook.edu/downloads/DT/DT100S.tar.gz"
elif [ ${DT_SYS} = "100R" ]; then
	export DT_URL="https://ringo.ams.stonybrook.edu/downloads/DT/DT100R.tar.gz"
elif [ ${DT_SYS} = "1244" ]; then 
	export DT_URL="https://ringo.ams.stonybrook.edu/downloads/DT/DT1244.tar.gz"
else
	echo "ERROR: Unrecognized DT_SYS setting! Download URL will not be set. Please edit the DT_SYS value in run.000.prepare_env.sh before trying again."
fi


echo "Environment setup script complete for ${DT_MODE} using the ${DT_SYS} system set. Correct any errors if noted."
