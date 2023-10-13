function HCPD_PredErr_vs_sociodemograph(avgPredErr, sublist, outdir, bhvr_cls_names, metric)

% HCPD_PredErr_vs_sociodemograph(avgPredErr, sublist, outdir, bhvr_cls_names, metric)
%
%   - bhvr_cls_names
%     {'Cognition', 'Emotion recognition'}
%     {'Behavioral inhibition', 'Externalizing problems', 'Premeditation/perseverance', 'Impulsivity - urgency'}

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir), 'HCP-A'))

load(avgPredErr)
subjects = table2array(readtable(sublist, 'ReadVariableNames', false));
csv_dir = '/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development/phenotype';
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
    csv = fullfile(csv_dir, 'socdem01.txt');
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

    XTickLabels = {'KINDERGARTEN' ; '1ST to 3RD' ; '4TH to 6TH' ; '7TH to 9TH' ; ...
        '10TH to 12TH' ; 'HIGH SCHOOL GRADUATE' ; ...
        'SOME COLLEGE, NO DEGREE' ; 'ASSOCIATE DEGREE' ;  'BACHELOR''S DEGREE'};

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

    Xlabel = 'Education';
    Ylabel = 'Prediction error (abs)';
    outbase = 'PredErr_vs_educ';
    HCPA_violin_PredErr_vs_other_var(educ_num, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'prnt_educ'
    csv = fullfile(csv_dir, 'socdem01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    peduc = d.cg1_bkgrnd_education(idx);
    ptnr_educ = d.ptner_grade(idx);

    %% Original unique values for parent:
    % '10TH GRADE;'
    % '12TH GRADE, NO DIPLOMA;'
    % '9TH GRADE;'
    % 'ASSOCIATE DEGREE: ACADEMIC PROGRAM;'
    % 'ASSOCIATE DEGREE: OCCUPATIONAL, TECHNICAL, OR VOCATIONAL PROGRAM;'
    % 'BACHELOR'S DEGREE (EXAMPLE:BA, AB, BS, BBA); '
    % 'DOCTORAL DEGREE (EXAMPLE:PhD, EdD);'
    % 'GED OR EQUIVALENT;'
    % 'HIGH SCHOOL GRADUATE;'
    % 'MASTER'S DEGREE (EXAMPLE:MA, MS, MEng, MEd, MBA); '
    % 'PROFESSIONAL SCHOOL DEGREE (EXAMPLE: MD, DDS, DVM, JD);'
    % 'SOME COLLEGE, NO DEGREE;'

    XTickLabels = {'BELOW 12TH GRADE' ; 'HIGH SCHOOL GRADUATE, GED OR EQUIVALENT' ; ...
        'SOME COLLEGE, NO DEGREE' ; 'ASSOCIATE DEGREE' ; 'BACHELOR''S DEGREE' ; ...
        'MASTER''S DEGREE' ; 'PROFESSIONAL SCHOOL DEGREE' ; 'DOCTORAL DEGREE'};
    
    peduc_num = nan(size(peduc));
    idx = contains(peduc, '9TH') | contains(peduc, '10TH') | contains(peduc, '12TH');
    peduc_num(idx) = 1;
    idx = contains(peduc, 'HIGH SCHOOL GRADUATE') | contains(peduc, 'GED');
    peduc_num(idx) = 2;
    idx = contains(peduc, XTickLabels{3});
    peduc_num(idx) = 3;
    idx = contains(peduc, XTickLabels{4});
    peduc_num(idx) = 4;
    idx = contains(peduc, 'BACHELOR');
    peduc_num(idx) = 5;
    idx = contains(peduc, 'MASTER');
    peduc_num(idx) = 6;
    idx = contains(peduc, XTickLabels{7});
    peduc_num(idx) = 7;
    idx = contains(peduc, XTickLabels{8});
    peduc_num(idx) = 8;

    Xlabel = 'Parent''s education';
    Ylabel = 'Prediction error (abs)';
    outbase = 'PredErr_vs_prnt_educ';
    HCPA_violin_PredErr_vs_other_var(peduc_num, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    %% Original unique values for parent's partner:
    % '10TH GRADE;'
    % '11TH GRADE;'
    % '12TH GRADE, NO DIPLOMA;'
    % '2ND GRADE;'
    % '8TH GRADE;'
    % '9TH GRADE;'
    % 'ASSOCIATE DEGREE: ACADEMIC PROGRAM;'
    % 'ASSOCIATE DEGREE: OCCUPATIONAL, TECHNICAL, OR VOCATIONAL PROGRAM;'
    % 'BACHELOR'S DEGREE (EXAMPLE:BA, AB, BS, BBA); '
    % 'DOCTORAL DEGREE (EXAMPLE:PhD, EdD);'
    % 'DON'T KNOW'
    % 'GED OR EQUIVALENT;'
    % 'HIGH SCHOOL GRADUATE;'
    % 'MASTER'S DEGREE (EXAMPLE:MA, MS, MEng, MEd, MBA); '
    % 'PROFESSIONAL SCHOOL DEGREE (EXAMPLE: MD, DDS, DVM, JD);'
    % 'SOME COLLEGE, NO DEGREE;'
    XTickLabels = {'DON''T KNOW' ; 'BELOW 12TH GRADE' ; 'HIGH SCHOOL GRADUATE, GED OR EQUIVALENT' ; ...
        'SOME COLLEGE, NO DEGREE' ; 'ASSOCIATE DEGREE' ; 'BACHELOR''S DEGREE' ; ...
        'MASTER''S DEGREE' ; 'PROFESSIONAL SCHOOL DEGREE' ; 'DOCTORAL DEGREE'};
    
    ptnr_educ_num = nan(size(ptnr_educ));
    idx = contains(ptnr_educ, XTickLabels{1});
    ptnr_educ_num(idx) = 1;
    idx = contains(ptnr_educ, '2ND') | contains(ptnr_educ, '8TH') | contains(ptnr_educ, '9TH') | contains(ptnr_educ, '10TH') | contains(ptnr_educ, '11TH') | contains(ptnr_educ, '12TH');
    ptnr_educ_num(idx) = 2;
    idx = contains(ptnr_educ, 'HIGH SCHOOL GRADUATE') | contains(ptnr_educ, 'GED');
    ptnr_educ_num(idx) = 3;
    idx = contains(ptnr_educ, XTickLabels{4});
    ptnr_educ_num(idx) = 4;
    idx = contains(ptnr_educ, XTickLabels{5});
    ptnr_educ_num(idx) = 5;
    idx = contains(ptnr_educ, 'BACHELOR');
    ptnr_educ_num(idx) = 6;
    idx = contains(ptnr_educ, 'MASTER');
    ptnr_educ_num(idx) = 7;
    idx = contains(ptnr_educ, XTickLabels{7});
    ptnr_educ_num(idx) = 8;
    idx = contains(ptnr_educ, XTickLabels{8});
    ptnr_educ_num(idx) = 9;

    Xlabel = 'Parent''s partner''s education';
    Ylabel = 'Prediction error (abs)';
    outbase = 'PredErr_vs_prnt_ptnr_educ';
    HCPA_violin_PredErr_vs_other_var(ptnr_educ_num, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'income'
    csv = fullfile(csv_dir, 'socdem01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    income = d.annual_fam_inc(idx);
    income(income==-999999) = nan;

    Ylabel = 'Family income';
    outbase = 'PredErr_vs_income';
    HCPA_scatter_PredErr_vs_other_var(err_avg, income, outdir, outbase, bhvr_cls_names, Ylabel, 1)
case 'race'
    csv = fullfile(csv_dir, 'socdem01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    race = d.race(idx);

    idx = cellfun(@isempty, race);
    race{idx} = 'Unknown or not reported';

    Xlabel = 'Race';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = unique(race);
    Xdata = nan(length(race), 1);
    for x = 1:length(XTickLabels)
        Xdata(strcmp(race, XTickLabels{x})) = x;
    end
    outbase = 'PredErr_vs_race';
    HCPA_violin_PredErr_vs_other_var(Xdata, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    Xdata2 = nan(length(race), 1);
    XTickLabels2 = XTickLabels
    for x = 1:length(XTickLabels)
        if(length(find(strcmp(race, XTickLabels{x}))) > 1)
            Xdata2(strcmp(race, XTickLabels{x})) = x;
        else
            XTickLabels2 = setdiff(XTickLabels2, XTickLabels(x));
        end
    end
    outbase = 'PredErr_vs_race_removeSingleDataPoint';
    HCPA_violin_PredErr_vs_other_var(Xdata2, err_avg, outdir, outbase, XTickLabels2, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'age'
    csv = fullfile(csv_dir, 'socdem01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    age = d.interview_age(idx);

    Ylabel = 'Age';
    outbase = 'PredErr_vs_age';
    HCPA_scatter_PredErr_vs_other_var(err_avg, age, outdir, outbase, bhvr_cls_names, Ylabel, 1)
case 'sex'
    csv = fullfile(csv_dir, 'socdem01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    sex = d.sex(idx);

    sex = strcmp(sex, 'F');

    Xlabel = 'Sex';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = {'M', 'F'};
    outbase = 'PredErr_vs_sex';
    HCPA_violin_PredErr_vs_other_var(sex, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'site'
    csv = fullfile(csv_dir, 'ndar_subject01.txt');
    d = readtable(csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');
    site = d.site(idx);

    XTickLabels = unique(site);
    Xdata = nan(length(site), 1);
    for x = 1:length(XTickLabels)
        Xdata(strcmp(site, XTickLabels{x})) = x;
    end

    Xlabel = 'Site';
    Ylabel = 'Prediction error (abs)';
    outbase = 'PredErr_vs_site';
    HCPA_violin_PredErr_vs_other_var(Xdata, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
end

end