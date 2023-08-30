function ABCD_PredErr_vs_sociodemograph(subj_ls, avgPredErr, outdir, bhvr_cls_names, metric)

% ABCD_PredErr_vs_sociodemograph(subj_ls, avgPredErr, outdir, bhvr_cls_names, metric)
%
% Inputs:
%   - subj_ls
%     Full path to the subject list. The subjects should be corresponded to the prediction
%     errors provided by `avgPredErr`.
%
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%
%   - outdir
%     Full path to output directory.
%
%   - bhvr_cls_names
%     A cell array contains the subtitles for each subplot which corresponds to a behavioral cluster. 
%     The number of entries in `bhvr_cls_names` should be the same with the number of fields in the `err_arg` 
%     structure passed in by `avgPredErr` variable.
%     e.g. bhvr_cls_names = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
%
%   - metric
%     Choose from 'handedness', 'prt_educ', 'income', 'address_size', 'ethnicity', 'age', and 'sex'.

[subjects, nsub] = CBIG_text2cell(subj_ls);
if(~strcmpi(metric, 'ICV'))
    for i = 1:nsub
        subjects{i} = [subjects{i}(1:4) '_' subjects{i}(5:end)];
    end
end

load(avgPredErr)
csv_dir = '/data/project/AfrAm_FuncParc/data/datasets/inm7_superds/original/abcd/phenotype/phenotype';
start_dir = pwd;

subj_hdr = 'subjectkey';
event_hdr = 'eventname';

if(~strcmpi(metric, 'site'))
    site_relpath = 'abcd_lt01.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', site_relpath));
    cd(start_dir)
    site_csv = fullfile(csv_dir, site_relpath);
    d_site = readtable(site_csv);

    site_base_event = strcmp(d_site.(event_hdr), 'baseline_year_1_arm_1');
    site = cell(nsub,1);
    for s = 1:nsub
        tmp_idx = strcmp(d_site.(subj_hdr), subjects{s});
        if(any(tmp_idx==1))
            tmp_idx = tmp_idx & site_base_event;
            site(s) = d_site.site_id_l(tmp_idx);
        end
    end
    uq_st = unique(site);
