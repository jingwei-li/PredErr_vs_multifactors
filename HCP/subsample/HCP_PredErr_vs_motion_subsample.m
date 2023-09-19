function HCP_PredErr_vs_motion_subsample(FD_txt, DV_txt, avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats)

% HCP_PredErr_vs_motion_subsample(FD_txt, DV_txt, avgPredErr, bhvr_cls_names, outmat, figout, s_size, repeats)
%
% Required inputs:
%   - FD_txt
%     A text file that contains the FD of each subject.
%     e.g. '/data/project/predict_stereotype/from_sg/HCP_race/scripts/lists/FD_948.txt'
%
%   - DV_txt
%     A text file that contains the DVARS of each subject.
%     e.g. '/data/project/predict_stereotype/from_sg/HCP_race/scripts/lists/DV_948.txt'
%
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
%
    
addpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))

outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
outdir = fileparts(figout);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end

FD = dlmread(FD_txt);
DV = dlmread(DV_txt);
load(avgPredErr)

asso = subsample_PredErr_vs_continuous_covar(err_avg, FD, s_size, repeats);
save([outmat 'FD.mat'], 'asso')

hist_subsample_rho(asso, bhvr_cls_names, [figout 'FD'])
hist_subsample_pval(asso, bhvr_cls_names, [figout 'FD'])

asso = subsample_PredErr_vs_continuous_covar(err_avg, DV, s_size, repeats);
save([outmat 'DV.mat'], 'asso')

hist_subsample_rho(asso, bhvr_cls_names, [figout 'DV'])
hist_subsample_pval(asso, bhvr_cls_names, [figout 'DV'])

rmpath(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'subsampling'))

end