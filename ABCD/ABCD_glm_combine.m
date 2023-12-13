function ABCD_glm_combine(avgPredErr, outdir, subj_ls, Euler_lh, Euler_rh, my_pheno_csv, ABCD_csv_dir)

% ABCD_glm_combine(avgPredErr, outdir, subj_ls, Euler_lh, Euler_rh, my_pheno_csv, ABCD_csv_dir)
%
% Build a full GLM with all scan-related and sociodemographic covariates: Euler characteristic, ICV, FD, 
% parental education, family income, ethnicity, age, sex.
% Assess the importance of each covariate by the likelihood ratio test between the full
% model and the model without the examined covariate.
%
% Inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - outdir
%     Output directory
%   - subj_ls
%     Subject list.
%   - Euler_lh
%     A text file of the Euler characteristic of the left hemisphere, across all individuals.
%   - Euler_rh
%     A text file of the Euler characteristic of the right hemisphere, across all individuals.
%   - my_pheno_csv
%     The csv file created by this set of code: 
%     https://github.com/jingwei-li/Unfairness_ABCD_process/tree/master/preparation
%   - ABCD_csv_dir
%     The local location of ABCD phenotypes folder. Default:
%     '/data/project/predict_stereotype/datasets/inm7_superds/original/abcd/phenotype/phenotype'
%

if(~exist('ABCD_csv_dir', 'var') || isempty(ABCD_csv_dir))
    ABCD_csv_dir = '/data/project/predict_stereotype/datasets/inm7_superds/original/abcd/phenotype/phenotype';
end

load(avgPredErr)
T = struct2table(err_avg);
N = length(fieldnames(err_avg));
for c = 1:N 
    T = renamevars(T, ['class' num2str(c)], ['err_class' num2str(c)]);
end

[subjects, nsub] = CBIG_text2cell(subj_ls);

%% read Euler characteristic
lh_euler = dlmread(Euler_lh);
rh_euler = dlmread(Euler_rh);
euler = (lh_euler + rh_euler) ./ 2;

d = readtable(my_pheno_csv);
[~, ~, idx] = intersect(subjects, d.subjectkey, 'stable');
site = d.site(idx);
uq_st = unique(site);
euler_proc = zeros(size(euler));
for s = 1:length(uq_st)
    euler_st = euler(strcmp(site, uq_st{s}));
    euler_proc(strcmp(site, uq_st{s})) = euler_st - median(euler_st);
end

%% read ICV and FD
d = readtable(my_pheno_csv);
[subjects, nsub] = CBIG_text2cell(subj_ls);
[~, ~, idx] = intersect(subjects, d.subjectkey, 'stable');
ICV = d.ICV(idx);
FD = d.FD(idx);

%% read parental education, ethnicity, age, sex, family income
start_dir = pwd;

subj_hdr = 'subjectkey';
event_hdr = 'eventname';

% csv filenames
educ_relpath = 'pdem02.txt';
educ_csv = fullfile(ABCD_csv_dir, educ_relpath);
ethn_relpath = 'acspsw03.txt';
ethn_csv = fullfile(ABCD_csv_dir, ethn_relpath);
age_relpath = 'abcd_lt01.txt';
age_csv = fullfile(ABCD_csv_dir, age_relpath);
sex_relpath = 'abcd_lt01.txt';
sex_csv = fullfile(ABCD_csv_dir, sex_relpath);
income_relpath = 'pdem02.txt';
income_csv = fullfile(ABCD_csv_dir, income_relpath);
site_relpath = 'abcd_lt01.txt';
site_csv = fullfile(ABCD_csv_dir, site_relpath);

% get csv files from datalad repo
cd(ABCD_csv_dir)
system(sprintf('datalad get -s inm7-storage %s', educ_relpath));
system(sprintf('datalad get -s inm7-storage %s', ethn_relpath));
system(sprintf('datalad get -s inm7-storage %s', age_relpath));
system(sprintf('datalad get -s inm7-storage %s', sex_relpath));
system(sprintf('datalad get -s inm7-storage %s', income_relpath));
system(sprintf('datalad get -s inm7-storage %s', site_relpath));
cd(start_dir)

% ----- parental education -----
d = readtable(educ_csv);
peduc_hdr = 'demo_prnt_ed_v2';
peduc_colloquial = 'Parent 1''s degree';
base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');

% Based on ABCD documentation:
%  0 = Never attended/Kindergarten only; 1 = 1st grade; 2 = 2nd grade; 3 = 3rd grade; 4 = 4th grade; 
%  5 = 5th grade; 6 = 6th grade; 7 = 7th grade; 8 = 8th grade; 9 = 9th grade; 10 = 10th grade; 
%  11 = 11th grade; 12 = 12th grade; 13 = High school graduate; 14 = GED or equivalent Diploma; 
%  15 = Some college; 16 = Associate degree: Occupational; 17 = Associate degree: Academic Program; 
%  18 = Bachelor's degree (ex. BA); 19 = Master's degree (ex. MA); 20 = Professional School degree (ex. MD); 
%  21 = Doctoral degree (ex. PhD); 777 = Refused to answer Prefiero no responder ; 999 = Don't Know No
% 
% 777 & 999 are replaced with NaN.
peduc_read = d.(peduc_hdr);

