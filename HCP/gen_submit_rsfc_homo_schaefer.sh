#!/bin/bash

proj_dir='/home/jli/my_projects/fairAI/from_sg'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/new_results/HCP/PredErr_vs_IndivFunc/logs
# create the logs dir if it doesn't exist
[ ! -d "${LOGS_DIR}" ] && mkdir -p "${LOGS_DIR}"

# print the .submit header
printf "# The environment
universe       = vanilla
getenv         = True
request_cpus   = ${CPUS}
request_memory = ${RAM}
# Execution
initial_dir    = $proj_dir/new_scripts/HCP
executable     = /opt/MATLAB/R2023a/bin/matlab
transfer_executable   = False
\n"

HCP_dir=/home/jli/datasets/human-connectome-project-openaccess
outdir=$proj_dir/new_results/HCP/PredErr_vs_IndivFunc
mkdir -p $outdir

subj_ls=$proj_dir/HCP_race/scripts/lists/subjects_wIncome_948.txt
outname=$outdir/homo_subjects_wIncome_948.mat
printf "arguments = -singleCompThread -r rsfc_homo_schaefer(400,'$subj_ls','$HCP_dir','$outname')\n"
printf "log       = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.log\n"
printf "output    = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.out\n"
printf "error     = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.err\n"
printf "Queue\n\n"
