# DT Test Set Series
DOCKTest: Truncated test sets of protein-ligand systems to quickly check DOCK6 performance.

# Usage
## 1) Clone the repository from GitHub

To clone the scripts from GitHub, create an empty directory and run the command

`git clone https://github.com/ReillyO/DT100.git`

The `run.xxx` files and `zzz.scripts` folder should download automatically to your current directory. 

## 2) Customize the Scripts

Before running any scripts, open the `run.000.prepare_env.sh` in a text editor and:
* Change the `DT_MODE` variable to the desired option (100S, 100R, 1244)
* Change the `MAINDIR` environment variable definition to the desired absolute path
* Change the `DOCKHOME` variable to an absolute path to a DOCK installation (Note: path should not point to the `bin` folder, but to the folder above it)
* (optional) Change the `SYSDIR` environment variable definition to desired path if storage space is a concern (the full system folder will eventually require ~4GB of storage space for the 100-system modes, and ~45GB of space for the 1244 mode)

The pose reproduction simplex random seed trials are also modifiable and can be edited by adding or changing values in the array in `run.003.pose_reproduction.sh`. More detail on this is provided in Modifications.

## 3) Run The Scripts 
### a) Interactive

The steps can be run one-by-one in an interactive bash terminal in the order indicated by the prefix numbers (000, 001, 002, etc).

1) `source run.000.setup_env.sh` will set the needed paths in their environment variables.
2) `bash run.001.fetch_and_organize.sh` will use `wget` to retrieve a tarball of system files, and unpack them into a standardized directory structure.
3) `bash run.002.generate_grids.sh` will use `grid` to generate receptor grids - this step is computationally intensive.
4) `bash run.003.pose_reproduction.sh` will use `dock6` to perform pose reproduction trials using all random seeds in the file - this step is computationally intensive.
5) `bash run.004.analyze.sh` will collect the results of each pose reproduction and report system successes as well as how they compare to the provided reference file - it requires Python3 to be installed and accessible.

### b) Automated

The steps can also be ran in series using the `run_all_steps.sh` script located in the `zzz.scripts` directory. This script will run each step as described above, and wait for a step's completion before beginning the next one.

If the user has access to a Slurm-enabled computer cluster, the `run_all_steps.slurm` script in the `zzz.scripts` directory can be submitted to run in the queue instead of in the user's session. 

## 4) Interpreting Results

The script will output a high-level summary file with suffix `_Performance_Summary.txt`, which provides comparison to the reference file in `zzz.parameters` as well as a list of system-seed combinations (hereafter "cases") that produce errors. This should be sufficient for the majority of quick "sanity check" analyses. It is also output to console by the `run.004` script.

The script also provides per-case performance data ("Success", "Sampling Failure", "Scoring Failure") in a CSV file with suffix `_System_Performance.csv` for ready analysis. Rows are labeled with system PDB code (eg, 1A28), and columns with seed labels. If for some reason no docked molecules could be produced, the value will be "No Poses Generated".

Finally, per-case RMSDs are collected in a file with suffix `_Raw_Data.csv`, where each row begins with a case label (eg, 1A28_seed1) followed by comma-separated RMSDs in the order they appeared for fine-grain analysis. 

# Modifications

The systems and random seed experiments performed can be easily edited with the correct steps:

## Adding Systems

After unpacking the downloaded TAR file, the `SYSDIR` directory contains a directory for every system, labeled as its 4-letter PDB code. To add a system for analysis:
1) Create a new directory in `SYSDIR` named as the system's 4-character PDB code (eg 1A29)
2) Create a directory `001.files` in the newly created 4-character folder (SYSDIR/1A29/001.files)
3) In `001.files`, add:
* a charged receptor Mol2 file with name format SYSCODE.rec.clean.mol2 
* charged ligand Mol2 file with name format SYSCODE.lig.am1bcc.mol2 
* and a receptor sphere file with name format SYSCODE.rec.clust.close.sph
4) In the `zzz.parameters` directory, there is a file named `system_list.txt` that is referenced by the scripts. Open it in a text editor, and add the new system PDB code on a new line.
The new system should now be recognized and integrated into the benchmark the next time it is run. If this system is to be permanently integrated into the testset, any errors it produces should be added to the `ref_DT100_Performance_Summary.txt` file for future distribution.

## Adding Tests

New simplex random seed tests can be created by opening the `run.003.pose_reproduction.sh` script in a text editor and adding new values to the `random_seeds` array definition. These tests will automatically integrated next time the benchmark is run, and noted in the analysis summary. The reference file contained in DT100.tar.gz at time of writing contains data on random seeds 1 thru 10, so any of these can be added if additional data is desired.



