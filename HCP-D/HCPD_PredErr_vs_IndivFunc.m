function HCPD_PredErr_vs_IndivFunc(avgPredErr, outdir, Xlabels, func_metric, varargin)

% HCPD_PredErr_vs_IndivFunc(pred_dir, outdir, func_metric, varargin)
%
% Compulsory inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCPA_avgPredErr`.
%   - Xlabels
%     {'Cognition', 'Emotion recognition'}
%   - func_metric
%     Choose from 'rsfc_homo'. 
%     'rsfc_homo' represents the individual resting-state functional homogeneity 
%     of Schaefer 400 parcellation.
%
%  varargin:
%    If 'rsfc_homo' is used, varargin should pass in the full paths to the .mat file which contains
%    the homogeneity of each individual. 
%    For example, (..., 'homo_mat', '/home/xxx/homo_openness_allRun_sub.mat')
%

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir), 'HCP-A'))

load(avgPredErr)

switch func_metric
case 'rsfc_homo'
    [homo_mat, site_csv] = ...
        internal.stats.parseArgs({'homo_mat', 'site_csv'}, {[], []}, varargin{:});

    load(homo_mat)

    Ylabel = 'Resting-state functional homogeneity (Schaefer 400)';
    outbase = 'PredErr_vs_rsfchomo';
    HCPA_scatter_PredErr_vs_other_var(err_avg, homo_out, outdir, outbase, Xlabels, Ylabel, 1)

    d = readtable(site_csv);
    mask = startsWith( d.Properties.VariableNames, 'site_');
    dummies = table2array(d(:,mask));
    [resid, ~, ~, ~] = CBIG_glm_regress_matrix(homo_out, dummies, 1, []);

    Ylabel = 'RS functional homogeneity, site regressed';
    outbase = 'PredErr_vs_rsfchomo_siteReg';
    if(any(~isnan(resid)))
        HCPA_scatter_PredErr_vs_other_var(err_avg, resid, outdir, outbase, Xlabels, Ylabel, 1)
    end
otherwise
    error('Unknown metric: %s', func_metric)
end
    
    
end