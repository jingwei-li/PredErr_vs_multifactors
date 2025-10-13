#!/bin/bash
# 
# Collect the intracranial volume of each subject.
# The output will be a text file.
#
# Author: Jingwei Li, 30/06/2023

data_dir=/data/project/parcellate_ABCD_preprocessed/data/datasets_repo/original/hcp/hcp_development
subj_ls=/data/project/predict_stereotype/lists/HCP-D_allRun.csv
outdir=
outbase_suffix=

main() {
    c=1
    subjects=$(cat $subj_ls)
    out="$outdir/ICV.${outbase_suffix}.txt"
    if [[ -f $out ]]; then rm $out; fi
    touch $out
    for s in $subjects; do
        cd $data_dir
        datalad get -n ${s}
        git -C ${s} config --local --add remote.datalad.annex-ignore true
        cd $data_dir/${s}/T1w
        datalad get -n .
        git -C . config --local --add remote.datalad.annex-ignore true
        cd $data_dir/${s}/T1w/${s}/stats
        git -C . config --local --add remote.datalad.annex-ignore true
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
    HCP-D_collect_ICV.sh

DESCRIPTION:
    Collect the intracranial volume of each subject.
    
ARGUMENTS:
    -data_dir       <data_dir>       : The local path of inm-7 superdataset's subfolder that contains HCP-A subjects (full path).
                                       Default: $data_dir
    -subj_ls        <subj_ls>        : Subject list, full path. Default:
                                       $subj_ls
    -outdir         <outdir>         : Output directory, full path.
    -outbase_suffix <outbase_suffix> : The output file names, for instance for the left hemisphere, 
                                       will be <outdir>/lh_Euler.<outbase_suffix>.txt

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