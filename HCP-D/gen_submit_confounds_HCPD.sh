#!/bin/bash

proj_dir='/data/project/predict_stereotype'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/new_results/HCP-D/lists/nuisance_regressors/logs
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
executable     = /usr/bin/python3
transfer_executable   = False
\n"

sublist=$proj_dir/new_results/HCP-D/lists/all_subjects.csv
outdir=$proj_dir/new_results/HCP-D/lists/nuisance_regressors
c=1
while IFS= read -r line; do
    if [ "$c" -ge "$1" ] && [ "$c" -le "$2" ]; then
    if [[ ! -f $outdir/${line}_rfMRI_REST2_PA_resid0.csv ]]; then
    printf "arguments = confounds_HCPD.py $line $outdir \n"
    printf "log       = $LOGS_DIR/confounds_HCPD_\$(Cluster).\$(Process).log \n"
    printf "output    = $LOGS_DIR/confounds_HCPD_\$(Cluster).\$(Process).out \n"
    printf "error     = $LOGS_DIR/confounds_HCPD_\$(Cluster).\$(Process).err \n"
    printf "Queue\n\n"
    fi
    fi
    c=$(awk -v x="$c" 'BEGIN { printf "%s", 1+x }' </dev/null)
done < $sublist