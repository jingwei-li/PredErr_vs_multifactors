function HCPD_covariates_association(outdir, Euler_lh, Euler_rh, ICV_txt, FD_txt, subj_ls, HCPD_csv_dir)

% HCPD_covariates_association(outdir, Euler_lh, Euler_rh, ICV_txt, FD_txt, subj_ls, HCPD_csv_dir)
%
% Wrapper script to calculate the correlations among covariates (Euler characteristic, ICV, FD, 
% education, ethnicity, age, sex, family income).
% The correlation between any two continuous covariates will be calculated by Pearson's 
% correlation. The correlation between any two categorical covariates will be captured by 
% Cramer's V. The relationship between a continuous variable and a categorical variable
% will be captured by the prediction accuracy of logistic regression.
%
% Inputs:
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
%   - HCPD_csv_dir
%     The local location of HCP-D phenotypes folder. Default:
%     '/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development/phenotype'
%

addpath(fileparts(fileparts(mfilename('fullpath'))))

if(~exist('HCPD_csv_dir', 'var') || isempty(HCPD_csv_dir))
    HCPD_csv_dir = '/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development/phenotype';
end

%% read Euler characteristic
lh_euler = dlmread(Euler_lh);
rh_euler = dlmread(Euler_rh);
euler = (lh_euler + rh_euler) ./ 2;

%% read ICV and FD
ICV = dlmread(ICV_txt);
FD = dlmread(FD_txt);

%% read parental education, ethnicity, age, sex, family income
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
race = d.race(idx);

empty_idx = cellfun(@isempty, race);
race{empty_idx} = 'Unknown or not reported';

% ---- age, sex, family income
age = d.interview_age(idx);
sex = d.sex(idx);

income = d.annual_fam_inc(idx);
income(income==-999999) = nan;

