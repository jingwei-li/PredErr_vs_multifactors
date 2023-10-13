function ABCD_PredErr_vs_sociodemograph_subsample(subj_ls, avgPredErr, bhvr_cls_names, outdir, s_size, repeats, metric)

% ABCD_PredErr_vs_sociodemograph_subsample(subj_ls, avgPredErr, bhvr_cls_names, outdir, s_size, repeats, metric)
%
%   - subj_ls
%     Full path to the subject list. The subjects should be corresponded to the prediction
%     errors provided by `avgPredErr`.
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - bhvr_cls_names
%     A cell array contains the X-axis names for each behavioral cluster. The number of entries 
%     in `bhvr_cls_names` should be the same with the number of fields in the `asso` structure.
%     Example: bhvr_cls_names = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
%   - outdir
%     Full path to output directory.
%   - s_size
%     Size of each subsample.
%   - repeats
%     Number of repetitions of subsampling.
%   - metric
%     Choose from 'handedness', 'prt_educ', 'income', 'address_size', 'ethnicity', 'age', 'sex', and 'site'.
%

addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))

[subjects, nsub] = CBIG_text2cell(subj_ls);
if(~strcmpi(metric, 'ICV'))
    for i = 1:nsub
        subjects{i} = [subjects{i}(1:4) '_' subjects{i}(5:end)];
    end
end

load(avgPredErr)
csv_dir = '/data/project/predict_stereotype/datasets/inm7_superds/original/abcd/phenotype/phenotype';
start_dir = pwd;

subj_hdr = 'subjectkey';
event_hdr = 'eventname';

