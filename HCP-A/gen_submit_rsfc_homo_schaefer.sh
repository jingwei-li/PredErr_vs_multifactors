#!/bin/bash

proj_dir='/data/project/predict_stereotype'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/new_results/HCP-A/PredErr_vs_IndivFunc/logs
# create the logs dir if it doesn't exist
[ ! -d "${LOGS_DIR}" ] && mkdir -p "${LOGS_DIR}"

# print the .submit header
printf "# The environment
universe       = vanilla
getenv         = True
request_cpus   = ${CPUS}
request_memory = ${RAM}
# Execution
initial_dir    = $proj_dir/new_scripts/PredErr_vs_multifactors/HCP-A
executable     = /opt/MATLAB/R2023a/bin/matlab
transfer_executable   = False
\n"

HCPA_dir=/home/jli/datasets/inm7-superds/original/hcp/hcp_aging
conf_dir=$proj_dir/new_results/HCP-A/lists/nuisance_regressors
outdir=$proj_dir/new_results/HCP-A/PredErr_vs_IndivFunc
mkdir -p $outdir

subj_ls=$proj_dir/new_results/HCP-A/lists/sublist_allbehavior.csv
outname=$outdir/homo_sub_allbehavior.mat
printf "arguments = -singleCompThread -r HCPA_rsfc_homo_schaefer(400,'$subj_ls','$HCPA_dir','$conf_dir','$outname')\n"
printf "log       = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.log\n"
printf "output    = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.out\n"
printf "error     = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.err\n"
printf "Queue\n\n"
