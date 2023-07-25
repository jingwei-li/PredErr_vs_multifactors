# Author: Jianxiao
# Modified by Jingwei to be adapted to the new project

import numpy as np
import pandas as pd
import nibabel as nib
from scipy.ndimage import binary_erosion
import datalad.api as dl
from os.path import isfile, dirname, join
from os import environ, system
import argparse

parser = argparse.ArgumentParser(description='Compute nuisance confounds for one HCP-Aging subject',
                                 formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument('out', help='Output list (full path).')
parser.add_argument('-d', help='Local path of HCP-Aging folder under inm-7 superdataset.',
    default='/home/jli/datasets/inm7-superds/original/hcp/hcp_aging')
parser.add_argument('-s', help='Path to the subject list.',
    default='/home/jli/my_projects/fairAI/from_sg/new_results/HCP-A/lists/sublist_allbehavior.csv')
args = parser.parse_args()

# Set-up
code_dir = dirname(dirname(__file__))
sublist = pd.read_csv(args.s, header=None)
allFD = np.empty(sublist.shape)
for i in range(0,4):
    allFD[i] = np.nan

for sub in range(0, len(sublist)):
    subject = sublist[0][sub]

    sub_dir = join(args.d, subject + '_V1_MR')
    dl.get(sub_dir, dataset=args.d, get_data=False, recursive=True, recursion_limit=1, on_failure='stop')
    data_dir = join(sub_dir, 'MNINonLinear')
    dl.get(data_dir, dataset=sub_dir, get_data=False, recursive=True, recursion_limit=1, on_failure='stop')

    # initialize FD array for current subject
    FD = np.empty([4, 1])
    for i in range(0,4):
        FD[i] = np.nan

    # Download subject-specific files    
    i = 0
    for run in ['REST1_AP', 'REST1_PA', 'REST2_AP', 'REST2_PA']:
        run = 'rfMRI_' + run
        run_dir = join(data_dir, 'Results', run)

        # Download run-specific files
        meanFD_file = join(run_dir, 'Movement_RelativeRMS_mean.txt')
        dl.get(meanFD_file, dataset=data_dir, source='inm7-storage', on_failure='stop')

        # Get FD
        FD[i] = pd.read_table(meanFD_file, sep='  ', header=None, engine='python').values

        # write to all subjects' FD and DVARS lists
        allFD[sub] = np.nanmean(FD)
        print('Computed mean FD and DVARS for sub %d: %s run: %s' % (sub, subject, run))

        i = i + 1

        # Drop run-specific files
        dl.drop(meanFD_file, dataset=data_dir)

np.savetxt(args.out, allFD, fmt='%f')