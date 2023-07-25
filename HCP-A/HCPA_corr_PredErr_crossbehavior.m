function HCPA_corr_PredErr_crossbehavior(colloq_txt, cbpp_dir, outmat)

% HCPA_corr_PredErr_crossbehavior(colloq_txt, cbpp_dir, outmat)
%
% 

method = 'SVR';
atlas = 'SchMel4';
nrep = 100;

colloq_names = table2array(readtable(colloq_txt, 'delimiter', ',', 'ReadVariableNames', false));
convert_fun = @(x)regexprep(x, ' +', '_');
filestems = convert_fun(colloq_names);
nbhvr = length(filestems);

for i = 1:nbhvr
    matname = fullfile(cbpp_dir, ['wbCBPP_' method '_standard_' filestems{i} '_' atlas '.mat']);
    load(matname)
    err(:,i,:) = (yt - yp)';
end

for i = 1:nrep
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