#!/bin/bash

# note that analysis expects Python3 to be installed and available
# Script will:
#  - Collect symmetry-corrected RMSDs for each pose in each system and
#    dump them into a specified .txt file ($rmsd_dump_file)
#  - Use a Python script to determine whether each system saw a Success,
#    Sampling Failure, or Scoring failure using the collected RMSDs
#  - The same Python script will compare the performance to a bundled 
#    reference and output a summary with any noted changes

# assumes pose reproduction (step 003) has been run successfully
# (script will note if any systems appear to have suffered errors)

# set some paths
dockdir="${DOCKHOME}/bin/"
rootdir="${MAINDIR}"
sysdir="${SYSDIR}"
paramdir="${rootdir}/zzz.parameters"
scriptdir="${rootdir}/zzz.scripts"
rmsddir="${rootdir}/zzz.rmsds"
dtmode="DT${DT_MODE}"

rmsd_dump_file="${rootdir}/${dtmode}_all_rmsd_dump.txt"
if [ -s ${rmsd_dump_file} ]; then rm ${rmsd_dump_file}; fi
touch ${rmsd_dump_file}

echo "Collecting RMSDs..."

while read system; do
	rawfile="${sysdir}/${system}/004.analysis/system_rmsds.txt"
	cd ${sysdir}/${system}
	if [ -s ${rawfile} ]; then rm ${rawfile}; fi
	touch ${rawfile}
	for dir in `ls -d 003.pose_rep*`; do
		echo "SYSTEM: ${system}_${dir//003.pose_rep_/}" >> ${rawfile}
		grep "RMSDh" ${dir}/${system}.*out_conformers.mol2 >> ${rawfile}
	done
	
	sed -i "s/##########                            HA_RMSDh: *//g" ${rawfile}

	cat ${rawfile} >> ${rmsd_dump_file}

done < ${paramdir}/system_list.txt

out_prefix=${rootdir}/${dtmode}
ref_file=${paramdir}/ref_${dtmode}_Performance_Summary.txt

echo "Analyzing RMSDs..."

# python3  generate_summary.py                RMSDfile        OutPrefix            ReferenceFile
python3 ${scriptdir}/generate_summary.py  ${rmsd_dump_file} ${out_prefix} `realpath --relative-to=./ ${ref_file}`

echo "Done! Results dumped to `realpath --relative-to=./ ${out_prefix}_Performance_Summary.txt`. "
