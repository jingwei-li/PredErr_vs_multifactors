import numpy as np
import pandas as pd
from os.path import isfile, dirname, join
from os import system
import argparse

proj_dir = '/home/jli/my_projects/fairAI/from_sg'
code_dir = dirname(dirname(__file__))
parser = argparse.ArgumentParser(description='Average DVARS timeseries for each run, each subject. Summarize',
                                 formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument('-d', help='The folder that contains one DVARS timeseries text file per run per subject.',
    default=join(proj_dir, 'new_results', 'HCP-A', 'lists', 'dvars'))
parser.add_argument('-s', help='The subject list.', 
    default=join(proj_dir, 'new_results', 'HCP-A', 'lists', 'sublist_allbehavior.csv'))
parser.add_argument('-o', help='The output file.',
    default=join(proj_dir, 'new_results', 'HCP-A', 'lists', 'DV.sub_allbehavior.txt'))
args = parser.parse_args()

with open(args.s, 'r') as f:
    subjects = f.readlines()
    subjects = [line.rstrip() for line in subjects]

DV =[]
for s in subjects:
    DVsub = 0
    n = np.zeros(1)
    for run in ['REST1_AP', 'REST1_PA', 'REST2_AP', 'REST2_PA']:
        DVpath = join(args.d, s + '_rfMRI_' + run)
        if isfile(DVpath):
            n = n+1
            DVsub = DVsub + np.mean(pd.read_table(DVpath, sep='  ', header=None, engine='python').values)
    print(DVsub)
    print(n)
    DV.append(np.divide(DVsub, n))

np.savetxt(args.o, DV, fmt='%f')