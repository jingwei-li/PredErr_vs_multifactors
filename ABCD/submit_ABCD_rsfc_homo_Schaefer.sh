#!/bin/sh
#
# Submit job to compute resting-state homogeneity of the ABCD data
#
# Jingwei Li, 16/05/2023

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
memory=5
outdir=/mnt/nas/CSC7/Yeolab/PreviousLabMembers/jingweil/MyProject/fairAI/ABCD_race/mat/RSFC

#########################
# core function
#########################
main() {
    work_dir=$outdir/logs/HPC
	mkdir -p $work_dir

    cmd="$DIR/ABCD_rsfc_homo_Schaefer.sh"

    jname=rsfc_homo_Schaefer
    $CBIG_CODE_DIR/setup/CBIG_pbsubmit -cmd "$cmd" -walltime 30:00:00 -mem ${memory}G \
-name $jname -joberr $work_dir/$jname.err -jobout $work_dir/$jname.out
}

main