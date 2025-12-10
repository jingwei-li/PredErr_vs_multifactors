function HCP_covariates_association(outdir, Euler_lh, Euler_rh, subj_ls, FD_txt, FS_csv, restrict_csv, behav_csv)

% HCP_covariates_association(outdir, Euler_lh, Euler_rh, subj_ls, FD_txt, FS_csv, restrict_csv, behav_csv)
%
% Wrapper script to calculate the correlations among covariates (Euler characteristic, ICV, FD, 
% education, race, age, gender, family income).
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
%   - subj_ls
%     Subject list.
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

addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'covariates_corr'))

if(~exist('FS_csv', 'var') || isempty(FS_csv))
    FS_csv = '/data/project/predict_stereotype/datasets/HCP_YA_csv/FreeSurfer_jingweili_6_20_2023_1200subjects.csv';
end
if(~exist('restricted_csv', 'var') || isempty(restrict_csv))
    restrict_csv = '/data/project/predict_stereotype/datasets/HCP_YA_csv/RESTRICTED_jingweili_6_26_2023_1200subjects.csv';
end
if(~exist('behav_csv', 'var') || isempty(behav_csv))
    behav_csv = '/data/project/predict_stereotype/datasets/HCP_YA_csv/Behavioral_jingweili_6_26_2023_1200subjects.csv';
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
race = d.Race(idx);
age = d.Age_in_Yrs(idx);
income = d.SSAGA_Income(idx);
fam_id = d.Family_ID(idx);

%% read gender
d = readtable(behav_csv);
[~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
gender = d.Gender(idx);

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
% (education, ethnicity, gender, family income)
categoric.CramerV = ones(4,4);
categoric.names = {'Education', 'Ethnicity', 'Gender', 'Income'};

categoric.CramerV(1,2) = CramerV(outdir, cellstr(num2str(educ)), race);
categoric.CramerV(2,1) = categoric.CramerV(1,2);
categoric.CramerV(1,3) = CramerV(outdir, cellstr(num2str(educ)), gender);
categoric.CramerV(3,1) = categoric.CramerV(1,3);
categoric.CramerV(1,4) = CramerV(outdir, cellstr(num2str(educ)), cellstr(num2str(income)));
categoric.CramerV(4,1) = categoric.CramerV(1,4);
categoric.CramerV(2,3) = CramerV(outdir, race, gender);
categoric.CramerV(3,2) = categoric.CramerV(2,3);
categoric.CramerV(2,4) = CramerV(outdir, race, cellstr(num2str(income)));
categoric.CramerV(4,2) = categoric.CramerV(2,4);
categoric.CramerV(3,4) = CramerV(outdir, gender, cellstr(num2str(income)));
categoric.CramerV(4,3) = categoric.CramerV(3,4);

%% correlation between a continuous covariate and a categorical covariate
% captured by logistic regression
cont_cate.acc = nan(4,4);
cont_cate.names1 = {'Euler', 'ICV', 'FD', 'Age'};
cont_cate.names2 = {'Education', 'Ethnicity', 'Gender', 'Income'};

% use Euler characteristic to predict (education, ethnicity, gender, family income)
cont_cate.acc(1,1) = LogisticReg(outdir, euler, cellstr(num2str(educ)), fam_id);
cont_cate.acc(1,2) = LogisticReg(outdir, euler, race, fam_id);
cont_cate.acc(1,3) = LogisticReg(outdir, euler, gender, fam_id);
cont_cate.acc(1,4) = LogisticReg(outdir, euler, cellstr(num2str(income)), fam_id);

% use ICV to predict (education, ethnicity, gender, family income)
cont_cate.acc(2,1) = LogisticReg(outdir, ICV, cellstr(num2str(educ)), fam_id);
cont_cate.acc(2,2) = LogisticReg(outdir, ICV, race, fam_id);
cont_cate.acc(2,3) = LogisticReg(outdir, ICV, gender, fam_id);
cont_cate.acc(2,4) = LogisticReg(outdir, ICV, cellstr(num2str(income)), fam_id);

% use FD to predict (education, ethnicity, gender, family income)
cont_cate.acc(3,1) = LogisticReg(outdir, FD, cellstr(num2str(educ)), fam_id);
cont_cate.acc(3,2) = LogisticReg(outdir, FD, race, fam_id);
cont_cate.acc(3,3) = LogisticReg(outdir, FD, gender, fam_id);
cont_cate.acc(3,4) = LogisticReg(outdir, FD, cellstr(num2str(income)), fam_id);

% use age to predict (education, ethnicity, gender, family income)
cont_cate.acc(4,1) = LogisticReg(outdir, age, cellstr(num2str(educ)), fam_id);
cont_cate.acc(4,2) = LogisticReg(outdir, age, race, fam_id);
cont_cate.acc(4,3) = LogisticReg(outdir, age, gender, fam_id);
cont_cate.acc(4,4) = LogisticReg(outdir, age, cellstr(num2str(income)), fam_id);

save(fullfile(outdir, 'corr.mat'), 'continuous', 'categoric', 'cont_cate')


rmpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'covariates_corr'))
    
end