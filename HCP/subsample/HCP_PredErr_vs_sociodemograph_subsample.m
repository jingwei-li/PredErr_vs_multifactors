function HCP_PredErr_vs_sociodemograph_subsample(subj_ls, avgPredErr, bhvr_cls_names, outdir, s_size, repeats, metric)

% HCP_PredErr_vs_sociodemograph_subsample(subj_ls, avgPredErr, bhvr_cls_names, outdir, s_size, repeats, metric)
%
%   - subj_ls
%     Full path to the subject list. The subjects should be corresponded to the prediction
%     errors provided by `avgPredErr`.
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCP_avgPredErr`.
%   - bhvr_cls_names
%     A cell array contains the X-axis names for each behavioral cluster. The number of entries 
%     in `bhvr_cls_names` should be the same with the number of fields in the `asso` structure.
%     Example: bhvr_cls_names = {'Social cognition', 'Negative/Positive feelings', 'Emotion recognition'};
%   - outdir
%     Full path to output directory.
%   - s_size
%     Size of each subsample (e.g. 455).
%   - repeats
%     Number of repetitions of subsampling (e.g. 100).
%   - metric
%     Choose from 'handedness', 'educ', 'income', 'race', 'age', 'gender', 'BMI', 'zygosity', 'menstruation', 
%     'alcohol', and 'smoke'
%

addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))

subjects = dlmread(subj_ls);
load(avgPredErr)

csv_dir = '/data/project/predict_stereotype/datasets/HCP_YA_csv';
subj_hdr = 'Subject';

switch metric
case 'handedness'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    handedness = d.Handedness(idx);

    hand_LR = handedness;
    hand_LR(hand_LR>=-40 & hand_LR<=40) = nan;
    hand_LR(hand_LR<-40) = 2; % left-handed
    hand_LR(hand_LR>40) = 1; %right-handed

    outmat = fullfile(outdir, 'PredErr_vs_handedness.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, hand_LR, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_handedness');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'educ'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    educ = d.SSAGA_Educ(idx);

    outmat = fullfile(outdir, 'PredErr_vs_educ.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, educ, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_educ');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'income'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    income = d.SSAGA_Income(idx);
    % <$10,000 = 1, 10K-19,999 = 2, 20K-29,999 = 3, 30K-39,999 = 4, 40K-49,999 = 5, 50K-74,999 = 6, 75K-99,999 = 7, >=100,000 = 8

    outmat = fullfile(outdir, 'PredErr_vs_income.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, income, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_income');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'race'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    race = d.Race(idx);

    XTickLabels = unique(race);
    Xdata = nan(length(race), 1);
    for x = 1:length(XTickLabels)
        Xdata(strcmp(race, XTickLabels{x})) = x;
    end

    outmat = fullfile(outdir, 'PredErr_vs_ethnicity.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, Xdata, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_ethnicity');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'age'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    age = d.Age_in_Yrs(idx);

    outmat = fullfile(outdir, 'PredErr_vs_age.mat');
    asso = subsample_PredErr_vs_continuous_covar(err_avg, age, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_age');
    hist_subsample_rho(asso, bhvr_cls_names, figout)
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'gender'
    csv = fullfile(csv_dir, 'Behavioral_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    gender = d.Gender(idx);

    gender = strcmp(gender, 'F');

    outmat = fullfile(outdir, 'PredErr_vs_gender.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, gender, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_gender');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'BMI'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    BMI = d.BMI(idx);

    outmat = fullfile(outdir, 'PredErr_vs_BMI.mat');
    asso = subsample_PredErr_vs_continuous_covar(err_avg, BMI, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_BMI');
    hist_subsample_rho(asso, bhvr_cls_names, figout)
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'zygosity'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    SR = d.ZygositySR(idx);
    GT = d.ZygosityGT(idx);
    zygosity = cell(length(idx), 1);
    zygosity(strcmp(SR, 'NotTwin')) = {'NotTwin'};
    zygosity(~strcmp(SR, 'NotTwin')) = GT(~strcmp(SR, 'NotTwin'));

    XTickLabels = unique(zygosity);
    XTickLabels = setdiff(XTickLabels, {''})
    Xdata = nan(length(zygosity), 1);
    for x = 1:length(XTickLabels)
        Xdata(strcmp(zygosity, XTickLabels{x})) = x;
    end

    outmat = fullfile(outdir, 'PredErr_vs_zygosity.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, Xdata, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_zygosity');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'menstruation'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    mens = d.Menstrual_DaysSinceLast(idx);

    mens_grp = nan(size(mens));
    mens_grp(mens>=0 & mens<=5) = 1;
    mens_grp(mens>5 & mens<=13) = 2;
    mens_grp(mens==14) = 3;
    mens_grp(mens>14 & mens<=35) = 4;
    mens_grp(mens<0) = 5;
    mens_grp(mens>35 ) = 6;
    mens_grp(isnan(mens)) = nan;

    outmat = fullfile(outdir, 'PredErr_vs_menstruation.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, mens_grp, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_menstruation');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)

    %% birth control
    contra = d.Menstrual_UsingBirthControl(idx);

    outmat = fullfile(outdir, 'PredErr_vs_contraceptive.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, contra, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_contraceptive');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'alcohol'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    alc_dp = d.SSAGA_Alc_D4_Dp_Dx(idx);

    outmat = fullfile(outdir, 'PredErr_vs_AlcDp.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, alc_dp, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_AlcDp');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'smoke'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    FTND = d.SSAGA_FTND_Score(idx);
    HSI = d.SSAGA_HSI_Score(idx);

    outmat = fullfile(outdir, 'PredErr_vs_FTND.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, FTND, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_FTND');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)

    outmat = fullfile(outdir, 'PredErr_vs_HSI.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, HSI, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_HSI');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
otherwise
    error('Unknown metric: %s', metric)
end

rmpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))
    
end