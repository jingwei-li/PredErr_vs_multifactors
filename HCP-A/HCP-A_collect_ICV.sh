#!/bin/sh
# 
# Collect the intracranial volume of each subject.
# The output will be a text file.
#
# Author: Jingwei Li, 30/06/2023

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

data_dir=/home/jli/datasets/inm7-superds/original/hcp/hcp_aging
subj_ls=/home/jli/my_projects/fairAI/from_sg/new_results/HCP-A/lists/sublist_allbehavior.csv
outdir=
outbase_suffix=

main() {
    c=1
    subjects=$(cat $subj_ls)
    out="$outdir/ICV.${outbase_suffix}.txt"
    touch $out
    for s in $subjects; do
        cd $data_dir/${s}_V1_MR/T1w/${s}_V1_MR/stats
        datalad get -s inm7-storage aseg.stats

        ICV=$(grep 'EstimatedTotalIntraCranialVol' aseg.stats | cut -d , -f 4 | cut -d ' ' -f 2)

        echo "#$c $s: ICV = $ICV "

        echo $ICV >> $out
        c=$(awk -v x="$c" 'BEGIN { printf "%s", 1+x }' </dev/null)

        datalad drop aseg.stats
    done
}


#############################
# Function usage
#############################
usage() { echo "
NAME:
    HCP-A_collect_Euler.sh

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
    $DIR/HCP-A_collect_Euler.sh \\
    -data_dir <path_to_HCP-A> -subj_ls <path_to_list>/HCP-A_openness_allRun_sub.csv \\
    -outdir <path_to_output_files> -outbase_suffix openness_allRun_sub

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