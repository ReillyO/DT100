import sys, os
from collections import defaultdict

# Script to extract individual molecules from a multi-Mol2 file
# Infile should be a text file with one number per line describing
# all Mol2 indices to be saved starting from ZERO

try:
    infile = sys.argv[1]
    mol2file = sys.argv[2]
    outfile = sys.argv[3]
except:
    print("provide infile mol2file outfile")

to_save_idxs = []
with open(infile, 'r') as f:
    for line in f.readlines():
        to_save_idxs.append(int(line.strip()))


mol = []  # array of strings (each string is a line)
delim = "##########"
prevline = delim  # makes it a little cleaner 
keep = True
curr_idx = 0

if curr_idx in to_save_idxs: keep = True
else: keep = False

with open(mol2file, 'r') as f:
    for line in f.readlines():
        if delim in line and delim not in prevline:
            with open(outfile, 'a') as f:
                f.write("".join(mol))
            mol = []
            curr_idx += 1
            if curr_idx in to_save_idxs: keep = True
            else: keep = False 
        if keep: mol.append(line)
        prevline = line

with open(outfile, 'a') as f:
    f.write("".join(mol))
        
