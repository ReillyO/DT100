#!/bin/bash

# Environment variables should be set according to user's environment
# For instance, set MAINDIR to the filepath that the testset will be located
# in so that the absolute path can be referenced by the other scripts. 

# THIS SHOULD BE RUN USING source ./run.000.prepare_env 

# DT_MODE options:
#   100S: 100 systems with high rates of success across multiple seeds
#         ("100-Successful")
#   100R: 100 systems blending high, middling, and low rates of 
#         success across multiple seeds ("100-Representative")
#   1244: the 1,244 systems in the SB2025 test set

export DT_MODE="100S"

# testset directory
export MAINDIR="/absolute/path/to/working/directory/"

if [ ! -e ${MAINDIR} ]; then 
	echo "MAINDIR path does not exist! Please correct and try again."
	unset ${MAINDIR}
fi

# system directory (usually nested in testset directory)
export SYSDIR="${MAINDIR}/zzz.DT_systems/"

if [ -e ${SYSDIR} ]; then
	echo "SYSDIR path already exists! Please save any important data or delete it before re-trying."
	unset ${SYSDIR}
else
	echo "Attempting to create zzz.DT_systems directory in `realpath --relative-to=./ ${MAINDIR}`"
	mkdir ${SYSDIR} && echo "Successful!"
fi

# path to DOCK6 folder (NOT the bin folder)
export DOCKHOME="/absolute/path/to/DOCK/installation/"

if [ ! -e ${DOCKHOME} ]; then
	echo "DOCKHOME path does not exist! Please correct and try again."
	unset ${DOCKHOME}
fi

# URL to download testset from Rizzo lab page
if [ ${DT_MODE} = "100S" ]; then 
	export DT_URL="https://ringo.ams.stonybrook.edu/downloads/DT/DT100S.tar.gz"
elif [ ${DT_MODE} = "100R" ]; then
	export DT_URL="https://ringo.ams.stonybrook.edu/downloads/DT/DT100R.tar.gz"
elif [ ${DT_MODE} = "1244" ]; then 
	export DT_URL="https://ringo.ams.stonybrook.edu/downloads/DT/DT1244.tar.gz"
else
	echo "Unrecognized DT_MODE setting! Download URL not set. Please edit the DT_MODE value in run.000.prepare_env.sh before trying again."
fi

