function HCPD_cbpp(target, psy_file, conf_file, sublist, fc_dir, out_dir)
% This script runs whole-brain CBPP using combined connectivity data
%
% ARGUMENTS:
% target       name of target psychometric variable to predict
% psy_file     absolute path to the .csv file containing the psychometric variables to predict
% conf_file    absolute path to the .mat file containing the confounding variables
% sublist      absolute path to custom subject list (.csv file where each line is one subject ID)
% fc_dir       absolute path to FC data directory
% out_dir   absolute path to output directory
%
% OUTPUT:
% 1 output file in the output directory containing the prediction performance
%
% Jianxiao Wu, last edited on 27-Feb-2025

if nargin ~= 6
    disp('HCPD_cbpp(target, psy_file, conf_file, sublist, fc_dir, out_dir)'); return
end

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir), 'external_packages', 'cbpp'));

% target psychometric variable
y = readtable(psy_file, 'VariableNamingRule', 'preserve');
y = y.(target);

% confounding variable
conf = readtable(conf_file, 'VariableNamingRule', 'preserve');
conf = removevars(conf, ['Sub_Key']);

% FC data
subjects = table2array(readtable(sublist, 'ReadVariableNames', false));
fc = zeros(454, 454, length(subjects));
for sub_ind = 1:length(subjects)
    fc_file = fullfile(fc_dir, num2str(subjects{sub_ind}) + "_V1_MR.h5");
    fc_sub = h5read(fc_file, "/rs_sfc_level4/block0_values");
    fc_curr = triu(ones(454), 1);
    fc_curr(fc_curr > 0) = fc_sub;
    fc(:, :, sub_ind) = fc_curr + fc_curr';
end

% cross-validation by site
idx = ~cellfun(@isempty, strfind(conf.Properties.VariableNames, 'site'));
cv_ind = table2array(conf(:,idx==1));
cv_ind = cv_ind * [1:size(cv_ind,2)]';
conf(:,idx) = [];   % if split folds by site, then don't need to regress site

options = []; options.save_weights = 0;
options.prefix = strcat(regexprep(target, ' +', '_'), '_SchMel4');
CBPP_wholebrain(fc, y, table2array(conf), cv_ind, out_dir, options);

end
