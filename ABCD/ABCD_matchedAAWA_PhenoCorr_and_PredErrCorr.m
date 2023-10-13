function ABCD_matchedAAWA_PhenoCorr_and_PredErrCorr(full_subj_ls, PredErr_allsub, selAAWA_mat, ...
    model_dir, ErrCorr_out_AA, ErrCorr_out_WA, PhenoCorr_out_AA, PhenoCorr_out_WA)

% ABCD_matchedAA_PhenoCorr_and_PredErrCorr()
%
% 
[subjects, nsub] = CBIG_text2cell(full_subj_ls);
err_allsub = load(PredErr_allsub);
selAAWA = load(selAAWA_mat);
nbhvr = length(selAAWA.bhvr_nm);

pair = 1;
for b1 = 1:(nbhvr-1)
    y1 = load(fullfile(model_dir, selAAWA.bhvr_nm{b1}, ['y_' selAAWA.bhvr_nm{b1} '.mat']));
    selAA_1 = cat(2, selAAWA.selAA{b1,:});
    selWA_1 = cat(1, selAAWA.selWA{b1,:});

    for b2 = (b1+1):nbhvr
        y2 = load(fullfile(model_dir, selAAWA.bhvr_nm{b2}, ['y_' selAAWA.bhvr_nm{b2} '.mat']));
        selAA_2 = cat(2, selAAWA.selAA{b2,:});
        selWA_2 = cat(1, selAAWA.selWA{b2,:});

        [unionAA, AA_idx] = intersect(subjects, union(selAA_1, selAA_2), 'stable');
        [unionWA, WA_idx] = intersect(subjects, union(selWA_1, selWA_2), 'stable');
        fprintf('Number of AA-WA pairs for %s: %d, for %s:, %d, union of AA: %d, union of WA: %d\n', ...
            selAAWA.bhvr_nm{b1}, length(selAA_1), selAAWA.bhvr_nm{b2}, length(selAA_2), length(unionAA), length(unionWA))
        
        y_corr_AA(pair, 1) = CBIG_corr(y1.y(AA_idx), y2.y(AA_idx));
        y_corr_WA(pair, 1) = CBIG_corr(y1.y(WA_idx), y2.y(WA_idx));
        y_spcorr_AA(pair, 1) = corr(y1.y(AA_idx), y2.y(AA_idx), 'Type', 'Spearman');
        y_spcorr_WA(pair, 1) = corr(y1.y(WA_idx), y2.y(WA_idx), 'Type', 'Spearman');

        err1_AA = err_allsub.err(AA_idx, b1);
        err2_AA = err_allsub.err(AA_idx, b2);
        nonnanidx = find(~isnan(err1_AA) & ~isnan(err2_AA));
        err_corr_AA(pair, 1) = CBIG_corr(err1_AA(nonnanidx), err2_AA(nonnanidx));
        err_spcorr_AA(pair, 1) = corr(err1_AA(nonnanidx), err2_AA(nonnanidx), 'Type', 'Spearman');

        err1_WA = err_allsub.err(WA_idx, b1);
        err2_WA = err_allsub.err(WA_idx, b2);
        nonnanidx = find(~isnan(err1_WA) & ~isnan(err2_WA));
        err_corr_WA(pair, 1) = CBIG_corr(err1_WA(nonnanidx), err2_WA(nonnanidx));
        err_spcorr_WA(pair, 1) = corr(err1_WA(nonnanidx), err2_WA(nonnanidx), 'Type', 'Spearman');

        pair = pair + 1;
    end
end

%% save out prediction error's correlation of AA
outdir = fileparts(ErrCorr_out_AA);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
err_corr = err_corr_AA;
err_spcorr = err_spcorr_AA;
save(ErrCorr_out_AA, 'err_corr', 'err_spcorr')

%% save out prediction error's correlation of WA
outdir = fileparts(ErrCorr_out_WA);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
err_corr = err_corr_WA;
err_spcorr = err_spcorr_WA;
save(ErrCorr_out_WA, 'err_corr', 'err_spcorr')

%% save out behavioral correlation of AA
outdir = fileparts(PhenoCorr_out_AA);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
y_corr = y_corr_AA;
y_spcorr = y_spcorr_AA;
save(PhenoCorr_out_AA, 'y_corr', 'y_spcorr')

%% save out behavioral correlation of WA
outdir = fileparts(PhenoCorr_out_WA);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
y_corr = y_corr_WA;
y_spcorr = y_spcorr_WA;
save(PhenoCorr_out_WA, 'y_corr', 'y_spcorr')
    
end