function HCPA_generalise_cbpp(model, target, atlas, in_mat, out_dir, saveWeights, sublist, parcel)
% This script runs whole-brain or region-wise CBPP using combined connectivity data
%
% ARGUMENTS:
% model        'whole-brain' or 'region-wise'
% atlas        short-form name of the atlas used for parcellation. Choose from 'AICHA', 'SchMel1', 'SchMel2', 
%                'SchMel3' and 'SchMel4'
% in_mat       absolute path to input .mat file with variables `fc`, `y`, `conf` inside.
% output_dir   absolute path to output directory
% saveWeights  (default: 0) set to 1 to also save the regression weights from whole-brain CBPP models
% sublist      absolute path to custom subject list (.csv file where each line is one subject ID)
% parcel       (optional) pick one parcel to run region-wise CBPP
%
% OUTPUT:
% 1 output file in the output directory containing the prediction performance, and whole-brain model regression
% weights if saveWeights=1
% For example: wbCBPP_SVR_eNKI-RS_AICHA_fluidcog.mat
%
% Jianxiao Wu, last edited on 26-Nov-2021

if nargin < 5
    disp('HCPD_generalise_cbpp(model, target, atlas, in_mat, out_dir, <saveWeights>, <sublist>, <parcel>)'); return
end

if nargin < 6
    saveWeights = 0;
end

if nargin < 7
    sublist='';
end

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir), 'external_packages', 'cbpp'));

load(in_mat, 'fc', 'y', 'conf');

n_fold = 5; n_repeat = 200;
options = []; options.save_weights = saveWeights;
%%%% cross-validation by site
idx = ~cellfun(@isempty, strfind(conf.Properties.VariableNames, 'site'));
cv_ind = table2array(conf(:,idx==1));
cv_ind = cv_ind * [1:size(cv_ind,2)]';
conf(:,idx) = [];   % if split folds by site, then don't need to regress site
%%%%

y = y.(target);
conf = table2array(conf);
%cv_ind = CVPart_noFam(n_fold, n_repeat, length(CBIG_text2cell(sublist)), 1);


switch atlas
case 'AICHA'
    nparc = 384;
case 'SchMel1'
    nparc = 100 + 16;
case 'SchMel2'
    nparc = 200 + 32;
case 'SchMel3'
    nparc = 300 + 50;
case 'SchMel4'
    nparc = 400 + 54;
otherwise
    error('Invalid atlas option'); return
end

if nargin < 8
    parcels = 1:nparc;
else
    parcels = parcel;
end

if strcmp(model, 'whole-brain')
    options.prefix = [regexprep(target, ' +', '_') '_' atlas];
    CBPP_wholebrain(fc, y, conf, cv_ind, out_dir, options);
elseif strcmp(model, 'region-wise')
    for parcel = parcels
        options.prefix = [regexprep(target, ' +', '_') '_' atlas '_parcel' num2str(parcel)];
        x = squeeze(fc(parcel, :, :)); x(parcel, :) = [];
        CBPP_parcelwise(x, y, conf, cv_ind, out_dir, options);
    end
else
    error('Invalid model option'); return
end

end

function cv_ind = CVPart_noFam(n_fold, n_repeat, n_sub, seed)

rng(seed);
cv_ind = zeros(n_sub, n_repeat);
for repeat = 1:n_repeat
    cv_part = cvpartition(n_sub, 'KFold', n_fold);
    for fold = 1:n_fold
        test_ind = cv_part.test(fold);
        cv_ind(test_ind==1, repeat) = fold;
    end
end

end

