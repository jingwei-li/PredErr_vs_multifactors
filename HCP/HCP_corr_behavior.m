function HCP_corr_behavior(model_dir, bhvr_ls, outmat)

[bhvr_nm, nbhvr] = CBIG_text2cell(bhvr_ls);

y_corr = nan(nbhvr*(nbhvr-1)/2, 1);
pair = 1;
for b1 = 1:(nbhvr-1)
    y1 = load(fullfile(model_dir, ['y_' bhvr_nm{b1} '.mat']));
    for b2 = (b1+1):nbhvr
        y2 = load(fullfile(model_dir, ['y_' bhvr_nm{b2} '.mat']));
        y_corr(pair, 1) = CBIG_corr(y1.y, y2.y);
        y_spcorr(pair, 1) = corr(y1.y, y2.y, 'Type', 'Spearman');
        pair = pair + 1;
    end
end

outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outmat, 'y_corr', 'y_spcorr')

end