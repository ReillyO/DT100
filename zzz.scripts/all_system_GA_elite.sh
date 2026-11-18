#!/bin/bash

# Script will run DOCK pose reproduction on every system listed in the
# zzz.parameters/system_list.txt file and write out 100 scored poses for
# sucess/scorefail/samplefail analysis. 

# ARGUMENTS:
#  - simplex random seed (ex. 1)

# sample usage:
# bash all_system_FLX.sh 1


### Set some paths
dockhome="${DT_DOCKHOME}"
dockbin="${dockhome}/bin/"
dockparamdir="${dockhome}/parameters"
rootdir="${DT_MAINDIR}"
sysdir="${DT_SYSDIR}"
dtparamdir="${rootdir}/zzz.parameters"
scriptdir="${rootdir}/zzz.scripts"

### Set random seed
label=${1}
seed=${2}

# Set counter for batching
nrun=1

# loop reads systems from system_list.txt in parameters
while read system; do
	# move to system directory and copy in pertinent files
	cd ${sysdir}/${system}/003.GA_fl_${label}/

	cp ${dockparamdir}/vdw_AMBER_parm99.defn ./vdw.defn
	cp ${dockparamdir}/flex.defn ./flex.defn
	cp ${dockparamdir}/flex_drive.tbl ./flex_drive.tbl


	# do a quick DOCK in-and-out to give the ligand a proper header
	cat > calc_stats.in << EOF
