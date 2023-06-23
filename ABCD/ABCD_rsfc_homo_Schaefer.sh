#!/bin/sh
#
# Bash wrapper to calculate resting-state functional homogeneity 
# in the ABCD data of Schaefer parcellation.
# This script calls the matlab function `ABCD_rsfc_homo_Schaefer`.
#
# Jingwei Li, 16/05/2023

DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
scale=400
subj_ls=/mnt/nas/CSC7/Yeolab/PreviousLabMembers/jingweil/MyProject/fairAI/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt
data_dir=/mnt/isilon/CSC2/Yeolab/Data/ABCD/process/y0/rs_GSR_mf_FD0.3_DVARS50
outname=/mnt/nas/CSC7/Yeolab/PreviousLabMembers/jingweil/MyProject/fairAI/ABCD_race/mat/RSFC/homo_pass_rs_pass_pheno_5351.mat
outdir=$(dirname $outname)
echo $outdir


#########################
# core function
#########################
main() {
	mkdir -p $outdir/logs
    LF="$outdir/logs/rsfc_homo.log"
    if [ -f $LF ]; then rm $LF; fi

    echo "scale = $scale" >> $LF
    echo "subj_ls = $subj_ls" >> $LF
    echo "data_dir = $data_dir" >> $LF
    echo "outname = $outname" >> $LF

    ############ Call matlab function
    matlab -nodesktop -nosplash -nodisplay -r "addpath $DIR; \
        ABCD_rsfc_homo_Schaefer($scale, '$subj_ls', '$data_dir', '$outname'); exit;" >> $LF 2>&1
}

main