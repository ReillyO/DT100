import os, sys
from collections import defaultdict

# NOMENCLATURE
#  - system/sys:       Particular PDB code 
#  - experiment/expt:  Seed or other condition
#  - case:             Particular PDB code under given condition/seed

def performance_string_from_list(rmsd_list):
    if rmsd_list[0] < 2.0: return "Success"
    elif rmsd_list[0] == 123456789.0: return "No Poses Generated"
    for rmsd in rmsd_list:
        if rmsd < 2.0: return "Scoring Fail"
    return "Sampling Fail"

def aworsethanb(perf1, perf2):
    return (perf2 == "Success" and (perf1 == "Scoring Fail" or perf1 == "Sampling Fail")) or (perf2 == "Scoring Fail" and perf1 == "Sampling Fail")

##############################################
#               Main                         #
##############################################


# check arguments
try:
    in_file = sys.argv[1]
    out_prefix = sys.argv[2]
    ref_file = sys.argv[3]
except:
    print("Syntax: python generate_summary.py $in_file $outprefix $reference")

# per-experiment rmsd dictionary
case_rmsd_dict = defaultdict(list)
expt_count = 0
current_expt = ""

# read in RMSDs for each test case from dump file
# note if no RMSDs were found, usually indicating a failure/error
with open(in_file, 'r') as rmsd_file:
    rmsd_list = []
    for line in rmsd_file.readlines():
        if "SYSTEM" in line and expt_count > 0:
            if len(rmsd_list) == 0: 
                print("NO RMSDS FOUND FOR EXPT " + current_expt)
                rmsd_list = [123456789.0]
            case_rmsd_dict[current_expt] = rmsd_list
            rmsd_list = []
            current_expt = line.split("SYSTEM: ")[1].strip()
            expt_count += 1
        elif "SYSTEM" in line:
            current_expt = line.split("SYSTEM: ")[1].strip()
            expt_count += 1
        else:
            rmsd_list.append(float(line))
    if len(rmsd_list) == 0:
        print("NO RMSDS FOUND FOR EXPT " + current_expt)
        rmsd_list = [123456789.0]
    case_rmsd_dict[current_expt] = rmsd_list
    rmsd_list = []

# per-system, -experiment, and -case performance dictionaries
sys_perf_dict = defaultdict(list) # "AAAA" : [SF, S, S, S...]
expt_perf_dict = defaultdict(list) # "seed1" : [S, SF, S, S...]
case_perf_dict = defaultdict(str) # "AAAA_seed1" : "S"
case_fails = []

# populate dictionaries
for case in case_rmsd_dict.keys():
    system, experiment = case.split("_", 1)
    performance = performance_string_from_list(case_rmsd_dict[case])
    # per-system stat collection
    sys_perf_dict[system].append(performance)

    # per-experiment (seed) stat collection
    expt_perf_dict[experiment].append(performance)

    # per-case stat collection
    case_perf_dict[case] = performance

    if performance != "Success":
        case_fails.append(case)


# per-experiment summary stats [# Successes, # ScoreFs, # SampleFs, # Errors]
expt_dict = defaultdict(list)
for expt in expt_perf_dict.keys():
    expt_dict[expt] = [expt_perf_dict[expt].count("Success"), 
                       expt_perf_dict[expt].count("Scoring Fail"), 
                       expt_perf_dict[expt].count("Sampling Fail"), 
                       expt_perf_dict[expt].count("No Poses Generated")]



# write out verbose per-case RMSD CSV
max_length = 0
# first determine longest RMSD list
for case in case_rmsd_dict.keys():
    l = len(case_rmsd_dict[case])
    if l > max_length:
        max_length = l
output = ""
raw_data_file = out_prefix + "_Raw_Data.csv"
# "top row" labels
output += ","
for i in range(1, max_length+1):
    output += "Pose" + str(i) + ","
output = output.rsplit(",",1)[0]
output += "\n"
# RMSD rows
for key in case_rmsd_dict.keys():
    output += key+","
    output += ",".join(map(str, case_rmsd_dict[key])) + "\n"
with open(raw_data_file, 'w') as f:
    f.write(output)



# write out verbose per-system success/fail CSV
output = ","
output += ",".join(expt_perf_dict.keys())
output += "\n"
for system in sys_perf_dict.keys():
    output += system + ","
    output += ",".join(sys_perf_dict[system])
    output += "\n"
perf_summary_file = out_prefix + "_System_Performance.csv"
with open(perf_summary_file, 'w') as f:
    f.write(output)



