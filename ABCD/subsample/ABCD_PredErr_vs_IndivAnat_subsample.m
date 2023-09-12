function ABCD_PredErr_vs_IndivAnat_subsample(avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats, anat_metric, varargin)

% ABCD_PredErr_vs_IndivAnat_bstrp(avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats, anat_metric, varargin)
%
% Compulsory inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `ABCD_avgPredErr`.
%   - bhvr_cls_names
%     A cell array contains the X-axis names for each behavioral cluster. The number of entries 
%     in `bhvr_cls_names` should be the same with the number of fields in the `err_avg` structure 
%     in `avgPredErr`.
%     Example: bhvr_cls_names = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodromal Psychosis'};
%   - outmat
%     Output mat file. It will contain a struct variable. Each field will be the bootstrapped 
%     association between prediction error of one behavioral class with the given covariate.
%   - figout
%     Output name (without extension, full-path).
%   - s_size
%     Size of each subsample.
%   - repeats
%     Number of repetitions of subsampling.
%   - anat_metric
%     Choose between 'Euler' or 'ICV'. 
%     'Euler' represents the Euler characteristic of the original individual surfaces before FreeSurfer 
%     fix the holes. It captures the the individual surfaces' topology. 
%     'ICV' - intracranial volume.
%
% varargin:
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

addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))

load(avgPredErr)
outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
outdir = fileparts(figout);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end

switch anat_metric
case 'Euler'
    [lh_path, rh_path, subj_ls, site_csv] = ...
        internal.stats.parseArgs({'lh', 'rh', 'subj_ls', 'site_csv'}, {[],[], ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt', ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/phenotypes_pass_rs.txt'}, varargin{:});
    lh_euler = dlmread(lh_path);
    rh_euler = dlmread(rh_path);
    euler = (lh_euler + rh_euler) ./ 2;

    asso = subsample_PredErr_vs_continuous_covar(err_avg, euler, s_size, repeats);
    save(outmat, 'asso')

    hist_subsample_rho(asso, bhvr_cls_names, figout)
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'ICV'
    [subj_ls, my_csv] = internal.stats.parseArgs({'subj_ls', 'csv'}, ...
        {'/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt', ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/phenotypes_pass_rs.txt'}, varargin{:});
    d = readtable(my_csv);
    [subjects, nsub] = CBIG_text2cell(subj_ls);
    [~, ~, idx] = intersect(subjects, d.subjectkey, 'stable');
    ICV = d.ICV(idx);

    asso = subsample_PredErr_vs_continuous_covar(err_avg, ICV, s_size, repeats);
    save(outmat, 'asso')

    hist_subsample_rho(asso, bhvr_cls_names, figout)
    hist_subsample_pval(asso, bhvr_cls_names, figout)
otherwise
    error('Unknown metric: %s', anat_metric)
end

rmpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))
    
end