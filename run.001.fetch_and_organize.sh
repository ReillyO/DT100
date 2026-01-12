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
DT_URL=${DT100_URL}

if [ ! -e ${rootdir}/DT100.tar.gz ]; then 
	echo -e "\nFetching files (speed may vary depending on internet connection)\n"
	wget --no-check-certificate --directory-prefix=${rootdir} ${DT_URL} -O DT100.tar.gz
else
	echo -e "\nFound tarball with filename DT100.tar.gz; systems in this file will be used for the DT100 test. If you would like the script to re-download the tarball from the DOCK website, delete the DT100.tar.gz file from this directory and run the script again.\n"
fi

if [ ! -s ${rootdir}/DT100.tar.gz ]; then
	echo "Something went wrong with the download. Exiting..."
	exit 1
fi

echo -e "Un-tarring files...\n"
tar -xf DT100.tar.gz --directory ${rootdir}/

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
	cp ${rootdir}/DT100/${system}/${system}.rec.clean.mol2          ${sysdir}/${system}/001.files/  
	cp ${rootdir}/DT100/${system}/${system}.lig.am1bcc.mol2         ${sysdir}/${system}/001.files/
	cp ${rootdir}/DT100/${system}/${system}.rec.clust.close.sph     ${sysdir}/${system}/001.files/
done < ${rootdir}/DT100/params/system_list.txt

mkdir ${paramdir}
cp ${rootdir}/DT100/params/* ${paramdir}/


echo -e "Cleaning up workspace...\n"
if [ -s ${rootdir}/trash/ ]; then rm -r ${MAINDIR}/trash; fi
mkdir ${rootdir}/trash
mv ${rootdir}/DT100/ ${MAINDIR}/trash/
mv ${rootdir}/DT100.tar.gz ${MAINDIR}/trash

echo -e "Done!\n"
echo -e "All system files are located in ./`realpath --relative-to=./ ${sysdir}`\n"
echo -e "Temporary files have been moved to ./`realpath --relative-to=./ ${rootdir}/trash` and can be removed if needed\n" 
echo -e "Next step is run.002.generate_grids.sh\n"
