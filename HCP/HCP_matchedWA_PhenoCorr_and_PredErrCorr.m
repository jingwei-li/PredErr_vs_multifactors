function HCP_matchedWA_PhenoCorr_and_PredErrCorr(full_subj_ls, full_bhvr_ls58, bhvr_ls, splitWA_dir, model_dir, ErrCorr_out, PhenoCorr_out)

% HCP_matchedWA_PehnoCorr_and_PredErrCorr()
%
% Long description

nfolds = 10;
nseeds = 40;
seed_ub = 400;

[subjects, nsub] = CBIG_text2cell(full_subj_ls);

[bhvr_nm, nbhvr] = CBIG_text2cell(bhvr_ls);
full_bhvr_nm = CBIG_text2cell(full_bhvr_ls58);
[~, ~, idx_in58] = intersect(bhvr_nm, full_bhvr_nm, 'stable');

actual_seeds = zeros(nseeds, nbhvr);
use_seed_bhvr_ldir = fullfile(splitWA_dir, 'usable_seeds');

seed_counts = zeros(1, nbhvr);
for i = 1:seed_ub
    curr_usable_ls = fullfile(use_seed_bhvr_ldir, ['usable_behaviors_seed' num2str(i), '.txt']);
    if(exist(curr_usable_ls, 'file'))
        curr_bhvr_nm = CBIG_text2cell(curr_usable_ls);
        [~, ~, IB] = intersect(curr_bhvr_nm, bhvr_nm, 'stable');
        if(length(IB) < length(curr_bhvr_nm))
            error('Seed %d: Some behavior in the usable behavioral list is not in the full behavioral list.', i)
        end

        for b = 1:length(curr_bhvr_nm)
            seed_counts(IB(b)) = seed_counts(IB(b)) + 1;
            actual_seeds(seed_counts(IB(b)), IB(b)) = i;
        end
    end
end
actual_seeds

for i = 1:nseeds
    pair = 1;
    for b1 = 1:(nbhvr-1)
        splitWA_1 = load(fullfile(splitWA_dir, ['split_seed' num2str(actual_seeds(i,b1)) '.mat']));
        selWA_1 = cat(1, splitWA_1.best_assign{idx_in58(b1)}{:});

        y1 = load(fullfile(model_dir, ['y_' bhvr_nm{b1} '.mat']));

        final = load(fullfile(model_dir, ['randseed_' num2str(actual_seeds(i,b1))], ...
            bhvr_nm{b1}, ['final_result_' bhvr_nm{b1} '.mat']));
        curr_yp1 = final.y_predict_concat;

        full_split1 = load(fullfile(model_dir, ['randseed_' num2str(actual_seeds(i,b1))], ...
            bhvr_nm{b1}, ['no_relative_' num2str(nfolds) '_fold_sub_list_' bhvr_nm{b1} '.mat']));
        curr_yt1 = nan(size(curr_yp1));
        for f = 1:nfolds
            y_reg = load(fullfile(model_dir, ['randseed_' num2str(actual_seeds(i,b1))], ...
                bhvr_nm{b1}, 'y', ['fold_' num2str(f)], ['y_regress_' bhvr_nm{b1} '.mat']));
            curr_yt1(full_split1.sub_fold(f).fold_index==1) = y_reg.y_resid(full_split1.sub_fold(f).fold_index==1);
        end


        for b2 = (b1+1):nbhvr
            splitWA_2 = load(fullfile(splitWA_dir, ['split_seed' num2str(actual_seeds(i,b2)) '.mat']));
            selWA_2 = cat(1, splitWA_2.best_assign{idx_in58(b2)}{:});
            [unionWA, WA_idx] = intersect(subjects, union(selWA_1, selWA_2), 'stable');
            fprintf('#WA for %s: %d, for %s:, %d, union: %d\n', bhvr_nm{b1}, length(selWA_1), ...
                bhvr_nm{b2}, length(selWA_2), length(unionWA))
            
            y2 = load(fullfile(model_dir, ['y_' bhvr_nm{b2} '.mat']));
            y_corr(pair, i) = CBIG_corr(y1.y(WA_idx), y2.y(WA_idx));
            y_spcorr(pair, i) = corr(y1.y(WA_idx), y2.y(WA_idx), 'Type', 'Spearman');

            final = load(fullfile(model_dir, ['randseed_' num2str(actual_seeds(i,b2))], ...
                bhvr_nm{b2}, ['final_result_' bhvr_nm{b2} '.mat']));
            curr_yp2 = final.y_predict_concat;
    
            full_split2 = load(fullfile(model_dir, ['randseed_' num2str(actual_seeds(i,b2))], ...
                bhvr_nm{b2}, ['no_relative_' num2str(nfolds) '_fold_sub_list_' bhvr_nm{b2} '.mat']));
            curr_yt2 = nan(size(curr_yp2));
            for f = 1:nfolds
                y_reg = load(fullfile(model_dir, ['randseed_' num2str(actual_seeds(i,b2))], ...
                    bhvr_nm{b2}, 'y', ['fold_' num2str(f)], ['y_regress_' bhvr_nm{b2} '.mat']));
                curr_yt2(full_split2.sub_fold(f).fold_index==1) = y_reg.y_resid(full_split2.sub_fold(f).fold_index==1);
            end

            err1 = curr_yt1(WA_idx) - curr_yp1(WA_idx);
            err2 = curr_yt2(WA_idx) - curr_yp2(WA_idx);
            err_corr(pair, i) = CBIG_corr(err1, err2);
            err_spcorr(pair, i) = corr(err1, err2, 'Type', 'Spearman');

            pair = pair + 1;
        end
    end
end

outdir = fileparts(PhenoCorr_out);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(PhenoCorr_out, 'y_corr', 'y_spcorr')

outdir = fileparts(ErrCorr_out);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(ErrCorr_out, 'err_corr', 'err_spcorr')

    
end