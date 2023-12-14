function std_Jval = Jacobian_single_subj(subj_id, maskname, Jacobian_dir)

% - subj_id
%   A string. Subject ID.
% - Jacobian_dir
%   A string. The directory to Jacobian volumes that have the same size as the brain mask in the template space.
% - maskname
%   A string, e.g. '/data/project/predict_stereotype/Jacobian/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz'

Jacobian_mri = fullfile(Jacobian_dir, ['wj_sub-' subj_id '_T1w_resize.nii.gz']);
if(~exist(Jacobian_mri, 'file'))
    if(exist(fullfile(Jacobian_dir, ['wj_sub-' subj_id '_ses-baselineYear1Arm1_T1w_resize.nii.gz']), 'file'))
        Jacobian_mri = fullfile(Jacobian_dir, ['wj_sub-' subj_id '_ses-baselineYear1Arm1_T1w_resize.nii.gz']);
    elseif(exist(fullfile(Jacobian_dir, ['wj_sub-' subj_id '_ses-baselineYear1Arm1_rec-normalized_T1w_resize.nii.gz']), 'file'))
        Jacobian_mri = fullfile(Jacobian_dir, ['wj_sub-' subj_id '_ses-baselineYear1Arm1_rec-normalized_T1w_resize.nii.gz']);
    elseif(exist(fullfile(Jacobian_dir, ['wj_sub-' subj_id '_ses-baselineYear1Arm1_run-01_T1w_resize.nii.gz']), 'file'))
        Jacobian_mri = fullfile(Jacobian_dir, ['wj_sub-' subj_id '_ses-baselineYear1Arm1_run-01_T1w_resize.nii.gz']);
    elseif(exist(fullfile(Jacobian_dir, ['wj_sub-' subj_id '_ses-baselineYear1Arm1_rec-normalized_run-01_T1w_resize.nii.gz']), 'file'))
        Jacobian_mri = fullfile(Jacobian_dir, ['wj_sub-' subj_id '_ses-baselineYear1Arm1_rec-normalized_run-01_T1w_resize.nii.gz']);
    else
        std_Jval = nan;
        warning('%s doesn''t have Jacobian volume', subj_id);
        return
    end
end
Jacobian = MRIread(Jacobian_mri);
Jvol = Jacobian.vol(:);
        
mask = MRIread(maskname);
mvol = mask.vol(:);
        
idx = find(mvol>0.9);
Jval = Jvol(idx);
        
std_Jval = std(Jval);
    
        
end