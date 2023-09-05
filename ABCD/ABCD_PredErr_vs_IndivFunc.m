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

load(avgPredErr)

switch func_metric
case 'rsfc_homo'
    [homo_mat, subj_ls, site_csv] = ...
        internal.stats.parseArgs({'homo_mat', 'subj_ls', 'site_csv'}, {[], ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt', ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/phenotypes_pass_rs.txt'}, varargin{:});

    load(homo_mat)

    Ylabel = 'Resting-state functional homogeneity (Schaefer 400)';
    outbase = 'PredErr_vs_rsfchomo';
    ABCD_scatter_PredErr_vs_other_var(err_avg, homo_out, outdir, outbase, Xlabels, Ylabel, 1)

    % regress out site
    d = readtable(site_csv);
    [subjects, nsub] = CBIG_text2cell(subj_ls);
    [~, ~, idx] = intersect(subjects, d.subjectkey, 'stable');
    site = d.site(idx);
    uq_st = unique(site);
    dummies = zeros(length(site), length(uq_st));
    for s = 1:length(uq_st)
        dummies(:,s) = double(strcmp(site, uq_st{s}));
    end
    [resid, ~, ~, ~] = CBIG_glm_regress_matrix(homo_out, dummies, 1, []);

    Ylabel = 'RS functional homogeneity, site regressed';
    outbase = 'PredErr_vs_rsfchomo_siteReg';
    ABCD_scatter_PredErr_vs_other_var(err_avg, resid, outdir, outbase, Xlabels, Ylabel, 1)
otherwise
    error('Unknown metric: %s', func_metric)
end

end