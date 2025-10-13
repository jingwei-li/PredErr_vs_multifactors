function [perf, weights, b] = KRR_one_fold(x, y, kernel, conf, cv_ind, fold, seed, lambdas)
    % [perf, weights, b] = KRR_one_fold(x, y, kernel, conf, cv_ind, fold, seed, lambdas)
    %
    % This function runs Kernel Ridge Regression for one cross-validation fold. The relationship
    % between features and targets is assumed to be y = K(x, x) * weights + b.
    %
    % The lambda parameter is determined via inner-loop cross-validation optimising the
    % correlation between predicted and actual values of the target variables.
    %
    % For now I assume that no feature selection is used.
    %
    % Inputs:
    %       - x       :
    %                  NxP matrix containing P features from N subjects
    %       - y       :
    %                  NxT matrix containing T target values from N subjects
    %       - kernel  :
    %                  The type of kernel to apply on x. Choices are:
    %                  'poly2' (2nd order polynomial): K(a, b) = (a' * b + 1)^2
    %                  'corr' (correlation): K(a, b) = corr(a, b)
    %       - conf    :
    %                  NxC matrix containing C confounding variables from N subjects
    %                  Set this to [] if no confound is to bbe removed
    %       - cv_ind  :
    %                  Nx1 matrix containing cross-validation fold assignment for N subjects. Values
    %                  should range from 1 to K for a K-fold cross-validation
    %       - fold    :
    %                  Fold to be used as validation set
    %       - seed    :
    %                  Seed used to randomise the inner-loop indices. User either a scalar or 'shuffle'
    %       - lambas  :
    %                  Vector of values to try for tuning the regularisation parameter lambda
    %                  default: [0, 0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1 5 10]
    %
    % Output:
    %       - r_test :
    %                 Pearson correlation between predicted target values and actual target values in
    %                 validation set
    %       - r_train:
    %                 Pearson correlation between predicted target values and actual target values in
    %                 training set
    %       - weights:
    %                 Kx1 matrix containing weights of the K training subjects
    %       - b      :
    %                 Intercept value
    %
    % Example:
    % [r_test, r_train] = KRR_one_fold(x, y, 'poly2', conf, cv_ind, 1, 'shuffle')
    % This command runs KRR using fold 1 as validation set, and the rest as
    % training set, using 2nd order polynomial kernel
    %
    % Jianxiao Wu, last edited on 25-11-2019
    
    % Usage
    if nargin < 7
        disp('[perf, weights, b] = KRR_one_fold(x, y, kernel, conf, cv_ind, fold, seed, [lambdas])');
        return
    end
    
    % Default lambda values
    if nargin < 8
        lambdas = [0, 0.0001, 0.0005, 0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1 5 10];
    end
    
    % Apply kernel to features
    switch kernel
        case 'poly2'
            x_kernel = (x * x' + 1).^2;
        case 'corr'
            x_kernel = corr(x');
            x_kernel(isnan(x_kernel)) = 0;
        otherwise
            disp('Invalid kernel type');
            return
    end
    
    % Split outer training/test sets
    x_train = x_kernel(cv_ind~=fold, cv_ind~=fold);
    y_train = y(cv_ind~=fold, :);
    x_test = x_kernel(cv_ind==fold, cv_ind~=fold);
    y_test = y(cv_ind==fold, :);
    if numel(conf) ~= 0
        conf_train = conf(cv_ind~=fold, :);
        conf_test = conf(cv_ind==fold, :);
    end
    
    % Tune lambda (regularisation parameter)
    r_lambda = zeros(size(lambdas));
    for i = 1:length(lambdas)
        lambda = lambdas(i);
        
        % set up inner-loop indices
        rng(seed);
        inner_ind = cvpartition(size(x_train, 1), 'KFold', 10); %10-fold CV
        
        % 10-fold inner-loop cross-validation
        for fold_inner = 1:10
            x_train_inner = x_train(inner_ind.training(fold_inner), inner_ind.training(fold_inner));
            y_train_inner = y_train(inner_ind.training(fold_inner), :);
            x_val = x_train(inner_ind.test(fold_inner), inner_ind.training(fold_inner));
            y_val = y_train(inner_ind.test(fold_inner), :);
            
            % regress out confounds if necessary
            if numel(conf) ~= 0
                conf_train_inner = conf_train(inner_ind.training(fold_inner), :);
                conf_val = conf_train(inner_ind.test(fold_inner), :);
                [y_train_inner, reg_y] = regress_confounds_y(y_train_inner, conf_train_inner);
                y_val = regress_confounds_y(y_val, conf_val, reg_y);
            end
            
            % compute KRR
            [perf, ~, ~] = compute_krr(x_train_inner, y_train_inner, x_val, y_val, lambda);
            if ~isnan(perf.r_test)
                r_lambda(i) = r_lambda(i) + perf.r_test/10;
            end
        end
    end
    
    % Test model with best lambda
    lambda_best = lambdas(r_lambda==max(r_lambda));
    if size(lambda_best, 2) > 1
        lambda_best = lambda_best(1);
    end
    if numel(conf) ~= 0
        [y_train, reg_y] = regress_confounds_y(y_train, conf_train);
        y_test = regress_confounds_y(y_test, conf_test, reg_y);
    end
    [perf, weights, b] = compute_krr(x_train, y_train, x_test, y_test, lambda_best);
end
    
function [perf, alpha, b] = compute_krr(x_train, y_train, x_test, y_test, lambda)
    % training
    % k_lambda = N_train_inner x N_train_inner matrix
    k_lambda = x_train + lambda * eye(size(x_train, 1));
    % one_row = N_train_inner x 1 vector
    one_row = ones(size(x_train, 1), 1);
    if rank(k_lambda) >= size(x_train, 1) % if N(features) > N(subjects)
        % b = scalar
        b = (one_row' * (k_lambda \ one_row)) \ one_row' * (k_lambda \ y_train);
        % alpha = N_train_inner x 1 vector
        alpha = k_lambda \ (y_train - one_row * b);
    else % if N(features) < N(subjects)
        b = pinv(one_row' * pinv(k_lambda))' * (pinv(k_lambda) * y_train);
        alpha = pinv(k_lambda) * (y_train - one_row * b);
    end
    
    % training set performance
    y_train_pred = x_train * alpha + ones(size(y_train, 1), 1) * b;
    perf.r_train = corr(y_train_pred, y_train, 'type', 'Pearson', 'Rows', 'complete');
    perf.nrmsd_train = sqrt(sum((y_train - y_train_pred).^2) / (length(y_train) - 1)) / std(y_train);
    
    % test set performance
    y_test_pred = x_test * alpha + ones(size(y_test, 1), 1) * b;
    perf.r_test = corr(y_test_pred, y_test, 'type', 'Pearson', 'Rows', 'complete');
    perf.nrmsd_test = sqrt(sum((y_test - y_test_pred).^2) / (length(y_test) - 1)) / std(y_test);

    % edited by Jianxiao -- save true and predicted scores
    perf.y_test = y_test;
    perf.ypred_test = y_test_pred;
end
    