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
parser.add_argument('sub', type=int, help="Index of subject in HCP-A_AllComp.csv")
parser.add_argument('out', help='Output directory.')
parser.add_argument('-d', help='Local path of HCP-Aging folder under inm-7 superdataset.',
    default='/home/jli/datasets/inm7-superds/original/hcp/hcp_aging')
args = parser.parse_args()

# Set-up
csf_code = np.array([4, 5, 14, 15, 24, 31, 43, 44, 63, 250, 251, 252, 253, 254, 255]) - 1

code_dir = dirname(__file__)
subls_path = join(code_dir, 'cbpp', 'bin', 'sublist', 'HCP-A_openness_allRun_sub.csv')
sublist = pd.read_csv(subls_path, header=None)
subject = sublist[0][args.sub-1]

sub_dir = join(args.d, subject + '_V1_MR')
dl.get(sub_dir, dataset=args.d, get_data=False, recursive=True, recursion_limit=1, on_failure='stop')
data_dir = join(sub_dir, 'MNINonLinear')
dl.get(data_dir, dataset=sub_dir, get_data=False, recursive=True, recursion_limit=1, on_failure='stop')
t1_dir = join(sub_dir, 'T1w')
dl.get(t1_dir, dataset=sub_dir, get_data=False, recursive=True, recursion_limit=1, on_failure='stop')

# Download subject-specific files
atlas_file = join(data_dir, 'ROIs', 'Atlas_wmparc.2.nii.gz')
dl.get(atlas_file, dataset=data_dir, source='inm7-storage', on_failure='stop')

for run in ['REST1_AP', 'REST1_PA', 'REST2_AP', 'REST2_PA']:
    run = 'rfMRI_' + run
    run_dir = join(data_dir, 'Results', run)

    # Download run-specific files
    motion_file = join(run_dir, 'Movement_Regressors_hp0_clean.txt')
    dl.get(motion_file, dataset=data_dir, source='inm7-storage', on_failure='stop')
    rs_file = join(run_dir, run + '_hp0_clean.nii.gz')
    dl.get(rs_file, dataset=data_dir, source='inm7-storage', on_failure='stop')

    # Load image files
    data = nib.load(rs_file).get_fdata()
    data = data.reshape((data.shape[0]*data.shape[1]*data.shape[2], data.shape[3]))
    atlas = nib.load(atlas_file).get_fdata()
    atlas_dims = atlas.shape
    atlas = atlas.reshape((data.shape[0]))

    # compute WM & CSF confounds
    wm_ind = np.where(atlas >= 3000)[0]
    wm_mask = np.zeros(atlas.shape)
    wm_mask[wm_ind] = 1
    wm_mask = binary_erosion(wm_mask).reshape((atlas.shape))
    wm_signal = data[np.where(wm_mask == 1)[0], :].mean(axis=0)
    wm_diff = np.diff(wm_signal, prepend=wm_signal[0])
    csf_signal = data[[i for i in range(len(atlas)) if atlas[i] in csf_code]].mean(axis=0)
    csf_diff = np.diff(csf_signal, prepend=csf_signal[0])

    # Get motion parameters
    motion = pd.read_table(motion_file, sep='  ', header=None, engine='python')
    motion = motion.join(np.power(motion, 2), lsuffix='motion', rsuffix='motion2')

    # Save all confounds together
    conf = motion.assign(wm=wm_signal).assign(wmdiff=wm_diff).assign(csf=csf_signal).assign(csfdiff=csf_diff)
    out_file = join(args.out, subject + '_' + run + '_resid0.csv')
    conf.to_csv(out_file, header=False, index=False)
    print('Computed confounds for sub %d: %s run: %s' % (args.sub, subject, run))

    # Drop run-specific files
    dl.drop(motion_file, dataset=data_dir)
    dl.drop(rs_file, dataset=data_dir)

# Drop common atlas file
dl.drop(atlas_file, dataset=data_dir)