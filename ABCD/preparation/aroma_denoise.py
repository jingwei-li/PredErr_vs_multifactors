from pathlib import Path
import argparse

import nipype.pipeline as pe
from nipype.interfaces import utility as niu
from nipype.interfaces import fsl
from niworkflows.interfaces.bold import NonsteadyStatesDetector

#base_dir = base_dir = Path(__file__).resolve().parent
#data_dir = Path('/data', 'project', 'parcellate_ABCD_preprocessed', 'data', 'temp', 'MNI152NLin6Asym_AROMA_fsaverage',
#                'fmriprep', 'sub-NDARINV4NVN1B5J', 'ses-baselineYear1Arm1', 'func')
#prefix = 'sub-NDARINV4NVN1B5J_ses-baselineYear1Arm1_task-rest_run-1'

def main():
    parser = argparse.ArgumentParser(description='Apply AROMA denoising.')
    parser.add_argument('--data_dir', type=Path, help='Absoute path to subject data directory')
    parser.add_argument('--prefix', type=str, help='Subject data files prefix')
    parser.add_argument('--work_dir', type=Path, help='Absolute path to working directory')
    args = parser.parse_args()

    wf = pe.Workflow('aroma_denoise', base_dir=args.work_dir)
    in_fields = ['input', 'mask', 'melodic', 'filter', 'cut_out', 'smooth_out', 'aroma_out', 'output']
    inputnode = pe.Node(niu.IdentityInterface(fields=in_fields), name='inputnode')
    inputnode.inputs.input = Path(
        args.data_dir, f'{args.prefix}_space-MNI152NLin6Asym_res-2_desc-preproc_bold.nii.gz')
    inputnode.inputs.mask = Path(
        args.data_dir, f'{args.prefix}_space-MNI152NLin6Asym_res-2_desc-brain_mask.nii.gz')
    inputnode.inputs.melodic = Path(args.data_dir, f'{args.prefix}_desc-MELODIC_mixing.tsv')
    inputnode.inputs.melodic_cut = Path(args.work_dir, f'{args.prefix}_desc-MELODIC_mixing_cut.tsv')
    inputnode.inputs.filter = Path(args.data_dir, f'{args.prefix}_AROMAnoiseICs.csv')
    inputnode.inputs.cut_out = Path(args.work_dir, f'{args.prefix}_bold_cut.nii.gz')
    inputnode.inputs.smooth_out = Path(args.work_dir, f'{args.prefix}_bold_smooth.nii.gz')
    inputnode.inputs.aroma_out = Path(args.work_dir, f'{args.prefix}_smoothAROMAnonaggr_bold.nii.gz')
    inputnode.inputs.output = Path(args.work_dir, f'{args.prefix}_smoothAROMAnonaggr_bold_final.nii.gz')

    # remove non-steady state
    get_dummy = pe.Node(NonsteadyStatesDetector(), name='get_dummy')
    rm_nonsteady = pe.Node(
        niu.Function(function=_remove_volumes, output_names=['bold_cut', 'melodic_cut']),
        name='rm_nonsteady')

    # smooth
    calc_median_val = pe.Node(fsl.ImageStats(op_string="-k %s -p 50"), name='calc_median_val')
    calc_bold_mean = pe.Node(fsl.MeanImage(), name='calc_bold_mean')
    getusans = pe.Node(
        niu.Function(function=_getusans_func, output_names=['usans']), name='getusans', mem_gb=0.01)
    smooth = pe.Node(fsl.SUSAN(fwhm=6.0, output_type='NIFTI_GZ'), name='smooth')

    # aroma denoising
    aroma_denoise = pe.Node(
        niu.Function(function=_aroma_denoise, output_names=['denoise_out']), name='aroma_denoise')

    # add_nonsteady
    add_nonsteady = pe.Node(
        niu.Function(function=_add_volumes, output_names=['bold_add']), name='add_nonsteady')

    wf.connect([
        (inputnode, get_dummy, [('input', 'in_file')]),
        (inputnode, rm_nonsteady, [('input', 'bold_file'), ('melodic', 'melodic'),
                                    ('cut_out', 'output'), ('melodic_cut', 'melodic_cut')]),
        (get_dummy, rm_nonsteady, [('n_dummy', 'skip_vols')]),
        (inputnode, calc_median_val, [('mask', 'mask_file')]),
        (rm_nonsteady, calc_median_val, [('bold_cut', 'in_file')]),
        (rm_nonsteady, calc_bold_mean, [('bold_cut', 'in_file')]),
        (calc_median_val, getusans, [('out_stat', 'thresh')]),
        (calc_bold_mean, getusans, [('out_file', 'image')]),
        (inputnode, smooth, [('smooth_out', 'out_file')]),
        (rm_nonsteady, smooth, [('bold_cut', 'in_file')]),
        (getusans, smooth, [('usans', 'usans')]),
        (calc_median_val, smooth, [(('out_stat', _getbtthresh), 'brightness_threshold')]),
        (inputnode, aroma_denoise, [('filter', 'filter_file'), ('aroma_out', 'output')]),
        (rm_nonsteady, aroma_denoise, [('melodic_cut', 'melodic')]),
        (smooth, aroma_denoise, [('smoothed_file', 'in_file')]),
        (inputnode, add_nonsteady, [('input', 'bold_file'),
                                            ('output', 'output')]),
        (get_dummy, add_nonsteady, [('n_dummy', 'skip_vols')]),
        (aroma_denoise, add_nonsteady, [('denoise_out', 'bold_cut_file')])])
    
    wf.run()

def _remove_volumes(bold_file, melodic, skip_vols, output, melodic_cut):
    """Remove skip_vols from bold_file."""
    import nibabel as nb
    import pandas as pd

    if skip_vols == 0:
        return bold_file, melodic

    bold_img = nb.load(bold_file)
    bold_img.__class__(
        bold_img.dataobj[..., skip_vols:], bold_img.affine, bold_img.header
    ).to_filename(output)

    melodic_mix = pd.read_table(melodic, header=None, delim_whitespace=True)
    melodic_mix = melodic_mix[skip_vols:]
    melodic_mix.to_csv(melodic_cut, sep='\t', header=False, index=False)

    return output, melodic_cut

def _getusans_func(image, thresh):
    return [tuple([image, thresh])]

def _getbtthresh(medianval):
    return 0.75 * medianval

def _aroma_denoise(in_file, melodic, filter_file, output):
    import pandas as pd
    import subprocess

    # 4,5,6,7,10,11,12,13,14,18,19,20,21,23,24,25,26,28,30,32,34,35,39,40,41,49,51,58,59,60,61,64,65,66,69,71,73,74,75
    filters = pd.read_csv(filter_file, sep='\t', header=None, dtype=str).values[0][0]
    command = ['fsl_regfilt', '-i', str(in_file), '-d', str(melodic), '-f', str(filters), '-o', str(output)]
    print(command)
    subprocess.run(command)
    return output

def _add_volumes(bold_file, bold_cut_file, skip_vols, output):
    """Prepend skip_vols from bold_file onto bold_cut_file."""
    import nibabel as nb
    import numpy as np

    if skip_vols == 0:
        return bold_cut_file

    bold_img = nb.load(bold_file)
    bold_cut_img = nb.load(bold_cut_file)

    bold_data = np.concatenate((bold_img.dataobj[..., :skip_vols], bold_cut_img.dataobj), axis=3)
    bold_img.__class__(bold_data, bold_img.affine, bold_img.header).to_filename(output)
    return output

if __name__ == '__main__':
    main()