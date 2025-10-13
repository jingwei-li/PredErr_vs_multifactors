# Author: Jianxiao
# Modified by Jingwei to be adapted to the new project

import numpy as np
import pandas as pd
import datalad.api as dl
from os.path import isdir, dirname, join
from os import system, listdir
import argparse

parser = argparse.ArgumentParser(description='Compute nuisance confounds for one HCP-D subject',
                                 formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument('out', help='Output list (full path).')
parser.add_argument('-d', help='Local path of HCP superdataset',
    default='/data/project/predict_stereotype/datasets/human-connectome-project-openaccess')
parser.add_argument('-s', help='Subject list.', default='')
args = parser.parse_args()

# Set-up
sublist = pd.read_csv(args.s, header=None, dtype=str)

allFD = np.empty(sublist.shape)
for i in range(0,4):
    allFD[i] = np.nan

for sub in range(0, len(sublist)):
    subject = sublist[0][sub]

    sub_dir = join(args.d, 'HCP1200', subject)
    dl.get(sub_dir, dataset=args.d, get_data=False, recursive=True, recursion_limit=1, on_failure='stop')
    data_dir = join(sub_dir, 'MNINonLinear')
    dl.get(data_dir, dataset=sub_dir, get_data=False, recursive=True, recursion_limit=1, on_failure='stop')
    system('git -C ' + data_dir + ' config --local --replace-all remote.datalad.annex-ignore false')

    # initialize FD array for current subject
    FD = np.empty([4, 1])
    for i in range(0,4):
        FD[i] = np.nan

    # Download subject-specific files    
    i = 0
    for run in ['REST1_LR', 'REST1_RL', 'REST2_LR', 'REST2_RL']:
        run = 'rfMRI_' + run
        run_dir = join(data_dir, 'Results', run)
        if not isdir(run_dir):
            i = i + 1
            continue

        # Download run-specific files
        meanFD_file = join(run_dir, 'Movement_RelativeRMS_mean.txt')
        dl.get(meanFD_file, dataset=data_dir, on_failure='stop')

        # Get FD
        FD[i] = pd.read_table(meanFD_file, sep='  ', header=None, engine='python').values

        # write to all subjects' FD lists
        allFD[sub] = np.nanmean(FD)
        print('Computed mean FD for sub %d: %s run: %s' % (sub, subject, run))

        i = i + 1

        # Drop run-specific files
        dl.drop(meanFD_file, dataset=data_dir)

np.savetxt(args.out, allFD, fmt='%f')
