#!/bin/bash

# Script to clean up the main directory. Will ask if the user wishes to remove:
#  - zzz.DT_systems folder entirely
#  - All experimental results (003 directories)
#  - zzz.analysis folder entirely
#  - any _Performance_Summary.txt file
#  - the DT*.tar.gz file(s) if present

### Set some paths
dockdir="${DT_DOCKHOME}/bin/"
rootdir="${DT_MAINDIR}"
sysdir="${DT_SYSDIR}"
paramdir="${rootdir}/zzz.parameters"
scriptdir="${rootdir}/zzz.scripts"
dtpref="DT${DT_MODE}"

echo "CLEANING SCRIPT"
echo "Indicate if each directory/file should be deleted. Any input other than 'y' will skip the removal."

if [ -s ${rootdir}/zzz.DT_systems ]; then
    echo "Delete current DT_SYSDIR (`realpath --relative-to=./ ${rootdir}/zzz.DT_systems`)?"
    echo -n "y/N:"
    read rem
    if [ "${rem}" = "y" ]; then
	echo "Removing..."
	rm -rf ${rootdir}/zzz.DT_systems
    fi
fi

if [ -s ${rootdir}/zzz.DT_systems ]; then
    echo "Delete any extant 003 directories (clear experimental data while preserving grids)?"
    echo -n "y/N:"
    read rem
    if [ "${rem}" = "y" ]; then
        echo "Removing..."
        rm -rf ${rootdir}/zzz.DT_systems/*/003*
    fi
fi

if [ -s ${rootdir}/zzz.analysis ]; then
    echo "Delete current Analysis directory (`realpath --relative-to=./ ${rootdir}/zzz.analysis`)?"
    echo -n "y/N:"
    read rem
    if [ "${rem}" = "y" ]; then
	echo "Removing..."
 	rm -rf ${rootdir}/zzz.analysis
    fi
fi

exit

if [ -s ${rootdir}/*Performance_Summary.txt ]; then
    echo "Delete extant Performance_Summarys and output (`realpath --relative-to=./ ${rootdir}/zzz.analysis`)?"
    echo -n "y/N:"
    read rem
    if [ "${rem}" = "y" ]; then
	echo "Removing..."
 	rm -rf ${rootdir}/*Performance_Summary.tx
        rm -rf ${rootdir}/DT100.out
    fi
fi

if [ -s ${rootdir}/DT*.tar.gz ]; then
echo "Delete extant system tarball(s) (`realpath --relative-to=./ ${rootdir}/DT*.tar.gz`)?"
    echo -n "y/N:"
    read rem
    if [ "${rem}" = "y" ]; then
        echo "Removing..."
        rm -rf ${rootdir}/DT*.tar.gz
    fi
fi