# check results against saved reference file
# First collect what experiments are in the 
# reference using Expts section 
# Then check if same errors are present in current test
# using the Fails section
fail_mismatches = defaultdict(str)

ref_case_fails_dict = defaultdict(str)
with open(ref_file, 'r') as f:
    # Expts, Fails, None
    state = "None"
    ref_expts = []
    non_ref_expts = []
    
    for line in f.readlines():
        if "Comparing" in line:
            state = "None"

        if line == "\n": continue
        if state == "Expts": # read expts in the reference file
            ref_expt, _ = line.rsplit(":", 1)
            ref_expts.append(ref_expt)
        elif state == "Fails": # case fails in the reference file
            ref_case, ref_result = line.rsplit(":", 1)
            ref_case_fails_dict[ref_case] = ref_result.strip()

        if "Success/ScoreFail/SampleFail/SystemError" in line:
            state = "Expts"
        elif "Failures" in line:
            state = "Fails"

changed_fails = 0
changed_successes = 0
not_in_ref_count = 0
ref_untested_count = 0

# check cases where current test failed
for case in case_fails:
    if case not in ref_case_fails_dict.keys():
        sys, expt = case.split("_", 1)
        if expt in ref_expts:
            fail_mismatches[case] = "Success -> " + case_perf_dict[case]
            changed_fails += 1
        else:
            not_in_ref_count += 1

# check cases where reference notes failure
for case in ref_case_fails_dict.keys():
    if case not in case_perf_dict.keys():
        # fail_mismatches[case] = ref_case_fails_dict[case] + " -> Not tested"
        ref_untested_count += 1
    elif case in case_perf_dict.keys():
        if ref_case_fails_dict[case] != case_perf_dict[case]:
            fail_mismatches[case] = ref_case_fails_dict[case] + " -> " + case_perf_dict[case]
            if aworsethanb(ref_case_fails_dict[case], case_perf_dict[case]):
                changed_successes += 1
            else:
                changed_fails += 1


for expt in expt_perf_dict.keys():
    if expt not in ref_expts:
        non_ref_expts.append(expt)


output =  "#######################################################\n"
output += "#             DT100 Performance Summary               #\n"
output += "#######################################################\n\n"
nsys = str(len(sys_perf_dict.keys()))
nexpt = str(len(expt_perf_dict.keys()))
output += "Test performed on " + nsys + " systems with " + nexpt + " different seeds/conditions.\n"
diff = changed_successes - changed_fails
if diff > 0:
    output += "DOCK performed better than the reference with net " +str(diff)+" previous failures now successes.\n"
elif diff < 0:
    output += "DOCK performed worse than the reference with net " +str(abs(diff))+" previous successes now failures.\n"
else:
    output += "DOCK performed equally well compared to the reference with net " +str(diff)+" system results changed.\n"

output += "("+ str(changed_successes) + " systems improved, " + str(changed_fails) + " systems worsened)\n" 



# success/fail reporting
output += "\n#### Success/ScoreFail/SampleFail/SystemError ####\n"
for expt in expt_dict:
    output += expt + ": " + ", ".join(str(x).rjust(4) for x in expt_dict[expt]) + "\n"

# comparison to given reference
output += "\n#### Comparing Behavior to Reference (ref -> this trial) ####\n"

# warnings for experiments not in reference
if len(non_ref_expts) > 0:
    output += "WARNING: case(s) " + str(non_ref_expts) + " could not be compared to given reference!\n"
    output += "    This means " + str(not_in_ref_count) + " systems experiencing errors could not be compared.\n"
    output += "    The failures are still reported below in DOCK Failures.\n"
    output += "    (usually this means you are running a random seed not present in the reference file)\n"

if ref_untested_count > 0:
    output += "NOTE: there are " + str(ref_untested_count) + " fail cases in the reference that were not tested in the current run.\n"

if changed_fails == 0:
    output += "Perfect agreement with cases present in reference file " + ref_file + "\n"
else:
    for case in sorted(fail_mismatches.keys()):
        output += case + ": " + fail_mismatches[case] + "\n"


# test-specific failures
output += "\n#### DOCK Failures In This Trial ####\n"
for case in sorted(case_perf_dict.keys()):
    if case_perf_dict[case] != "Success":
        output += case + ": " + case_perf_dict[case] + "\n"

human_summary_file = out_prefix + "_Performance_Summary.txt"
with open(human_summary_file, 'w') as f:
    f.write(output)

print(output)


