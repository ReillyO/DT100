#!/bin/bash

# Environment variables should be set according to user's environment
# For instance, set DT_MAINDIR to the filepath that the testset will be located
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
export DT_MAINDIR="/absolute/path/to/working/directory/"

if [ ! -e ${DT_MAINDIR} ]; then 
	echo "ERROR: DT_MAINDIR path does not exist! Please correct and try again."
	unset DT_MAINDIR
fi

# system directory (usually nested in testset directory)
export DT_SYSDIR="${DT_MAINDIR}/zzz.DT_systems/"

if [ -e ${SYSDIR} ]; then
	echo "ERROR: SYSDIR path already exists! Please save any important data or delete it before re-trying. SYSDIR path will not be set."
	unset SYSDIR
else
	echo "Attempting to create zzz.DT_systems directory in `realpath --relative-to=./ ${DT_MAINDIR}`"
	mkdir ${DT_SYSDIR} && echo "Successful!"
fi

# path to DOCK6 folder (NOT the bin folder)
export DT_DOCKHOME="/absolute/path/to/DOCK/installation/"

if [ ! -e ${DOCKHOME} ]; then
	echo "ERROR: DOCKHOME path does not exist! Please correct and try again. DOCKHOME path will not be set."
	unset DOCKHOME
fi

# URL to download testset from Rizzo lab page
if [ ${DT_MODE} = "100S" ]; then 
	export DT_URL="https://ringo.ams.stonybrook.edu/downloads/DT/DT100S.tar.gz"
elif [ ${DT_MODE} = "100R" ]; then
	export DT_URL="https://ringo.ams.stonybrook.edu/downloads/DT/DT100R.tar.gz"
elif [ ${DT_MODE} = "1244" ]; then 
	export DT_URL="https://ringo.ams.stonybrook.edu/downloads/DT/DT1244.tar.gz"
else
	echo "ERROR: Unrecognized DT_MODE setting! Download URL will not be set. Please edit the DT_MODE value in run.000.prepare_env.sh before trying again."
fi

# computing
# retain the `nproc` result or enter a custom number
export DT_NPROC="`nproc`"
echo "Detected ${DT_NPROC} processors in the current environment! Computing resources will be budgeted to reflect this. This can be changed via the DT_NPROC variable in run.000.prepare_env.sh."

echo "Environment setup script complete for DT${DT_MODE}. Correct any errors if noted."