%% read site for cross-validation
csv = fullfile(HCPD_csv_dir, 'ndar_subject01.txt');
d = readtable(csv);
[~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
site = d.site(idx);

%% calculate correlation between continuous variables
% (Euler characteristic, ICV, FD, age)
continuous.corr = ones(4,4);
continuous.names = {'Euler', 'ICV', 'FD', 'Age'};

idx = isnan(euler) | isnan(ICV);
continuous.corr(1,2) = corr(euler(~idx), ICV(~idx));
continuous.corr(2,1) = continuous.corr(1,2);

idx = isnan(euler) | isnan(FD);
continuous.corr(1,3) = corr(euler(~idx), FD(~idx));
continuous.corr(3,1) = continuous.corr(1,3);

idx = isnan(euler) | isnan(age);
continuous.corr(1,4) = corr(euler(~idx), age(~idx));
continuous.corr(4,1) = continuous.corr(1,4);

idx = isnan(ICV) | isnan(FD);
continuous.corr(2,3) = corr(ICV(~idx), FD(~idx));
continuous.corr(3,2) = continuous.corr(2,3);

idx = isnan(ICV) | isnan(age);
continuous.corr(2,4) = corr(ICV(~idx), age(~idx));
continuous.corr(4,2) = continuous.corr(2,4);

idx = isnan(FD) | isnan(age);
continuous.corr(3,4) = corr(FD(~idx), age(~idx));
continuous.corr(4,3) = continuous.corr(3,4);

%% calculate Cramer's V between categorical variables
% (education, ethnicity, sex, family income)
categoric.CramerV = ones(4,4);
categoric.names = {'Education', 'Ethnicity', 'Sex', 'Income'};

categoric.CramerV(1,2) = CramerV(outdir, cellstr(num2str(educ_num)), race);
categoric.CramerV(2,1) = categoric.CramerV(1,2);
categoric.CramerV(1,3) = CramerV(outdir, cellstr(num2str(educ_num)), sex);
categoric.CramerV(3,1) = categoric.CramerV(1,3);
categoric.CramerV(1,4) = CramerV(outdir, cellstr(num2str(educ_num)), cellstr(num2str(income)));
categoric.CramerV(4,1) = categoric.CramerV(1,4);
categoric.CramerV(2,3) = CramerV(outdir, race, sex);
categoric.CramerV(3,2) = categoric.CramerV(2,3);
categoric.CramerV(2,4) = CramerV(outdir, race, cellstr(num2str(income)));
categoric.CramerV(4,2) = categoric.CramerV(2,4);
categoric.CramerV(3,4) = CramerV(outdir, sex, cellstr(num2str(income)));
categoric.CramerV(4,3) = categoric.CramerV(3,4);

%% correlation between a continuous covariate and a categorical covariate
% captured by logistic regression
cont_cate.acc = nan(4,4);
cont_cate.names1 = {'Euler', 'ICV', 'FD', 'Age'};
cont_cate.names2 = {'Education', 'Ethnicity', 'Sex', 'Income'};

% use Euler characteristic to predict (education, ethnicity, sex, family income)
idx = isnan(euler) | isnan(educ_num) | cellfun(@isempty, site);
cont_cate.acc(1,1) = LogisticReg(outdir, euler(~idx), cellstr(num2str(educ_num(~idx))), site(~idx));
idx = isnan(euler) | cellfun(@isempty, race) | cellfun(@isempty, site);
cont_cate.acc(1,2) = LogisticReg(outdir, euler(~idx), race(~idx), site(~idx));
idx = isnan(euler) | cellfun(@isempty, sex) | cellfun(@isempty, site);
cont_cate.acc(1,3) = LogisticReg(outdir, euler(~idx), sex(~idx), site(~idx));
idx = isnan(euler) | isnan(income) | cellfun(@isempty, site);
cont_cate.acc(1,4) = LogisticReg(outdir, euler(~idx), cellstr(num2str(income(~idx))), site(~idx));

% use ICV to predict (education, ethnicity, sex, family income)
idx = isnan(ICV) | isnan(educ_num) | cellfun(@isempty, site);
cont_cate.acc(2,1) = LogisticReg(outdir, ICV(~idx), cellstr(num2str(educ_num(~idx))), site(~idx));
idx = isnan(ICV) | cellfun(@isempty, race) | cellfun(@isempty, site);
cont_cate.acc(2,2) = LogisticReg(outdir, ICV(~idx), race(~idx), site(~idx));
idx = isnan(ICV) | cellfun(@isempty, sex) | cellfun(@isempty, site);
cont_cate.acc(2,3) = LogisticReg(outdir, ICV(~idx), sex(~idx), site(~idx));
idx = isnan(ICV) | isnan(income) | cellfun(@isempty, site);
cont_cate.acc(2,4) = LogisticReg(outdir, ICV(~idx), cellstr(num2str(income(~idx))), site(~idx));

% use FD to predict (education, ethnicity, sex, family income)
idx = isnan(FD) | isnan(educ_num) | cellfun(@isempty, site);
cont_cate.acc(3,1) = LogisticReg(outdir, FD(~idx), cellstr(num2str(educ_num(~idx))), site(~idx));
idx = isnan(FD) | cellfun(@isempty, race) | cellfun(@isempty, site);
cont_cate.acc(3,2) = LogisticReg(outdir, FD(~idx), race(~idx), site(~idx));
idx = isnan(FD) | cellfun(@isempty, sex) | cellfun(@isempty, site);
cont_cate.acc(3,3) = LogisticReg(outdir, FD(~idx), sex(~idx), site(~idx));
idx = isnan(FD) | isnan(income) | cellfun(@isempty, site);
cont_cate.acc(3,4) = LogisticReg(outdir, FD(~idx), cellstr(num2str(income(~idx))), site(~idx));

% use age to predict (education, ethnicity, sex, family income)
idx = isnan(age) | isnan(educ_num) | cellfun(@isempty, site);
cont_cate.acc(4,1) = LogisticReg(outdir, age(~idx), cellstr(num2str(educ_num(~idx))), site(~idx));
idx = isnan(age) | cellfun(@isempty, race) | cellfun(@isempty, site);
cont_cate.acc(4,2) = LogisticReg(outdir, age(~idx), race(~idx), site(~idx));
idx = isnan(age) | cellfun(@isempty, sex) | cellfun(@isempty, site);
cont_cate.acc(4,3) = LogisticReg(outdir, age(~idx), sex(~idx), site(~idx));
idx = isnan(age) | isnan(income) | cellfun(@isempty, site);
cont_cate.acc(4,4) = LogisticReg(outdir, age(~idx), cellstr(num2str(income(~idx))), site(~idx));

save(fullfile(outdir, 'corr.mat'), 'continuous', 'categoric', 'cont_cate')


rmpath(fileparts(fileparts(mfilename('fullpath'))))
    
end