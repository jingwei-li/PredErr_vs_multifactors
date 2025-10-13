## HCP Young Adult data processing

### Previously computed data

Subjects with all resting-state runs available:

```bash
python3 create_allRun_sublists.py ${proj_dir}/phenotype ${proj_dir}/lists \
    ${proj_dir}/scripts/PredErr_vs_multifactors/HCP/lists/HCP-YA_exclude.csv
```

RSFC computed in the mpp project: 

```bash
datalad clone git@gin.g-node.org:/jadecci/multimodal_features.git
```

### Extract features/confounds

1. DVARS

```bash
./HCP_collect_DVARS.sh -c ${proj_dir}/containers/images/neurodesk/neurodesk-fsl--6.0.5.1.simg \
    -d ${proj_dir}/data/human-connectome-project-openaccess/HCP1200 \
    -s ${proj_dir}/lists/HCP-YA_allRun.csv \
    -o ${proj_dir}/results/HCP/lists/dvars
```

```bash
python3 HCP_average_DVARS.py -s ${proj_dir}/lists/HCP-YA_allRun.csv
```

2. FD

```bash
python3 HCP_collect_FD.py ${proj_dir}/results/HCP/lists/FD.allsub.txt \
    -d ${proj_dir}/data/human-connectome-project-openaccess \
    -s ${proj_dir}/lists/HCP-YA_allRun.csv
```

3. ICV

```bash
python3 HCP_collect_ICV.sh -outdir ${proj_dir}/results/HCP/lists -outbase_suffix allsub
```

4. Confounds: age, sex, site, education (saved together wigh DVARS, FD, and ICV)

```bash
python3 HCP_extract_targets_confounds.py \
    --unres_csv ${proj_dir}/data/unrestricted_hcpya.csv \
    --res_csv ${proj_dir}/data/restricted_hcpya.csv \
    --sub_list ${proj_dir}/lists/HCP-YA_allRun.csv \
    --ICV_txt ${proj_dir}/results/HCP/lists/ICV.allsub.txt \
    --FD_txt ${proj_dir}/results/HCP/lists/FD.allsub.txt \
    --DV_txt ${proj_dir}/results/HCP/lists/DV.allsub.txt \
    --psy_csv ${proj_dir}/scripts/PredErr_vs_multifactors/HCP/lists/behavior_names.csv \
    --colloq_csv ${proj_dir}/scripts/PredErr_vs_multifactors/HCP/lists/colloquial_names.csv \
    --out_dir ${proj_dir}/results/HCP/lists
```

5. Euler characteristics

```bash
python3 HCP_collect_Euler.py
```
