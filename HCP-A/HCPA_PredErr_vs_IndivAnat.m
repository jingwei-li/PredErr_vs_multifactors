function HCPA_PredErr_vs_IndivAnat(avgPredErr, outdir, Xlabels, anat_metric, varargin)

% HCPA_PredErr_vs_IndivAnat(pred_dir, parcellation, targets, anat_metric, varargin)
%
% Compulsory inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCPA_avgPredErr`.
%   - anat_metric
%     Choose between 'Euler', 'ICV'. 
%     'Euler' represents the Euler characteristic of the original individual surfaces before FreeSurfer 
%     fix the holes. It captures the the individual surfaces' topology. 
%     'ICV' - intracranial volume.
%   - Xlabels
%     {'Cognition', 'Emotion recognition', 'Perceived negatives'}
%  varargin:
%    If 'Euler' is used, varargin should contain the full paths to the list of individuals' Euler 
%    characteristics for left and right hemispheres separately.
%    For example, (..., 'lh', '/home/xxx/lh.openness_allRun_sub.txt', 
%                  'rh', '/home/xxx/rh.openness_allRun_sub.txt'）
%    If 'ICV' is used, varargin should contain the full paths to the list of individuals' ICV  
%    For example, (..., 'ICV_ls', 'ICV.openness_allRun_sub.txt')
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
    HCPA_scatter_PredErr_vs_other_var(err_avg, euler, outdir, outbase, Xlabels, Ylabel, 1)
case 'ICV'
    ICV_ls = internal.stats.parseArgs({'ICV_ls'}, {[]}, varargin{:});
    ICV = dlmread(ICV_ls);

    Ylabel = 'ICV';
    outbase = 'PredErr_vs_ICV';
    HCPA_scatter_PredErr_vs_other_var(err_avg, ICV, outdir, outbase, Xlabels, Ylabel, 1)
end

end