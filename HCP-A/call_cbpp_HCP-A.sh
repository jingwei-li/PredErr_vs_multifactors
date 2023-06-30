#! /usr/bin/env bash
# This script runs the unit test for this repository
# Jianxiao Wu, last edited on 03-Apr-2020

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
n_sub=50
matlab_cmd="/opt/MATLAB/R2023a/bin/matlab -nodesktop -nosplash -nodisplay -nojvm -singleCompThread -r"

# subject list variables
sublist_FC=$ROOT_DIR/external_packages/cbpp/bin/sublist/HCP-A_fluidcog_allRun_sub.csv  # fluid composite
sublist_OP=$ROOT_DIR/external_packages/cbpp/bin/sublist/HCP-A_openness_allRun_sub.csv  # openness

# wbCBPP 
$matlab_cmd "addpath('$ROOT_DIR/external_packages/cbpp/generalisability_CBPP'); \
             generalise_cbpp('whole-brain', 'HCP-A_fluidcog', 'SchMel4', '$input_dir', '$output_dir', 1, '$sublist_FC'); \
             generalise_cbpp('whole-brain', 'HCP-A_openness', 'SchMel4', '$input_dir', '$output_dir', 1, '$sublist_OP'); \
             exit"



date

}

##################################################################
# Function usage
##################################################################

# Usage
usage() { echo "
Usage: $0 -i input_dir -o output_dir

This script parcellates and computes the connectivity of 50 HCP subjects using their surface (fsLR) and 50 subjects using their MNI data. The corresponding combined FC matrix was then used for whole-brain and parcel-wise CBPP.
The prediction results are compared to their corresponding ground truth files.

REQUIRED ARGUMENTS:
  -i <input_dir>    absolute path to input directory
                    Under input directory, a .mat file contains the functional connectivity, confounds, and target variables will be read by the scripts.
  -o <output_dir> 	absolute path to output directory

OPTIONAL ARGUMENTS:
  -h			          display help message

OUTPUTS:
	$0 will create 2 files containing the combined FC matrix for surface and volumetric data respectively:
		HCP_gsr_parc300_Pearson.mat
    HCP_fix_wmcsf_AICHA_Pearson.mat

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
while getopts "i:o:h" opt; do
  case $opt in
    i) input_dir=${OPTARG} ;;  # /home/jli/projects/jianxiao/generalizability_CBPP/proc_data
    o) output_dir=${OPTARG} ;;
    h) usage; exit ;;
    *) usage; 1>&2; exit 1 ;;
  esac
done

##################################################################
# Check parameter
##################################################################

if [ -z $input_dir ]; then
  echo "Input directory not defined."; 1>&2; exit 1
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

