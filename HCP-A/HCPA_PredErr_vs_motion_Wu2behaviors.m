function HCPA_PredErr_vs_motion(FD_txt, DV_txt, pred_dir, outdir)

% HCPA_PredErr_vs_motion(FD_txt, DV_txt, pred_dir, outdir)
%
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

FD = dlmread(FD_txt);
DV = dlmread(DV_txt);

Ylabel = 'FD';
outbase = 'PredErr_vs_FD';
HCPA_scatter_PredErr_vs_other_var(err, FD, outdir, outbase, Xlabels, Ylabel, 1)


Ylabel = 'DVARS';
outbase = 'PredErr_vs_DV';
HCPA_scatter_PredErr_vs_other_var(err, DV, outdir, outbase, Xlabels, Ylabel, 1)
    
end