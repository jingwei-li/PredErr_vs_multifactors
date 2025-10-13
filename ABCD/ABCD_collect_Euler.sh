#!/bin/sh
# 
# Collect the Euler number of each subject, for left and right hemisphere separately.
# The output will be two text files for both hemispheres.
#
# Author: Jingwei Li, 28/04/2023

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

data_dir=/data/project/parcellate_ABCD_preprocessed/data/ABCD_freesurfer
subj_ls=/data/project/predict_stereotype/results/ABCD/lists/sublist_allbehavior.csv
outdir=
outbase_suffix=

main() {
    c=1
    subjects=$(cat $subj_ls)
    lh_out="$outdir/lh_Euler.${outbase_suffix}.txt"
    rh_out="$outdir/rh_Euler.${outbase_suffix}.txt"
    touch $lh_out
    touch $rh_out
    for s in $subjects; do
        stats_in="$data_dir/$s/stats/aseg.stats"
        datalad get -d $data_dir/$s $stats_in

        lh_holes=$(grep 'lhSurfaceHoles' $data_dir/$s/stats/aseg.stats | cut -d , -f 4 | cut -d ' ' -f 2)
        rh_holes=$(grep 'rhSurfaceHoles' $data_dir/$s/stats/aseg.stats | cut -d , -f 4 | cut -d ' ' -f 2)

        lh_euler=$(echo "2 - 2 * $lh_holes" | bc)
        rh_euler=$(echo "2 - 2 * $rh_holes" | bc)

        echo "#$c $s: lh_holes = $lh_holes rh_holes = $rh_holes lh_euler=$lh_euler rh_euler=$rh_euler"

        echo $lh_euler >> $lh_out
        echo $rh_euler >> $rh_out
        c=$(echo "$c+1" | bc)

        datalad drop -d $data_dir/$s $stats_in
    done
}


#############################
# Function usage
#############################
usage() { echo "
NAME:
    ABCD_collect_Euler.sh

DESCRIPTION:
    Collect the Euler number of each subject, for left and right hemisphere separately.
    
ARGUMENTS:
    -data_dir       <data_dir>       : The recon-all output directory of all ABCD subjects (full path).
                                       Default: $data_dir
    -subj_ls        <subj_ls>        : Subject list, full path.
                                       Default: $subj_ls
    -outdir         <outdir>         : Output directory, full path.
    -outbase_suffix <outbase_suffix> : The output file names, for instance for the left hemisphere, 
                                       will be <outdir>/lh_Euler.<outbase_suffix>.txt

EXAMPLE:
    $DIR/ABCD_collect_Euler.sh \\
    -data_dir <path_to_ABCD_reconall_output> -subj_ls <path_to_list>/subjects_pass_rs_pass_pheno.txt \\
    -outdir <path_to_output_files> -outbase_suffix subjects_pass_rs_pass_pheno

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
        -data_dir)
            data_dir=$1; shift;;
        -subj_ls)
            subj_ls=$1; shift;;
        -outdir)
            outdir=$1; shift;;
        -outbase_suffix)
            outbase_suffix=$1; shift;;
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

###############################
# check parameters
###############################
if [ -z "$outdir" ]; then
	arg1err "-outdir"
fi
if [ -z "$outbase_suffix" ]; then
	arg1err "-outbase_suffix"
fi

main