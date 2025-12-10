function covariate_association(dataset, list_dir, data_dir, outdir)
    % Set-up
    conf = readtable(fullfile(list_dir, strcat(dataset, "_conf_split.csv")), "VariableNamingRule", "preserve");
    if strcmp(dataset, "HCP-D")
        subjects = cellfun(@(x){x(1:10)}, conf.subjectkey);
        sociodemo = readtable(fullfile(data_dir, "socdem01.txt"));
        [~, ~, sociodemo_idx] = intersect(subjects, sociodemo.src_subject_id, 'stable');
    elseif strcmp(dataset, "HCP")
        subjects = conf.Subject;
        sociodemo = readtable(fullfile(data_dir, "restricted_hcpya.csv"));
        [~, ~, sociodemo_idx] = intersect(subjects, sociodemo.Subject, 'stable');
    elseif strcmp(dataset, "ABCD")
        subjects = regexprep(conf.participant_id, "sub-NDAR", "NDAR_");
    end

    % Euler, ICV, FD
    lh_euler = dlmread(fullfile(list_dir, "lh_Euler.allsub.txt"));
    rh_euler = dlmread(fullfile(list_dir, "rh_Euler.allsub.txt"));
    euler = (lh_euler + rh_euler) / 2;
    ICV = conf.ICV;
    FD = conf.FD;

    % Site, (parent) education, ethnicity/race, age, sex, household income
    if strcmp(dataset, "HCP-D")
        site = conf.site_Harvard + 2 * conf.site_UCLA + 3 * conf.site_UMinn + 4 * conf.site_WashU;
        site = arrayfun(@num2str, site, "UniformOutput", 0);

        race = sociodemo.race(sociodemo_idx);
        idx = cellfun(@isempty, race);
        race{idx} = 'Unknown or not reported';

        age = conf.interview_age;
        sex = conf.sex_F;

        income = sociodemo.annual_fam_inc(sociodemo_idx);
        income(income == -999999) = nan;

        educ_num = conf.("education_2ND_GRADE;") + conf.("education_3RD_GRADE;") ...;
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
        site = sociodemo.Family_ID(sociodemo_idx); % family id for cross-validation
        race = sociodemo.Race(sociodemo_idx);
        age = conf.Age_in_Yrs;
        sex = conf.Gender_F;
        income = sociodemo.SSAGA_Income(sociodemo_idx);

        educ_num = conf.("Educ_11.0") + 2 * conf.("Educ_12.0") + 3 * conf.("Educ_13.0") ...
            + 4 * conf.("Educ_14.0") + 5 * conf.("Educ_15.0") + 6 * conf.("Educ_16.0") ...
            + 7 * conf.("Educ_17.0");

    elseif strcmp(dataset, "ABCD")
        site = conf.site_id_l;
        age = conf.interview_age;
        sex = conf.sex_F;

        race = readtable(fullfile(data_dir, "acspsw03.txt"));
        [~, ~, idx] = intersect(subjects, race.src_subject_id, 'stable');
        race = cellfun(@num2str, num2cell(race.race_ethnicity(idx)), 'UniformOutput', false);

        income = readtable(fullfile(data_dir, "pdem02.txt"));
        [~, ~, idx] = intersect(subjects, income.src_subject_id, 'stable');
        income = income.demo_comb_income_v2(idx);
        income(income == 999) = nan;
        income(income == 777) = 0; % Refuse to answer

        educ_num = 1 * (conf.("prnt_ed_1.0") + conf.("prnt_ed_3.0") + conf.("prnt_ed_4.0") ...
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

    
    % Correlation between continuous variables
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

    % Cramer's V between categorical variables
    % (education, ethnicity, sex, family income)
    categoric.CramerV = ones(4,4);
    categoric.names = {'Education', 'Ethnicity', 'Sex', 'Income'};

    categoric.CramerV(1,2) = CramerV(outdir, cellstr(num2str(educ_num)), race);
    categoric.CramerV(2,1) = categoric.CramerV(1,2);
    categoric.CramerV(1,3) = CramerV(outdir, cellstr(num2str(educ_num)), cellstr(num2str(sex)));
    categoric.CramerV(3,1) = categoric.CramerV(1,3);
    categoric.CramerV(1,4) = CramerV(outdir, cellstr(num2str(educ_num)), cellstr(num2str(income)));
    categoric.CramerV(4,1) = categoric.CramerV(1,4);
    categoric.CramerV(2,3) = CramerV(outdir, race, cellstr(num2str(sex)));
    categoric.CramerV(3,2) = categoric.CramerV(2,3);
    categoric.CramerV(2,4) = CramerV(outdir, race, cellstr(num2str(income)));
    categoric.CramerV(4,2) = categoric.CramerV(2,4);
    categoric.CramerV(3,4) = CramerV(outdir, cellstr(num2str(sex)), cellstr(num2str(income)));
    categoric.CramerV(4,3) = categoric.CramerV(3,4);

    % Logistic regression between a continuous variable and a categorical variable
    cont_cate.acc = nan(4,4);
    cont_cate.names1 = {'Euler', 'ICV', 'FD', 'Age'};
    cont_cate.names2 = {'Education', 'Ethnicity', 'Sex', 'Income'};

    % use Euler characteristic to predict (education, ethnicity, sex, family income)
    idx = isnan(euler) | isnan(educ_num) | cellfun(@isempty, site);
    cont_cate.acc(1,1) = LogisticReg(outdir, euler(~idx), cellstr(num2str(educ_num(~idx))), site(~idx));
    idx = isnan(euler) | cellfun(@isempty, race) | cellfun(@isempty, site);
    cont_cate.acc(1,2) = LogisticReg(outdir, euler(~idx), race(~idx), site(~idx));
    idx = isnan(euler) | isnan(sex) | cellfun(@isempty, site);
    cont_cate.acc(1,3) = LogisticReg(outdir, euler(~idx), cellstr(num2str(sex(~idx))), site(~idx));
    idx = isnan(euler) | isnan(income) | cellfun(@isempty, site);
    cont_cate.acc(1,4) = LogisticReg(outdir, euler(~idx), cellstr(num2str(income(~idx))), site(~idx));

    % use ICV to predict (education, ethnicity, sex, family income)
    idx = isnan(ICV) | isnan(educ_num) | cellfun(@isempty, site);
    cont_cate.acc(2,1) = LogisticReg(outdir, ICV(~idx), cellstr(num2str(educ_num(~idx))), site(~idx));
    idx = isnan(ICV) | cellfun(@isempty, race) | cellfun(@isempty, site);
    cont_cate.acc(2,2) = LogisticReg(outdir, ICV(~idx), race(~idx), site(~idx));
    idx = isnan(ICV) | isnan(sex)  | cellfun(@isempty, site);
    cont_cate.acc(2,3) = LogisticReg(outdir, ICV(~idx), cellstr(num2str(sex(~idx))), site(~idx));
    idx = isnan(ICV) | isnan(income) | cellfun(@isempty, site);
    cont_cate.acc(2,4) = LogisticReg(outdir, ICV(~idx), cellstr(num2str(income(~idx))), site(~idx));

    % use FD to predict (education, ethnicity, sex, family income)
    idx = isnan(FD) | isnan(educ_num) | cellfun(@isempty, site);
    cont_cate.acc(3,1) = LogisticReg(outdir, FD(~idx), cellstr(num2str(educ_num(~idx))), site(~idx));
    idx = isnan(FD) | cellfun(@isempty, race) | cellfun(@isempty, site);
    cont_cate.acc(3,2) = LogisticReg(outdir, FD(~idx), race(~idx), site(~idx));
    idx = isnan(FD) | isnan(sex)  | cellfun(@isempty, site);
    cont_cate.acc(3,3) = LogisticReg(outdir, FD(~idx), cellstr(num2str(sex(~idx))), site(~idx));
    idx = isnan(FD) | isnan(income) | cellfun(@isempty, site);
    cont_cate.acc(3,4) = LogisticReg(outdir, FD(~idx), cellstr(num2str(income(~idx))), site(~idx));

    % use age to predict (education, ethnicity, sex, family income)
    idx = isnan(age) | isnan(educ_num) | cellfun(@isempty, site);
    cont_cate.acc(4,1) = LogisticReg(outdir, age(~idx), cellstr(num2str(educ_num(~idx))), site(~idx));
    idx = isnan(age) | cellfun(@isempty, race) | cellfun(@isempty, site);
    cont_cate.acc(4,2) = LogisticReg(outdir, age(~idx), race(~idx), site(~idx));
    idx = isnan(age) | isnan(sex)  | cellfun(@isempty, site);
    cont_cate.acc(4,3) = LogisticReg(outdir, age(~idx), cellstr(num2str(sex(~idx))), site(~idx));
    idx = isnan(age) | isnan(income) | cellfun(@isempty, site);
    cont_cate.acc(4,4) = LogisticReg(outdir, age(~idx), cellstr(num2str(income(~idx))), site(~idx));

    save(fullfile(outdir, 'covar_assoc.mat'), 'continuous', 'categoric', 'cont_cate');

end