function ABCD_behavior_vs_IndivAnat(avgBehavior, outdir, Xlabels, anat_metric, varargin)

% ABCD_corr_behaviorVScovariates(model_dir, bhvr_ls)
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
%   - anat_metric
%     Choose between 'Euler' or 'ICV'. 
%     'Euler' represents the Euler characteristic of the original individual surfaces before FreeSurfer 
%     fix the holes. It captures the the individual surfaces' topology. 
%     'ICV' - intracranial volume.
%
%  varargin:
%    If 'Euler' is used, varargin should contain the full paths to the list of individuals' Euler 
%    characteristics for left and right hemispheres separately. Moreoever, for preprocessing Euler
%    characteristics, the subject list, and a csv file contains the site information should also 
%    be passed in.
%    For example, (..., 'lh', '/home/xxx/lh.subjects_pass_rs_pass_pheno.txt', 
%                  'rh', '/home/xxx/rh.subjects_pass_rs_pass_pheno.txt',
%                  'subj_ls', '/home/xxx/subjects_pass_rs_pass_pheno.txt',
%                  'site_csv', '/home/xxx/phenotypes_pass_rs.txt')
%
%    If 'ICV' is used, varargin should contain the full paths to the subject list, and to a csv file 
%    created by this set of code: https://github.com/jingwei-li/Unfairness_ABCD_process/tree/master/preparation
%    For example, (..., 'subj_ls', '/home/xxx/subjects_pass_rs_pass_pheno.txt',
%                  'csv', '/home/xxx/phenotypes_pass_rs.txt')
%

load(avgBehavior)

switch anat_metric
case 'Euler'
    [lh_path, rh_path, subj_ls, site_csv] = ...
        internal.stats.parseArgs({'lh', 'rh', 'subj_ls', 'site_csv'}, {[],[], ...
        '/data/project/predict_stereotype/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt', ...
        '/data/project/predict_stereotype/from_sg/ABCD_race/scripts/lists/phenotypes_pass_rs.txt'}, varargin{:});
    lh_euler = dlmread(lh_path);
    rh_euler = dlmread(rh_path);
    euler = (lh_euler + rh_euler) ./ 2;

    % centering within each site, taking square root, and multipling by -1
    d = readtable(site_csv);
    [subjects, nsub] = CBIG_text2cell(subj_ls);
    [~, ~, idx] = intersect(subjects, d.subjectkey, 'stable');
    site = d.site(idx);
    uq_st = unique(site);
    euler_proc = zeros(size(euler));
    for s = 1:length(uq_st)
        euler_st = euler(strcmp(site, uq_st{s}));
        euler_proc(strcmp(site, uq_st{s})) = euler_st - median(euler_st);
    end

    Ylabel = 'Euler characteristic (centered per site)';
    outbase = 'behavior_vs_Euler';
    ABCD_scatter_PredErr_vs_other_var(bhvr_avg, euler_proc, outdir, outbase, Xlabels, Ylabel, 1)
case 'ICV'
    [subj_ls, my_csv] = internal.stats.parseArgs({'subj_ls', 'csv'}, ...
        {'/data/project/predict_stereotype/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt', ...
        '/data/project/predict_stereotype/from_sg/ABCD_race/scripts/lists/phenotypes_pass_rs.txt'}, varargin{:});
    d = readtable(my_csv);
    [subjects, nsub] = CBIG_text2cell(subj_ls);
    [~, ~, idx] = intersect(subjects, d.subjectkey, 'stable');
    ICV = d.ICV(idx);

    Ylabel = 'ICV';
    outbase = 'behavior_vs_ICV';
    ABCD_scatter_PredErr_vs_other_var(bhvr_avg, ICV, outdir, outbase, Xlabels, Ylabel, 1)
case 'Jacobian'
    Jacobian_ls = internal.stats.parseArgs({'Jacobian_ls'}, {[]}, varargin{:});
    Jacobian = dlmread(Jacobian_ls);

    Ylabel = 'Jacobian STD';
    outbase = 'behavior_vs_Jacobian';
    ABCD_scatter_PredErr_vs_other_var(bhvr_avg, Jacobian, outdir, outbase, Xlabels, Ylabel, 1)
otherwise
    error('Unknown metric: %s', anat_metric)
end
    
end