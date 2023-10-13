function HCPA_PredErr_vs_IndivFunc(pred_dir, outdir, func_metric, varargin)

% HCPA_PredErr_vs_IndivFunc(pred_dir, outdir, func_metric, varargin)
%
% Compulsory inputs:
%   - pred_dir
%     The diretory that contains the .mat files of prediction results.
%   - func_metric
%     Choose from 'rsfc_homo'. 
%     'rsfc_homo' represents the individual resting-state functional homogeneity 
%     of Schaefer 400 parcellation.
%
%  varargin:
%    If 'rsfc_homo' is used, varargin should pass in the full paths to the .mat file which contains
%    the homogeneity of each individual. 
%    For example, (..., 'homo_mat', '/home/xxx/homo_openness_allRun_sub.mat')
%

ls_dir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'external_packages', 'cbpp', 'bin', 'sublist');
sub_ls_op = fullfile(ls_dir, 'HCP-A_openness_allRun_sub.csv');
sub_ls_fc = fullfile(ls_dir, 'HCP-A_fluidcog_allRun_sub.csv');
sub_op = CBIG_text2cell(sub_ls_op);
sub_fc = CBIG_text2cell(sub_ls_fc);
[~,~,idx] = intersect(sub_fc, sub_op, 'stable');

parcellation = 'SchMel4';
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

switch func_metric
case 'rsfc_homo'
    if(strcmp(varargin{1}, 'homo_mat'))
        homo_mat = varargin{2};
    else
        error('Unknown option %s', varargin{1});
    end

    load(homo_mat)

    Ylabel = 'Resting-state functional homogeneity (Schaefer 400)';
    outbase = 'PredErr_vs_rsfchomo';
    HCPA_scatter_PredErr_vs_other_var(err, homo_out, outdir, outbase, Xlabels, Ylabel, 1)
otherwise
    error('Unknown metric: %s', func_metric)
end
    
    
end