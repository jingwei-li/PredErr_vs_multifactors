function HCP_PredErr_vs_IndivAnat(avgPredErr, outdir, Xlabels, anat_metric, varargin)

% HCP_PredErr_vs_IndivAnat(avgPredErr, outdir, Xlabels, anat_metric, varargin)
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
%     Example: Xlabels = {'Cognitive flexibility, inhibition', 'Negative feelings', 'Positive feelings', 'Emotion recognition'};
%
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
    
load(avgPredErr)

switch anat_metric
case 'Euler'
    [lh_path, rh_path] = internal.stats.parseArgs({'lh', 'rh'}, {[],[]}, varargin{:});
    lh_euler = dlmread(lh_path);
    rh_euler = dlmread(rh_path);
    euler = (lh_euler + rh_euler) ./ 2;

    Ylabel = 'Euler characteristic';
    outbase = 'PredErr_vs_Euler';
    HCP_scatter_PredErr_vs_other_var(err_avg, euler, outdir, outbase, Xlabels, Ylabel, 0.1)

    Ylabel = 'log( - Euler characteristic)';
    outbase = 'PredErr_vs_log-Euler';
    HCP_scatter_PredErr_vs_other_var(err_avg, log(-euler), outdir, outbase, Xlabels, Ylabel, 0.1)
case 'ICV'
    [subj_ls, csv] = internal.stats.parseArgs({'subj_ls', 'csv'}, ...
        {'/home/jli/my_projects/fairAI/from_sg/HCP_race/scripts/lists/subjects_wIncome_948.txt', ...
        '/home/jli/datasets/HCP_YA_csv/FreeSurfer_jingweili_6_20_2023_1200subjects.csv'}, varargin{:});
    d = readtable(csv);
    subjects = dlmread(subj_ls);
    [~, ~, idx] = intersect(subjects, d.Subject, 'stable');
    ICV = d.FS_IntraCranial_Vol(idx);

    Ylabel = 'ICV';
    outbase = 'PredErr_vs_ICV';
    HCP_scatter_PredErr_vs_other_var(err_avg, ICV, outdir, outbase, Xlabels, Ylabel, 0.1)
otherwise
    error('Unknown metric: %s', anat_metric)
end

end