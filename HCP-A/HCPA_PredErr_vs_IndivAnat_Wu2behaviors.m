function HCPA_PredErr_vs_IndivAnat(pred_dir, parcellation, outdir, anat_metric, varargin)

% HCPA_PredErr_vs_IndivAnat(pred_dir, parcellation, targets, anat_metric, varargin)
%
% Compulsory inputs:
%   - pred_dir
%     The diretory that contains the .mat files of prediction results.
%   - parcellation
%     Choose among 'SchMel1', 'SchMel2', 'SchMel3', and 'SchMel4'.
%   - anat_metric
%     Choose between 'Euler', 'talxfm', 'ICV' or 'bbr_cost'. 
%     'Euler' represents the Euler characteristic of the original individual surfaces before FreeSurfer 
%     fix the holes. It captures the the individual surfaces' topology. 
%     'ICV' - intracranial volume.
%  varargin:
%    If 'Euler' is used, varargin should contain the full paths to the list of individuals' Euler 
%    characteristics for left and right hemispheres separately.
%    For example, (..., 'lh', '/home/xxx/lh.openness_allRun_sub.txt', 
%                  'rh', '/home/xxx/rh.openness_allRun_sub.txt'）
%    If 'ICV' is used, varargin should contain the full paths to the list of individuals' ICV  
%    For example, (..., 'ICV_ls', 'ICV.openness_allRun_sub.txt')
%    

ls_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'cbpp', 'bin', 'sublist');
sub_ls_op = fullfile(ls_dir, 'HCP-A_openness_allRun_sub.csv');
sub_ls_fc = fullfile(ls_dir, 'HCP-A_fluidcog_allRun_sub.csv');
sub_op = CBIG_text2cell(sub_ls_op);
sub_fc = CBIG_text2cell(sub_ls_fc);
[~,~,idx] = intersect(sub_fc, sub_op, 'stable');

targets = {'fluidcog', 'openness'};
Xlabels = {'Fluid cognition', 'NEO openness'};
for t = 1:length(targets)
    err.(targets{t}) = nan(length(sub_op), 1);
    load(fullfile(pred_dir, ['wbCBPP_SVR_standard_HCP-A' '_' targets{t} '_' parcellation '.mat']))
    if(strcmp(targets{t}, 'fluidcog'))
        err.(targets{t})(idx) = abs(mean(yp-yt, 1)');
    else
        err.(targets{t}) = abs(mean(yp-yt, 1)');
    end
end

switch anat_metric
case 'Euler'
    [lh_path, rh_path] = internal.stats.parseArgs({'lh', 'rh'}, {[],[]}, varargin{:});
    lh_euler = dlmread(lh_path);
    rh_euler = dlmread(rh_path);
    euler = (lh_euler + rh_euler) ./ 2;
    
    Ylabel = 'Euler characteristic';
    outbase = 'PredErr_vs_Euler';
    HCPA_scatter_PredErr_vs_other_var(err, euler, outdir, outbase, Xlabels, Ylabel, 1)
case 'ICV'
    ICV_ls = internal.stats.parseArgs({'ICV_ls'}, {[]}, varargin{:});
    ICV = dlmread(ICV_ls);

    Ylabel = 'ICV';
    outbase = 'PredErr_vs_ICV';
    HCPA_scatter_PredErr_vs_other_var(err, ICV, outdir, outbase, Xlabels, Ylabel, 1)
end

end