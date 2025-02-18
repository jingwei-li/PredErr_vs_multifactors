import os, argparse
import datalad.api as dl

parser = argparse.ArgumentParser(description='Find the resting-state runs for each ABCD subject.')
parser.add_argument('--in_ls', help='Input subject list (text file). Format: sub-NDARINV*')
parser.add_argument('--out_txt', help='Output text file containing run numbers for each subject. Format of each row: sub-NDARINV* 01 02 03 04')
parser.add_argument('--data_dir', help='The local directory of ABCD derivatives repository.',
    default='/data/project/parcellate_ABCD_preprocessed/data/ABCD_fMRIprep')
args = parser.parse_args()

ses = 'ses-baselineYear1Arm1'
with open(args.in_ls) as file:
    subjects = file.readlines()
    subjects = [line.rstrip() for line in subjects]

out_arr = []
for s in subjects:
    out_curr = s
    sub_dir = os.path.join(args.data_dir, 'fmriprep', s)
    if os.path.exists(sub_dir):
        dl.get(path=sub_dir, dataset=args.data_dir, get_data=False)
        i = 1
        while i<=10:
            run_curr = str(i).zfill(2)
            prefix = s + '_' + ses + '_task-rest_run-' + run_curr
            fslr_run = os.path.join(
                sub_dir, ses, 'func', prefix + '_space-fsLR_den-91k_bold.dtseries.nii')
            mri_run = os.path.join(
                sub_dir, ses, 'func', prefix
                + '_space-MNI152NLin6Asym_desc-smoothAROMAnonaggr_bold.nii.gz')
            if os.path.islink(fslr_run) and os.path.islink(mri_run):
                out_curr = out_curr + ' ' + run_curr
            i += 1
        out_arr.append(out_curr)
        print(out_curr)

outdir = os.path.dirname(args.out_txt)
if not os.path.exists(outdir):
    os.mkdir(outdir)
with open(args.out_txt, 'w') as f:
    for item in out_arr:
        f.write('%s\n' % item)