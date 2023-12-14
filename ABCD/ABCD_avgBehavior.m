function ABCD_avgBehavior(model_dir, full_bhvr_ls, bhvr_cls_csv, outmat)

% ABCD_avgBehavior(model_dir, full_bhvr_ls, bhvr_cls_csv, outmat)
%
% 

[bhvr_nm, nbhr] = CBIG_text2cell(full_bhvr_ls);
T = readtable(bhvr_cls_csv, 'Delimiter', ',', 'headerlines', 0);
headers = T.Properties.VariableNames;

for c = 1:length(headers)
    bhvr_cls = T.(headers{c});
    bhvr_cls = bhvr_cls(~cellfun('isempty', bhvr_cls));

    load(fullfile(model_dir, bhvr_cls{1}, ['y_' bhvr_cls{1} '.mat']));
    bhvr1 = (y - mean(y)) ./ std(y, 1);
    bhvr_avg.(headers{c}) = bhvr1;
    clear y

    for b = 2:length(bhvr_cls)
        load(fullfile(model_dir, bhvr_cls{b}, ['y_' bhvr_cls{b} '.mat']));
        curr_bhvr = (y - mean(y)) ./ std(y, 1);
        curr_corr = corr(bhvr1, curr_bhvr);
        fprintf('Class %d: corr(behavior1, behavior%d) = %f\n', c, b, curr_corr)
        if(curr_corr >= 0)
            bhvr_avg.(headers{c}) = bhvr_avg.(headers{c}) + curr_bhvr;
        else
            bhvr_avg.(headers{c}) = bhvr_avg.(headers{c}) + curr_bhvr .* -1;
        end
    end
    bhvr_avg.(headers{c}) = bhvr_avg.(headers{c}) ./ length(bhvr_cls);
end

outdir = fileparts(outmat);
if(~exist(outdir, 'dir'))
    mkdir(outdir)
end
save(outmat, 'bhvr_avg')

end