#! /usr/bin/env bash
# Adapted from CBPP unit test script written by Jianxiao Wu
# Modified by Jingwei Li, Jul. 2023

###########################################
# Define paths
###########################################

if [ "$(uname)" == "Linux" ]; then
  SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
elif [ "$(uname)" == "Darwin" ]; then
  SCRIPT_DIR=$(dirname "$0")
  SCRIPT_DIR=$(cd "$SCRIPT_DIR"; pwd)
fi
ROOT_DIR=$(dirname "$SCRIPT_DIR")

###########################################
# Main commands
###########################################
main(){

date

# set up parameters
matlab_cmd="/opt/MATLAB/R2023a/bin/matlab -nodesktop -nosplash -nodisplay -nojvm -singleCompThread -r"

# subject list variables
sublist=/data/project/predict_stereotype/new_results/HCP-A/lists/sublist_allbehavior.csv
echo $target

# wbCBPP 
$matlab_cmd "addpath('$SCRIPT_DIR'); \
             HCPA_generalise_cbpp('whole-brain', '$target', 'SchMel4', '$in_mat', '$output_dir', 1, '$sublist'); \
             exit"



date

}

##################################################################
# Function usage
##################################################################

# Usage
usage() { echo "
Usage: $0 -i in_mat -t \"target\" -o output_dir

This script parcellates and computes the connectivity of 50 HCP subjects using their surface (fsLR) and 50 subjects using their MNI data. The corresponding combined FC matrix was then used for whole-brain and parcel-wise CBPP.
The prediction results are compared to their corresponding ground truth files.

REQUIRED ARGUMENTS:
  -i <in_mat>       absolute path to input .mat file contains the functional connectivity, confounds, and target variables will be read by the scripts.
  -t <target>       target behavioral variable to be predicted
  -o <output_dir> 	absolute path to output directory

OPTIONAL ARGUMENTS:
  -h			          display help message

OUTPUTS:

	$0 will create 4 files containing the prediction performance of whole-brain CBPP for surface and volumetric data respectively:
		wbCBPP_SVR_standard_HCP_surf_gsr_300_Pearson.mat
    wbCBPP_SVR_standard_HCP_vol_fix_wmcsf_AICHA_Pearson.mat

" 1>&2; exit 1; }

# Display help message if no argument is supplied
if [ $# -eq 0 ]; then
  usage; 1>&2; exit 1
fi

##################################################################
# Assign input variables
##################################################################

# Assign parameter
while getopts "i:t:o:h" opt; do
  case $opt in
    i) in_mat=${OPTARG} ;;  # /home/jli/my_projects/fairAI/from_sg/new_results/HCP-A/cbpp/HCPA_fix_resid0_SchMel4_Pearson.mat
    t) target="${OPTARG}" ;;
    o) output_dir=${OPTARG} ;;
    h) usage; exit ;;
    *) usage; 1>&2; exit 1 ;;
  esac
done

##################################################################
# Check parameter
##################################################################

if [ -z $in_mat ]; then
  echo "Input .mat file not defined."; 1>&2; exit 1
fi
if [ -z "$target" ]; then
  echo "Target variable not defined."; 1>&2; exit 1
fi
if [ -z $output_dir ]; then
  echo "Output directory not defined."; 1>&2; exit 1
fi

##################################################################
# Set up output directory
##################################################################

if [ ! -d "$output_dir" ]; then
  echo "Output directory does not exist. Making directory now..."
  mkdir -p $output_dir
fi

###########################################
# Implementation
###########################################

main

