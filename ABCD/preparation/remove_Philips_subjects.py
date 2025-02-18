import os, argparse
import pandas as pd
import datalad.api as dl

# input arguments
parser = argparse.ArgumentParser(description='Remove ABCD subjects whose data were collected using Philips scanner.')
parser.add_argument('--in_ls', help='Input subject list (text file). Format: sub-NDARINV*')
parser.add_argument('--out_ls', help='Output subject list (text file). Format: sub-NDARINV*')
parser.add_argument('--data_dir', help='The local directory of INM-7 ABCD datalad repository (top-level folder).',
    default='/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd')
args = parser.parse_args()

# read subject list
with open(args.in_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]

subjects_csv = ['NDAR_' + line[8:] for line in subjects ]

# read scanner csv
pheno_dir = os.path.join(args.data_dir, 'phenotype')
scanner_csv = os.path.join(pheno_dir, 'phenotype', 'abcd_mri01.txt')
dl.get(path=pheno_dir, dataset=args.data_dir, get_data=False)
dl.get(path=scanner_csv, dataset=pheno_dir)
df = pd.read_csv(scanner_csv, delimiter='\t', low_memory=False)
dl.drop(scanner_csv, dataset=pheno_dir, reckless='kill')
df = df[df.subjectkey.isin(subjects_csv) & df.eventname.isin(['baseline_year_1_arm_1'])]
df = df[['subjectkey', 'mri_info_manufacturer']]

# collect scanner information, filter subjects
out_subj = []
for i in subjects_csv:
    scanner = df[df.subjectkey == i].mri_info_manufacturer.to_string()
    if (scanner.find('Philips') == -1):
        out_subj.append(i)
    

out_subj = ['sub-' + s[:4] + s[5:] for s in out_subj]

# save out
outdir = os.path.dirname(args.out_ls)
if not os.path.exists(outdir):
    os.mkdir(outdir)
with open(args.out_ls, 'w') as f:
    for item in out_subj:
        f.write('%s\n' % item)