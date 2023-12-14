function ABCD_Jacobian_all_subj(subj_ls, outtxt, maskname, Jacobian_dir)

% ABCD_Jacobian_all_subj(subj_ls, outtxt, maskname, Jacobian_dir)
%
% Inputs:
%   - subj_ls
%     A string. The list of subject IDs.
%     E.g. '/data/project/predict_stereotype/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt'
%   - outtxt
%     A string. The output list of Jacobian standard deviation of all subjects.
%     E.g. '/data/project/predict_stereotype/new_results/ABCD/lists/Jacobian.subjects_pass_rs_pass_pheno.txt'
%   - maskname
%     A string. Path to the brain mask in the MNI152 2009c asymetric template.
%     Default: '/data/project/predict_stereotype/Jacobian/tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz'
%   - Jacobian_dir
%     The folder that contains the Jacobian volumes which have the same size as the brain mask.
%     Default: '/data/project/predict_stereotype/new_results/ABCD/Jacobian_resize'
%
% Author: Jingwei Li
% Date: 2023/12/14
%
    
    
script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir), 'Jacobian'))
    
proj_dir = '/data/project/predict_stereotype';
if(~exist('maskname', 'var') || isempty(maskname))
    maskname = fullfile(proj_dir, 'Jacobian', 'tpl-MNI152NLin2009cAsym_res-02_desc-brain_mask.nii.gz');
end
if(~exist('Jacobian_dir', 'var') || isempty(Jacobian_dir))
    Jacobian_dir = fullfile(proj_dir, 'new_results', 'ABCD', 'Jacobian_resize');
end
        
[subj_IDs, num_subj] = CBIG_text2cell(subj_ls);
        
std_Jval_all = zeros(num_subj, 1);
for i = 1:num_subj
    fprintf('Subject: %s\n', subj_IDs{i})
    std_Jval_all(i) = Jacobian_single_subj(subj_IDs{i}, maskname, Jacobian_dir);
end
        
dlmwrite(outtxt, std_Jval_all)
    
rmpath(fullfile(fileparts(script_dir), 'Jacobian'))
        
end