import os, sys
from collections import defaultdict

# Accepts 
#  - a file of Tanimoto similarities 
#  - a file of RMSDs 
#  - a reference file OR the keyword "GENERATE_REFERENCE"
#  - a prefix for the output
# and passes judgement

# this should be a hierarchy best -> worst
perf_options = ["PerfectID", "UniqPoseID", "BuiltPoseID", "BuiltChemID", "BuiltFail", "Incomplete"]

# uses the Tanimoto similarity values and RMSD values from DOCK to 
# judge performance for the system
# ASSUMES THAT the tan_list and rmsd_list are in the same order/length 
def performance_string_from_lists(tan_list, rmsd_list):
    if rmsd_list[0] == 12345678: return "Incomplete"
    if tan_list[0] == 1.0 and rmsd_list[0] < 2.0: return "PerfectID"
    found_built = False
    match_count = 0
    for i in range(1, len(tan_list)):
        if tan_list[i] == 1.0:
            match_count += 1
            if rmsd_list[i] < 2.0 and match_count == 1:
                return "UniqPoseID"
            elif rmsd_list[i] < 2.0:
                return "BuiltPoseID"
    if match_count > 0: return "BuiltChemID"
    return "BuiltFail"

# read in requisite files
try: 
    tanfile = sys.argv[1]
    rmsdfile = sys.argv[2]
    reffile = sys.argv[3]
    outpref = sys.argv[4]
except:
    print("provide: tanfile rmsdfile reffile prefix")

if reffile == "GENERATE_REFERENCE": print("NOTE: generating a reference file, will be prefixed 'ref'")

# STEP 1: collect statistics from current run

# for RMSD and Tanimoto scores, every dictionary entry corresponds to
# a run "case" - system+seed combo, and the value is a list of the 
# RMSD or Tanimoto similarity scores.
tan_dict = defaultdict(list)
seeds = []
with open(tanfile, 'r') as f:
    for line in f.readlines():
        linelist = line.split(",")
        case = linelist[0].strip()
        seed = int(case.split("_")[1].strip("seed"))
        if seed not in seeds: seeds.append(seed); 
        tan_dict[case] = [float(x.strip()) for x in linelist[1:]]

rmsd_dict = defaultdict(list)
sys_list = []
with open(rmsdfile, 'r') as f:
    for line in f.readlines():
        linelist = line.split(",")
        case = linelist[0].strip()
        rmsd_dict[case] = [1000 if float(x.strip()) == -1000 else float(x.strip()) for x in linelist[1:]]
        sys = case.split("_")[0].strip()
        if sys not in sys_list: sys_list.append(sys)

# initialize dict to store performance totals for each seed (one int
# per entry in perf_options)
stats = defaultdict(list) 
for sidx in range(0, len(seeds)):
    stats[seeds[sidx]] = [0] * len(perf_options)

# initialize dict to store per-case performance (key is the case, value
# is the performance string
perf_dict = defaultdict(str)
for case in tan_dict:
    perf = performance_string_from_lists(tan_dict[case], rmsd_dict[case])
    seed = int(case.split("_")[1].strip("seed")) 
    
    stats[seed][perf_options.index(perf)] += 1
    perf_dict[case] = perf



