#!/bin/bash

proj_dir='/home/jli/my_projects/fairAI/from_sg'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/new_results/HCP-A/logs
# create the logs dir if it doesn't exist
[ ! -d "${LOGS_DIR}" ] && mkdir -p "${LOGS_DIR}"

# print the .submit header
printf "# The environment
universe              = vanilla
getenv                = True
request_cpus          = ${CPUS}
request_memory        = ${RAM}

# Execution
initialdir            = $DIR
executable            = call_cbpp_HCP-A_27behavior.sh
transfer_executable   = False
\n"

in_mat=$proj_dir/new_results/HCP-A/cbpp/HCPA_fix_resid0_SchMel4_Pearson.mat
outdir=$proj_dir/new_results/HCP-A/cbpp
list=$DIR/lists/colloquial_list.txt

while IFS= read -r line; do
if [[ "$line" == "Perceived Rejection" ]]; then
    printf "arguments = \"-i $in_mat -o $outdir -t '$line'\" \n"
    printf "log       = $LOGS_DIR/call_cbpp_HCP-A_\$(Cluster).\$(Process).log \n"
    printf "output    = $LOGS_DIR/call_cbpp_HCP-A_\$(Cluster).\$(Process).out \n"
    printf "error     = $LOGS_DIR/call_cbpp_HCP-A_\$(Cluster).\$(Process).err \n"
    printf "Queue\n\n"
fi
done < $list