switch metric
case 'handedness'
    hand_relpath = 'abcd_ehis01.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', hand_relpath));
    cd(start_dir)
    hand_csv = fullfile(csv_dir, hand_relpath);
    d = readtable(hand_csv);
    [~, ~, idx] = intersect(subjects, d.(subj_hdr), 'stable');

    % 1=right handed; 2=left handed; 3=mixed handed
    handedness = d.ehi_y_ss_scoreb(idx);
    %handedness = cellfun(@str2num, handedness);  % this line is necessary for older matlab versions
    handedness(handedness==3) = nan;

    outmat = fullfile(outdir, 'PredErr_vs_handedness.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, handedness, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_handedness');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'prt_educ'
    educ_relpath = 'pdem02.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', educ_relpath));
    cd(start_dir)
    educ_csv = fullfile(csv_dir, educ_relpath);
    d = readtable(educ_csv);

    peduc_hdr = {'demo_prnt_ed_v2', 'demo_prtnr_ed_v2'};
    peduc_colloquial = {'Parent 1''s degree', 'Parent 2''s degree'};
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
    peduc_read = [];
    for c = 1:length(peduc_hdr)
        curr_peduc = d.(peduc_hdr{c});
        peduc_read = [peduc_read curr_peduc];
    end

    % select only the rows corresponding to required subjects
    %peduc = cell(nsub, length(peduc_hdr));  % for older versions of matlab
    peduc = nan(nsub, length(peduc_hdr));
    for s = 1:nsub
        tmp_idx = strcmp(d.(subj_hdr), subjects{s});
        if(any(tmp_idx==1))
            tmp_idx = tmp_idx & base_event;
            peduc(s,:) = peduc_read(tmp_idx,:);
        end
    end
    % the following three commented lines are for older versions of matlab
    %empty_idx = cellfun(@isempty, peduc);
    %peduc(empty_idx) = {'NaN'};
    %peduc = cellfun(@str2num, peduc);

    % convert 777 & 999 to nan; 1-5 to the median 3 ("Grade 1-5"); 6-8 to the median 7 ("Grade 6-8"); 
    % 9-12 to the median 10.5 ("Grade 9-12"); 13-14 to the median 13.5 ("High school diploma, GED, or equvalent"); 
    % 16-17 to the median 16.5 ("Associate degree")
    peduc(peduc>25) = nan;
    peduc(peduc>=1 & peduc<=5) = 3;
    peduc(peduc>=6 & peduc<=8) = 7;
    peduc(peduc>=9 & peduc<=12) = 10.5;
    peduc(peduc>=13 & peduc<=14) = 13.5;
    peduc(peduc>=16 & peduc<=17) = 16.5;

    %% plot parent 1's education
    outmat = fullfile(outdir, 'PredErr_vs_Prt1_Educ.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, peduc(:,1), s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_Prt1_Educ');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)

    %% who is the parent 1?
    % 1 = Childs Biological Mother; 2 = Childs Biological Father; 3 = Adoptive Parent; 4 = Childs Custodial Parent; 5 = Other
    prim = nan(nsub, 1);
    for s = 1:nsub
        tmp_idx = strcmp(d.(subj_hdr), subjects{s});
        if(any(tmp_idx==1))
            tmp_idx = tmp_idx & base_event;
            prim(s) = d.demo_prim(tmp_idx);
        end
    end

    % plot parent 1's education when he/she is the biological mother
    peduc_bm = peduc(:,1);
    peduc_bm(prim ~= 1) = nan;

    outmat = fullfile(outdir, 'PredErr_vs_Prt1_Educ_BioMother.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, peduc_bm, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_Prt1_Educ_BioMother');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)

    %% plot parent 2's education
    outmat = fullfile(outdir, 'PredErr_vs_Prt2_Educ.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, peduc(:,2), s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_Prt2_Educ');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'income'
    income_relpath = 'pdem02.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', income_relpath));
    cd(start_dir)
    income_csv = fullfile(csv_dir, income_relpath);
    d = readtable(income_csv);
    base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');

    income = nan(nsub,1);
    for s = 1:nsub
        tmp_idx = strcmp(d.(subj_hdr), subjects{s});
        if(any(tmp_idx==1))
            tmp_idx = tmp_idx & base_event;
            income(s) = d.demo_comb_income_v2(tmp_idx);
        end
    end
    % 1= Less than $5,000; 2=$5,000 through $11,999; 3=$12,000 through $15,999; 4=$16,000 through $24,999; 
    % 5=$25,000 through $34,999; 6=$35,000 through $49,999; 7=$50,000 through $74,999; 
    % 8= $75,000 through $99,999; 9=$100,000 through $199,999; 10=$200,000 and greater. 
    % 999 = Don't know; 777 = Refuse to answer

    % change 999 to NaN; change 777 to 0, for the convenience of plotting
    income(income==999) = NaN;
    income(income==777) = 0;

    outmat = fullfile(outdir, 'PredErr_vs_income.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, income, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_income');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'address_size'
    size_relpath = 'pdem02.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', size_relpath));
    cd(start_dir)
    size_csv = fullfile(csv_dir, size_relpath);
    d = readtable(size_csv);
    base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');

    add_size = nan(nsub,1);
    for s = 1:nsub
        tmp_idx = strcmp(d.(subj_hdr), subjects{s});
        if(any(tmp_idx==1))
            tmp_idx = tmp_idx & base_event;
            add_size(s) = d.demo_roster_v2(tmp_idx);
        end
    end

    outmat = fullfile(outdir, 'PredErr_vs_AddrSize.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, add_size, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_AddrSize');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'ethnicity'
    ethn_relpath = 'acspsw03.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', ethn_relpath));
    cd(start_dir)
    ethn_csv = fullfile(csv_dir, ethn_relpath);
    d = readtable(ethn_csv);
    base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');

    ethnicity = nan(nsub,1);
    for s = 1:nsub
        tmp_idx = strcmp(d.(subj_hdr), subjects{s});
        if(any(tmp_idx==1))
            tmp_idx = tmp_idx & base_event;
            ethnicity(s) = d.race_ethnicity(tmp_idx);
        end
    end

    outmat = fullfile(outdir, 'PredErr_vs_ethnicity.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, ethnicity, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_ethnicity');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'age'
    age_relpath = 'abcd_lt01.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', age_relpath));
    cd(start_dir)
    age_csv = fullfile(csv_dir, age_relpath);
    d = readtable(age_csv);
    base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');

    age = nan(nsub,1);
    for s = 1:nsub
        tmp_idx = strcmp(d.(subj_hdr), subjects{s});
        if(any(tmp_idx==1))
            tmp_idx = tmp_idx & base_event;
            age(s) = d.interview_age(tmp_idx);
        end
    end

    outmat = fullfile(outdir, 'PredErr_vs_age.mat');
    asso = subsample_PredErr_vs_continuous_covar(err_avg, age, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_age');
    hist_subsample_rho(asso, bhvr_cls_names, figout)
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'sex'
    sex_relpath = 'abcd_lt01.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', sex_relpath));
    cd(start_dir)
    sex_csv = fullfile(csv_dir, sex_relpath);
    d = readtable(sex_csv);
    base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');

    sex = cell(nsub,1);
    for s = 1:nsub
        tmp_idx = strcmp(d.(subj_hdr), subjects{s});
        if(any(tmp_idx==1))
            tmp_idx = tmp_idx & base_event;
            sex(s) = d.sex(tmp_idx);
        end
    end
    sex = strcmp(sex, 'F');

    outmat = fullfile(outdir, 'PredErr_vs_sex.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, sex, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_sex');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'site'
    site_relpath = 'abcd_lt01.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', site_relpath));
    cd(start_dir)
    site_csv = fullfile(csv_dir, site_relpath);
    d = readtable(site_csv);
    base_event = strcmp(d.(event_hdr), 'baseline_year_1_arm_1');

    site = cell(nsub,1);
    for s = 1:nsub
        tmp_idx = strcmp(d.(subj_hdr), subjects{s});
        if(any(tmp_idx==1))
            tmp_idx = tmp_idx & base_event;
            site(s) = d.site_id_l(tmp_idx);
        end
    end

    XTickLabels = unique(site);
    Xdata = nan(length(site), 1);
    for x = 1:length(XTickLabels)
        Xdata(strcmp(site, XTickLabels{x})) = x;
    end

    outmat = fullfile(outdir, 'PredErr_vs_site.mat');
    asso = subsample_PredErr_vs_categorical_covar(err_avg, Xdata, s_size, repeats);
    save(outmat, 'asso')

    figout = fullfile(outdir, 'PredErr_vs_site');
    shade_subsample_effect(asso, bhvr_cls_names, [figout '_Effect'])
    hist_subsample_pval(asso, bhvr_cls_names, figout)
otherwise
    error('Unknown metric: %s', metric)
end

rmpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))
    
end