function ABCD_PredErr_vs_IndivAnat(avgPredErr, outdir, Xlabels, anat_metric, varargin)

% ABCD_PredErr_vs_IndivAnat(avgPredErr, outdir, Xlabels, anat_metric, varargin)
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
%     Example: Xlabels = {'Verbal Memory', 'Cognition', 'Mental Rotation', 'CBCL', 'Prodomal Psychosis'};
%
%   - anat_metric
%     Choose between 'Euler', 'talxfm', 'ICV' or 'bbr_cost'. 
%     'Euler' represents the Euler characteristic of the original individual surfaces before FreeSurfer 
%     fix the holes. It captures the the individual surfaces' topology. 
%     'talxfm' represents the scaling factors in the linear transformation from native T1 to talairach
%     space. These factors indicate how much the individual brain needs to be streched/shrunk along each 
%     direction to be aligned with the talairach atlas.
%     'ICV' - intracranial volume.
%     'bbr_cost' is the cost from bbregister.
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
%    If 'talxfm' is used, varargin should contain the full paths to the list of individuals' scaling 
%    factors along each of the three dimensions.  X: left-right; Y: inferior-superior; Z: anterior-posterior
%    For example, (..., 'x', '/home/xxx/talxfm_x.subjects_pass_rs_pass_pheno.txt',
%                  'y', '/home/xxx/talxfm_y.subjects_pass_rs_pass_pheno.txt',
%                  'z', '/home/xxx/talxfm_z.subjects_pass_rs_pass_pheno.txt')
%
%    If 'ICV' is used, varargin should contain the full paths to the subject list, and to a csv file 
%    created by this set of code: https://github.com/jingwei-li/Unfairness_ABCD_process/tree/master/preparation
%    For example, (..., 'subj_ls', '/home/xxx/subjects_pass_rs_pass_pheno.txt',
%                  'csv', '/home/xxx/phenotypes_pass_rs.txt')
%    
%    If 'bbr_cost' is used, varargin should contain the full path to a list of bbregister cost of
%    individual participants.
%    For example, (..., 'bbr_ls', '/home/xxx/bbr_cost.subjects_pass_rs_pass_pheno.txt')
%


load(avgPredErr)

switch anat_metric
case 'Euler'
    [lh_path, rh_path, subj_ls, site_csv] = ...
        internal.stats.parseArgs({'lh', 'rh', 'subj_ls', 'site_csv'}, {[],[], ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt', ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/phenotypes_pass_rs.txt'}, varargin{:});
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
    %euler_proc = sign(euler_proc) .* sqrt(abs(euler_proc));
    %euler_proc(euler_proc >10) = nan;

    Ylabel = 'Euler characteristic (centered per site)';
    outbase = 'PredErr_vs_Euler';
    ABCD_scatter_PredErr_vs_other_var(err_avg, euler_proc, outdir, outbase, Xlabels, Ylabel, 1)

    %Ylabel = 'log( - Euler characteristic)';
    %outbase = 'PredErr_vs_log-Euler';
    %ABCD_scatter_PredErr_vs_other_var(err_avg, log(-euler), outdir, outbase, Xlabels, Ylabel, 1)
case 'ICV'
    [subj_ls, my_csv] = internal.stats.parseArgs({'subj_ls', 'csv'}, ...
        {'/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/subjects_pass_rs_pass_pheno.txt', ...
        '/home/jli/my_projects/fairAI/from_sg/ABCD_race/scripts/lists/phenotypes_pass_rs.txt'}, varargin{:});
    d = readtable(my_csv);
    [subjects, nsub] = CBIG_text2cell(subj_ls);
    [~, ~, idx] = intersect(subjects, d.subjectkey, 'stable');
    ICV = d.ICV(idx);

    Ylabel = 'ICV';
    outbase = 'PredErr_vs_ICV';
    ABCD_scatter_PredErr_vs_other_var(err_avg, ICV, outdir, outbase, Xlabels, Ylabel, 1)
case 'talxfm'
    [x_path, y_path, z_path] = internal.stats.parseArgs({'x','y','z'}, {[],[],[]}, varargin{:});
    scaling = dlmread(x_path);
    scaling = [scaling dlmread(y_path)];
    scaling = [scaling dlmread(z_path)];
    Ylabels = {'Talairach transform scaling factor (X)', 'Talairach transform scaling factor (Y)', ...
        'Talairach transform scaling factor (Z)'};
    outbases = {'PredErr_vs_talxfm_x', 'PredErr_vs_talxfm_y', 'PredErr_vs_talxfm_z'};
    for i = 1:3
        ABCD_scatter_PredErr_vs_other_var(err_avg, scaling(:,i), outdir, outbases{i}, Xlabels, Ylabels{i}, 1)
    end
case 'bbr_cost'
    if(strcmp(varargin{1}, 'bbr_ls'))
        bbr_path = varargin{2};
    else
        error('Unknown option %s', varargin{1});
    end
    bbr = dlmread(bbr_path);
    Ylabel = 'T1-T2* registration (bbregister) cost';
    outbase = 'PredErr_vs_bbr';
    ABCD_scatter_PredErr_vs_other_var(err_avg, bbr, outdir, outbase, Xlabels, Ylabel, 1)
otherwise
    error('Unknown metric: %s', anat_metric)
end


end

