#!/bin/bash

proj_dir='/data/project/predict_stereotype/new_results/HCP-D'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/logs
# create the logs dir if it doesn't exist
[ ! -d "${LOGS_DIR}" ] && mkdir -p "${LOGS_DIR}"

# print the .submit header
printf "# The environment
universe       = vanilla
getenv         = True
request_cpus   = ${CPUS}
request_memory = ${RAM}
# Execution
initial_dir    = $DIR
executable     = /opt/MATLAB/R2023a/bin/matlab
transfer_executable   = False
\n"

in_dir=/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development
conf_dir=$proj_dir/lists/nuisance_regressors
psy_file=$proj_dir/lists/HCP-D_y.csv
conf_file=$proj_dir/lists/HCP-D_conf.csv
out_dir=$proj_dir/cbpp/404sub_16behaviors
mkdir -p $out_dir
sublist=$proj_dir/lists/sublist_allbehavior.csv

printf "arguments = -singleCompThread -nojvm -nodesktop -r HCPD_preproc_for_CBPP('$in_dir','$conf_dir','$psy_file','$conf_file','$out_dir','$sublist')\n"
printf "log       = ${LOGS_DIR}/preproc_\$(Cluster).\$(Process).log\n"
printf "output    = ${LOGS_DIR}/preproc_\$(Cluster).\$(Process).out\n"
printf "error     = ${LOGS_DIR}/preproc_\$(Cluster).\$(Process).err\n"
printf "Queue\n\n"
