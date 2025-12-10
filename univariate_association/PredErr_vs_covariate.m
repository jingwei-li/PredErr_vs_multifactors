function PredErr_vs_covariate(dataset, method, cbpp_dir, list_dir, data_dir, outdir, subsample)
    % Set-up
    load(fullfile(cbpp_dir, strcat("avg_PredErr_", method, ".mat")));
    conf = readtable(fullfile(list_dir, strcat(dataset, "_conf_split.csv")), "VariableNamingRule", "preserve");
    if strcmp(dataset, "HCP-D")
        subjects = cellfun(@(x){x(1:10)}, conf.subjectkey);
        sociodemo = readtable(fullfile(data_dir, "socdem01.txt"));
        [~, ~, sociodemo_idx] = intersect(subjects, sociodemo.src_subject_id, 'stable');
        Xlabels = {'Cognition', 'Emotion Recognition'};
    elseif strcmp(dataset, "HCP")
        subjects = conf.Subject;
        sociodemo = readtable(fullfile(data_dir, "restricted_hcpya.csv"));
        [~, ~, sociodemo_idx] = intersect(subjects, sociodemo.Subject, 'stable');
        if strcmp(method, "SVR")
            Xlabels = {'Social Cognition', 'Negative / Positive Feelings', 'Emotion Recognition'};
        elseif strcmp(method, "KRR")
            Xlabels = {'Social Cognition', 'Negative / Positive Feelings', 'Emotion Recognition', ...
                'Positive Affect'};
        end
        bhvr_cls_csv = fullfile(list_dir, strcat("behavior_cls_", method, "_above0.3.csv"));
    elseif strcmp(dataset, "ABCD")
        subjects = regexprep(conf.participant_id, "sub-NDAR", "NDAR_");
        Xlabels = {'Verbal Memory', 'Cognition', 'CBCL', 'Prodromal Psychosis'};
        bhvr_cls_csv = fullfile(list_dir, strcat("behavior_cls_", method, "_above0.3.csv"));
    end
    if strcmp(dataset, "HCP") | strcmp(dataset, "ABCD")
        T = readtable(bhvr_cls_csv, "Delimiter", ",", "headerlines", 0);
        bhvr_cls_names = T.Properties.VariableNames;
    end

    %%% Euler
    label = "Euler characteristic";
    outbase = strcat("euler_", method);
    lh_euler = dlmread(fullfile(list_dir, "lh_Euler.allsub.txt"));
    rh_euler = dlmread(fullfile(list_dir, "rh_Euler.allsub.txt"));
    covar = (lh_euler + rh_euler) / 2;

    % For HCP-D and ABCD, center within each site
    % Make sure all values are >=1 for log-transform
    if strcmp(dataset, "HCP-D")
        site = conf.site_Harvard + 2 * conf.site_UCLA + 3 * conf.site_UMinn + 4 * conf.site_WashU;
        site = arrayfun(@num2str, site, "UniformOutput", 0);
    elseif strcmp(dataset, "ABCD")
        site = conf.site_id_l;
    end
    if strcmp(dataset, "HCP-D") | strcmp(dataset, "ABCD")
        label = "Euler characterisitc (centered per site)";
        sites = unique(site);
        euler_proc = zeros(size(covar));
        for s = 1:length(sites)
            euler_site = covar(strcmp(site, sites{s}));
            euler_proc(strcmp(site, sites{s})) = euler_site - median(euler_site);
        end
        covar = -(euler_proc - max(euler_proc)) + 1;
    else
        covar = -covar + 1;
    end
    scatter_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label);

    % subsampling in ABCD and HCP-YA
    if strcmp(dataset, "ABCD") | strcmp(dataset, "HCP")
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, covar, "continuous", bhvr_cls_names, outbase, outdir);
        end
    end

    %%% ICV
    label = "Intracranial volume";
    outbase = strcat("ICV_", method);
    scatter_PredErr_vs_covariate(err_avg, conf.ICV, outdir, outbase, Xlabels, label);
    if strcmp(dataset, "ABCD") | strcmp(dataset, "HCP")
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, conf.ICV, "continuous", bhvr_cls_names, outbase, outdir);
        end
    end

    %%% FD
    label = "Framewise displacement";
    outbase = strcat("FD_", method);
    scatter_PredErr_vs_covariate(err_avg, conf.FD, outdir, outbase, Xlabels, label);
    if strcmp(dataset, "ABCD") | strcmp(dataset, "HCP")
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, conf.FD, "continuous", bhvr_cls_names, outbase, outdir);
        end
    end

    %%% Age
    label = "Age";
    outbase = strcat("age_", method);
    if strcmp(dataset, "HCP-D") | strcmp(dataset, "ABCD")
        covar = conf.interview_age;
    elseif strcmp(dataset, "HCP")
        covar = conf.Age_in_Yrs;
    end
    scatter_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label);
    if strcmp(dataset, "ABCD") | strcmp(dataset, "HCP")
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, covar, "continuous", bhvr_cls_names, outbase, outdir);
        end
    end

    %%% Sex/gender
    label = "Sex/gender";
    outbase = strcat("sex_", method);
    if strcmp(dataset, "HCP-D") | strcmp(dataset, "ABCD")
        covar = conf.sex_F;
    elseif strcmp(dataset, "HCP")
        covar = conf.Gender_F;
    end
    XTickLabel = {"M", "F"};
    violin_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label, XTickLabel);
    if strcmp(dataset, "ABCD") | strcmp(dataset, "HCP")
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, covar, "categorical", bhvr_cls_names, outbase, outdir);
        end
    end

    %%% Ethnicity/race
    label = "Ethnicity/race";
    outbase = strcat("race_", method);
    if strcmp(dataset, "HCP-D")
        % Check later if we should remove single-occurrence data points
        covar = sociodemo.race(sociodemo_idx);
        idx = cellfun(@isempty, covar);
        covar{idx} = 'Unknown or not reported';
        XTickLabel = unique(covar);
    elseif strcmp(dataset, "HCP")
        covar = sociodemo.Race(sociodemo_idx);
        XTickLabel = unique(covar);
    elseif strcmp(dataset, "ABCD")
        race = readtable(fullfile(data_dir, "acspsw03.txt"));
        [~, ~, idx] = intersect(subjects, race.src_subject_id, 'stable');
        covar = race.race_ethnicity(idx);
        XTickLabel = {'White', 'Black', 'Hispanic', 'Asian', 'Other'};
    end

    if strcmp(dataset, "HCP-D") | strcmp(dataset, "HCP")
        race = nan(length(covar), 1);
        for i = 1:length(XTickLabel)
            race(strcmp(covar, XTickLabel{i})) = i;
        end
        covar = race;
    end
    violin_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label, XTickLabel); 

    if strcmp(dataset, "ABCD") | strcmp(dataset, "HCP")
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, covar, "categorical", bhvr_cls_names, outbase, outdir);
        end
    end

    %%% (Parent) education
    if strcmp(dataset, "HCP-D")
        label = "Education level";
        outbase = strcat("educ_", method);
        XTickLabel = {'1ST to 3RD' ; '4TH to 6TH' ; '7TH to 9TH' ; ...
            '10TH to 12TH' ; 'HIGH SCHOOL GRADUATE' ; 'SOME COLLEGE, NO DEGREE' ; ...
            'ASSOCIATE DEGREE' ;  'BACHELOR''S DEGREE'};
        covar = conf.("education_2ND_GRADE;") + conf.("education_3RD_GRADE;") ...;
            + 2 * (conf.("education_4TH_GRADE;") + conf.("education_5TH_GRADE;") ...
            + conf.("education_6TH_GRADE;")) ...
            + 3 * (conf.("education_7TH_GRADE;") + conf.("education_8TH_GRADE;") ...
            + conf.("education_9TH_GRADE;")) ...
            + 4 * (conf.("education_10TH_GRADE;") + conf.("education_11TH_GRADE;") ...
            + conf.("education_12TH_GRADE") + conf.("education_12TH_GRADE_NO_DIPLOMA;")) ...
            + 5 * conf.("education_HIGH_SCHOOL_GRADUATE;") ...
            + 6 * conf.("education_SOME_COLLEGE_NO_DEGREE;") ...
            + 7 * (conf.("education_ASSOCIATE_DEGREE:_ACADEMIC_PROGRAM;") ...
            + conf.("education_ASSOCIATE_DEGREE:_OCCUPATIONAL_TECHNICAL_OR_VOCATIONA")) ...
            + 8 * conf.("education_BACHELOR'S_DEGREE_(EXAMPLE:_BA_AB_BS_BBA);");
        violin_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label, XTickLabel);

    elseif strcmp(dataset, "HCP")
        label = "Education in years";
        outbase = strcat("educ_", method);
        XTickLabel = {"11", "12", "13", "14", "15", "16", "17"};
        covar = conf.("Educ_11.0") + 2 * conf.("Educ_12.0") + 3 * conf.("Educ_13.0") ...
            + 4 * conf.("Educ_14.0") + 5 * conf.("Educ_15.0") + 6 * conf.("Educ_16.0") ...
            + 7 * conf.("Educ_17.0");
        violin_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label, XTickLabel);
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, covar, "categorical", bhvr_cls_names, outbase, outdir);
        end

    elseif strcmp(dataset, "ABCD")
        label = "Parent's degree";
        XTickLabel = {'Never/Kindergrarten', 'Grade 1-5', 'Grade 6-8', 'Grade 9-12', ...
            'High school diploma, GED, or equvalent', 'Some college', 'Associate degree', ...
            'Bachelor''s degree', 'Master''s degree', 'Professional School degree', ...
            'Doctoral degree'};
        % Remember to check availability later
        outbase = strcat("p1educ_", method);
        covar = 1 * (conf.("prnt_ed_1.0") + conf.("prnt_ed_3.0") + conf.("prnt_ed_4.0") ...
            + conf.("prnt_ed_5.0")) ...
            + 2 * (conf.("prnt_ed_6.0") + conf.("prnt_ed_7.0") + conf.("prnt_ed_8.0")) ...
            + 3 * (conf.("prnt_ed_9.0") + conf.("prnt_ed_10.0") + conf.("prnt_ed_11.0") ...
            + conf.("prnt_ed_12.0")) ...
            + 4 * (conf.("prnt_ed_13.0") + conf.("prnt_ed_14.0")) ...
            + 5 * conf.("prnt_ed_15.0") ...
            + 6 * (conf.("prnt_ed_16.0") + conf.("prnt_ed_17.0")) ...
            + 7 * conf.("prnt_ed_18.0") + 8 * conf.("prnt_ed_19.0") ...
            + 9 * conf.("prnt_ed_20.0") + 10 * conf.("prnt_ed_21.0");
        violin_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label, XTickLabel);
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, covar, "categorical", bhvr_cls_names, outbase, outdir);
        end

        outbase = strcat("p2educ_", method);
        covar = conf.("prtnr_ed_0.0") ...
            + 1 * (conf.("prtnr_ed_1.0") + conf.("prtnr_ed_3.0") + conf.("prtnr_ed_4.0") ...
            + conf.("prtnr_ed_5.0")) ...
            + 2 * (conf.("prtnr_ed_6.0") + conf.("prtnr_ed_7.0") + conf.("prtnr_ed_8.0")) ...
            + 3 * (conf.("prtnr_ed_9.0") + conf.("prtnr_ed_10.0") + conf.("prtnr_ed_11.0") ...
            + conf.("prtnr_ed_12.0")) ...
            + 4 * (conf.("prtnr_ed_13.0") + conf.("prtnr_ed_14.0")) ...
            + 5 * conf.("prtnr_ed_15.0") ...
            + 6 * (conf.("prtnr_ed_16.0") + conf.("prtnr_ed_17.0")) ...
            + 7 * conf.("prtnr_ed_18.0") + 8 * conf.("prtnr_ed_19.0") ...
            + 9 * conf.("prtnr_ed_20.0") + 10 * conf.("prtnr_ed_21.0");
        violin_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label, XTickLabel);
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, covar, "categorical", bhvr_cls_names, outbase, outdir);
        end
    end

    %%% Household income
    label = "Household income";
    outbase = strcat("income_", method);
    if strcmp(dataset, "HCP-D")
        covar = sociodemo.annual_fam_inc(sociodemo_idx);
        covar(covar == -999999) = nan;
        covar = covar + 1; % avoid -Inf from log-transformation
        scatter_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label);

    elseif strcmp(dataset, "HCP")
        XTickLabel = {'<$10,000', '10K-19,999', '20K-29,999', '30K-39,999', '40K-49,999', ...
            '50K-74,999', '75K-99,999', '>=100,000'};
        covar = sociodemo.SSAGA_Income(sociodemo_idx);
        violin_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label, XTickLabel);

    elseif strcmp(dataset, "ABCD")
        XTickLabel = {'Refuse ans', '<$5k', '$5k-12k', '$12k-16k', '$16k-25k', ...
            '$25k-35k', '$35k-50k', '$50k-75k', '$75k-100k', '$100k-200k', '>=$200k'};
        income = readtable(fullfile(data_dir, "pdem02.txt"));
        [~, ~, idx] = intersect(subjects, income.src_subject_id, 'stable');
        covar = income.demo_comb_income_v2(idx);
        covar(covar == 999) = nan;
        covar(covar == 777) = 0; % Refuse to answer
        violin_PredErr_vs_covariate(err_avg, covar, outdir, outbase, Xlabels, label, XTickLabel);
    end

    if strcmp(dataset, "ABCD") | strcmp(dataset, "HCP")
        if subsample == 1
            subsample_PredErr_vs_covariate(err_avg, covar, "categorical", bhvr_cls_names, outbase, outdir);
        end
    end
end