end


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

    Xlabel = 'Handedness';
    Ylabel = 'Prediction error (abs)';
    XTickLabels = {'R', 'L'};
    outbase = 'PredErr_vs_handedness';
    ABCD_violin_PredErr_vs_other_var(handedness, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
case 'prt_educ'
    educ_relpath = 'pdem02.txt';
    cd(csv_dir)
    system(sprintf('datalad get -s inm7-storage %s', educ_relpath));
    cd(start_dir)
    educ_csv = fullfile(csv_dir, educ_relpath);
    d = readtable(educ_csv);

    %dummies = zeros(length(site), length(uq_st));
    %for s = 1:length(uq_st)
    %    dummies(:,s) = double(strcmp(site, uq_st{s})).*s;
    %end
    %dummies = cellstr(num2str(sum(dummies,2)));

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

    XTickLabels = {'Never/Kindergrarten', 'Grade 1-5', 'Grade 6-8', 'Grade 9-12', ...
        'High school diploma, GED, or equvalent', 'Some college', 'Associate degree', ...
        'Bachelor''s degree', 'Master''s degree', 'Professional School degree', 'Doctoral degree'};


    % plot parent 1's education
    Xlabel = peduc_colloquial{1};
    Ylabel = 'Prediction error (abs)';
    outbase = 'PredErr_vs_Prt1_Educ';
    ABCD_violin_PredErr_vs_other_var(peduc(:,1), err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
    %outbase = 'PredErr_vs_Prt1_Educ_site';
    %ABCD_violin_PredErr_vs_other_var(peduc(:,1), err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1, dummies)

    err_names = fieldnames(err_avg);
    for s = 1:length(uq_st)
        site_idx = strcmp(site, uq_st{s});
        if(length(find(site_idx==1)) > 300)
            new_err = err_avg;
            for c = 1:length(err_names);
                new_err.(err_names{c}) = err_avg.(err_names{c})(site_idx);
            end
            outbase = ['PredErr_vs_Prt1_Educ_' uq_st{s}];
            ABCD_violin_PredErr_vs_other_var(peduc(site_idx,1), new_err, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
        end
    end

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

    % plot stacked barplot representing the roles of parent 1 associated with each level of education.
    legends = {'Biological Mother', 'Biological Father', 'Adoptive Parent', 'Custodial Parent', 'Other'};
    Xlabel = peduc_colloquial{1};
    Ylabel = 'Relationship with child';
    outbase = 'stack_Prt1Relationship_by_educ';
    ABCD_stack_bar(peduc(:,1), prim, outdir, outbase, XTickLabels, Xlabel, Ylabel, legends)

    % plot parent 1's education when he/she is the biological mother
    peduc_bm = peduc(:,1);
    peduc_bm(prim ~= 1) = nan;
    Xlabel = 'Parent 1 (biological mother)''s education';
    outbase = 'PredErr_vs_Prt1_Educ_BioMother';
    ABCD_violin_PredErr_vs_other_var(peduc_bm, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    % plot parent 2's education
    Xlabel = peduc_colloquial{2};
    Ylabel = 'Prediction error (abs)';
    outbase = 'PredErr_vs_Prt2_Educ';
    ABCD_violin_PredErr_vs_other_var(peduc(:,2), err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
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

    XTickLabels = {'Refuse ans', '<$5k', '$5k-12k', '$12k-16k', '$16k-25k', ...
        '$25k-35k', '$35k-50k', '$50k-75k', '$75k-100k', '$100k-200k', '>=$200k'};
    Xlabel = 'Household income';
    Ylabel = 'Prediction error (abs)';
    outbase = 'PredErr_vs_income';
    ABCD_violin_PredErr_vs_other_var(income, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    err_names = fieldnames(err_avg);
    for s = 1:length(uq_st)
        site_idx = strcmp(site, uq_st{s});
        if(length(find(site_idx==1)) > 300)
            new_err = err_avg;
            for c = 1:length(err_names);
                new_err.(err_names{c}) = err_avg.(err_names{c})(site_idx);
            end
            outbase = ['PredErr_vs_income_' uq_st{s}];
            ABCD_violin_PredErr_vs_other_var(income(site_idx), new_err, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
        end
    end
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
    XTickLabels = arrayfun(@num2str, unique(add_size(~isnan(add_size))), 'UniformOutput', 0);
    Xlabel = '#People living at parent''s address';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_AddrSize';
    ABCD_violin_PredErr_vs_other_var(add_size, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
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
    
    XTickLabels = {'White', 'Black', 'Hispanic', 'Asian', 'Other'};
    Xlabel = 'Ethnicity';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_ethnicity';
    ABCD_violin_PredErr_vs_other_var(ethnicity, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    err_names = fieldnames(err_avg);
    for s = 1:length(uq_st)
        site_idx = strcmp(site, uq_st{s});
        if(length(find(site_idx==1)) > 300)
            new_err = err_avg;
            for c = 1:length(err_names);
                new_err.(err_names{c}) = err_avg.(err_names{c})(site_idx);
            end
            outbase = ['PredErr_vs_ethnicity_' uq_st{s}];
            ABCD_violin_PredErr_vs_other_var(ethnicity(site_idx), new_err, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
        end
    end
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

    Ylabel = 'Age';
    outbase = 'PredErr_vs_age_scatter';
    ABCD_scatter_PredErr_vs_other_var(err_avg, age, outdir, outbase, bhvr_cls_names, Ylabel, 1)

    XTickLabels = arrayfun(@num2str, unique(age(~isnan(age))), 'UniformOutput', 0);
    Xlabel = 'Age';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_age';
    ABCD_violin_PredErr_vs_other_var(age, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    dummies = zeros(length(site), length(uq_st));
    for s = 1:length(uq_st)
        dummies(:,s) = double(strcmp(site, uq_st{s}));
    end
    [resid, ~, ~, ~] = CBIG_glm_regress_matrix(age, dummies, 1, []);
    Xlabel = 'Age';
    outbase = 'PredErr_vs_age_siteReg_scatter';
    ABCD_scatter_PredErr_vs_other_var(err_avg, resid, outdir, outbase, bhvr_cls_names, Ylabel, 1)
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

    XTickLabels = {'M', 'F'};
    Xlabel = 'Sex';
    Ylabel = 'Prediction error(abs)';
    outbase = 'PredErr_vs_sex';
    ABCD_violin_PredErr_vs_other_var(sex, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    err_names = fieldnames(err_avg);
    for s = 1:length(uq_st)
        site_idx = strcmp(site, uq_st{s});
        if(length(find(site_idx==1)) > 300)
            new_err = err_avg;
            for c = 1:length(err_names);
                new_err.(err_names{c}) = err_avg.(err_names{c})(site_idx);
            end
            outbase = ['PredErr_vs_sex_' uq_st{s}];
            ABCD_violin_PredErr_vs_other_var(sex(site_idx), new_err, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
        end
    end
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

    Xlabel = 'Site';
    Ylabel = 'Prediction error (abs)';
    outbase = 'PredErr_vs_site';
    ABCD_violin_PredErr_vs_other_var(Xdata, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)

    Xdata2 = nan(length(site), 1);
    XTickLabels2 = XTickLabels
    for x = 1:length(XTickLabels)
        if(length(find(strcmp(site, XTickLabels{x}))) > 1)
            Xdata2(strcmp(site, XTickLabels{x})) = x;
        else
            XTickLabels2 = setdiff(XTickLabels2, XTickLabels(x));
        end
    end
    outbase = 'PredErr_vs_site_removeSingleDataPoint';
    ABCD_violin_PredErr_vs_other_var(Xdata2, err_avg, outdir, outbase, XTickLabels, Xlabel, Ylabel, bhvr_cls_names, 1)
otherwise
    error('Unknown metric: %s', metric)
end



end


function ABCD_stack_bar(Xdata, Ydata, outdir, outbase, XTickLabels, Xlabel, Ylabel, legends)

% ABCD_stack_bar(Xdata, Ydata, outdir, outbase, XTickLabels, Xlabel, Ylabel, legends)
%
% 

addpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

colors = [172, 146, 235; ...
          79, 193, 232; ...
          160, 213, 104; ...
          255, 206, 84; ...
          237, 85, 100]./255;

idx = ~isnan(Xdata) & ~isnan(Ydata);
Xclasses = unique(Xdata(idx));
Yclasses = unique(Ydata(idx));
M = zeros(length(Xclasses), length(Yclasses));
for i = 1:length(Xclasses)
    for j = 1:length(Yclasses)
        M(i,j) = length(find(Xdata==Xclasses(i) & Ydata==Yclasses(j)));
    end
end

f = figure;
if(length(Xclasses)<=5)
    set(gcf, 'position', [0 0 600 525])
else
    set(gcf, 'position', [0 0 1350 525])
end
bar(M,'stacked')
xlabel(Xlabel, 'fontsize', 12);
ylabel(Ylabel, 'fontsize', 12);
legend(legends, 'fontsize', 12);
set(gca, 'XTickLabel', XTickLabels, 'fontsize', 12)
if(length(Xclasses) > 5)
    rotateXLabels( gca(), 30 );
end
set(gca, 'tickdir', 'out', 'box', 'off');

if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
outname = fullfile(outdir, [outbase]);
export_fig(outname, '-png', '-nofontswap', '-a1');
set(gcf, 'color', 'w')
hgexport(f, outname)
close

rmpath(genpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'fig_util')))

end
