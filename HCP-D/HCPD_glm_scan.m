function HCPD_glm_scan(avgPredErr, outdir, Euler_lh, Euler_rh, ICV_txt, FD_txt, subj_ls, site_csv)

% HCPD_glm_scan(avgPredErr, outdir, Euler_lh, Euler_rh, ICV_txt, FD_txt)
%
% Build a full GLM with all scan-related covariates: Euler characteristic, ICV, and FD.
% Assess the importance of each covariate by the likelihood ratio test between the full
% model and the model without the examined covariate.
%
% Inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCPD_avgPredErr`.
%   - outdir
%     Output directory
%   - Euler_lh
%     A text file of the Euler characteristic of the left hemisphere, across all individuals.
%   - Euler_rh
%     A text file of the Euler characteristic of the right hemisphere, across all individuals.
%   - ICV_txt
%     A text file that contains the ICV of each subject.
%     e.g. '/data/project/predict_stereotype/new_results/HCP-D/lists/ICV.455sub_22behaviors.txt'
%   - FD_txt
%     A text file that contains the FD of each subject.
%     e.g. '/data/project/predict_stereotype/new_results/HCP-D/lists/FD.455sub_22behaviors.txt'
%   - subj_ls
%     Subject list.
%   - site_csv
%     The csv file from the HCP-D dataset which contains the site information. Default:
%     '/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development/phenotype/ndar_subject01.txt'
%

if(~exist('site_csv', 'var') || isempty(site_csv))
    site_csv = '/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development/phenotype/ndar_subject01.txt';
end

%% initialize the table to be writen out: the first columns are the prediction errors
load(avgPredErr)
T = struct2table(err_avg);
N = length(fieldnames(err_avg));
for c = 1:N 
    T = renamevars(T, ['class' num2str(c)], ['err_class' num2str(c)]);
end

%% read Euler characteristic
lh_euler = dlmread(Euler_lh);
rh_euler = dlmread(Euler_rh);
euler = (lh_euler + rh_euler) ./ 2;

subjects = table2array(readtable(subj_ls, 'ReadVariableNames', false));
d = readtable(site_csv);
[~, ~, idx] = intersect(subjects, d.src_subject_id, 'stable');
site = d.site(idx);
uq_st = unique(site);
euler_proc = zeros(size(euler));
for s = 1:length(uq_st)
    euler_st = euler(strcmp(site, uq_st{s}));
    euler_proc(strcmp(site, uq_st{s})) = euler_st - median(euler_st);
end

%% read ICV and FD
ICV = dlmread(ICV_txt);
FD = dlmread(FD_txt);

%% write these variables to a csv file
T = addvars(T, euler_proc, ICV, FD);
T = T(~any(ismissing(T), 2), :);
writetable(T, fullfile(outdir, 'scan_related.csv'))

%% call R script
script_dir = fileparts(fileparts(mfilename('fullpath')));
rScriptFilename = fullfile(script_dir, 'glm', 'glm_scan.r');
command = sprintf('Rscript %s %s %s', rScriptFilename, fullfile(outdir, 'scan_related.csv'), ...
    outdir);
status = system(command);
if status == 0
    disp('R script executed successfully.');
else
    error('Error executing R script.');
end

end