#!/bin/bash

proj_dir='/data/project/predict_stereotype'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/new_results/HCP-A/lists/dvars/logs
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
executable     = $DIR/HCP-A_collect_DVARS.sh
transfer_executable   = False
\n"

subj_ls=$proj_dir/new_results/HCP-A/lists/sublist_allbehavior.csv
printf "arguments = -s $subj_ls \n"
printf "log       = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.log\n"
printf "output    = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.out\n"
printf "error     = ${LOGS_DIR}/\$(Cluster).\$(Process).${start}.err\n"
printf "Queue\n\n"
