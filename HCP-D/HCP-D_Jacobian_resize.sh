#!/bin/bash

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

indir=/data/project/predict_stereotype/Jacobian/HCP-D/HCP-D_cat12.8.1
outdir=/data/project/predict_stereotype/new_results/HCP-D/Jacobian_resize
mask=/data/project/predict_stereotype/Jacobian/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz
subj_ls=/data/project/predict_stereotype/new_results/HCP-D/lists/sublist_allbehavior_455sub.csv

main() {
    subjects=$(cat $subj_ls)

    for s in $subjects; do
        echo $s

        cd $indir/sub-${s}/mri
        datalad get wj_sub-${s}_T1w.nii.gz
        mri_vol2vol --mov $indir/sub-${s}/mri/wj_sub-${s}_T1w.nii.gz \
            --o $outdir/wj_sub-${s}_T1w_resize.nii.gz \
            --targ $mask --regheader
        datalad drop wj_sub-${s}_T1w.nii.gz
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
    $DIR/HCP-D_Jacobian_resize.sh \\
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
