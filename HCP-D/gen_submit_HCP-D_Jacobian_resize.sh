#!/bin/bash

proj_dir='/data/project/predict_stereotype'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/new_results/HCP-D/Jacobian_resize/logs
# create the logs dir if it doesn't exist
[ ! -d "${LOGS_DIR}" ] && mkdir -p "${LOGS_DIR}"

# print the .submit header
printf "# The environment
universe       = vanilla
getenv         = True
request_cpus   = ${CPUS}
request_memory = ${RAM}
# Execution
initial_dir    = $proj_dir/new_scripts/PredErr_vs_multifactors/HCP-D
executable     = HCP-D_Jacobian_resize.sh
transfer_executable   = False
\n"

indir=$proj_dir/Jacobian/HCP-D/HCP-D_cat12.8.1
outdir=$proj_dir/new_results/HCP-D/Jacobian_resize
subj_ls=$proj_dir/new_results/HCP-D/lists/sublist_allbehavior_455sub.csv
mask=$proj_dir/Jacobian/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz
mkdir -p $outdir

printf "arguments = -indir $indir -outdir $outdir -subj_ls $subj_ls -mask $mask\n"
printf "log       = ${LOGS_DIR}/\$(Cluster).\$(Process).log\n"
printf "output    = ${LOGS_DIR}/\$(Cluster).\$(Process).out\n"
printf "error     = ${LOGS_DIR}/\$(Cluster).\$(Process).err\n"
printf "Queue\n\n"