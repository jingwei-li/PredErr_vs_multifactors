## HCP Development prediction error analysis

For data processing, see README in the folder `preparation`.

### Behavior prediction

1. Run prediction

```console
target_list=${proj_dir}/scripts/PredErr_vs_multifactors/HCP-D/lists/colloquial_list.txt
psy_file=${proj_dir}/results/HCP-D/lists/HCP-D_y.csv
conf_file=${proj_dir}/results/HCP-D/lists/HCP-D_conf.csv
sublist=${proj_dir}/results/HCP-D/lists/sublist_allbehavior.csv
fc_dir=${proj_dir}/data/mfe_output/HCP-D
out_dir=${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors
while IFS= read -r line; do
    matlab914 -nojvm -singlecompThread \
        -batch "HCPD_cbpp('$line', '$psy_file', '$conf_file', '$sublist', '$fc_dir', '$out_dir')"
done < $target_list
```

2. Plot prediction accuracies

```console
target_list=${proj_dir}/scripts/PredErr_vs_multifactors/HCP-D/lists/colloquial_list.txt
acc_dir=${proj_dir}/results/HCP-D/cbpp/432sub_22behaviors
out_dir=${proj_dir}/results/HCP-D/cbpp/figures
matlab914 -singlecompThread \
    -batch "HCPD_plot_accuracy('$target_list', '$acc_dir', '$out_dir', 'SVR_22behaviors_acc_corr')"
```
