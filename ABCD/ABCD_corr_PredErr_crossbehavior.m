function ABCD_corr_PredErr_crossbehavior(model_dir, subfold_dir, bhvr_ls, outmat)

% ABCD_corr_PredErr_crossbehavior(model_dir, subfold_dir, bhvr_ls, outmat)
%
% 

[bhvr_nm, nbhvr] = CBIG_text2cell(bhvr_ls);
nfolds = 120;

ker_param.type = 'corr';
ker_param.scale = NaN;
ker_param = struct2cell(ker_param);
lambda_set = [ 0 0.00001 0.0001 0.001 0.004 0.007 0.01 0.04 0.07 0.1 0.4 0.7 1 1.5 2 2.5 3 3.5 4 ...
    5 10 15 20];

for b = 1:nbhvr
    load(fullfile(subfold_dir, ['sub_fold_pass_rs_pass_pheno_' bhvr_nm{b} '.mat']))
    opt = load(fullfile(model_dir, bhvr_nm{b}, ['final_result_' bhvr_nm{b} '.mat']));
    curr_err_sum = zeros(length(sub_fold(1).fold_index), 1);
    curr_sum = zeros(length(sub_fold(1).fold_index), 1);
    for f = 1:nfolds
        test_cv = load(fullfile(model_dir, bhvr_nm{b}, 'test_cv', ...
            ['fold_' num2str(f)], ['acc_' bhvr_nm{b} '.mat']));

        opt_kernel_idx = strcmp(ker_param(1,:,:), opt.optimal_kernel(f).type);
        opt_lambda_idx = lambda_set == opt.optimal_lambda(f);
        opt_thres_idx = 1;

        curr_err = test_cv.y_t{opt_kernel_idx, opt_lambda_idx, opt_thres_idx}{1} - ...
            test_cv.y_p{opt_kernel_idx, opt_lambda_idx, opt_thres_idx}{1};
        curr_err_sum(sub_fold(f).fold_index==1) = curr_err_sum(sub_fold(f).fold_index==1) + curr_err;
        curr_sum(sub_fold(f).fold_index==1) = curr_sum(sub_fold(f).fold_index==1) + 1;
    end
    err(:, b) = curr_err_sum ./ curr_sum;
end

pair = 1;
for b1 = 1:nbhvr-1
    nan_idx1 = find(isnan(err(:,b1)));
    for b2 = (b1+1):nbhvr
        nan_idx2 = find(isnan(err(:,b2)));
        idx = setdiff(1:size(err,1), union(nan_idx1, nan_idx2));
        err_corr(pair, 1) = CBIG_corr(err(idx,b1), err(idx,b2));
        err_spcorr(pair, 1) = corr(err(idx,b1), err(idx,b2), 'Type', 'Spearman');
        pair = pair+1;
    end
end

outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir);
end
save(outmat, 'err', 'err_corr', 'err_spcorr');
    
end