conformer_search_type                                        rigid
use_internal_energy                                          no
ligand_atom_file                                             ${system}.lig.am1bcc.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               no
use_database_filter                                          yes
dbfilter_max_heavy_atoms                                     999
dbfilter_min_heavy_atoms                                     0
dbfilter_max_rot_bonds                                       999
dbfilter_min_rot_bonds                                       0
dbfilter_max_hb_donors                                       999
dbfilter_min_hb_donors                                       0
dbfilter_max_hb_acceptors                                    999
dbfilter_min_hb_acceptors                                    0
dbfilter_max_molwt                                           9999.0
dbfilter_min_molwt                                           0.0
dbfilter_max_formal_charge                                   10.0
dbfilter_min_formal_charge                                   -10.0
orient_ligand                                                no
bump_filter                                                  no
score_molecules                                              no
atom_model                                                   all
vdw_defn_file                                                vdw.defn
flex_defn_file                                               flex.defn
flex_drive_file                                              flex_drive.tbl
ligand_outfile_prefix                                        ${system}_lig_stat
write_mol_solvation                                          no
write_orientations                                           no
num_final_scored_poses                                       1
num_preclustered_conformers                                  1
score_threshold                                              100.0
rank_ligands                                                 no
EOF
	
	${dockbin}/dock6 -i calc_stats.in -o calc_stats.out

	# extract relevant crystal ligand parameters and if they are outside the standard GA ranges, update
	ga_constraint_upper_mol_wt="500.0"
	ga_constraint_rot_bon="10"
	ga_constraint_H_accept="10"
	ga_constraint_H_don="5"
	ga_constraint_formal_charge="2"

	grep "Molecular_Weight:" ${system}_lig_stat_scored.mol2 > TMP_stat.txt
	sed -i "s/#* *Molecular_Weight: *//g" TMP_stat.txt
	stat=`cat TMP_stat.txt`
        if (( $(echo "${stat} > ${ga_constraint_upper_mol_wt}" | bc -l) )); then
                ga_constraint_upper_mol_wt=${stat}
        fi

	grep "DOCK_Rotatable_Bonds:" ${system}_lig_stat_scored.mol2 > TMP_stat.txt; 
	sed -i "s/#* *DOCK_Rotatable_Bonds: *//g" TMP_stat.txt; 
	stat=`cat TMP_stat.txt`
	if (( $(echo "${stat} > ${ga_constraint_rot_bon}" | bc -l) )); then
		ga_constraint_rot_bon=${stat}
	fi	

	grep "HBond_Acceptors:" ${system}_lig_stat_scored.mol2 > TMP_stat.txt; 
	sed -i "s/#* *HBond_Acceptors: *//g" TMP_stat.txt
	stat=`cat TMP_stat.txt`
        if (( $(echo "${stat} > ${ga_constraint_H_accept}" | bc -l) )); then
                ga_constraint_H_accept=${stat}
        fi

	grep "HBond_Donors:" ${system}_lig_stat_scored.mol2 > TMP_stat.txt; 
	sed -i "s/#* *HBond_Donors: *//g" TMP_stat.txt
	stat=`cat TMP_stat.txt`
        if (( $(echo "${stat} > ${ga_constraint_H_don}" | bc -l) )); then
                ga_constraint_H_don=${stat}
        fi

	grep "Formal_Charge:" ${system}_lig_stat_scored.mol2 > TMP_stat.txt; 
	sed -i "s/#* *Formal_Charge: *//g" TMP_stat.txt
	stat=`cat TMP_stat.txt`
	stat=${stat//-/}
        if (( $(echo "${stat} > ${ga_constraint_formal_charge}" | bc -l) )); then
                ga_constraint_formal_charge=${stat}
        fi
	
	# create DOCK input file with system-specific nomenclature
########################################################################################
	cat > elitism.in<<EOF
conformer_search_type                                        genetic
ga_molecule_file                                             ${system}_GA_roul.gen10_processed.mol2 
ga_utilities                                                 no
ga_fraglib_scaffold_file                                     ${sysdir}/${system}/003.fraglib/GA_scaffold.mol2
ga_fraglib_linker_file                                       ${sysdir}/${system}/003.fraglib/GA_sidechain.mol2
ga_fraglib_sidechain_file                                    ${sysdir}/${system}/003.fraglib/GA_linker.mol2
ga_torenv_table                                              ${sysdir}/${system}/003.fraglib/GA_torenv.dat
ga_max_generations                                           10
ga_xover_on                                                  no
ga_bond_tolerance                                            0.5
ga_angle_cutoff                                              0.14
ga_check_overlap                                             no
ga_mutate_addition                                           yes
ga_mutate_deletion                                           yes
ga_mutate_substitution                                       yes
ga_mutate_replacement                                        yes
ga_add_rate                                                  25
ga_del_rate                                                  25
ga_sub_rate                                                  25
ga_rep_rate                                                  25
ga_mutate_parents                                            yes
ga_pmut_rate                                                 0.3
ga_omut_rate                                                 0.7
ga_max_mut_cycles                                            5
ga_mut_sampling_method                                       rand
ga_num_random_picks                                          15
ga_max_root_size                                             5
ga_energy_cutoff                                             100
ga_heur_unmatched_num                                        1
ga_heur_matched_rmsd                                         2.0
ga_mol_wt_cutoff_type                                        hard
ga_constraint_upper_mol_wt                                   ${ga_constraint_upper_mol_wt}
ga_constraint_lower_mol_wt                                   0
ga_constraint_rot_bon                                        ${ga_constraint_rot_bon}
ga_constraint_H_accept                                       ${ga_constraint_H_accept}
ga_constraint_H_don                                          ${ga_constraint_H_don}
ga_constraint_formal_charge                                  ${ga_constraint_formal_charge}
ga_ensemble_size                                             50
ga_selection_method                                          elitism
ga_elitism_combined                                          yes
ga_elitism_option                                            max
ga_max_num_gen_with_no_crossover                             25
ga_name_identifier                                           ${system}_GA_elite
ga_output_prefix                                             ${system}_GA_elite
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
internal_energy_cutoff                                       100.0
use_database_filter                                          no
orient_ligand                                                no
bump_filter                                                  no
score_molecules                                              yes
contact_score_primary                                        no
grid_score_primary                                           yes
grid_score_rep_rad_scale                                     1
grid_score_vdw_scale                                         1
grid_score_es_scale                                          1
grid_lig_efficiency                                          no
grid_score_grid_prefix                                       ${sysdir}/${system}/002.grid_gen/${system}.rec
minimize_ligand                                              yes
minimize_anchor                                              yes
minimize_flexible_growth                                     yes
use_advanced_simplex_parameters                              no
simplex_max_cycles                                           1
simplex_score_converge                                       0.1
simplex_cycle_converge                                       1.0
simplex_trans_step                                           1.0
simplex_rot_step                                             0.1
simplex_tors_step                                            10.0
simplex_anchor_max_iterations                                500
simplex_grow_max_iterations                                  500
simplex_grow_tors_premin_iterations                          0
simplex_final_min                                            no
simplex_random_seed                                          ${seed}
simplex_restraint_min                                        no
atom_model                                                   all
vdw_defn_file                                                vdw.defn
flex_defn_file                                               flex.defn
flex_drive_file                                              flex_drive.tbl
EOF
################################################################################
	
	# run DOCK as background process
	#echo "Running DOCK elitism for ${system}"
	${dockbin}/dock6 -i elitism.in -o elitism.out &	
	
	cd ${sysdir}

	# Batch jobs based on number of processors
	if ((nrun % DT_NPROC == 0)); then
		echo "batch $((nrun / DT_NPROC))" 
		wait
	fi

	nrun=$((nrun+1))

done < ${dtparamdir}/system_list.txt

# ensure all background DOCKing finishes
wait

while read system; do
	cd ${sysdir}/${system}/003.GA_fl_${label}/
	rm -f vdw.defn flex.defn flex_drive.tbl ${system}.lig.am1bcc.mol2 ${system}.rec.clean.mol2 ${system}.rec.clust.close.sph
	cd ${sysdir}
done < ${dtparamdir}/system_list.txt

wait
