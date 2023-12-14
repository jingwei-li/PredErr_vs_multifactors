#!/bin/bash

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

proj_dir=/data/project/predict_stereotype
indir=$proj_dir/Jacobian/ABCD/extracted/mri
outdir=$proj_dir/new_results/ABCD/Jacobian_resize
mask=$proj_dir/Jacobian/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz
subj_ls=$proj_dir/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt
#subj_ls=/data/project/predict_stereotype/new_results/ABCD/Jacobian_resize/subjects_no_Jacobian_1.txt

main() {
    subjects=$(cat $subj_ls)

    touch $outdir/subjects_no_Jacobian.txt
    for s in $subjects; do
        echo $s
        if [ -f $indir/wj_sub-${s}_ses-baselineYear1Arm1_T1w.nii.gz ]; then
            mri_vol2vol --mov $indir/wj_sub-${s}_ses-baselineYear1Arm1_T1w.nii.gz \
                --o $outdir/wj_sub-${s}_T1w_resize.nii.gz --targ $mask --regheader
        elif [ -f $indir/wj_sub-${s}_ses-baselineYear1Arm1_rec-normalized_T1w.nii.gz ]; then
            mri_vol2vol --mov $indir/wj_sub-${s}_ses-baselineYear1Arm1_rec-normalized_T1w.nii.gz \
                --o $outdir/wj_sub-${s}_T1w_resize.nii.gz --targ $mask --regheader
        elif [ -f $indir/wj_sub-${s}_ses-baselineYear1Arm1_run-01_T1w.nii.gz ]; then
            mri_vol2vol --mov $indir/wj_sub-${s}_ses-baselineYear1Arm1_run-01_T1w.nii.gz \
                --o $outdir/wj_sub-${s}_T1w_resize.nii.gz --targ $mask --regheader
        elif [ -f $indir/wj_sub-${s}_ses-baselineYear1Arm1_rec-normalized_run-01_T1w.nii.gz ]; then
            mri_vol2vol --mov $indir/wj_sub-${s}_ses-baselineYear1Arm1_rec-normalized_run-01_T1w.nii.gz \
                --o $outdir/wj_sub-${s}_T1w_resize.nii.gz --targ $mask --regheader
        else
            echo $s >> $outdir/subjects_no_Jacobian.txt
        fi
    done
}

#############################
# Function usage
#############################
usage() { echo "
NAME:
    HCP-D_Jacobian_resize.sh

DESCRIPTION:
    Collect the intracranial volume of each subject.
    
ARGUMENTS:
    -indir     <indir>      : The directory of the DataLad dataset of the HCP-D CAT12 output.
                              Default: $indir
    -subj_ls   <subj_ls>    : Subject list, full path. Default:
                              $subj_ls
    -outdir    <outdir>     : Output directory to store the resized Jacobian volume of each subject.
                              Default: $outdir
    -mask      <mask>       : Full path to the MNI152 2009c asymetric brain template mask.
                              This is the target each Jacobian volume should be resized to.

EXAMPLE:
    $DIR/ABCD_Jacobian_resize.sh \\
    -indir <path_to_CAT12_output> -subj_ls <path_to_list>/all_subjects.csv \\
    -outdir <path_to_output_files> -mask <path_to_target>

" 1>&2; exit 1; }

##########################################
# Parse Arguments 
##########################################
# Display help message if no argument is supplied
if [ $# -eq 0 ]; then
	usage; 1>&2; exit 1
fi

while [ $# -gt 0 ]; do
	flag=$1; shift;
	
	case $flag in
        -indir)
            data_dir=$1; shift;;
        -subj_ls)
            subj_ls=$1; shift;;
        -outdir)
            outdir=$1; shift;;
        -mask)
            outbase_suffix=$1; shift;;
        -h)
            usage; 1>&2; exit 0;;
        *)
            echo "Unknown flag $flag"
            usage; 1>&2; exit 1;;
    esac
done

##########################################
# ERROR message
##########################################	
arg1err() {
	echo "ERROR: flag $1 requires one argument"
	exit 1
}


main
