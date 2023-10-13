function HCP_glm_scan(avgPredErr, outdir, Euler_lh, Euler_rh, subj_ls, FD_txt, FS_csv)

% HCP_glm_scan(avgPredErr, outdir, Euler_lh, Euler_rh, subj_ls, FD_txt, FS_csv)
%
% Build a full GLM with all scan-related covariates: Euler characteristic, ICV, and FD.
% Assess the importance of each covariate by the likelihood ratio test between the full
% model and the model without the examined covariate.
%
% Inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCP_avgPredErr`.
%   - outdir
%     Output directory
%   - Euler_lh
%     A text file of the Euler characteristic of the left hemisphere, across all individuals.
%   - Euler_rh
%     A text file of the Euler characteristic of the right hemisphere, across all individuals.
%   - subj_ls
%     Subject list.
%   - FD_txt
%     A text file that contains the FD of each subject.
%     e.g. '/data/project/predict_stereotype/from_sg/HCP_race/scripts/lists/FD_948.txt'
%   - FS_csv
%     The FreeSurfer csv file from HCP website.
%     e.g. '/data/project/predict_stereotype/datasets/HCP_YA_csv/FreeSurfer_jingweili_6_20_2023_1200subjects.csv'

if(~exist('FS_csv', 'var') || isempty(FS_csv))
    FS_csv = '/data/project/predict_stereotype/datasets/HCP_YA_csv/FreeSurfer_jingweili_6_20_2023_1200subjects.csv';
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

%% read ICV
d = readtable(FS_csv);
subjects = dlmread(subj_ls);
[~, ~, idx] = intersect(subjects, d.Subject, 'stable');
ICV = d.FS_IntraCranial_Vol(idx);

%% read FD
FD = dlmread(FD_txt);

%% write these variables to a csv file
T = addvars(T, euler, ICV, FD);
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