function HCP_behavior_vs_IndivFunc(avgBehavior, outdir, Xlabels, func_metric, varargin)

% HCP_behavior_vs_IndivFunc(avgBehavior, outdir, Xlabels, func_metric, varargin)
%
% Compulsory inputs:
%   - avgBehavior
%     Average behavioral scores from the groups of behavioral measures which share similar
%     patterns in the prediction errors. It is computed by the function `HCP_avgBehavior.m`.
%
%   - outdir
%     Full path to output directory.
%
%   - Xlabels
%     A cell array contains the X-axis names for each behavioral cluster. The number of
%     entries in `Xlabels` should be the same with the number of fields in the `bhvr_arg` structure
%     passed in by `avgBehavior` variable.
%     Example: Xlabels = {'Cognitive control', 'Negative feelings', 'Positive feelings', 'Emotion recognition'};
%              Xlabels = {'Social cognition', 'Negative/Positive feelings', 'Emotion recognition'};
%
%   - func_metric
%     Choose from 'rsfc_homo'. 
%     'rsfc_homo' represents the individual resting-state functional homogeneity of Schaefer 400 parcellation.
%
%  varargin:
%    If 'rsfc_homo' is used, varargin should pass in the full paths to the .mat file which contains
%    the homogeneity of each individual. 
%    For example, (..., 'homo_mat', '/home/xxx/homo_subjects_wIncome_948.mat')
%

load(avgBehavior)

switch func_metric
case 'rsfc_homo'
    if(strcmp(varargin{1}, 'homo_mat'))
        homo_mat = varargin{2};
    else
        error('Unknown option %s', varargin{1});
    end

    load(homo_mat)

    Ylabel = 'Resting-state functional homogeneity (Schaefer 400)';
    outbase = 'behavior_vs_rsfchomo';
    HCP_scatter_PredErr_vs_other_var(bhvr_avg, homo_out, outdir, outbase, Xlabels, Ylabel, 1)
otherwise
    error('Unknown metric: %s', func_metric)
end
    
end