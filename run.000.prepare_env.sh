#!/bin/bash

# Environment variables should be set according to user's environment
# For instance, set MAINDIR to the filepath that the testset will be located
# in so that the absolute path can be referenced by the other scripts. 

# THIS SHOULD BE RUN USING source ./run.000.prepare_env 

# testset directory
export MAINDIR="/absolute/path/to/working/directory/"

if [ ! -e ${MAINDIR} ]; then 
	echo "MAINDIR path does not exist! Please correct and try again."
	unset ${MAINDIR}
fi

# system directory (usually nested in testset directory)
export SYSDIR="${MAINDIR}/zzz.DT100_systems/"

if [ ! -e ${SYSDIR} ]; then
	echo "SYSDIR path does not exist! Please correct and try again."
	unset ${SYSDIR}
fi

# path to DOCK6 folder (NOT the bin folder)
export DOCKHOME="/absolute/path/to/DOCK/installation/"

if [ ! -e ${DOCKHOME} ]; then
	echo "DOCKHOME path does not exist! Please correct and try again."
	unset ${DOCKHOME}
fi

# URL to download testset from Rizzo lab page
export DT100_URL="https://ringo.ams.stonybrook.edu/downloads/DT100/DT100.tar.gz"

