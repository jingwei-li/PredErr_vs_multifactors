#!/bin/bash

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)
container="/home/jli/containers/images/neurodesk/neurodesk-fsl--6.0.5.1.simg"
subj_ls=/home/jli/my_projects/fairAI/from_sg/new_results/HCP-D/lists/all_subjects.csv
data_dir="/home/jli/datasets/inm7_superds/original/hcp/hcp_development"
#outdir="/home/jli/my_projects/fairAI/from_sg/new_results/HCP-D/lists/dvars"
outdir="/home/jli/my_projects/fairAI/from_sg/new_results/HCP-D/lists/dvars_nonclean"

main() {
    subjects=$(cat $subj_ls)
    for s in $subjects; do
        cd $data_dir
        datalad get -n ${s}_V1_MR
        cd ${s}_V1_MR/MNINonLinear
        datalad get -n .
        git -C . config --local --add remote.datalad.annex-ignore true
        cd Results
        for run in REST1_AP REST1_PA REST2_AP REST2_PA; do
            run=rfMRI_${run}
            if [[ -d $run ]]; then
                cd $run
                #in=${run}_hp0_clean.nii.gz
                in=${run}.nii.gz
                out=$outdir/${s}_${run}
                if [[ ! -f ${out}_conf ]]; then
                    datalad get -s inm7-storage $in
                
                    t=$outdir/$s
                    mkdir -p $t

                    singularity run $container fsl_motion_outliers -i $in -o ${out}_conf -t $t -s $out --dvars --nomoco
                    echo "Calculated DVARS for $s, run $run"

                    datalad drop $in
                    rm -r $t
                else
                    echo "DVARS for $s, run $run already exists."
                fi
                cd ..
            fi
        done
        cd $data_dir
        datalad uninstall ${s}_V1_MR --recursive
    done
}

#############################
# Function usage
#############################
usage() { echo "
NAME:
    HCP-A_collect_DVARS_onesub.sh
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
        -c)
            container=$1; shift;;
        -d)
            data_dir=$1; shift;;
        -s)
            subj_ls=$1; shift;;
        -o)
            outdir=$1; shift;;
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
if [ -z "$container" ]; then
	arg1err "-container"
fi
if [ -z "$data_dir" ]; then
	arg1err "-data_dir"
fi
if [ -z "$outdir" ]; then
	arg1err "-outdir"
fi
if [ -z "$subj_ls" ]; then
	arg1err "-s"
fi

main