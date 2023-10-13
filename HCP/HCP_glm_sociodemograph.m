function HCP_glm_sociodemograph(avgPredErr, outdir, subj_ls, restrict_csv, behav_csv)

% HCP_glm_sociodemograph(avgPredErr, outdir, subj_ls, restrict_csv, behav_csv)
%
% Build a full GLM with all scan-related covariates: education, family income, ethnicity, 
% age, sex.
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
%   - restricted_csv
%     The restricted csv file from HCP website
%     e.g. '/data/project/predict_stereotype/datasets/HCP_YA_csv/RESTRICTED_jingweili_6_26_2023_1200subjects.csv'
%   - behav_csv
%     The unrestricted behavioral csv file form HCP website
%     e.g. '/data/project/predict_stereotype/datasets/HCP_YA_csv/Behavioral_jingweili_6_26_2023_1200subjects.csv'
%

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

%% read education, race, age, income, family id
subjects = dlmread(subj_ls);
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
writetable(T, fullfile(outdir, 'sociodemograph_related.csv'))

%% call R script
script_dir = fileparts(fileparts(mfilename('fullpath')));
rScriptFilename = fullfile(script_dir, 'glm', 'glm_sociodemograph.r');
command = sprintf('Rscript %s %s %s', rScriptFilename, fullfile(outdir, 'sociodemograph_related.csv'), ...
    outdir);
status = system(command);
if status == 0
    disp('R script executed successfully.');
else
    error('Error executing R script.');
end
    
end