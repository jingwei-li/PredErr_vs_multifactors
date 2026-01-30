function multivariate_association(dataset, method, cbpp_dir, list_dir, data_dir, outdir)
    % multivariate_association(dataset, list_dir, data_dir, outdir)
    %
    % Build a full GLM with all scan-related and sociodemographic covariates: Euler characteristic,
    % ICV, FD, education, family income, ethnicity, age, sex.
    % Assess the importance of each covariate by the likelihood ratio test between the full
    % model and the model without the examined covariate.

    % Set-up
    conf = readtable(fullfile(list_dir, strcat(dataset, "_conf_split.csv")), "VariableNamingRule", "preserve");
    load(fullfile(cbpp_dir, strcat("avg_PredErr_", method, ".mat")));
    T = struct2table(err_avg);
    for c = 1:length(fieldnames(err_avg))
        T = renamevars(T, strcat("class", num2str(c)), strcat("err_class", num2str(c)));
    end

    % Euler, ICV, FD
    lh_euler = dlmread(fullfile(list_dir, "lh_Euler.allsub.txt"));
    rh_euler = dlmread(fullfile(list_dir, "rh_Euler.allsub.txt"));
    euler = (lh_euler + rh_euler) / 2;
    ICV = conf.ICV;
    FD = conf.FD;

    % (Parent) education, ethnicity/race, age, sex, household income
    if strcmp(dataset, "HCP-D")
        subjects = cellfun(@(x){x(1:10)}, conf.subjectkey);
        sociodemo = readtable(fullfile(data_dir, "socdem01.txt"));
        [~, ~, sociodemo_idx] = intersect(subjects, sociodemo.src_subject_id, 'stable');
        age = conf.interview_age;
        sex = conf.sex_F;

        site = conf.site_Harvard + 2 * conf.site_UCLA + 3 * conf.site_UMinn + 4 * conf.site_WashU;
        site = arrayfun(@num2str, site, "UniformOutput", 0);
        euler = proc_euler(euler, site);

        race = sociodemo.race(sociodemo_idx);
        idx = cellfun(@isempty, race);
        race{idx} = 'Unknown or not reported';

        income = sociodemo.annual_fam_inc(sociodemo_idx);
        income(income == -999999) = nan;

        educ = conf.("education_2ND_GRADE;") + conf.("education_3RD_GRADE;") ...
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

    elseif strcmp(dataset, "HCP")
        sociodemo = readtable(fullfile(data_dir, "restricted_hcpya.csv"));
        [~, ~, sociodemo_idx] = intersect(conf.Subject, sociodemo.Subject, 'stable');
        age = conf.Age_in_Yrs;
        sex = conf.Gender_F;
        income = sociodemo.SSAGA_Income(sociodemo_idx);
        race = sociodemo.Race(sociodemo_idx);

        educ_vars = {'Educ_11.0', 'Educ_12.0', 'Educ_13.0', 'Educ_14.0', 'Educ_15.0', ...
            'Educ_16.0', 'Educ_17.0'};
        T_educ = conf(:, educ_vars);
        educ_names = {'educ_11', 'educ_12', 'educ_13', 'educ_14', 'educ_15', 'educ_16', 'educ_17'};
        T_educ = renamevars(T_educ, T_educ.Properties.VariableNames, educ_names);

    elseif strcmp(dataset, "ABCD")
        subjects = regexprep(conf.participant_id, "sub-NDAR", "NDAR_");
        age = conf.interview_age;
        sex = conf.sex_F;

        site = conf.site_id_l;
        euler = proc_euler(euler, site);

        race = readtable(fullfile(data_dir, "acspsw03.txt"));
        [~, ~, idx] = intersect(subjects, race.src_subject_id, 'stable');
        race = cellfun(@num2str, num2cell(race.race_ethnicity(idx)), 'UniformOutput', false);

        income = readtable(fullfile(data_dir, "pdem02.txt"));
        [~, ~, idx] = intersect(subjects, income.src_subject_id, 'stable');
        income = income.demo_comb_income_v2(idx);
        income(income == 999) = nan;
        income(income == 777) = 0; % Refuse to answer

        educ = 1 * (conf.("prnt_ed_1.0") + conf.("prnt_ed_3.0") + conf.("prnt_ed_4.0") ...
            + conf.("prnt_ed_5.0")) ...
            + 2 * (conf.("prnt_ed_6.0") + conf.("prnt_ed_7.0") + conf.("prnt_ed_8.0")) ...
            + 3 * (conf.("prnt_ed_9.0") + conf.("prnt_ed_10.0") + conf.("prnt_ed_11.0") ...
            + conf.("prnt_ed_12.0")) ...
            + 4 * (conf.("prnt_ed_13.0") + conf.("prnt_ed_14.0")) ...
            + 5 * conf.("prnt_ed_15.0") ...
            + 6 * (conf.("prnt_ed_16.0") + conf.("prnt_ed_17.0")) ...
            + 7 * conf.("prnt_ed_18.0") + 8 * conf.("prnt_ed_19.0") ...
            + 9 * conf.("prnt_ed_20.0") + 10 * conf.("prnt_ed_21.0");
    end

    if strcmp(dataset, "HCP-D") || strcmp(dataset, "ABCD")
        T_educ = covar_table(educ, "educ");
    end
    if strcmp(dataset, "HCP") || strcmp(dataset, "ABCD")
        T_income = covar_table(income, "income");
        T = horzcat(T, T_income);
    else
        T = addvars(T, income);
    end

    T = addvars(T, euler, ICV, FD, age, sex);
    T = horzcat(T, T_educ);
    T_race = covar_table(race, "race");
    T = horzcat(T, T_race);

    T = T(~any(ismissing(T), 2), :);
    outfile = fullfile(outdir, strcat("glm_data_", method, ".csv"));
    writetable(T, outfile);

    % call R script
    rScriptFilename = fullfile(fileparts(mfilename('fullpath')), 'glm_combine.r');
    command = sprintf('Rscript %s %s %s %s', rScriptFilename, method, outfile, outdir);
    status = system(command);
    if status == 0
        disp('R script executed successfully.');
    else
        error('Error executing R script.');
    end

end

function euler_proc = proc_euler(euler, site)
    sites = unique(site);
    euler_proc = zeros(size(euler));
    for s = 1:length(sites)
        euler_site = euler(strcmp(site, sites{s}));
        euler_proc(strcmp(site, sites{s})) = euler_site - median(euler_site);
    end
end

function T_covar = covar_table(covar, prefix)
    covar_cat = categorical(covar);
    covar_dummy = dummyvar(covar_cat);
    T_covar = array2table(covar_dummy(:, 1:end-1));
    oldnames = T_covar.Properties.VariableNames;
    newnames = categories(covar_cat);
    T_covar = renamevars(T_covar, oldnames, strcat(prefix, "_", newnames(1:end-1)));
end
