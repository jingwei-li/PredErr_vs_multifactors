#!/bin/bash

proj_dir='/data/project/predict_stereotype'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/new_results/HCP-A/lists/logs
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

out=$proj_dir/new_results/HCP-A/lists/FD.sub_allbehavior.txt
sublist=$proj_dir/new_results/HCP-A/lists/sublist_allbehavior.csv
printf "arguments = HCP-A_collect_FD.py $out -s $sublist \n"
printf "log       = ${LOGS_DIR}/FD.\$(Cluster).\$(Process).log\n"
printf "output    = ${LOGS_DIR}/FD.\$(Cluster).\$(Process).out\n"
printf "error     = ${LOGS_DIR}/FD.\$(Cluster).\$(Process).err\n"
printf "Queue\n\n"