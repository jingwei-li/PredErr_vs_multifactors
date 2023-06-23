function ABCD_PredErr_vs_IndivFunc(avgPredErr, outdir, Xlabels, func_metric, varargin)

% ABCD_PredErr_vs_IndivFunc(avgPredErr, outdir, Xlabels, func_metric, varargin)
%
% Compulsory inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%
%   - outdir
%     Full path to output directory.
%
%   - Xlabels
%     A cell array contains the X-axis names for each behavioral cluster. The number of
%     entries in `Xlabels` should be the same with the number of fields in the `err_arg` structure
%     passed in by `avgPredErr` variable.
%     Example: Xlabels = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodomal Psychosis'};
%
%   - func_metric
%     Choose from 'rsfc_homo'. 
%     'rsfc_homo' represents the individual resting-state functional homogeneity of Schaefer 400 parcellation.
%
%  varargin:
%    If 'rsfc_homo' is used, varargin should pass in the full paths to the .mat file which contains
%    the homogeneity of each individual. 
%    For example, (..., 'homo_mat', '/home/xxx/homo_pass_rs_pass_pheno_5351.mat')
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
    ABCD_scatter_PredErr_vs_other_var(err_avg, homo_out, outdir, outbase, Xlabels, Ylabel, 1)
otherwise
    error('Unknown metric: %s', func_metric)
end

end