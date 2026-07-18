#!/bin/bash

# Assumes that run.000. script has already been run with desired filepaths

# Script will:
# - OBLITERATE existing test directories
# - use wget to fetch a tarball of Mol2 files from the specified URL
# - extract the Mol2s from the tar file
# - generate the directory structure for grid generation and benchmarking
# - move each system's files into their respective directory
# - move junk files to a "trash" directory to be deleted when convenient

# Sample usage:
# bash run.001.fetch_and_organize


rootdir=${MAINDIR}
sysdir=${SYSDIR}
paramdir="${rootdir}/zzz.parameters/"
scriptdir="${rootdir}/zzz.scripts"
DT_URL=${DT_URL}
DT_PREF="DT${DT_MODE}"
DT_FILE="${DT_PREF}.tar.gz"

if [ ! -e ${rootdir}/${DT_FILE} ]; then 
	echo -e "\nFetching files (speed may vary depending on internet connection)\n"
	wget --no-check-certificate --directory-prefix=${rootdir} ${DT_URL} -O ${DT_FILE}
else
	echo -e "\nFound tarball with filename ${DT_FILE}; systems in this file will be used for the DT test. If you would like the script to re-download the tarball from the DOCK website, delete the ${DT_FILE} file from this directory and run the script again.\n"
fi

if [ ! -s ${rootdir}/${DT_FILE} ]; then
	echo "Something went wrong with the download. Exiting..."
	exit 1
fi

echo -e "Un-tarring files...\n"
tar -xf ${DT_FILE} --directory ${rootdir}/

if [ -s ${sysdir} ]; then
	echo -e "Removing old system directory...\n"
	rm -r ${sysdir}
fi

if [ -s ${paramdir} ]; then 
	echo -e "Removing old parameter directory...\n"
	rm -r ${paramdir}
fi


echo -e "Creating directory structure and moving files...\n"
mkdir ${sysdir}
while read system; do
	mkdir ${sysdir}/${system}
	mkdir ${sysdir}/${system}/001.files
	mkdir ${sysdir}/${system}/002.grid_gen
	mkdir ${sysdir}/${system}/004.analysis
	cp ${rootdir}/${DT_PREF}/${system}/${system}.rec.clean.mol2          ${sysdir}/${system}/001.files/  
	cp ${rootdir}/${DT_PREF}/${system}/${system}.lig.am1bcc.mol2         ${sysdir}/${system}/001.files/
	cp ${rootdir}/${DT_PREF}/${system}/${system}.rec.clust.close.sph     ${sysdir}/${system}/001.files/
done < ${rootdir}/${DT_PREF}/params/system_list.txt

mkdir ${paramdir}
cp ${rootdir}/${DT_PREF}/params/* ${paramdir}/


echo -e "Cleaning up workspace...\n"
if [ -s ${rootdir}/trash/ ]; then rm -r ${MAINDIR}/trash; fi
mkdir ${rootdir}/trash
mv ${rootdir}/${DT_PREF}/ ${MAINDIR}/trash/
mv ${rootdir}/${DT_FILE} ${MAINDIR}/trash

echo -e "Done!\n"
echo -e "All system files are located in ./`realpath --relative-to=./ ${sysdir}`\n"
echo -e "Temporary files have been moved to ./`realpath --relative-to=./ ${rootdir}/trash` and can be removed if needed\n" 
echo -e "Next step is run.002.generate_grids.sh\n"