# STEP 2: Either
#   Generate summary file based on comparison to reference OR
#   Generate a non-compared reference file for future use
if reffile != "GENERATE_REFERENCE":
    ref_perf_dict = defaultdict(str)
    ref_stats = defaultdict(int)
    ref_seeds = []
    non_trial_seeds = []
    non_ref_seeds = []
    
    # First, read data from the provided reference file
    with open(reffile, 'r') as f:
        # Expts, Fails, None
        state = "None"
        
        for line in f.readlines():
            if "Comparing" in line:
                state = "None"
	
            if line == "\n": continue
            if state == "Expts": # read expts in the reference file
                if len(line.rsplit(":", 1)) == 1: continue
                ref_seed, vals = line.rsplit(":", 1)
                vals = vals.split(", ")
                ref_seed = int(ref_seed.strip().strip("seed"))
                for i in range(len(vals)):
                    vals[i] = vals[i].strip()
                    ref_stats[ref_seed] = [int(x) for x in vals]
                if ref_seed in seeds: ref_seeds.append(ref_seed)
                else: non_trial_seeds.append(ref_seed)
            
            elif state == "Fails": # case-by-case fails in the reference file
                ref_case, ref_result = line.rsplit(":", 1)
                ref_perf_dict[ref_case] = ref_result.strip()
            
            if "Performance" in line:
                state = "Expts"
            elif "Failures" in line:
                state = "Fails"

    # initialize array to hold differences in performance totals (ints) between ref and current
    # (across all seeds)
    stat_diffs = [0] * len(perf_options)

    # find seeds not present in reference and calculate stat_diffs 
    for seed in seeds: 
        if seed not in ref_seeds: non_ref_seeds.append(seed); continue
        for opt in range(0, len(perf_options)):
            stat_diffs[opt] += stats[seed][opt] - ref_stats[seed][opt]

    # run through all performances, compare to reference, and increment counters
    # if a difference is found
    total_improve = 0
    total_decline = 0
    net_diff = 0
    for case in perf_dict:
        seed = int(case.split("_")[1].strip("seed"))
        if case in ref_perf_dict and perf_dict[case] != ref_perf_dict[case]:
            if perf_options.index(perf_dict[case]) > perf_options.index(ref_perf_dict[case]):
                total_decline += 1; net_diff -= 1
            else:
                total_improve += 1; net_diff += 1
        elif seed in ref_seeds and perf_dict[case] != ref_perf_dict[case] and perf_dict[case] != perf_options[0]:
            total_decline += 1; net_diff -= 1

    # MAIN OUTPUT   
 
    output = []
    output.append("#######################################################")
    output.append("#             DTGA Performance Summary                #")
    output.append("#######################################################")
    output.append("")
    output.append(f"Test performed on {int(len(perf_dict)/len(seeds))} systems with {len(seeds)} seeds")

    # let the user know what seeds are available/which ones cannot be compared
    if len(non_trial_seeds) > 0: output.append(f"NOTE: seeds ({" ".join([str(x) for x in non_trial_seeds])}) from reference were not tested in this trial")
    if len(non_ref_seeds) > 0: output.append(f"NOTE: seeds ({" ".join([str(x) for x in non_ref_seeds])}) from this trial are not present in the reference and cannot be compared")
    
    # summary
    if net_diff == 0: output.append(f"TAKEAWAY: DOCK performed net EQUAL to the reference presented")
    elif net_diff < 0: output.append(f"TAKEAWAY: DOCK performed net WORSE than the reference presented")
    else: output.append(f"TAKEAWAY: DOCK performed net BETTER than the reference presented")

    output.append(f"Improved: +{total_improve}")
    output.append(f"Declined: -{total_decline}")
    d = total_improve - total_decline
    output.append(f"Net:      {'-' if d < 0 else '+'}{net_diff}")
    
    # per-seed numbers for each performance category
    output.append("")
    output.append(f"### Performance ({','.join(perf_options)}) ###")
 
    # format and add one seed per line 
    for seed in seeds:
        stat_line = "seed" + str(seed)                                                       # seedX
        stat_line = stat_line.rjust(7) + ":"                                                 #   seedX:
        for opt in range(0, len(perf_options)):
            if seed in ref_seeds:                                                            #   seedX: aa(aa), [...]
                tmp_field = str(stats[seed][opt]) + "(" + str(ref_stats[seed][opt]) + ")"
            else: tmp_field = str(stats[seed][opt]) + "()"
            stat_line += tmp_field.rjust(11) + ","
        stat_line = stat_line.rsplit(",", 1)[0]
        output.append(stat_line)

    # provide summary statistics: sum and avg changes
    output.append("")
    output.append("### Overall change ###")
    stat_line = "Sum:    "
    for opt in range(0, len(perf_options)):
        stat_line += str(stat_diffs[opt]).rjust(11) + ","
    stat_line = stat_line.rsplit(",", 1)[0]
    output.append(stat_line)
    stat_line = "Average:"
    for opt in range(0, len(perf_options)):
        stat_line += str(round(float(stat_diffs[opt])/float(len(ref_seeds)), 3)).rjust(11) + ","
    stat_line = stat_line.rsplit(",", 1)[0]
    output.append(stat_line)
    
    # Print this as a short summary before all the verbosity and tell the user where
    # to find the rest
    print("\n".join(output))
    print("")
    print("Summary complete! Full output can be found in " + outpref + "_Performance_Summary.txt")

    # provide granular data on any changes between the reference and this one
    output.append("")
    output.append("#### Comparing to Reference ####")
    change = False
    for case in perf_dict:
        if case in ref_perf_dict and perf_dict[case] != ref_perf_dict[case]:
            output.append(case + ": " + ref_perf_dict[case] + "->" + perf_dict[case])
            change = True
    if not change: output.append("Perfect agreement with trials in reference") 
    output.append("")

    # provide a comprehensive list of the failures observed in the trial (anything not perf_options[0])
    output.append("#### DOCK Failures In This Trial ####")
    for case in perf_dict:
        if perf_dict[case] != perf_options[0]:
            output.append(f"{case}: {perf_dict[case]}")
    with open(outpref + "_Performance_Summary.txt", 'w') as f:
        f.write("\n".join(output))
     