% select only the rows corresponding to required subjects
peduc = nan(nsub, 1);
for s = 1:nsub
    tmp_idx = strcmp(d.(subj_hdr), [subjects{s}(1:4) '_' subjects{s}(5:end)]);
    if(any(tmp_idx==1))
        tmp_idx = tmp_idx & base_event;
        peduc(s,:) = peduc_read(tmp_idx,:);
    end
end

% convert 777 & 999 to nan; 1-5 to the median 3 ("Grade 1-5"); 6-8 to the median 7 ("Grade 6-8"); 
% 9-12 to the median 10.5 ("Grade 9-12"); 13-14 to the median 13.5 ("High school diploma, GED, or equvalent"); 
% 16-17 to the median 16.5 ("Associate degree")
peduc(peduc>25) = nan;
peduc(peduc>=1 & peduc<=5) = 3;
peduc(peduc>=6 & peduc<=8) = 7;
peduc(peduc>=9 & peduc<=12) = 10.5;
peduc(peduc>=13 & peduc<=14) = 13.5;
peduc(peduc>=16 & peduc<=17) = 16.5;

peduc = cellfun(@num2str, num2cell(peduc), 'UniformOutput', false);
uq_peduc = unique(peduc);
for i = 1:length(uq_peduc)
    idx = strcmp(peduc, uq_peduc{i});
    peduc(idx) = {['Level' num2str(i)]};
end

% ----- ethnicity -----
d = readtable(ethn_csv);
base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');
ethnicity = nan(nsub,1);
for s = 1:nsub
    tmp_idx = strcmp(d.(subj_hdr), [subjects{s}(1:4) '_' subjects{s}(5:end)]);
    if(any(tmp_idx==1))
        tmp_idx = tmp_idx & base_event;
        ethnicity(s) = d.race_ethnicity(tmp_idx);
    end
end
ethnicity = cellfun(@num2str, num2cell(ethnicity), 'UniformOutput', false);

% ----- age -----
d = readtable(age_csv);
base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');
age = nan(nsub,1);
for s = 1:nsub
    tmp_idx = strcmp(d.(subj_hdr), [subjects{s}(1:4) '_' subjects{s}(5:end)]);
    if(any(tmp_idx==1))
        tmp_idx = tmp_idx & base_event;
        age(s) = d.interview_age(tmp_idx);
    end
end

% ----- sex -----
d = readtable(sex_csv);
base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');

sex = cell(nsub,1);
for s = 1:nsub
    tmp_idx = strcmp(d.(subj_hdr), [subjects{s}(1:4) '_' subjects{s}(5:end)]);
    if(any(tmp_idx==1))
        tmp_idx = tmp_idx & base_event;
        sex(s) = d.sex(tmp_idx);
    end
end

% ----- family income -----
d = readtable(income_csv);
base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');

income = nan(nsub,1);
for s = 1:nsub
    tmp_idx = strcmp(d.(subj_hdr), [subjects{s}(1:4) '_' subjects{s}(5:end)]);
    if(any(tmp_idx==1))
        tmp_idx = tmp_idx & base_event;
        income(s) = d.demo_comb_income_v2(tmp_idx);
    end
end
income = cellfun(@num2str, num2cell(income), 'UniformOutput', false);
% 1= Less than $5,000; 2=$5,000 through $11,999; 3=$12,000 through $15,999; 4=$16,000 through $24,999; 
% 5=$25,000 through $34,999; 6=$35,000 through $49,999; 7=$50,000 through $74,999; 
% 8= $75,000 through $99,999; 9=$100,000 through $199,999; 10=$200,000 and greater. 
% 999 = Don't know; 777 = Refuse to answer

%% create dummy variables
peduc = categorical(peduc);
peduc_dummy = dummyvar(peduc);

income = categorical(income);
income_dummy = dummyvar(income);

ethnicity = categorical(ethnicity);
ethnicity_dummy = dummyvar(ethnicity);

sex = strcmp(sex, 'F');

%% write these variables to a csv file
T = addvars(T, euler_proc, ICV, FD);

T_peduc = array2table(peduc_dummy(:, 1:end-1));
oldnames = T_peduc.Properties.VariableNames;
newnames = categories(peduc);
T_peduc = renamevars(T_peduc, oldnames, strcat('educ_', newnames(1:end-1)));

T_income = array2table(income_dummy(:, 1:end-1));
oldnames = T_income.Properties.VariableNames;
newnames = categories(income);
T_income = renamevars(T_income, oldnames, strcat('income_', newnames(1:end-1)));

T_ethn = array2table(ethnicity_dummy(:, 1:end-1));
oldnames = T_ethn.Properties.VariableNames;
newnames = categories(ethnicity);
T_ethn = renamevars(T_ethn, oldnames, strcat('ethnicity_', newnames(1:end-1)));

T = horzcat(T, T_peduc);
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