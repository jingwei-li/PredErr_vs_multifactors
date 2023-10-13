# Author: Jianxiao
# Modified by Jingwei to be adapted to the new project

import numpy as np
import pandas as pd
import datalad.api as dl
from os.path import isdir, dirname, join
from os import system, listdir
import argparse

parser = argparse.ArgumentParser(description='Compute nuisance confounds for one HCP-Aging subject',
                                 formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument('out', help='Output list (full path).')
parser.add_argument('-d', help='Local path of HCP-Development folder under inm-7 superdataset.',
    default='/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development')
parser.add_argument('-s', help='Subject list.', default='')
args = parser.parse_args()

# Set-up
code_dir = dirname(dirname(__file__))
if not args.s:
    sublist = pd.DataFrame([filename for filename in listdir(args.d) if filename.startswith('HCD')])
else:
    sublist = pd.read_csv(args.s, header=None)
    sublist[0] = sublist[0].astype(str) + '_V1_MR'

allFD = np.empty(sublist.shape)
for i in range(0,4):
    allFD[i] = np.nan

for sub in range(0, len(sublist)):
    subject = sublist[0][sub]

    sub_dir = join(args.d, subject)
    dl.get(sub_dir, dataset=args.d, get_data=False, recursive=True, recursion_limit=1, on_failure='stop')
    data_dir = join(sub_dir, 'MNINonLinear')
    dl.get(data_dir, dataset=sub_dir, get_data=False, recursive=True, recursion_limit=1, on_failure='stop')
    system('git -C ' + data_dir + ' config --local --add remote.datalad.annex-ignore true')

    # initialize FD array for current subject
    FD = np.empty([4, 1])
    for i in range(0,4):
        FD[i] = np.nan

    # Download subject-specific files    
    i = 0
    for run in ['REST1_AP', 'REST1_PA', 'REST2_AP', 'REST2_PA']:
        run = 'rfMRI_' + run
        run_dir = join(data_dir, 'Results', run)
        if not isdir(run_dir):
            i = i + 1
            continue

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

if not args.s:
    sublist[0] = sublist[0].str.replace('_V1_MR', '')
    outdir = dirname(args.out)
    sublist.to_csv(join(outdir, 'all_subjects.csv'), index=None, header=None)