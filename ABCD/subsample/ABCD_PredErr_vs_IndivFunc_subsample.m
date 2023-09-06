function ABCD_PredErr_vs_IndivFunc_subsample(avgPredErr, bhvr_cls_names, outmat, figout, size, repeats, func_metric, varargin)

% ABCD_PredErr_vs_IndivFunc_subsample(avgPredErr, bhvr_cls_names, outmat, figout, size, repeats, func_metric, varargin)
%
% Compulsory inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - bhvr_cls_names
%     A cell array contains the X-axis names for each behavioral cluster. The number of entries 
%     in `bhvr_cls_names` should be the same with the number of fields in the `asso` structure.
%     Example: bhvr_cls_names = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
%   - outmat
%     Output mat file. It will contain a struct variable. Each field will be the bootstrapped 
%     association between prediction error of one behavioral class with the given covariate.
%   - figout
%     Output name (without extension, full-path).
%   - size
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

load(avgPredErr)
outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
outdir = fileparts(figout);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end

switch func_metric
case 'rsfc_homo'
    [homo_mat, subj_ls, site_csv] = ...
        internal.stats.parseArgs({'homo_mat', 'subj_ls', 'site_csv'}, {[], ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt', ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/phenotypes_pass_rs.txt'}, varargin{:});
    load(homo_mat)

    asso = ABCD_subsample_PredErr_vs_continuous_covar(err_avg, homo_out, size, repeats);
    save(outmat, 'asso')

    ABCD_hist_subsample_rho(asso, bhvr_cls_names, figout)
    ABCD_hist_subsample_pval(asso, bhvr_cls_names, figout)
otherwise
    error('Unknown metric: %s', func_metric)
end
    
end