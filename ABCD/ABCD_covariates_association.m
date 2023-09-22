function ABCD_covariates_association(outdir, Euler_lh, Euler_rh, subj_ls, my_pheno_csv, ABCD_csv_dir)

% ABCD_covariates_association(outdir, Euler_lh, Euler_rh, subj_ls, my_pheno_csv, ABCD_csv_dir)
%
% Wrapper script to calculate the correlations among covariates (Euler characteristic, ICV, FD, 
% parental education, ethnicity, age, sex, family income).
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
%   - my_pheno_csv
%     The csv file created by this set of code: 
%     https://github.com/jingwei-li/Unfairness_ABCD_process/tree/master/preparation
%   - ABCD_csv_dir
%     The local location of ABCD phenotypes folder. Default:
%     '/data/project/predict_stereotype/datasets/inm7_superds/original/abcd/phenotype/phenotype'

addpath(fileparts(fileparts(mfilename('fullpath'))))

if(~exist('ABCD_csv_dir', 'var') || isempty(ABCD_csv_dir))
    ABCD_csv_dir = '/data/project/predict_stereotype/datasets/inm7_superds/original/abcd/phenotype/phenotype';
end

%% read Euler characteristic
lh_euler = dlmread(Euler_lh);
rh_euler = dlmread(Euler_rh);
euler = (lh_euler + rh_euler) ./ 2;

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

% ---------------------------------------------------------
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end

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
% (parental education, ethnicity, sex, family income)
categoric.CramerV = ones(4,4);
categoric.names = {'Education', 'Ethnicity', 'Sex', 'Income'};

categoric.CramerV(1,2) = CramerV(outdir, peduc, ethnicity);
categoric.CramerV(2,1) = categoric.CramerV(1,2);
categoric.CramerV(1,3) = CramerV(outdir, peduc, sex);
categoric.CramerV(3,1) = categoric.CramerV(1,3);
categoric.CramerV(1,4) = CramerV(outdir, peduc, income);
categoric.CramerV(4,1) = categoric.CramerV(1,4);
categoric.CramerV(2,3) = CramerV(outdir, ethnicity, sex);
categoric.CramerV(3,2) = categoric.CramerV(2,3);
categoric.CramerV(2,4) = CramerV(outdir, ethnicity, income);
categoric.CramerV(4,2) = categoric.CramerV(2,4);
categoric.CramerV(3,4) = CramerV(outdir, sex, income);
categoric.CramerV(4,3) = categoric.CramerV(3,4);

%% correlation between a continuous covariate and a categorical covariate
% captured by logistic regression
cont_cate.acc = nan(4,4);
cont_cate.names1 = {'Euler', 'ICV', 'FD', 'Age'};
cont_cate.names2 = {'Education', 'Ethnicity', 'Sex', 'Income'};

% read site
d = readtable(site_csv);
base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');
site = cell(nsub,1);
for s = 1:nsub
    tmp_idx = strcmp(d.(subj_hdr), [subjects{s}(1:4) '_' subjects{s}(5:end)]);
    if(any(tmp_idx==1))
        tmp_idx = tmp_idx & base_event;
        site(s) = d.site_id_l(tmp_idx);
    end
end

% use Euler characteristic to predict (parental education, ethnicity, sex, family income)
cont_cate.acc(1,1) = LogisticReg(outdir, euler, peduc, site);
cont_cate.acc(1,2) = LogisticReg(outdir, euler, ethnicity, site);
cont_cate.acc(1,3) = LogisticReg(outdir, euler, sex, site);
cont_cate.acc(1,4) = LogisticReg(outdir, euler, income, site);

% use ICV to predict (parental education, ethnicity, sex, family income)
cont_cate.acc(2,1) = LogisticReg(outdir, ICV, peduc, site);
cont_cate.acc(2,2) = LogisticReg(outdir, ICV, ethnicity, site);
cont_cate.acc(2,3) = LogisticReg(outdir, ICV, sex, site);
cont_cate.acc(2,4) = LogisticReg(outdir, ICV, income, site);

% use FD to predict (parental education, ethnicity, sex, family income)
cont_cate.acc(3,1) = LogisticReg(outdir, FD, peduc, site);
cont_cate.acc(3,2) = LogisticReg(outdir, FD, ethnicity, site);
cont_cate.acc(3,3) = LogisticReg(outdir, FD, sex, site);
cont_cate.acc(3,4) = LogisticReg(outdir, FD, income, site);

% use age to predict (parental education, ethnicity, sex, family income)
cont_cate.acc(4,1) = LogisticReg(outdir, age, peduc, site);
cont_cate.acc(4,2) = LogisticReg(outdir, age, ethnicity, site);
cont_cate.acc(4,3) = LogisticReg(outdir, age, sex, site);
cont_cate.acc(4,4) = LogisticReg(outdir, age, income, site);

save(fullfile(outdir, 'corr.mat'), 'continuous', 'categoric', 'cont_cate')

rmpath(fileparts(fileparts(mfilename('fullpath'))))
    
end




