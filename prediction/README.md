## Behavior prediction
### HCP Development

```bash
target_list=${proj_dir}/scripts/PredErr_vs_multifactors/HCP-D/lists/colloquial_list.txt
data_dir=${proj_dir}/results/HCP-D/lists
fc_dir=${proj_dir}/data/mfe_output/HCP-D
out_dir=${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors
matlab914 -nojvm -singleCompThread \
    -batch "cbpp_allbehav('$target_list', '$data_dir', 'HCP-D', '$fc_dir', '$out_dir')"
```

### HCP Young Adult

```bash
target_list=${proj_dir}/scripts/PredErr_vs_multifactors/HCP/lists/colloquial_list.txt
data_dir=${proj_dir}/results/HCP/lists
fc_dir=${proj_dir}/data/mfe_output/HCP
out_dir=${proj_dir}/results/HCP/cbpp/796sub_51behaviors
matlab914 -nojvm -singleCompThread \
    -batch "cbpp_allbehav('$target_list', '$data_dir', 'HCP', '$fc_dir', '$out_dir')"
```

### ABCD

```bash
target_list=${proj_dir}/scripts/PredErr_vs_multifactors/ABCD/lists/colloquial_list.txt
data_dir=${proj_dir}/results/ABCD/lists
fc_dir=${proj_dir}/results/ABCD/rsfc_pearson
out_dir=${proj_dir}/results/ABCD/cbpp/4278sub_34behaviors
matlab914 -nojvm -singleCompThread \
    -batch "cbpp_allbehav('$target_list', '$data_dir', 'ABCD', '$fc_dir', '$out_dir')"
```

### Plot prediction accuracies

```bash
for method in SVR KRR; do
    python3 plot_accuracy.py --dataset HCP-D --method $method \
        --coloq_txt ${proj_dir}/scripts/PredErr_vs_multifactors/HCP-D/lists/colloquial_list.txt \
        --pred_dir ${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors \
        --out_dir ${proj_dir}/results/HCP-D/cbpp/figures \
        --out_stem 22behavior_acc
    python3 plot_accuracy.py --dataset HCP --method $method \
        --coloq_txt ${proj_dir}/scripts/PredErr_vs_multifactors/HCP/lists/colloquial_list.txt \
        --pred_dir ${proj_dir}/results/HCP/cbpp/796sub_51behaviors \
        --out_dir ${proj_dir}/results/HCP/cbpp/figures \
        --out_stem 51behavior_acc
    python3 plot_accuracy.py --dataset ABCD --method $method \
        --coloq_txt ${proj_dir}/scripts/PredErr_vs_multifactors/ABCD/lists/colloquial_list.txt \
        --pred_dir ${proj_dir}/results/ABCD/cbpp/4278sub_34behaviors \
        --out_dir ${proj_dir}/results/ABCDD/cbpp/figures \
        --out_stem 34behavior_acc
done
```

## Behavior clustering
First, correlations between prediction errors for each pair of behavioral measures are computed. Then the categories of behavioral measures are determined and entered manually. Finally, the normalized average prediction errors are computed for each cateogry.

### Correlation of prediction errors
#### HCP Development

```bash
colloq_txt=${proj_dir}/scripts/PredErr_vs_multifactors/HCP-D/lists/colloquial_list.txt
pred_dir=${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors
for method in SVR KRR; do
    outmat=${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors/corr_PredErr_${method}.mat
    matlab914 -nojvm -singleCompThread \
        -batch "corr_PredErr_crossbehav('HCP-D', '$method', '$colloq_txt', '$pred_dir', '$outmat')"
done
```

#### HCP Young Adult

```bash
colloq_txt=${proj_dir}/scripts/PredErr_vs_multifactors/HCP/lists/colloquial_list.txt
pred_dir=${proj_dir}/results/HCP/cbpp/784sub_51behaviors
for method in SVR KRR; do
    outmat=${proj_dir}/results/HCP/cbpp/784sub_51behaviors/corr_PredErr_${method}.mat
    matlab914 -nojvm -singleCompThread \
        -batch "corr_PredErr_crossbehav('HCP', '$method', '$colloq_txt', '$pred_dir', '$outmat')"
done
```

#### ABCD

```bash
colloq_txt=${proj_dir}/scripts/PredErr_vs_multifactors/ABCD/lists/colloquial_list.txt
pred_dir=${proj_dir}/results/ABCD/cbpp/4278sub_34behaviors
for method in SVR KRR; do
    outmat=${proj_dir}/results/ABCD/cbpp/4278sub_34behaviors/corr_PredErr_${method}.mat
    matlab914 -nojvm -singleCompThread \
        -batch "corr_PredErr_crossbehav('ABCD', '$method', '$colloq_txt', '$pred_dir', '$outmat')"
done
```

### Average prediction error for each category

#### HCP Development

```bash
colloq_txt=${proj_dir}/scripts/PredErr_vs_multifactors/HCP-D/lists/colloquial_list.txt
pred_dir=${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors
for method in SVR KRR; do
    outmat=${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors/avg_PredErr_${method}.mat
    clscsv=${proj_dir}/results/HCP-D/lists/behavior_cls_${method}_above0.3.csv
    matlab914 -nojvm -singleCompThread \
        -batch "avg_PredErr('HCP-D', '$method', '$pred_dir', '$colloq_txt', '$clscsv', '$outmat')"
done
```

#### HCP Young Adult

```bash
colloq_txt=${proj_dir}/scripts/PredErr_vs_multifactors/HCP/lists/colloquial_list.txt
pred_dir=${proj_dir}/results/HCP/cbpp/784sub_51behaviors
for method in SVR KRR; do
    outmat=${proj_dir}/results/HCP/cbpp/784sub_51behaviors/avg_PredErr_${method}.mat
    clscsv=${proj_dir}/results/HCP/lists/behavior_cls_${method}_above0.3.csv
    matlab914 -nojvm -singleCompThread \
        -batch "avg_PredErr('HCP', '$method', '$pred_dir', '$colloq_txt', '$clscsv', '$outmat')"
done
```

#### ABCD

```bash
colloq_txt=${proj_dir}/scripts/PredErr_vs_multifactors/ABCD/lists/colloquial_list.txt
pred_dir=${proj_dir}/results/ABCD/cbpp/4278sub_34behaviors
for method in SVR KRR; do
    outmat=${proj_dir}/results/ABCD/cbpp/4278sub_34behaviors/avg_PredErr_${method}.mat
    clscsv=${proj_dir}/results/ABCD/lists/behavior_cls_${method}_above0.4.csv
    matlab914 -nojvm -singleCompThread \
        -batch "avg_PredErr('ABCD', '$method', '$pred_dir', '$colloq_txt', '$clscsv', '$outmat'')"
done
```
