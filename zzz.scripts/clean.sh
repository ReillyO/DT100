#!/bin/bash

# Script to clean up the main directory. Will remove:
#  - the trash folder if present
#  - zzz.DT_systems folder entirely
#  - zzz.analysis folder entirely
#  - any _Performance_Summary.txt file
#  - the DT100.out file from batch script if present
#  - the DT1244.tar.gz file if present

### Set some paths
dockdir="${DT_DOCKHOME}/bin/"
rootdir="${DT_MAINDIR}"
sysdir="${DT_SYSDIR}"
paramdir="${rootdir}/zzz.parameters"
scriptdir="${rootdir}/zzz.scripts"
dtpref="DT${DT_MODE}"


if [ -s ${rootdir}/zzz.DT_systems ]; then
    echo "Removing extant zzz.DT_systems directory"
    rm -rf ${rootdir}/zzz.DT_systems
fi


if [ -s ${rootdir}/zzz.analysis ]; then
    echo "Removing extant zzz.analysis directory"
    rm -rf ${rootdir}/zzz.analysis
fi


if [ -s ${rootdir}/*Performance_Summary.txt ]; then
    echo "Removing extant performance summary file"
    rm -rf ${rootdir}/*Performance_Summary.txt
fi


if [ -s ${rootdir}/DT100.out ]; then
    echo "Removing extant performance summary file"
    rm -rf ${rootdir}/DT100.out
fi


if [ -s ${rootdir}/trash ]; then
    echo "Removing extant trash directory"
    rm -rf ${rootdir}/trash
fi 


if [ -s ${rootdir}/DT*.tar.gz ]; then
    echo "Removing extant tarball file"
    rm ${rootdir}/DT*.tar.gz
fi
