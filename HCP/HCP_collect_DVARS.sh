#!/bin/bash

main() {
    subjects=$(cat $subj_ls)
    for s in $subjects; do
        cd $data_dir
        datalad get -n $s
        cd ${s}/MNINonLinear
        datalad get -n .
        git -C . config --local --replace-all remote.datalad.annex-ignore false
        cd Results
        for run in REST1_LR REST1_RL REST2_LR REST2_RL; do
            run=rfMRI_${run}
            if [[ -d $run ]]; then
                cd $run
                #in=${run}_hp2000_clean.nii.gz
                in=${run}.nii.gz
                out=$outdir/${s}_${run}
                t=$outdir/$s
                if [[ ! -f ${out}_conf ]]; then
                    datalad get $in
                    mkdir -p $t

                    cmd="singularity run -B $data_dir/$s/MNINonLinear -B $outdir $container"
                    cmd="$cmd fsl_motion_outliers -i $(pwd)/$in -o ${out}_conf -t $t -s $out"
                    cmd="$cmd --dvars --nomoco"
                    eval $cmd
                    echo "Calculated DVARS for $s, run $run"

                    datalad drop $in
                    rm -rf $t
                else
                    echo "DVARS for $s, run $run already exists."
                fi
                cd ..
            fi
        done
        cd $data_dir
        datalad uninstall $s --recursive
    done
}

#############################
# Function usage
#############################
usage() { echo "
NAME:
    HCP-D_collect_DVARS.sh -c container -d data_dir -s subj_ls -o outdir
ARGUMENTS:
    -c      absolute path to FSL container
    -d      absolute path to raw data directory (containing subject folders)
    -s      absolute path to subject list
    -o      absolute path to output directory
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