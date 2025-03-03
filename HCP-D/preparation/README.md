## HCP Development data processing

### Previously computed data

Subjects with all resting-state runs available:

```bash
python3 create_allRun_sublists.py ${proj_dir}/phenotype ${proj_dir}/lists \
    ${proj_dir}/scripts/PredErr_vs_multifactors/HCP-D/lists/HCP-D_exclude.csv
```

RSFC computed in the mpp project: 

```bash
datalad clone git@gin.g-node.org:/jadecci/multimodal_features.git
```

### Extract features/confounds

1. DVARS

```bash
./HCP-D_collect_DVARS.sh -c ${proj_dir}/containers/images/neurodesk/neurodesk-fsl--6.0.5.1.simg \
    -d ${proj_dir}/data/datasets_repo/original/hcp/hcp_development \
    -s ${proj_dir}/lists/HCP-D_allRun.csv \
    -o ${proj_dir}/results/HCP-D/lists/dvars
```

```bash
python3 HCP-D_average_DVARS.py -s ${proj_dir}/lists/HCP-D_allRun.csv
```

2. FD

```bash
python3 HCP-D_collect_FD.py ${proj_dir}/results/HCP-D/lists/FD.allsub.txt \
    -d ${proj_dir}/data/datasets_repo/original/hcp/hcp_development \
    -s ${proj_dir}/lists/HCP-D_allRun.csv
```

3. ICV

```bash
python3 HCP-D_collect_ICV.sh -outdir ${proj_dir}/results/HCP-D/lists -outbase_suffix allsub
```

4. Confounds: age, sex, site, education (saved together wigh DVARS, FD, and ICV)

```bash
python3 HCP-D_extract_targets_confounds.py \
    --in_dir ${proj_dir}/data/datasets_repo/original/hcp/hcp_development/phenotype \
    --sub_list ${proj_dir}/lists/HCP-D_allRun.csv \
    --ICV_txt ${proj_dir}/results/HCP-D/lists/ICV.allsub.txt \
    --FD_txt ${proj_dir}/results/HCP-D/lists/FD.allsub.txt \
    --DV_txt ${proj_dir}/results/HCP-D/lists/DV.allsub.txt \
    --psy_csv ${proj_dir}/scripts/PredErr_vs_multifactors/HCP-D/lists/behavior_names.csv \
    --colloq_csv ${proj_dir}/scripts/PredErr_vs_multifactors/HCP-D/lists/colloquial_names.csv \
    --out_dir ${proj_dir}/results/HCP-D/lists
```
