#!/bin/bash

# script to 
#  1) generate focused fragment library for a provided
#     system ligand in "fraglib" directory
#  2) append the torenv and fragments to the standard lib
#     in the provided home dir 

dockdir="${DT_DOCKHOME}/bin/"
rootdir="${DT_MAINDIR}"
sysdir="${DT_SYSDIR}"
paramdir="${rootdir}/zzz.parameters"
scriptdir="${rootdir}/zzz.scripts"

while IFS= read -r system; do
	cd ${sysdir}/${system}

	if [ -e 003.fraglib ]; then rm -r 003.fraglib; fi
	mkdir 003.fraglib
	cd 003.fraglib

	cp ${sysdir}/${system}/001.files/${system}.lig.am1bcc.mol2 ./
	cp ${paramdir}/vdw_AMBER_parm99.defn ./vdw.defn
        cp ${paramdir}/flex.defn ./flex.defn
        cp ${paramdir}/flex_drive.tbl ./flex_drive.tbl
	
	cat <<EOF>frag.in
conformer_search_type                                        flex
write_fragment_libraries                                     yes
fragment_library_prefix                                      GA
fragment_library_freq_cutoff                                 1
fragment_library_sort_method                                 freq
fragment_library_trans_origin                                no
use_internal_energy                                          no
ligand_atom_file                                             ${system}.lig.am1bcc.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               no
use_database_filter                                          no
orient_ligand                                                no
bump_filter                                                  no
score_molecules                                              no
atom_model                                                   all
vdw_defn_file                                                vdw.defn
flex_defn_file                                               flex.defn
flex_drive_file                                              flex_drive.tbl
ligand_outfile_prefix                                        output
write_mol_solvation                                          no
write_orientations                                           no
num_final_scored_poses                                       1
num_preclustered_conformers                                  1
score_threshold                                              100.0
rank_ligands                                                 no
EOF

	${dockdir}/dock6 -i frag.in -o frag.out

	# produces unique_full_sorted_fraglib.dat for future use
	python ${dockdir}/combine_torenv.py ${DT_DOCKHOME}/parameters/fraglib_torenv.dat GA_torenv.dat

	rm vdw.defn flex.defn flex_drive.tbl ${system}.lig.am1bcc.mol2
		
done < ${paramdir}/system_list.txt
