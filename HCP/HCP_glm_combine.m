function HCP_glm_combine(avgPredErr, outdir, subj_ls, Euler_lh, Euler_rh, FD_txt, FS_csv, restrict_csv, behav_csv)

% HCP_glm_combine(avgPredErr, outdir, subj_ls, Euler_lh, Euler_rh, FD_txt, FS_csv, restrict_csv, behav_csv)
%
% Build a full GLM with all scan-related and sociodemographic covariates: Euler characteristic, 
% ICV, FD, education, family income, ethnicity, age, sex.
% Assess the importance of each covariate by the likelihood ratio test between the full
% model and the model without the examined covariate.
%
% Inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCP_avgPredErr`.
%   - outdir
%     Output directory
%   - subj_ls
%     Subject list.
%   - Euler_lh
%     A text file of the Euler characteristic of the left hemisphere, across all individuals.
%   - Euler_rh
%     A text file of the Euler characteristic of the right hemisphere, across all individuals.
%   - FD_txt
%     A text file that contains the FD of each subject.
%     e.g. '/data/project/predict_stereotype/from_sg/HCP_race/scripts/lists/FD_948.txt'
%   - FS_csv
%     The FreeSurfer csv file from HCP website.
%     e.g. '/data/project/predict_stereotype/datasets/HCP_YA_csv/FreeSurfer_jingweili_6_20_2023_1200subjects.csv'
%   - restricted_csv
%     The restricted csv file from HCP website
%     e.g. '/data/project/predict_stereotype/datasets/HCP_YA_csv/RESTRICTED_jingweili_6_26_2023_1200subjects.csv'
%   - behav_csv
%     The unrestricted behavioral csv file form HCP website
%     e.g. '/data/project/predict_stereotype/datasets/HCP_YA_csv/Behavioral_jingweili_6_26_2023_1200subjects.csv'
%

if(~exist('FS_csv', 'var') || isempty(FS_csv))
    FS_csv = '/data/project/predict_stereotype/datasets/HCP_YA_csv/FreeSurfer_jingweili_6_20_2023_1200subjects.csv';
end
if(~exist('restricted_csv', 'var') || isempty(restrict_csv))
    restrict_csv = '/data/project/predict_stereotype/datasets/HCP_YA_csv/RESTRICTED_jingweili_6_26_2023_1200subjects.csv';
end
if(~exist('behav_csv', 'var') || isempty(behav_csv))
    behav_csv = '/data/project/predict_stereotype/datasets/HCP_YA_csv/Behavioral_jingweili_6_26_2023_1200subjects.csv';
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

%% read education, race, age, income, family id
subj_hdr = 'Subject';

d = readtable(restrict_csv);
[~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
educ = d.SSAGA_Educ(idx);
ethnicity = d.Race(idx);
age = d.Age_in_Yrs(idx);
income = d.SSAGA_Income(idx);
fam_id = d.Family_ID(idx);

%% read gender
d = readtable(behav_csv);
[~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
sex = d.Gender(idx);

%% create dummy variables
educ = categorical(educ);
educ_dummy = dummyvar(educ);

income = categorical(income);
income_dummy = dummyvar(income);

ethnicity = categorical(ethnicity);
ethnicity_dummy = dummyvar(ethnicity);

sex = strcmp(sex, 'F');

%% write these variables to a csv file
T = addvars(T, euler, ICV, FD);

T_educ = array2table(educ_dummy(:, 1:end-1));
oldnames = T_educ.Properties.VariableNames;
newnames = categories(educ);
T_educ = renamevars(T_educ, oldnames, strcat('educ_', newnames(1:end-1)));

T_income = array2table(income_dummy(:, 1:end-1));
oldnames = T_income.Properties.VariableNames;
newnames = categories(income);
T_income = renamevars(T_income, oldnames, strcat('income_', newnames(1:end-1)));

T_ethn = array2table(ethnicity_dummy(:, 1:end-1));
oldnames = T_ethn.Properties.VariableNames;
newnames = categories(ethnicity);
T_ethn = renamevars(T_ethn, oldnames, strcat('ethnicity_', newnames(1:end-1)));

T = horzcat(T, T_educ);
T = horzcat(T, T_income);
T = horzcat(T, T_ethn);
T = addvars(T, age, sex);
T = T(~any(ismissing(T), 2), :);
writetable(T, fullfile(outdir, 'all_covariates.csv'))

%% call R script
script_dir = fileparts(fileparts(mfilename('fullpath')));
rScriptFilename = fullfile(script_dir, 'glm', 'glm_combine.r');
command = sprintf('Rscript %s %s %s', rScriptFilename, fullfile(outdir, 'all_covariates.csv'), ...
    outdir);
status = system(command);
if status == 0
    disp('R script executed successfully.');
else
    error('Error executing R script.');
end
    
end