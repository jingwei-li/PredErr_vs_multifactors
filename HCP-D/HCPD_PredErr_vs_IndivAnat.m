function HCPD_PredErr_vs_IndivAnat(avgPredErr, outdir, Xlabels, anat_metric, varargin)

% HCPD_PredErr_vs_IndivAnat(pred_dir, parcellation, targets, anat_metric, varargin)
%
% Compulsory inputs:
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCPD_avgPredErr`.
%   - anat_metric
%     Choose between 'Euler', 'ICV'. 
%     'Euler' represents the Euler characteristic of the original individual surfaces before FreeSurfer 
%     fix the holes. It captures the the individual surfaces' topology. 
%     'ICV' - intracranial volume.
%   - Xlabels
%     {'Cognition', 'Emotion recognition'}
%     {'Behavioral inhibition', 'Externalizing problems', 'Premeditation/perseverance', 'Impulsivity - urgency'}
%  varargin:
%    If 'Euler' is used, varargin should contain the full paths to the list of individuals' Euler 
%    characteristics for left and right hemispheres separately. Moreoever, for preprocessing Euler
%    characteristics, the subject list, and a csv file contains the site information should also 
%    be passed in.
%    For example, (..., 'lh', '/home/xxx/lh_Euler.sub_allbehavior.txt', 
%                  'rh', '/home/xxx/rh_Euler.sub_allbehavior.txt',
%                  'subj_ls', '/home/xxx/sublist_allhavior.csv',
%                  'site_csv', '/xxx/inm7_superds/original/hcp/hcp_development/phenotype/ndar_subject01.txt'）
%    If 'ICV' is used, varargin should contain the full paths to the list of individuals' ICV  
%    For example, (..., 'ICV_ls', 'ICV.sub_allbehavior.txt')
%    

script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(script_dir), 'HCP-A'))

load(avgPredErr)

switch anat_metric
case 'Euler'
    [lh_path, rh_path, subj_ls, site_csv] = ...
        internal.stats.parseArgs({'lh', 'rh', 'subj_ls', 'site_csv'}, {[],[], ...
        '/home/jli/my_projects/fairAI/from_sg/new_results/HCP-D/lists/sublist_allbehavior.csv', ...
        '/home/jli/datasets/inm7_superds/original/hcp/hcp_development/phenotype/ndar_subject01.txt'}, varargin{:});
    lh_euler = dlmread(lh_path);
    rh_euler = dlmread(rh_path);
    euler = (lh_euler + rh_euler) ./ 2;

    % centering within each site, taking square root, and multipling by -1
    d = readtable(site_csv);
    [subjects, nsub] = CBIG_text2cell(subj_ls);
    [~, ~, idx] = intersect(subjects, d.src_subject_id, 'stable');
    site = d.site(idx);
    uq_st = unique(site);
    euler_proc = zeros(size(euler));
    for s = 1:length(uq_st)
        euler_st = euler(strcmp(site, uq_st{s}));
        euler_proc(strcmp(site, uq_st{s})) = euler_st - median(euler_st);
    end
    
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