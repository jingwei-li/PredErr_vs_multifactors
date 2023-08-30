#!/bin/sh
# 
# Collect the Euler number of each subject, for left and right hemisphere separately.
# The output will be two text files for both hemispheres.
#
# Author: Jingwei Li, 30/06/2023

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

data_dir=/home/jli/datasets/inm7_superds/original/hcp/hcp_development
subj_ls=/home/jli/my_projects/fairAI/from_sg/new_results/HCP-D/lists/sublist_allbehavior.csv
outdir=
outbase_suffix=

main() {
    c=1
    lh_out="$outdir/lh_Euler.${outbase_suffix}.txt"
    rh_out="$outdir/rh_Euler.${outbase_suffix}.txt"
    touch $lh_out
    touch $rh_out
    while IFS= read -r s; do
        cd $data_dir
        datalad get -n ${s}_V1_MR
        git -C ${s}_V1_MR config --local --add remote.datalad.annex-ignore true
        cd $data_dir/${s}_V1_MR/T1w
        datalad get -n .
        git -C . config --local --add remote.datalad.annex-ignore true
        cd ./${s}_V1_MR/stats
        datalad get -s inm7-storage aseg.stats

        lh_holes=$(grep 'lhSurfaceHoles' aseg.stats | cut -d , -f 4 | cut -d ' ' -f 2)
        rh_holes=$(grep 'rhSurfaceHoles' aseg.stats | cut -d , -f 4 | cut -d ' ' -f 2)

        lh_euler=$(awk -v x="$lh_holes" 'BEGIN { printf "%s", 2-2*x }' </dev/null)
        rh_euler=$(awk -v x="$rh_holes" 'BEGIN { printf "%s", 2-2*x }' </dev/null)

        echo "#$c $s: lh_holes = $lh_holes rh_holes = $rh_holes lh_euler=$lh_euler rh_euler=$rh_euler"

        echo $lh_euler >> $lh_out
        echo $rh_euler >> $rh_out
        c=$(awk -v x="$c" 'BEGIN { printf "%s", 1+x }' </dev/null)

        datalad drop aseg.stats
    done < $subj_ls
}


#############################
# Function usage
#############################
usage() { echo "
NAME:
    HCP-D_collect_Euler.sh

DESCRIPTION:
    Collect the Euler number of each subject, for left and right hemisphere separately.
    
ARGUMENTS:
    -data_dir       <data_dir>       : The local path of inm-7 superdataset's subfolder that contains HCP-A subjects (full path).
                                       Default: $data_dir
    -subj_ls        <subj_ls>        : Subject list, full path. Default:
                                       $subj_ls
    -outdir         <outdir>         : Output directory, full path.
    -outbase_suffix <outbase_suffix> : The output file names, for instance for the left hemisphere, 
                                       will be <outdir>/lh_Euler.<outbase_suffix>.txt

EXAMPLE:
    $DIR/HCP-D_collect_Euler.sh \\
    -data_dir <path_to_HCP-D> -subj_ls <path_to_list>/sublist_allbehavior.csv \\
    -outdir <path_to_output_files> -outbase_suffix sub_allbehavior

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