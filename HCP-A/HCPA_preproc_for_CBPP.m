function HCPA_preproc_for_CBPP(sublist_jx, preproc_mat_jx, sublist_new, preproc_mat_new, conf_csv, targ_csv)

% HCPA_preproc_for_CBPP(sublist_jx, preproc_mat_jx, sublist_new, preproc_mat_new, conf_csv, targ_csv)
%
% Inputs:
%   - sublist_jx
%     The 715 subjects list from Jianxiao's previous paper.
%   - preproc_mat_jx
%     The .mat file that contains `fc`, `y`, and `conf` variables, after preprocessed by Jianxiao. 
%   - sublist_new
%     The subject list with all the behavioral variables, all confounding variables considered
%     for the current project. It is the output of `HCP-A_extract_targets_confounds.py`.
%   - preproc_mat_new
%     The output .mat file. It will contains the same variable names as `preproc_mat_jx`. But the
%     `fc` variable will be a subset of the `fc` in `preproc_mat_jx`, based on the correspondance
%     between the two subject lists. `y` and `conf` will be assigned by reading from `targ_csv` 
%     and `conf_csv`.
%   - conf_csv
%     The csv file contains all confounding variables considered for the current project. It is an
%     output of `HCP-A_extract_targets_confounds.py`.
%   - targ_csv
%     The csv file contains all behavioral measures to be predicted in the current project. It is 
%     also an output of `HCP-A_extract_targets_confounds.py`.
%
% Jingwei Li, 17/07/2023

subjects_jx = table2array(readtable(sublist_jx, 'ReadVariableNames', false));
subjects_new = table2array(readtable(sublist_new, 'ReadVariableNames', false));
[~,~,idx] = intersect(subjects_new, subjects_jx, 'stable');

load(preproc_mat_jx, 'fc')
fc = fc(:,:,idx);
y = readtable(targ_csv, 'VariableNamingRule', 'preserve');
y = removevars(y, ['Sub_Key']);
conf = readtable(conf_csv, 'VariableNamingRule', 'preserve');
conf = removevars(conf, ['Sub_Key']);
save(preproc_mat_new, 'fc', 'y', 'conf')
    
end