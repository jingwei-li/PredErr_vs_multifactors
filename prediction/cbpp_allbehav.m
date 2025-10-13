function cbpp_allbehav(colloq_txt, data_dir, dataset, fc_dir, out_dir, fam_file)
% This script runs whole-brain CBPP using combined connectivity data
%
% ARGUMENTS:
% colloq_txt   absolute path to colloquial names of behavioral measures
% data_dir     absolute path to extracted data directory
% dataset      name of dataset ('HCP-D', 'HCP')
% fc_dir       absolute path to FC data directory
% out_dir      absolute path to output directory
% fam_file     absolute path to .mat file containing HCP family IDs
%
% OUTPUT:
% 1 output file for each behavioral measure in colloq_txt in out_dir containing the prediction 
% performance
%
% Jianxiao Wu, last edited on 03-Mar-2025

if nargin < 5
    disp('cbpp_allbehav(colloq_txt, data_dir, dataset, fc_dir, out_dir)'); return
end

if nargin < 6
    fam_file = "/data/project/cbpp_data/cbpp_project/data/HCP_famID.mat";
end

script_dir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(fileparts(script_dir), 'external_packages', 'cbpp')));

% target variable names
colloq_names = table2array(readtable(colloq_txt, 'delimiter', ',', 'ReadVariableNames', false));
convert_fun = @(x)regexprep(x, ' +', '_');
filestems = convert_fun(colloq_names);
convert_fun = @(x)regexprep(x, '/+', '-');
filestems = convert_fun(filestems);

% confounding variable
if strcmp(dataset, "HCP-D") || strcmp(dataset, "HCP")
    conf = readtable(fullfile(data_dir, strcat(dataset, "_conf.csv")), ...
        'VariableNamingRule', 'preserve');
elseif strcmp(dataset, "ABCD")
    conf = readtable(fullfile(data_dir, strcat(dataset, "_conf_site.csv")), ...
        'VariableNamingRule', 'preserve');
end
if strcmp(dataset, "HCP-D")
    conf = removevars(conf, ['subjectkey']);
elseif strcmp(dataset, "HCP")
    conf = removevars(conf, ["Subject"]);
elseif strcmp(dataset, "ABCD")
    conf = removevars(conf, ["participant_id"]);
end
% all psychometric variables
y = readtable(fullfile(data_dir, strcat(dataset, "_y.csv")), 'VariableNamingRule', 'preserve');

% FC data
subjects = table2array(readtable(fullfile(data_dir, "sublist_allbehavior.csv"), ...
    'ReadVariableNames', false));
fc = zeros(454, 454, length(subjects));
for sub_ind = 1:length(subjects)
    if strcmp(dataset, "HCP-D")
        fc_file = fullfile(fc_dir, num2str(subjects{sub_ind}) + "_V1_MR.h5");
    elseif strcmp(dataset, "HCP")
        fc_file = fullfile(fc_dir, num2str(subjects(sub_ind)) + ".h5");
    elseif strcmp(dataset, "ABCD")
        fc_file = fullfile(fc_dir, num2str(subjects{sub_ind}) + "_ses-baselineYear1Arm1_RSFC_S4.mat");
    end
    if strcmp(dataset, "HCP-D") || strcmp(dataset, "HCP")
        fc_sub = h5read(fc_file, "/rs_sfc_level4/block0_values");
        fc_curr = triu(ones(454), 1);
        fc_curr(fc_curr > 0) = fc_sub;
        fc(:, :, sub_ind) = fc_curr + fc_curr';
    elseif strcmp(dataset, "ABCD")
        load(fc_file);
        fc(:, :, sub_ind) = corr_mat;
    end
end
fc(isnan(fc)) = 0;

% cross-validation indices
if strcmp(dataset, "HCP-D")
    % cross-validation by site
    idx = ~cellfun(@isempty, strfind(conf.Properties.VariableNames, 'site'));
    cv_ind = table2array(conf(:,idx==1));
    cv_ind = cv_ind * [1:size(cv_ind,2)]';
    conf(:,idx) = [];   % if split folds by site, then don't need to regress site
elseif strcmp(dataset, "HCP")
    cv_ind = CVPart_HCP(10, 10, fullfile(data_dir, "sublist_allbehavior.csv"), fam_file);
elseif strcmp(dataset, "ABCD")
    % leave-3-site-out cross-validation
    idx = ~cellfun(@isempty, strfind(conf.Properties.VariableNames, 'site-cluster'));
    sites = table2array(conf(:, idx==1));
    sites_test = nchoosek(unique(sites), 3);
    cv_ind = zeros(size(sites, 1), size(sites_test, 1));
    for repeat = 1:size(sites_test, 1)
        for sub = 1:size(sites, 1)
            if ismember(sites(sub), sites_test(repeat, :))
                cv_ind(sub, repeat) = 1;
            else
                cv_ind(sub, repeat) = 0;
            end
        end
    end
    conf(:,idx) = [];   % if split folds by site, then don't need to regress site
end

options = []; options.save_weights = 0;
for i = 1:length(filestems)
    options.prefix = strcat(filestems{i}, '_SchMel4');
    y_curr = y.(colloq_names{i});
    CBPP_wholebrain(fc, y_curr, table2array(conf), cv_ind, out_dir, options);
end

options.method = "KRR"
for i = 1:length(filestems)
    options.prefix = strcat(filestems{i}, '_SchMel4');
    y_curr = y.(colloq_names{i});
    CBPP_wholebrain(fc, y_curr, table2array(conf), cv_ind, out_dir, options);
end

end
