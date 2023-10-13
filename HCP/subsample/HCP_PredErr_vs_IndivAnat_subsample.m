function HCP_PredErr_vs_IndivAnat_subsample(avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats, anat_metric, varargin)

% HCP_PredErr_vs_IndivAnat_subsample(avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats, anat_metric, varargin)
%
% Compulsory inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCP_avgPredErr`.
%   - bhvr_cls_names
%     A cell array contains the X-axis names for each behavioral cluster. The number of entries 
%     in `bhvr_cls_names` should be the same with the number of fields in the `err_avg` structure 
%     in `avgPredErr`.
%     Example: bhvr_cls_names = {'Social cognition', 'Negative/Positive feelings', 'Emotion recognition'};
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
%  varargin:
%    If 'Euler' is used, varargin should contain the full paths to the list of individuals' Euler 
%    characteristics for left and right hemispheres separately. 
%    For example, (..., 'lh', '/home/xxx/lh.subjects_wIncome_948.txt', 
%                  'rh', '/home/xxx/rh.subjects_wIncome_948.txt')
%    
%    If 'ICV' is used, varargin should contain the full paths to the subject list, and to the HCP  
%    FreeSurfer csv file downloaded from http://db.humanconnectome.org
%    For example, (..., 'subj_ls', '/home/xxx/subjects_wIncome_948.txt',
%                  'csv', '/home/xxx/FreeSurfer_jingweili_6_20_2023_1200subjects.csv')
%    

addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))

load(avgPredErr)

switch anat_metric
case 'Euler'
    [lh_path, rh_path] = internal.stats.parseArgs({'lh', 'rh'}, {[],[]}, varargin{:});
    lh_euler = dlmread(lh_path);
    rh_euler = dlmread(rh_path);
    euler = (lh_euler + rh_euler) ./ 2;

    asso = subsample_PredErr_vs_continuous_covar(err_avg, euler, s_size, repeats);
    save(outmat, 'asso')

    hist_subsample_rho(asso, bhvr_cls_names, figout)
    hist_subsample_pval(asso, bhvr_cls_names, figout)
case 'ICV'
    [subj_ls, csv] = internal.stats.parseArgs({'subj_ls', 'csv'}, ...
        {'/data/project/predict_stereotype/from_sg/HCP_race/scripts/lists/subjects_wIncome_948.txt', ...
        '/data/project/predict_stereotype/datasets/HCP_YA_csv/FreeSurfer_jingweili_6_20_2023_1200subjects.csv'}, varargin{:});
    d = readtable(csv);
    subjects = dlmread(subj_ls);
    [~, ~, idx] = intersect(subjects, d.Subject, 'stable');
    ICV = d.FS_IntraCranial_Vol(idx);

    asso = subsample_PredErr_vs_continuous_covar(err_avg, ICV, s_size, repeats);
    save(outmat, 'asso')

    hist_subsample_rho(asso, bhvr_cls_names, figout)
    hist_subsample_pval(asso, bhvr_cls_names, figout)
otherwise
    error('Unknown metric: %s', anat_metric)
end

rmpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))
    
end