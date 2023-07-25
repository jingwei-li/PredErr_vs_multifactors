function HCPA_PredErr_vs_IndivFunc(avgPredErr, outdir, Xlabels, func_metric, varargin)

% HCPA_PredErr_vs_IndivFunc(pred_dir, outdir, func_metric, varargin)
%
% Compulsory inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCPA_avgPredErr`.
%   - Xlabels
%     {'Cognition', 'Emotion recognition', 'Perceived negatives'}
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

load(avgPredErr)

switch func_metric
case 'rsfc_homo'
    if(strcmp(varargin{1}, 'homo_mat'))
        homo_mat = varargin{2};
    else
        error('Unknown option %s', varargin{1});
    end

    load(homo_mat)

    Ylabel = 'Resting-state functional homogeneity (Schaefer 400)';
    outbase = 'PredErr_vs_rsfchomo';
    HCPA_scatter_PredErr_vs_other_var(err_avg, homo_out, outdir, outbase, Xlabels, Ylabel, 1)
otherwise
    error('Unknown metric: %s', func_metric)
end
    
    
end