#!/bin/bash

#
# This script will run the grid program. Parameters to set include the attractive and repulsive vdw
# exponents. We usually do 6-9, respectively, to 'soften' the receptor landscape. Grid spacing is
# typically set to 0.4. The box margin, or the distance beyond the spheres in every direction is 
# typically set to 8 angstroms. Finally, make sure sphcut and maxkeep match the previous csh script.
#
# This script will spawn one instance of GRID per system, which can be computationally intensive.


### Set some variables manually
attractive="6"
repulsive="9"
grid_spacing="0.3"
box_margin="8"
sphcut="8"
maxkeep="75"


### Set some paths
dockbin="${DT_DOCKHOME}/bin/"
dockparamdir="${DT_DOCKHOME}/parameters/"
rootdir="${DT_MAINDIR}"
sysdir="${DT_SYSDIR}"
dtparamdir="${rootdir}/zzz.parameters"
scriptdir="${rootdir}/zzz.scripts"

# Set counter for batching
nrun=1

# Check to see if grid generation is necessary by counting number of
# complete grids (.bmps) and number of systems
if [ `ls ${sysdir}/????/002.grid_gen/????.rec.bmp | wc -l` = `ls -d ${sysdir}/*/ | wc -l` ]; then 
	echo "ERROR: Grids are already present! Please use zzz.scripts/clean.sh to clear them if you wish to re-calculate.";
	echo "Exiting grid generation."
	exit
fi

echo "Starting grid generation for all systems..."

while read system; do 
	### Move to working directory
	if [ ! -s ${sysdir}/${system}/002.grid_gen ]; then
		mkdir ${sysdir}/${system}/002.grid_gen
	fi
	
	cd ${sysdir}/${system}/002.grid_gen/
	
	
	
	### Make sure the receptor and spheres are present
	if [ ! -s  ${sysdir}/${system}/001.files/${system}.rec.clean.mol2 ];then
		echo "Missing ${system}.rec.clean.mol2. Skipping..."
		continue
	fi
	
	if [ ! -s ${sysdir}/${system}/001.files/${system}.rec.clust.close.sph ];then
		echo "Missing ${system}.rec.clust.close.sph. Skipping..."
		continue
	fi
	
	
	
	### Link and copy some files here
	cp ${sysdir}/${system}/001.files/${system}.rec.clean.mol2 ./
	cp ${sysdir}/${system}/001.files/${system}.rec.clust.close.sph ./
	
	# Parameter files	
	cp ${dockparamdir}/vdw_AMBER_parm99.defn ./vdw.defn
	cp ${dockparamdir}/chem.defn ./chem.defn
	
	
	### Construct box.pdb centered on spheres
        # input file:	
	##################################################
	cat  >box.in <<EOF
yes
${box_margin}
./${system}.rec.clust.close.sph
1
box.pdb
EOF
	##################################################
	# command:
	${dockbin}/showbox < box.in > v.002.txt
	
	
	### Construct grid using receptor mol2 file and generated box
	# input file:
	##################################################
	cat  >grid.in<<EOF
compute_grids                  yes
grid_spacing                   ${grid_spacing}
output_molecule                no
contact_score                  no
chemical_score		       no
energy_score                   yes
energy_cutoff_distance         999
atom_model                     a
attractive_exponent            ${attractive}
repulsive_exponent             ${repulsive}
distance_dielectric            yes
dielectric_factor              4
allow_non_integral_charges     yes
bump_filter                    yes
bump_overlap                   0.75
receptor_file                  ./${system}.rec.clean.mol2
box_file                       ./box.pdb
vdw_definition_file            ./vdw.defn
chemical_definition_file       ./chem.defn
score_grid_prefix              ./${system}.rec
EOF
	##################################################
	# command:
	${dockbin}/grid -v -i grid.in -o grid.out & 
	
	rm -f ./${system}.rec.clean.mol2 
	rm -f ./${system}.rec.clust.close.sph 
	
	cd ${sysdir}

	# Batch based on number of processors
	if ((nrun % DT_NPROC == 0)); then
		echo "batch $((nrun/DT_NPROC))"
		wait
	fi

	nrun=$((nrun+1))

done < ${dtparamdir}/system_list.txt	

# ensure all grid processes finish before terminating script
wait

echo "Finished grid generation."

while read system; do
	if [ ! -s ${sysdir}/${system}/002.grid_gen/*bmp ]; then
		echo "WARNING: ${system} failed grid generation!"
	fi
done < ${dtparamdir}/system_list.txt

echo "Next step is to run 003.pose_reproduction.sh"
