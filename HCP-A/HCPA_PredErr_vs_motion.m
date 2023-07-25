function HCPA_PredErr_vs_motion(FD_txt, DV_txt, avgPredErr, outdir, Xlabels)

% HCPA_PredErr_vs_motion(FD_txt, DV_txt, pred_dir, outdir)
%
% - Xlabels
%     {'Cognition', 'Emotion recognition', 'Perceived negatives'}

load(avgPredErr)

FD = dlmread(FD_txt);
DV = dlmread(DV_txt);

Ylabel = 'FD';
outbase = 'PredErr_vs_FD';
HCPA_scatter_PredErr_vs_other_var(err_avg, FD, outdir, outbase, Xlabels, Ylabel, 1)


Ylabel = 'DVARS';
outbase = 'PredErr_vs_DV';
HCPA_scatter_PredErr_vs_other_var(err_avg, DV, outdir, outbase, Xlabels, Ylabel, 1)
    
end