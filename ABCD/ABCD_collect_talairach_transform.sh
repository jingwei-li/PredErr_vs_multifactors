#!/bin/sh
# 
# Collect the scaling factors of the transform between native brain and talairach space for each subject.
# The output will be three text files corresponding to each of the three dimensions.
#
# Author: Jingwei Li, 04/05/2023

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

data_dir=/mnt/isilon/CSC2/Yeolab/Data/ABCD/process/y0/recon_all
subj_ls=/mnt/nas/CSC7/Yeolab/PreviousLabMembers/jingweil/MyProject/fairAI/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt
outdir=
outbase_suffix=

main() {
    c=1
    subjects=$(cat $subj_ls)
    x_out="$outdir/talxfm_x.${outbase_suffix}.txt"
    y_out="$outdir/talxfm_y.${outbase_suffix}.txt"
    z_out="$outdir/talxfm_z.${outbase_suffix}.txt"
    touch $x_out $y_out $z_out
    for s in $subjects; do
        xfm=$data_dir/$s/mri/transforms/talairach.xfm
        parameters=$(grep  -P '^[-+]?[0-9]+\.?[0-9]* [-+]?[0-9]+\.?[0-9]* [-+]?[0-9]+\.?[0-9]* [-+]?[0-9]+\.?[0-9]*' $xfm | cut -d ';' -f 1)

        x_scale=$(echo $parameters | cut -d ' ' -f 1)
        y_scale=$(echo $parameters | cut -d ' ' -f 6)
        z_scale=$(echo $parameters | cut -d ' ' -f 11)

        echo "#$c $s: x_scale = $x_scale y_scale = $y_scale z_scale=$z_scale"

        echo $x_scale >> $x_out
        echo $y_scale >> $y_out
        echo $z_scale >> $z_out
        c=$(echo "$c+1" | bc)
    done
}

#############################
# Function usage
#############################
usage() { echo "
NAME:
    ABCD_collect_talairach_transform.sh

DESCRIPTION:
    Collect the scaling factors of the transform between native brain and talairach space for each subject.

ARGUMENTS:
    -data_dir       <data_dir>       : The recon-all output directory of all ABCD subjects (full path).
    -subj_ls        <subj_ls>        : Subject list, full path.
    -outdir         <outdir>         : Output directory, full path.
    -outbase_suffix <outbase_suffix> : The output file names, for instance for the scaling factor along the first axis, 
                                       will be <outdir>/talxfm_x.<outbase_suffix>.txt

EXAMPLE:
    $DIR/ABCD_collect_talairach_transform.sh \\
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