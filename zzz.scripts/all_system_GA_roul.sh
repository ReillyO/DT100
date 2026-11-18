#!/bin/bash

# Script will run DOCK pose reproduction on every system listed in the
# zzz.parameters/system_list.txt file and write out 100 scored poses for
# sucess/scorefail/samplefail analysis. 
# Afterwards will check if parent is present in final generation and delete it
# if it is (reconstructed or original)

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

verbose="false"

# loop reads systems from system_list.txt in parameters
while read system; do
	# move to system directory and copy in pertinent files
	if [ -e ${sysdir}/${system}/003.GA_fl_${label}/ ]; then rm -r ${sysdir}/${system}/003.GA_fl_${label}/; fi
	mkdir ${sysdir}/${system}/003.GA_fl_${label}/
	cd ${sysdir}/${system}/003.GA_fl_${label}/
	cp ${sysdir}/${system}/001.files/${system}.lig.am1bcc.mol2 ./
	cp ${sysdir}/${system}/001.files/${system}.rec.clean.mol2 ./
	cp ${sysdir}/${system}/001.files/${system}.rec.clust.close.sph ./

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
		ga_constraint_rot_bon=$((stat+1))
	fi	

	grep "HBond_Acceptors:" ${system}_lig_stat_scored.mol2 > TMP_stat.txt; 
	sed -i "s/#* *HBond_Acceptors: *//g" TMP_stat.txt
	stat=`cat TMP_stat.txt`
        if (( $(echo "${stat} > ${ga_constraint_H_accept}" | bc -l) )); then
                ga_constraint_H_accept=$((stat+1))
        fi

	grep "HBond_Donors:" ${system}_lig_stat_scored.mol2 > TMP_stat.txt; 
	sed -i "s/#* *HBond_Donors: *//g" TMP_stat.txt
	stat=`cat TMP_stat.txt`
        if (( $(echo "${stat} > ${ga_constraint_H_don}" | bc -l) )); then
                ga_constraint_H_don=$((stat+1))
        fi
	

	grep "FC_Rounded:" ${system}_lig_stat_scored.mol2 > TMP_stat.txt; 
	sed -i "s/#* *FC_Rounded: *//g" TMP_stat.txt
	stat=`cat TMP_stat.txt`
	stat=${stat//-/} # absolute value
        if (( $(echo "${stat} > ${ga_constraint_formal_charge}" | bc -l) )); then
                ga_constraint_formal_charge=$((stat+1))
        fi
	
	
	# create DOCK input file with system-specific nomenclature
########################################################################################
	cat > roulette.in<<EOF
conformer_search_type                                        genetic
ga_molecule_file                                             ${system}.lig.am1bcc.mol2
ga_utilities                                                 no
ga_fraglib_scaffold_file                                     ${dockparamdir}/fraglib_ga_scaffold.mol2
ga_fraglib_linker_file                                       ${dockparamdir}/fraglib_linker.mol2
ga_fraglib_sidechain_file                                    ${dockparamdir}/fraglib_sidechain.mol2
ga_torenv_table                                              ${sysdir}/${system}/003.fraglib/unique_full_sorted_fraglib.dat
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
ga_ensemble_size                                             20
ga_selection_method                                          roulette
ga_roulette_separate                                         yes
ga_max_num_gen_with_no_crossover                             25
ga_name_identifier                                           ${system}_GA_roul
ga_output_prefix                                             ${system}_GA_roul
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
internal_energy_cutoff                                       100.0
use_database_filter                                          no
orient_ligand                                                no
bump_filter                                                  no
score_molecules                                              yes
contact_score_primary                                        no
grid_score_primary                                           no
gist_score_primary                                           no
multigrid_score_primary                                      no
dock3.5_score_primary                                        no
continuous_score_primary                                     no
footprint_similarity_score_primary                           no
pharmacophore_score_primary                                  no
hbond_score_primary                                          no
internal_energy_score_primary                                no
descriptor_score_primary                                     yes
descriptor_use_grid_score                                    yes
descriptor_use_grid_lig_efficiency                           no
descriptor_use_pharmacophore_score                           no
descriptor_use_tanimoto                                      yes
descriptor_use_hungarian                                     no
descriptor_use_volume_overlap                                no
descriptor_use_gist                                          no
descriptor_use_dock3.5                                       no
descriptor_grid_score_rep_rad_scale                          1
descriptor_grid_score_vdw_scale                              1
descriptor_grid_score_es_scale                               1
descriptor_grid_score_grid_prefix                            ${sysdir}/${system}/002.grid_gen/${system}.rec
descriptor_fingerprint_ref_filename                          ${system}.lig.am1bcc.mol2
descriptor_weight_grid_score                                 1
descriptor_weight_fingerprint_tanimoto                       10
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
	#echo "Running DOCK roulette for ${system}"
	${dockbin}/dock6 -i roulette.in -o roulette.out &	
	

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
	# check for parent
	grep "Name" ${system}_GA_roul.restart0010.mol2 > TMP_names.txt
	i=0
	# this may need updating for newer versions with Brock's nomenclature changes
	while read name; do
		if [[ "${name}" =~ "${system}_GA_roul_g0000_i0000" ]]; then
			if [ "${verbose}" = "true" ]; then echo "removing parent molecule ${i}"; fi
		else
			echo ${i} >> TMP_to_keep.txt
		fi
		i=$((i+1))
	done < TMP_names.txt

	if [ -s TMP_to_keep.txt ]; then
		python ${scriptdir}/collect_specific_mol2s.py TMP_to_keep.txt ${system}_GA_roul.restart0010.mol2 ${system}_GA_roul.gen10_processed.mol2
		TMP_to_keep.txt
	else
		echo "NOTE: system ${system} did not produce any molecules from roulette. Please review the system."
	fi

	rm TMP_names.txt 

	rm -f vdw.defn flex.defn flex_drive.tbl ${system}.lig.am1bcc.mol2 ${system}.rec.clean.mol2 ${system}.rec.clust.close.sph
	cd ${sysdir}
done < ${dtparamdir}/system_list.txt

wait
