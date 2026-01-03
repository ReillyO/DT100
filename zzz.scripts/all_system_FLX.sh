#!/bin/bash

# Script will run DOCK pose reproduction on every system listed in the
# zzz.parameters/system_list.txt file and write out 100 scored poses for
# sucess/scorefail/samplefail analysis. 

# ARGUMENTS:
#  - label for trial dir
#  - simplex random seed (ex. 1)

# sample usage:
# bash all_system_FLX.sh 1


### Set some paths
dockdir="${DOCKHOME}/bin/"
rootdir="${MAINDIR}"
sysdir="${SYSDIR}"
paramdir="${rootdir}/zzz.parameters"
scriptdir="${rootdir}/zzz.scripts"

### Set random seed
label=${1}
seed=${2}

# loop reads systems from system_list.txt in parameters
while read system; do
	# move to system directory and copy in pertinent files
	mkdir ${sysdir}/${system}/003.pose_rep_${label}/
	cd ${sysdir}/${system}/003.pose_rep_${label}/
	cp ${sysdir}/${system}/001.files/${system}.lig.am1bcc.mol2 ./
	cp ${sysdir}/${system}/001.files/${system}.rec.clean.mol2 ./
	cp ${sysdir}/${system}/001.files/${system}.rec.clust.close.sph ./
	cp ${paramdir}/vdw_AMBER_parm99.defn ./vdw.defn
	cp ${paramdir}/flex.defn ./flex.defn
	cp ${paramdir}/flex_drive.tbl ./flex_drive.tbl
	
	# create DOCK input file with system-specific nomenclature
########################################################################################
	cat > flex.in<<EOF
conformer_search_type                                        flex
write_fragment_libraries                                     no
user_specified_anchor                                        no
limit_max_anchors                                            no
min_anchor_size                                              5
pruning_use_clustering                                       yes
pruning_max_orients                                          1000
pruning_clustering_cutoff                                    100
pruning_orient_score_cutoff                                  1000.0
pruning_conformer_score_cutoff                               100.0
pruning_conformer_score_scaling_factor                       1.0
use_clash_overlap                                            no
write_growth_tree                                            no
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
internal_energy_cutoff                                       100.0
ligand_atom_file                                             ${system}.lig.am1bcc.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               yes
use_rmsd_reference_mol                                       yes
rmsd_reference_filename                                      ${system}.lig.am1bcc.mol2
use_database_filter                                          no
orient_ligand                                                yes
automated_matching                                           yes
receptor_site_file                                           ${system}.rec.clust.close.sph
max_orientations                                             1000
critical_points                                              no
chemical_matching                                            no
use_ligand_spheres                                           no
bump_filter                                                  no
score_molecules                                              yes
contact_score_primary                                        no
grid_score_primary                                           yes
grid_score_rep_rad_scale                                     1
grid_score_vdw_scale                                         1
grid_score_es_scale                                          1
grid_lig_efficiency                                          no
grid_score_grid_prefix                                       ../002.grid_gen/${system}.rec
minimize_ligand                                              yes
minimize_anchor                                              yes
minimize_flexible_growth                                     yes
use_advanced_simplex_parameters                              no
minimize_flexible_growth_ramp                                yes
simplex_max_cycles                                           1
simplex_score_converge                                       0.1
simplex_initial_score_coverge                                5
simplex_cycle_converge                                       1.0
simplex_trans_step                                           1.0
simplex_rot_step                                             0.1
simplex_tors_step                                            10.0
simplex_anchor_max_iterations                                500
simplex_grow_max_iterations                                  250
simplex_grow_tors_premin_iterations                          0
simplex_final_min                                            no
simplex_random_seed                                          ${seed}
simplex_restraint_min                                        no
atom_model                                                   all
vdw_defn_file                                                ./vdw.defn
flex_defn_file                                               ./flex.defn
flex_drive_file                                              ./flex_drive.tbl
ligand_outfile_prefix                                        ${system}.${label}.out
write_mol_solvation                                          no
write_orientations                                           no
num_final_scored_poses                                       1000
num_preclustered_conformers                                  10000
write_conformations                                          yes
cluster_conformations                                        yes
cluster_rmsd_threshold                                       2.0
score_threshold                                              100.0
rank_ligands                                                 no
EOF
################################################################################
	
	# run DOCK as background process
	${dockdir}/dock6 -i flex.in -o flex.out &	
	
	cd ${sysdir}

done < ${paramdir}/system_list.txt

# ensure all background DOCKing finishes
wait

while read sys; do
	cd ${sysdir}/${sys}/003.pose_rep_${label}/
	rm -f vdw.defn flex.defn flex_drive.tbl ${system}.lig.am1bcc.mol2 ${system}.rec.clean.mol2 ${system}.rec.clust.close.sph
	cd ${sysdir}
done < ${paramdir}/system_list.txt

wait
