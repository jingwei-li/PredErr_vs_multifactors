function HCP_corr_PredErr_crossbehavior(model_dir, bhvr_ls, use_seed_bhvr_ldir, outmat)

% corr_PredErr_crossbehavior()
%
% 

nfolds = 10;
nseeds = 40;
seed_ub = 400;
[bhvr_nm, nbhvr] = CBIG_text2cell(bhvr_ls);

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
            final = load(fullfile(model_dir, ['randseed_' num2str(i)], ...
                curr_bhvr_nm{b}, ['final_result_' curr_bhvr_nm{b} '.mat']));
            curr_yp = final.y_predict_concat;

            load(fullfile(model_dir, ['randseed_' num2str(i)], curr_bhvr_nm{b}, ...
                ['no_relative_' num2str(nfolds) '_fold_sub_list_' curr_bhvr_nm{b} '.mat']));
            curr_yt = nan(size(curr_yp));
            for f = 1:nfolds
                y_reg = load(fullfile(model_dir, ['randseed_' num2str(i)], ...
                    curr_bhvr_nm{b}, 'y', ['fold_' num2str(f)], ['y_regress_' curr_bhvr_nm{b} '.mat']));
                curr_yt(sub_fold(f).fold_index==1) = y_reg.y_resid(sub_fold(f).fold_index==1);
            end
            %err(:, IB(b), seed_counts(IB(b))) = curr_yt - curr_yp;
            err(:, IB(b), seed_counts(IB(b))) = abs(curr_yt - curr_yp);
        end
    end
end

for b = 1:nbhvr
    if(seed_counts(b) ~= nseeds)
        error('Number of seed counts of %s is wrong.', bhvr_ls{b})
    end
end


for i = 1:nseeds
    pair = 1;
    for b1 = 1:nbhvr-1
        for b2 = (b1+1):nbhvr
            err_corr(pair, i) = CBIG_corr(err(:,b1,i), err(:,b2,i));
            err_spcorr(pair, i) = corr(err(:,b1,i), err(:,b2,i), 'Type', 'Spearman');
            pair = pair+1;
        end
    end
end

outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outmat, 'err', 'err_corr', 'err_spcorr')
    
end