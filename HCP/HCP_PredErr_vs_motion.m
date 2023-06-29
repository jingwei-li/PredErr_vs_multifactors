function HCP_PredErr_vs_motion(FD_txt, DV_txt, avgPredErr, outdir, Xlabels)

% HCP_PredErr_vs_motion(FD_txt, avgPredErr, outdir, Xlabels)
%
% Required inputs:
%   - FD_txt
%     A text file that contains the FD of each subject.
%     e.g. '/home/jli/my_projects/fairAI/from_sg/HCP_race/scripts/lists/FD_948.txt'
%
%   - DV_txt
%     A text file that contains the DVARS of each subject.
%     e.g. '/home/jli/my_projects/fairAI/from_sg/HCP_race/scripts/lists/DV_948.txt'
%
%   - avgPredErr
%     Average prediction error from the groups of behavioral measures which share similar
%     patterns in the errors. It is computed by the function `HCP_avgPredErr`.
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

FD = dlmread(FD_txt);
DV = dlmread(DV_txt);
load(avgPredErr)

Ylabel = 'FD';
outbase = 'PredErr_vs_FD';
HCP_scatter_PredErr_vs_other_var(err_avg, FD, outdir, outbase, Xlabels, Ylabel, 1)

Ylabel = 'log(FD)';
outbase = 'PredErr_vs_logFD';
HCP_scatter_PredErr_vs_other_var(err_avg, log(FD), outdir, outbase, Xlabels, Ylabel, 1)

Ylabel = 'DVARS';
outbase = 'PredErr_vs_DV';
HCP_scatter_PredErr_vs_other_var(err_avg, DV, outdir, outbase, Xlabels, Ylabel, 1)
    
end