import os, argparse
import pandas as pd
import numpy as np

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument('--subj_ls', help='HCP subject list.', default='/home/jli/my_projects/fairAI/from_sg/HCP_race/scripts/lists/subjects_wIncome_948.txt')
parser.add_argument('--csv', help='FreeSurfer CSV.', default='/home/jli/datasets/HCP_YA_csv/FreeSurfer_jingweili_6_20_2023_1200subjects.csv')
parser.add_argument('--outdir', help='Output directory.', default='/home/jli/my_projects/fairAI/from_sg/new_results/HCP/lists')
args = parser.parse_args()

# make output directory
if not os.path.exists(args.outdir):
    os.mkdir(args.outdir)

# read subject list
with open(args.subj_ls) as file:
    subjects = file.readlines()
    subjects = [int(line.rstrip()) for line in subjects]

# read csv file, grab subset of the dataframe that is necessary
df = pd.read_csv(args.csv, delimiter=',', low_memory=False)
df = df[df.Subject.isin(subjects)]
df = df[['Subject', 'FS_LH_Defect_Holes', 'FS_RH_Defect_Holes']]

lh_euler = np.array(2 - 2 * df.FS_LH_Defect_Holes)
rh_euler = np.array(2 - 2 * df.FS_RH_Defect_Holes)

outbase = os.path.basename(args.subj_ls)
lh_out = os.path.join(args.outdir, 'lh_Euler.' + outbase)
rh_out = os.path.join(args.outdir, 'rh_Euler.' + outbase)
with open(lh_out, 'w') as f:
    for item in lh_euler:
        f.write("%d\n" % item)
with open(rh_out, 'w') as f:
    for item in rh_euler:
        f.write("%d\n" % item)