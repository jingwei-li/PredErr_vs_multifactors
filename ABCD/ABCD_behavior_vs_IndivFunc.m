function ABCD_behavior_vs_IndivFunc(avgBehavior, outdir, Xlabels, func_metric, varargin)

% ABCD_behavior_vs_IndivFunc(avgBehavior, outdir, Xlabels, func_metric, varargin)
%
% Compulsory inputs:
%   - avgBehavior
%     Average behavioral scores from the groups of behavioral measures which share similar
%     patterns in the prediction errors. It is computed by the function `ABCD_avgBehavior.m`.
%
%   - outdir
%     Full path to output directory.
% 
%   - Xlabels
%     A cell array contains the X-axis names for each behavioral cluster. The number of 
%     entries in `Xlabels` should be the same with the number of fields in the `bhvr_avg` 
%     structure passed in by `avgBehavior` variable.
%     Example: Xlabels = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
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

load(avgBehavior)

switch func_metric
case 'rsfc_homo'
    [homo_mat, subj_ls, site_csv] = ...
        internal.stats.parseArgs({'homo_mat', 'subj_ls', 'site_csv'}, {[], ...
        '/data/project/predict_stereotype/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt', ...
        '/data/project/predict_stereotype/from_sg/ABCD_race/scripts/lists/phenotypes_pass_rs.txt'}, varargin{:});

    load(homo_mat)
    Ylabel = 'Resting-state functional homogeneity (Schaefer 400)';
    outbase = 'behavior_vs_rsfchomo';
    ABCD_scatter_PredErr_vs_other_var(bhvr_avg, homo_out, outdir, outbase, Xlabels, Ylabel, 1)
otherwise
    error('Unknown metric: %s', func_metric)
end

end