function HCPD_glm_sociodemograph(avgPredErr, outdir, subj_ls, HCPD_csv_dir)

% HCPD_glm_sociodemograph(avgPredErr, outdir, subj_ls, HCPD_csv_dir)
%
% Build a full GLM with all scan-related covariates: education, family income, ethnicity, 
% age, sex.
% Assess the importance of each covariate by the likelihood ratio test between the full
% model and the model without the examined covariate.
%
% Inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCPD_avgPredErr`.
%   - outdir
%     Output directory
%   - subj_ls
%     Subject list.
%   - HCPD_csv_dir
%     The local location of HCP-D phenotypes folder. Default:
%     '/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development/phenotype'
%

if(~exist('HCPD_csv_dir', 'var') || isempty(HCPD_csv_dir))
    HCPD_csv_dir = '/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development/phenotype';
end

%% initialize the table to be writen out: the first columns are the prediction errors
load(avgPredErr)
T = struct2table(err_avg);
N = length(fieldnames(err_avg));
for c = 1:N 
    T = renamevars(T, ['class' num2str(c)], ['err_class' num2str(c)]);
end

%% read education, ethnicity, age, sex, family income
start_dir = pwd;

subj_hdr = 'src_subject_id';
subjects = table2array(readtable(subj_ls, 'ReadVariableNames', false));

% ---- education
csv = fullfile(HCPD_csv_dir, 'socdem01.txt');
d = readtable(csv);
[~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
educ = d.bkgrnd_education(idx);

% original unique values:
% '10TH GRADE;'
% '11TH GRADE;'
% '12TH GRADE'
% '12TH GRADE, NO DIPLOMA;'
% '1ST GRADE;'
% '2ND GRADE;'
% '3RD GRADE;'
% '4TH GRADE;'
% '5TH GRADE;'
% '6TH GRADE;'
% '7TH GRADE;'
% '8TH GRADE;'
% '9TH GRADE;'
% 'ASSOCIATE DEGREE: ACADEMIC PROGRAM;'
% 'ASSOCIATE DEGREE: OCCUPATIONAL, TECHNICAL, OR VOCATIONAL PROGRAM;'
% 'BACHELOR'S DEGREE (EXAMPLE:BA, AB, BS, BBA); '
% 'HIGH SCHOOL GRADUATE;'
% 'KINDERGARTEN;'
% 'SOME COLLEGE, NO DEGREE;'
XTickLabels = {'DON''T KNOW' ; 'BELOW 12TH GRADE' ; 'HIGH SCHOOL GRADUATE, GED OR EQUIVALENT' ; ...
        'SOME COLLEGE, NO DEGREE' ; 'ASSOCIATE DEGREE' ; 'BACHELOR''S DEGREE' ; ...
        'MASTER''S DEGREE' ; 'PROFESSIONAL SCHOOL DEGREE' ; 'DOCTORAL DEGREE'};

educ_num = nan(size(educ));
idx = contains(educ, XTickLabels{1});
educ_num(idx) = 1;
idx = contains(educ, '1ST') | contains(educ, '2ND') | contains(educ, '3RD');
educ_num(idx) = 2;
idx = contains(educ, '4TH') | contains(educ, '5TH') | contains(educ, '6TH');
educ_num(idx) = 3;
idx = contains(educ, '7TH') | contains(educ, '8TH') | contains(educ, '9TH');
educ_num(idx) = 4;
idx = contains(educ, '10TH') | contains(educ, '11TH') | contains(educ, '12TH');
educ_num(idx) = 5;
idx = contains(educ, XTickLabels{6});
educ_num(idx) = 6;
idx = contains(educ, XTickLabels{7});
educ_num(idx) = 7;
idx = contains(educ, XTickLabels{8});
educ_num(idx) = 8;
idx = contains(educ, 'BACHELOR');
educ_num(idx) = 9;

% ---- ethnicity
[~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
ethnicity = d.race(idx);

empty_idx = cellfun(@isempty, ethnicity);
ethnicity{empty_idx} = 'Unknown or not reported';

% ---- age, sex, family income
age = d.interview_age(idx);
sex = d.sex(idx);

income = d.annual_fam_inc(idx);
income(income==-999999) = nan;

%% create dummy variables
educ_num = categorical(educ_num);
educ_dummy = dummyvar(educ_num);

ethnicity = categorical(ethnicity);
ethnicity_dummy = dummyvar(ethnicity);

sex = strcmp(sex, 'F');

%% write these variables to a csv file
T_educ = array2table(educ_dummy(:, 1:end-1));
oldnames = T_educ.Properties.VariableNames;
newnames = categories(educ_num);
T_educ = renamevars(T_educ, oldnames, strcat('educ_', newnames(1:end-1)));

T_ethn = array2table(ethnicity_dummy(:, 1:end-1));
oldnames = T_ethn.Properties.VariableNames;
newnames = categories(ethnicity);
T_ethn = renamevars(T_ethn, oldnames, strcat('ethnicity_', newnames(1:end-1)));

T = horzcat(T, T_educ);
T = horzcat(T, T_ethn);
T = addvars(T, age, sex, income);
T = T(~any(ismissing(T), 2), :);
writetable(T, fullfile(outdir, 'sociodemograph_related.csv'))

%% call R script
script_dir = fileparts(mfilename('fullpath'));
rScriptFilename = fullfile(script_dir, 'HCPD_glm_sociodemograph.r');
command = sprintf('Rscript %s %s %s', rScriptFilename, fullfile(outdir, 'sociodemograph_related.csv'), ...
    outdir);
status = system(command);
if status == 0
    disp('R script executed successfully.');
else
    error('Error executing R script.');
end
    
end