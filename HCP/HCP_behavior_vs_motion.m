function HCP_behavior_vs_motion(FD_txt, DV_txt, avgBehavior, outdir, Xlabels)

% HCP_behavior_vs_motion(FD_txt, DV_txt, avgBehavior, outdir, Xlabels)
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
%   - avgBehavior
%     Average behavioral scores from the groups of behavioral measures which share similar
%     patterns in the prediction errors. It is computed by the function `HCP_avgBehavior.m`.
%
%   - outdir
%     Full path to output directory.
%
%   - Xlabels
%     A cell array contains the X-axis names for each behavioral cluster. The number of
%     entries in `Xlabels` should be the same with the number of fields in the `bhvr_arg` structure
%     passed in by `avgBehavior` variable.
%     Example: Xlabels = {'Cognitive control', 'Negative feelings', 'Positive feelings', 'Emotion recognition'};
%              Xlabels = {'Social cognition', 'Negative/Positive feelings', 'Emotion recognition'};
%

FD = dlmread(FD_txt);
DV = dlmread(DV_txt);

load(avgBehavior)

Ylabel = 'FD';
outbase = 'behavior_vs_FD';
HCP_scatter_PredErr_vs_other_var(bhvr_avg, FD, outdir, outbase, Xlabels, Ylabel, 1)

Ylabel = 'log(FD)';
outbase = 'behavior_vs_logFD';
HCP_scatter_PredErr_vs_other_var(bhvr_avg, log(FD), outdir, outbase, Xlabels, Ylabel, 1)

Ylabel = 'DVARS';
outbase = 'behavior_vs_DV';
HCP_scatter_PredErr_vs_other_var(bhvr_avg, DV, outdir, outbase, Xlabels, Ylabel, 1)
    
end