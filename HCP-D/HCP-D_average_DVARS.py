import numpy as np
import pandas as pd
from os.path import isfile, join
import argparse

proj_dir = '/data/project/predict_stereotype'

parser = argparse.ArgumentParser(description='Average DVARS timeseries for each run, each subject. Summarize',
                                 formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument('-d', help='The folder that contains one DVARS timeseries text file per run per subject.',
    default=join(proj_dir, 'results', 'HCP-D', 'lists', 'dvars'))
parser.add_argument('-s', help='The subject list.', 
    default=join(proj_dir, 'results', 'HCP-D', 'lists', 'all_subjects.csv'))
parser.add_argument('-o', help='The output file.',
    default=join(proj_dir, 'results', 'HCP-D', 'lists', 'DV.allsub.txt'))
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
        else:
            Warning(DVpath + ' does not exist.')
    print(DVsub)
    print(n)
    DV.append(np.divide(DVsub, n))

np.savetxt(args.o, DV, fmt='%f')