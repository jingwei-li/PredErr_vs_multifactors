function HCP_PredErr_vs_IndivFunc_subsample(avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats, func_metric, varargin)

% HCP_PredErr_vs_IndivFunc_subsample(avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats, func_metric, varargin)
%
% Compulsory inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCP_avgPredErr`.
%   - bhvr_cls_names
%     A cell array contains the X-axis names for each behavioral cluster. The number of entries 
%     in `bhvr_cls_names` should be the same with the number of fields in the `err_avg` structure 
%     in `avgPredErr`.
%     Example: bhvr_cls_names = {'Social cognition', 'Negative/Positive feelings', 'Emotion recognition'};
%   - outmat
%     Output mat file. It will contain a struct variable. Each field will be the bootstrapped 
%     association between prediction error of one behavioral class with the given covariate.
%   - figout
%     Output name (without extension, full-path).
%   - s_size
%     Size of each subsample.
%   - repeats
%     Number of repetitions of subsampling.
%   - func_metric
%     Choose from 'rsfc_homo'. 
%     'rsfc_homo' represents the individual resting-state functional homogeneity of Schaefer 400 parcellation.
%
%  varargin:
%    If 'rsfc_homo' is used, varargin should pass in the full paths to the .mat file which contains
%    the homogeneity of each individual. 
%    For example, (..., 'homo_mat', '/home/xxx/homo_pass_rs_pass_pheno_5351.mat')
%

addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))

load(avgPredErr)

switch func_metric
case 'rsfc_homo'
    if(strcmp(varargin{1}, 'homo_mat'))
        homo_mat = varargin{2};
    else
        error('Unknown option %s', varargin{1});
    end

    load(homo_mat)
    
    asso = subsample_PredErr_vs_continuous_covar(err_avg, homo_out, s_size, repeats);
    save(outmat, 'asso')

    hist_subsample_rho(asso, bhvr_cls_names, figout)
    hist_subsample_pval(asso, bhvr_cls_names, figout)
otherwise
    error('Unknown metric: %s', func_metric)
end

rmpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))
    
end