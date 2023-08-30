#!/bin/bash

proj_dir='/home/jli/my_projects/fairAI/from_sg'
DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
REPO_DIR=$(dirname $DIR)

CPUS='1'
RAM='5G'
LOGS_DIR=$proj_dir/new_results/HCP-D/logs
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
executable            = call_cbpp_HCP-D_allbehavior.sh
transfer_executable   = False
\n"

#in_mat=$proj_dir/new_results/HCP-D/cbpp/281sub_38behaviors_peduc/HCPD_fix_resid0_SchMel4_Pearson.mat
#in_mat=$proj_dir/new_results/HCP-D/cbpp/337sub_29behaviors_peduc/HCPD_fix_resid0_SchMel4_Pearson.mat
#in_mat=$proj_dir/new_results/HCP-D/cbpp/455sub_22behaviors/HCPD_fix_resid0_SchMel4_Pearson.mat
in_mat=$proj_dir/new_results/HCP-D/cbpp/404sub_16behaviors/HCPD_fix_resid0_SchMel4_Pearson.mat

#outdir=$proj_dir/new_results/HCP-D/cbpp/281sub_38behaviors_peduc
#outdir=$proj_dir/new_results/HCP-D/cbpp/337sub_29behaviors_peduc
#outdir=$proj_dir/new_results/HCP-D/cbpp/455sub_22behaviors
outdir=$proj_dir/new_results/HCP-D/cbpp/404sub_16behaviors

#list=$DIR/lists/colloquial_list.txt
#list=$DIR/lists/colloquial_list2.txt
#list=$DIR/lists/colloquial_list3.txt
list=$DIR/lists/colloquial_list4.txt

#sublist=$proj_dir/new_results/HCP-D/lists/sublist_allbehavior_281sub.csv
#sublist=$proj_dir/new_results/HCP-D/lists/sublist_allbehavior_337sub.csv
#sublist=$proj_dir/new_results/HCP-D/lists/sublist_allbehavior_455_sub.csv
sublist=$proj_dir/new_results/HCP-D/lists/sublist_allbehavior.csv

while IFS= read -r line; do
    printf "arguments = \"-i $in_mat -o $outdir -s $sublist -t '$line' \" \n"
    printf "log       = $LOGS_DIR/call_cbpp_HCP-D_\$(Cluster).\$(Process).log \n"
    printf "output    = $LOGS_DIR/call_cbpp_HCP-D_\$(Cluster).\$(Process).out \n"
    printf "error     = $LOGS_DIR/call_cbpp_HCP-D_\$(Cluster).\$(Process).err \n"
    printf "Queue\n\n"
done < $list