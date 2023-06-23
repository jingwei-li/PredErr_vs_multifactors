#!/bin/sh
# 
# Collect the bbregister cost for each subject.
# The output will be a text file.
#
# Author: Jingwei Li, 04/05/2023

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

data_dir=/mnt/isilon/CSC2/Yeolab/Data/ABCD/process/y0/rs_GSR
subj_ls=/mnt/nas/CSC7/Yeolab/PreviousLabMembers/jingweil/MyProject/fairAI/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt
outdir=
outbase_suffix=

main() {
    c=1
    subjects=$(cat $subj_ls)
    out="$outdir/bbr_cost.${outbase_suffix}.txt"
    if [[ -f $out ]]; then rm $out; fi
    touch $out
    for s in $subjects; do
        runs=$(cat $data_dir/$s/logs/${s}_pass_qc.bold)
        nruns=$(echo $runs | wc -w)
        avg_cost=0
        for r in $runs; do
            curr_cost=$(cat $data_dir/$s/bold/$r/${s}_bld${r}_rest_mc_skip_reg.dat.mincost | cut -d ' ' -f 1)
            avg_cost=$(echo "$avg_cost + $curr_cost" | bc -l)
        done
        avg_cost=$(echo "$avg_cost / $nruns" | bc -l)
        echo "#$c $s: bbr_cost = $avg_cost"

        echo $avg_cost >> $out
        c=$(echo "$c+1" | bc)
    done
}

#############################
# Function usage
#############################
usage() { echo "
NAME:
    ABCD_collect_bbr_cost.sh

DESCRIPTION:
    Collect the bbregister cost for each subject.

ARGUMENTS:
    -data_dir       <data_dir>       : The preprocessed fMRI directory of all ABCD subjects (full path).
    -subj_ls        <subj_ls>        : Subject list, full path.
    -outdir         <outdir>         : Output directory, full path.
    -outbase_suffix <outbase_suffix> : The output file names will be <outdir>/bbr_cost.<outbase_suffix>.txt

EXAMPLE:
    $DIR/ABCD_collect_bbr_cost.sh \\
    -data_dir <path_to_ABCD_preprocessed_fMRI> -subj_ls <path_to_list>/subjects_pass_rs_pass_pheno.txt \\
    -outdir <path_to_output_files> -outbase_suffix subjects_pass_rs_pass_pheno

" 1>&2; exit 1; }

##########################################
# Parse Arguments 
##########################################
# Display help message if no argument is supplied
if [ $# -eq 0 ]; then
	usage; 1>&2; exit 1
fi

while [[ $# -gt 0 ]]; do
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