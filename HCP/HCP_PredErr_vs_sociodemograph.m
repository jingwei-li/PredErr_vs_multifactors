function HCP_PredErr_vs_sociodemograph(subj_ls, avgPredErr, outdir, bhvr_cls_names, metric)

% HCP_PredErr_vs_sociodemograph(subj_ls, avgPredErr, outdir, bhvr_cls_names, metric)
%
%   - bhvr_cls_names
%     A cell array contains the subtitles for each subplot which corresponds to a behavioral cluster. 
%     The number of entries in `bhvr_cls_names` should be the same with the number of fields in the `err_arg` 
%     structure passed in by `avgPredErr` variable.
%     e.g. bhvr_cls_names = {'Cognitive flexibility, inhibition', 'Negative feelings', 'Positive feelings', 'Emotion recognition'};
   
subjects = dlmread(subj_ls);
nsub = length(subjects);

load(avgPredErr)

csv_dir = '/home/jli/datasets/HCP_YA_csv';
subj_hdr = 'Subject';

switch metric
case 'handedness'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    handedness = d.Handedness(idx);

    Ylabel = 'Handedness';
    outbase = 'PredErr_vs_handedness_scatter';
    HCP_scatter_PredErr_vs_other_var(err_avg, handedness, outdir, outbase, bhvr_cls_names, Ylabel, 1)

    hand_LR = handedness;
    hand_LR(hand_LR>=-40 & hand_LR<=40) = nan;
    hand_LR(hand_LR<-40) = 2; % left-handed
    hand_LR(hand_LR>40) = 1; %right-handed

    Xlabel = 'Handedness';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = {'R', 'L'};
    outbase = 'PredErr_vs_handedness';
    HCP_violin_PredErr_vs_other_var(hand_LR, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'educ'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    educ = d.SSAGA_Educ(idx);

    Xlabel = 'Education in years';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = arrayfun(@num2str, unique(educ(~isnan(educ))), 'UniformOutput', 0);
    outbase = 'PredErr_vs_educ';
    HCP_violin_PredErr_vs_other_var(educ, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'income'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    income = d.SSAGA_Income(idx);
    % <$10,000 = 1, 10K-19,999 = 2, 20K-29,999 = 3, 30K-39,999 = 4, 40K-49,999 = 5, 50K-74,999 = 6, 75K-99,999 = 7, >=100,000 = 8
    XTickLabels = {'<$10,000', '10K-19,999', '20K-29,999', '30K-39,999', '40K-49,999', '50K-74,999', '75K-99,999', '>=100,000'};
    Xlabel = 'Household income';
    Ylabel = 'Prediction error (abs)';
    outbase = 'PredErr_vs_income';
    HCP_violin_PredErr_vs_other_var(income, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'race'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    race = d.Race(idx);

    Xlabel = 'Ethnic group';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = unique(race);
    Xdata = nan(length(race), 1);
    for x = 1:length(XTickLabels)
        Xdata(strcmp(race, XTickLabels{x})) = x;
    end
    outbase = 'PredErr_vs_ethnicity';
    HCP_violin_PredErr_vs_other_var(Xdata, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'age'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    age = d.Age_in_Yrs(idx);

    Xlabel = 'Age';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_age';
    HCP_scatter_PredErr_vs_other_var(err_avg, age, outdir, outbase, bhvr_cls_names, Ylabel, 1)
case 'gender'
    csv = fullfile(csv_dir, 'Behavioral_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    gender = d.Gender(idx);

    gender = strcmp(gender, 'F');

    XTickLabels = {'M', 'F'};
    Xlabel = 'Gender';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_gender';
    HCP_violin_PredErr_vs_other_var(gender, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'BMI'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    BMI = d.BMI(idx);

    Xlabel = 'BMI';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_BMI';
    HCP_scatter_PredErr_vs_other_var(err_avg, BMI, outdir, outbase, bhvr_cls_names, Ylabel, 1)
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
    Xlabel = 'Zygosity';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_zygosity';
    HCP_violin_PredErr_vs_other_var(Xdata, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'menstruation'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    mens = d.Menstrual_DaysSinceLast(idx);

    Xlabel = 'Days since last menstruation';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_menstruation';
    HCP_scatter_PredErr_vs_other_var(err_avg, mens, outdir, outbase, bhvr_cls_names, Ylabel, 1)
case 'alcohol'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    alc_dp = d.SSAGA_Alc_D4_Dp_Dx(idx);

    XTickLabels = {'No', 'Yes'};
    Xlabel = 'DSM4 alcohol dependence in lifetime';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_AlcDp';
    HCP_violin_PredErr_vs_other_var(alc_dp, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'smoke'
    csv = fullfile(csv_dir, 'RESTRICTED_jingweili_6_26_2023_1200subjects.csv');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    FTND = d.SSAGA_FTND_Score(idx);
    HSI = d.SSAGA_HSI_Score(idx);

    XTickLabels = {'0', '1', '2', '3', '4', '5', '>=6'};
    Xlabel = 'Fagerstrom Test For Nicotine Dependence score';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_FTND';
    HCP_violin_PredErr_vs_other_var(FTND, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    XTickLabels = {'0', '1', '2', '3', '>=4'};
    Xlabel = 'Fagerstrom Heaviness of Smoking Index';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_HSI';
    HCP_violin_PredErr_vs_other_var(HSI, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
end

end