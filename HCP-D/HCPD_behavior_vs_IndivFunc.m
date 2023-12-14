function HCPD_behavior_vs_IndivFunc(avgBehavior, outdir, Xlabels, func_metric, varargin)

% HCPD_behavior_vs_IndivFunc(avgBehavior, outdir, Xlabels, func_metric, varargin)
%
% Compulsory inputs:
%   - avgBehavior
%     Average behavioral scores from the groups of behavioral measures which share similar
%     patterns in the prediction errors. It is computed by the function `HCPD_avgBehavior.m`.
%
%   - outdir
%     Full path to output directory.
%
%   - Xlabels
%     {'Cognition', 'Emotion recognition'}
%     {'Behavioral inhibition', 'Externalizing problems', 'Premeditation/perseverance', 'Impulsivity - urgency'}
%
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

load(avgBehavior)

switch func_metric
case 'rsfc_homo'
    [homo_mat, site_csv] = ...
        internal.stats.parseArgs({'homo_mat', 'site_csv'}, {[], ...
            ['/data/project/predict_stereotype/datasets/inm7_superds/original/hcp/hcp_development/phenotype/ndar_subject01.txt']}, ...
            varargin{:});

    load(homo_mat)

    Ylabel = 'Resting-state functional homogeneity (Schaefer 400)';
    outbase = 'behavior_vs_rsfchomo';
    HCPA_scatter_PredErr_vs_other_var(bhvr_avg, homo_out, outdir, outbase, Xlabels, Ylabel, 1)

    d = readtable(site_csv);
    mask = startsWith( d.Properties.VariableNames, 'site_');
    dummies = table2array(d(:,mask));
    [resid, ~, ~, ~] = CBIG_glm_regress_matrix(homo_out, dummies, 1, []);

    Ylabel = 'RS functional homogeneity, site regressed';
    outbase = 'behavior_vs_rsfchomo_siteReg';
    if(any(~isnan(resid)))
        HCPA_scatter_PredErr_vs_other_var(bhvr_avg, resid, outdir, outbase, Xlabels, Ylabel, 1)
    end
otherwise
    error('Unknown metric: %s', func_metric)
end
    
end