else:
    output = []
    output.append("#######################################################")
    output.append("#             DTGA Performance Summary                #")
    output.append("#######################################################")
    output.append("")
    output.append(f"Test performed on {int(len(perf_dict)/len(seeds))} systems with {len(seeds)} seeds")
    output.append("")
    output.append(f"### Performance ({','.join(perf_options)}) ###")
    for seed in seeds:
        stat_line = "seed"+str(seed)
        stat_line = stat_line.rjust(6) + ":" 
        for opt in range(0, len(perf_options)):
            stat_line += str(stats[seed][opt]).rjust(8) + ","
        stat_line = stat_line.rsplit(",", 1)[0]
        output.append(stat_line)
    output.append("")
    output.append("#### Comparing to Reference ####")
    output.append("")
    output.append("#### DOCK Failures In This Trial ####")
    for case in perf_dict:
        if perf_dict[case] != perf_options[0]:
            output.append(f"{case}: {perf_dict[case]}")
    with open("ref_" + outpref + "_Performance_Summary.txt", 'w') as f:
        f.write("\n".join(output))


# Write out verbose data dump for per-case performance
per_sys_perf = defaultdict(list)
for sys in sys_list:
    per_sys_perf[sys] = [""] * len(seeds)

for case in perf_dict:
    sys = case.split("_")[0].strip()
    seed_idx = seeds.index(int(case.split("_")[1].strip("seed")))
    per_sys_perf[sys][seed_idx] = perf_dict[case]

output = []
output.append(","+",".join(["seed"+str(x) for x in seeds]))
for sys in sys_list:
    output.append(sys + "," + ",".join(per_sys_perf[sys]))

with open(outpref+"_System_Performance.csv", 'w') as f:
    f.write("\n".join(output))



# Write out verbose data dump for RMSDs and Tanimoto
longest = 0
for case in tan_dict:
    if len(tan_dict[case]) > longest: longest = len(tan_dict[case])

#Tanimoto
output = []
output.append(","+",".join(["Molecule"+str(x) for x in range(0, longest)]))
for case in tan_dict:
    output.append(case+","+",".join([str(x) for x in tan_dict[case]]))

with open(outpref+"_Raw_Tanimoto.csv", 'w') as f:
    f.write("\n".join(output))

#RMSDs
output = []
output.append(","+",".join(["Molecule"+str(x) for x in range(0, longest)]))
for case in tan_dict:
    output.append(case+","+",".join([str(x) for x in tan_dict[case]]))

with open(outpref+"_Raw_RMSDs.csv", 'w') as f:
    f.write("\n".join(output))

