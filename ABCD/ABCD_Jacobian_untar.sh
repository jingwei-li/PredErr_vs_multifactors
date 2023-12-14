#!/bin/bash

proj_dir=/data/project/predict_stereotype
datalad_dir=$proj_dir/Jacobian/ABCD/ABCD_cat12.8.1
outdir=$proj_dir/Jacobian/ABCD/extracted
subj_ls=$proj_dir/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt
#subj_ls=/data/project/predict_stereotype/new_results/ABCD/Jacobian_resize/subjects_no_Jacobian.txt
subjects=$(cat $subj_ls)

for s in $subjects; do
    cd $datalad_dir/sub-${s}/ses-baselineYear1Arm1
    if [ ! -f $outdir/mri/wj_sub-${s}_ses-baselineYear1Arm1*_T1w.nii.gz ]; then
        datalad get vbm.tar.gz
        if tar -tf vbm.tar.gz mri/wj_sub-${s}_ses-baselineYear1Arm1_rec-normalized_T1w.nii.gz >/dev/null 2>&1 ; then
            tar -C $outdir -xf $datalad_dir/sub-${s}/ses-baselineYear1Arm1/vbm.tar.gz mri/wj_sub-${s}_ses-baselineYear1Arm1_rec-normalized_T1w.nii.gz 
        elif tar -tf vbm.tar.gz mri/wj_sub-${s}_ses-baselineYear1Arm1_rec-normalized_run-01_T1w.nii.gz >/dev/null 2>&1 ; then
            tar -C $outdir -xf $datalad_dir/sub-${s}/ses-baselineYear1Arm1/vbm.tar.gz mri/wj_sub-${s}_ses-baselineYear1Arm1_rec-normalized_run-01_T1w.nii.gz 
        elif tar -tf vbm.tar.gz mri/wj_sub-${s}_ses-baselineYear1Arm1_run-01_T1w.nii.gz >/dev/null 2>&1 ; then
            tar -C $outdir -xf $datalad_dir/sub-${s}/ses-baselineYear1Arm1/vbm.tar.gz mri/wj_sub-${s}_ses-baselineYear1Arm1_run-01_T1w.nii.gz 
        else
            tar -C $outdir -xf $datalad_dir/sub-${s}/ses-baselineYear1Arm1/vbm.tar.gz mri/wj_sub-${s}_ses-baselineYear1Arm1_T1w.nii.gz
        fi
        datalad drop vbm.tar.gz --reckless kill
    fi
done
