function HCPA_PredErr_vs_sociodemograph(avgPredErr, sublist, outdir, bhvr_cls_names, metric)

% HCPA_PredErr_vs_sociodemograph(pred_dir, outdir, metric)
%
%   - bhvr_cls_names
%     {'Cognition', 'Emotion recognition', 'Perceived negatives'}
    
load(avgPredErr)
subjects = table2array(readtable(sublist, 'ReadVariableNames', false));
csv_dir = '/data/project/predict_stereotype/datasets/inm7-superds/original/hcp/hcp_aging/phenotype';
subj_hdr = 'src_subject_id';

switch metric
case 'handedness'
    csv = fullfile(csv_dir, 'edinburgh_hand01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    handedness = d.hcp_handedness_score(idx);

    hand_LR = handedness;
    hand_LR(hand_LR>=-40 & hand_LR<=40) = nan;
    hand_LR(hand_LR<-40) = 2; % left-handed
    hand_LR(hand_LR>40) = 1; %right-handed

    Xlabel = 'Handedness';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = {'R', 'L'};
    outbase = 'PredErr_vs_handedness';
    HCPA_violin_PredErr_vs_other_var(hand_LR, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'educ'
    csv = fullfile(csv_dir, 'ssaga_cover_demo01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    educ = d.bkgrnd_education(idx);

    Xlabel = 'Education';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = {'3RD', '9TH', '10TH', '11TH', '12TH', ...
        'TECHNICAL SCHOOL OR 1 YR COLLEGE', '2 YRS COLLEGE', '3 YRS COLLEGE', ...
        '4 YRS COLLEGE: B.A., B.S.', 'GRADUATE SCHOOL: M.A., M.S., J.D., M.D., Ph.D'};
    educ_num = nan(size(educ));
    for c = 1:length(XTickLabels)
        idx = strcmp(educ, XTickLabels{c});
        educ_num(idx) = c;
    end
    outbase = 'PredErr_vs_educ';
    HCPA_violin_PredErr_vs_other_var(educ_num, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'prnt_educ'
    csv = fullfile(csv_dir, 'ssaga_cover_demo01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    meduc = d.dm15f(idx);
    feduc = d.dm15g(idx);
    Ylabel = 'Prediction error (abs)';

    % 0 = Unschooled ; 1 = 1ST ; 2 = 2ND ; 3 = 3RD ; 4 = 4TH ; 5 = 5TH ; 6 = 6TH ; 
    % 7 = 7TH ; 8 = 8TH ; 9 = 9TH ; 10 = 10TH ; 11 = 11TH ; 12 = 12TH ; 
    % 13 = TECHNICAL SCHOOL OR 1 YR COLLEGE ; 14 = 2 YRS COLLEGE ; 15 = 3 YRS COLLEGE ; 
    % 16 = 4 YRS COLLEGE: B.A., B.S ; 17 = GRADUATE SCHOOL: M.A., M.S., J.D., M.D., Ph.D ; 
    % 9999 = Don't know
    XTickLabels = {'Unschooled' ; '1ST to 5TH' ; '6TH to 9TH' ; '10TH to 12TH' ; ...
        'TECHNICAL SCHOOL OR SOME COLLEGE' ; '4 YRS COLLEGE: B.A., B.S' ; ...
        'GRADUATE SCHOOL: M.A., M.S., J.D., M.D., Ph.D' ;  'Don''t know'};

    meduc(meduc>=1 & meduc<=5) = 3;
    meduc(meduc>=6 & meduc<=9) = 7.5;
    meduc(meduc>=10 & meduc<=12) = 11;
    meduc(meduc>=13 & meduc<=15) = 14;
    Xlabel = 'Mother''s education';
    outbase = 'PredErr_vs_peduc_m';
    HCPA_violin_PredErr_vs_other_var(meduc, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    feduc(feduc>=1 & feduc<=5) = 3;
    feduc(feduc>=6 & feduc<=9) = 7.5;
    feduc(feduc>=10 & feduc<=12) = 11;
    feduc(feduc>=13 & feduc<=15) = 14;
    Xlabel = 'Father''s education';
    outbase = 'PredErr_vs_peduc_f';
    HCPA_violin_PredErr_vs_other_var(feduc, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'income'
    csv = fullfile(csv_dir, 'ssaga_cover_demo01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    income = d.annual_fam_inc(idx);
    income(income==99 | income==99999 | income==-999999) = nan;

    Ylabel = 'Family income';
    outbase = 'PredErr_vs_income';
    HCPA_scatter_PredErr_vs_other_var(err_avg, income, outdir, outbase, bhvr_cls_names, Ylabel, 1)
case 'age'
    csv = fullfile(csv_dir, 'ssaga_cover_demo01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    age = d.interview_age(idx);

    Ylabel = 'Age';
    outbase = 'PredErr_vs_age';
    HCPA_scatter_PredErr_vs_other_var(err_avg, age, outdir, outbase, bhvr_cls_names, Ylabel, 1)
case 'sex'
    csv = fullfile(csv_dir, 'ssaga_cover_demo01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    sex = d.sex(idx);
    sex = strcmp(sex, 'F');

    Xlabel = 'Sex';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = {'M', 'F'};
    outbase = 'PredErr_vs_sex';
    HCPA_violin_PredErr_vs_other_var(sex, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'race'
    csv = fullfile(csv_dir, 'ndar_subject01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    race = d.race(idx);

    Xlabel = 'Race';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = unique(race);
    Xdata = nan(length(race), 1);
    for x = 1:length(XTickLabels)
        Xdata(strcmp(race, XTickLabels{x})) = x;
    end
    outbase = 'PredErr_vs_race';
    HCPA_violin_PredErr_vs_other_var(Xdata, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
end

end