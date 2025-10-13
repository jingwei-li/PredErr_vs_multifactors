from pathlib import Path
import argparse

from scipy.io import loadmat
import datalad.api as dl
import numpy as np
import pandas as pd


def read_data(data_file: Path, usecols: list, subjects: list, str_col: list = []) -> pd.DataFrame:
    dtypes = {"subjectkey": str}
    dtypes.update({col: float for col in usecols})
    dtypes.update({col: str for col in str_col})
    data = pd.read_table(
        data_file, usecols=usecols+["subjectkey"], dtype=dtypes, index_col="subjectkey",
        skiprows=[1])
    data = data.groupby(data.index).first()
    data = data.loc[data.index.isin(subjects)]
    return data


def read_icv(fs_stats_file: Path, fs_dir: Path) -> float:
    dl.get(fs_stats_file, dataset=fs_dir)
    with open(fs_stats_file, "r") as f:
        for line in f.read().splitlines():
            if "Estimated Total Intracranial Volume" in line:
                icv = float(line.split(", ")[3])
    dl.drop(fs_stats_file, dataset=fs_dir, reckless="kill")
    return icv


def read_motion(
        func_dir: Path, sub_dir: Path, subject: str, ses: str, runs: list) -> tuple[float, ...]:
    fd_runs = np.zeros(len(runs))
    dvars_runs = np.zeros(len(runs))
    for run_i, run in enumerate(runs):
        mt_file = Path(func_dir, f"{subject}_{ses}_task-rest_{run}_desc-confounds_timeseries.tsv")
        dl.get(mt_file, dataset=sub_dir)
        motion = pd.read_table(mt_file)
        if "non_steady_state_outlier00" in motion.columns:
            frame_start = int(motion["non_steady_state_outlier00"].sum())
        else:
            frame_start = 0
        fd_runs[run_i] = np.mean(motion["rmsd"].iloc[frame_start:])
        dvars_runs[run_i] = np.mean(motion["dvars"].iloc[frame_start:])
        dl.drop(mt_file, dataset=sub_dir, reckless="kill")
    return fd_runs.mean(), dvars_runs.mean()


parser = argparse.ArgumentParser(
    description="Get the final subject list with phenotypes and cross-vaidation indices")
parser.add_argument("--pheno_dir", help="Asbolute path to phenotype directory")
parser.add_argument("--colloq_csv", help="Absolute path to the colloquial names csv")
parser.add_argument("--sublist_txt", help="Absoulte path to a starting subject list")
parser.add_argument("--out_dir", help="Absolute path to output directory")
parser.add_argument("--fs_dir", help="Absolute path to freesurfer dataset")
parser.add_argument("--fp_dir", help="Absolute path to fmriprep dataset")
parser.add_argument("--censor_mat", help="Absolute path to the censoring output .mat file")
args = parser.parse_args()

sublist = pd.read_table(args.sublist_txt, header=None).squeeze()
subjectkey = "NDAR_" + sublist.str.split("NDAR").str[1]
sub_info = pd.DataFrame(
    {"participant_id": sublist, "subjectkey": subjectkey}).set_index("subjectkey")
colloq = pd.read_csv(args.colloq_csv).squeeze().to_dict()

# Cognition
tbss_cols = [
    "nihtbx_flanker_uncorrected", "nihtbx_list_uncorrected", "nihtbx_cardsort_uncorrected",
    "nihtbx_reading_uncorrected", "nihtbx_pattern_uncorrected", "nihtbx_picture_uncorrected",
    "nihtbx_picvocab_uncorrected", "nihtbx_fluidcomp_uncorrected", "nihtbx_cryst_uncorrected",
    "nihtbx_totalcomp_uncorrected"]
tbss = read_data(Path(args.pheno_dir, "abcd_tbss01.txt"), tbss_cols, subjectkey)
ps_cols = ["pea_ravlt_sd_trial_vi_tc", "pea_ravlt_ld_trial_vii_tc", "pea_wiscv_trs"]
ps = read_data(Path(args.pheno_dir, "abcd_ps01.txt"), ps_cols, subjectkey)
lmt_cols = ["lmt_scr_perc_correct", "lmt_scr_rt_correct"]
lmt = read_data(Path(args.pheno_dir, "lmtp201.txt"), lmt_cols, subjectkey)

# Mental health
cbcl_cols = [
    "cbcl_scr_syn_anxdep_r", "cbcl_scr_syn_withdep_r", "cbcl_scr_syn_somatic_r",
    "cbcl_scr_syn_social_r", "cbcl_scr_syn_thought_r", "cbcl_scr_syn_attention_r",
    "cbcl_scr_syn_rulebreak_r", "cbcl_scr_syn_aggressive_r"]
cbcl = read_data(Path(args.pheno_dir, "abcd_cbcls01.txt"), cbcl_cols, subjectkey)
mhp = read_data(Path(args.pheno_dir, "abcd_mhp02.txt"), ["pgbi_p_ss_score"], subjectkey)
mhy_cols = [
    "pps_y_ss_number", "pps_y_ss_severity_score", "upps_y_ss_negative_urgency",
    "upps_y_ss_positive_urgency", "upps_y_ss_lack_of_planning", "upps_y_ss_lack_of_perseverance",
    "upps_y_ss_sensation_seeking", "bis_y_ss_bis_sum", "bis_y_ss_bas_rr", "bis_y_ss_bas_drive",
    "bis_y_ss_bas_fs"]
mhy = read_data(Path(args.pheno_dir, 'abcd_mhy02.txt'), mhy_cols, subjectkey)

# Sociodemographic covariates: age, sex, parental education
lt_cols = ["interview_age", "sex", "site_id_l"]
lt = read_data(Path(args.pheno_dir, "abcd_lt01.txt"), lt_cols, subjectkey, ["sex", "site_id_l"])
pdem_cols = ["demo_prnt_ed_v2", "demo_prtnr_ed_v2"]
pdem = read_data(Path(args.pheno_dir, "pdem02.txt"), pdem_cols, subjectkey)
pdem = pdem.loc[(pdem["demo_prnt_ed_v2"] <= 21) & (pdem["demo_prtnr_ed_v2"] <= 21)]

# Subjects with all phenotype data available
data_all = [sub_info, tbss, ps, lmt, cbcl, mhp, mhy, lt, pdem]
sub_data = pd.concat(data_all, axis="columns").dropna()
sub_data = sub_data.rename(columns=colloq)
sublist_all = ("sub-NDAR" + sub_data.index.str.split("NDAR_").str[1]).to_list()

# Separate sex and education columns
conf_cols = ["interview_age", "site_id_l", "ICV", "FD", "DVARS"]
conf_cols_drop = []
conf_cols_pred = conf_cols + ["sex", "demo_prnt_ed_v2", "demo_prtnr_ed_v2"]
new_data = pd.get_dummies(sub_data["sex"]).astype(int)
for c in new_data.columns:
    sub_data["sex"+'_'+c] = new_data[c]
    conf_cols.append("sex"+'_'+c)
    conf_cols_drop.append("sex"+'_'+c)
sub_data["sex"] = sub_data["sex"].astype("category").cat.codes
new_data = pd.get_dummies(sub_data["demo_prnt_ed_v2"]).astype(int)
for c in new_data.columns:
    sub_data["prnt_ed"+'_'+str(c)] = new_data[c]
    conf_cols.append("prnt_ed"+'_'+str(c))
    conf_cols_drop.append("prnt_ed"+'_'+str(c))
new_data = pd.get_dummies(sub_data["demo_prtnr_ed_v2"]).astype(int)
for c in new_data.columns:
    sub_data["prtnr_ed"+'_'+str(c)] = new_data[c]
    conf_cols.append("prtnr_ed"+'_'+str(c))
    conf_cols_drop.append("prtnr_ed"+'_'+str(c))

# Imaging covariates: ICV, FD, DVARS
imag = {"ICV": {}, "FD": {}, "DVARS": {}}
censor = loadmat(args.censor_mat)
for subject_i, subject in enumerate(sublist_all):
    print(subject_i, subject)
    fs_stats_file = Path(args.fs_dir, subject, "stats", "aseg.stats")
    if subject == "sub-NDARINVRCE62M22":
        imag["ICV"][subject] = np.nan
    else:
        imag["ICV"][subject] = read_icv(fs_stats_file, Path(args.fs_dir, subject))
    func_dir = Path(args.fp_dir, subject, "ses-baselineYear1Arm1", "func")
    subject_i = np.where(censor["subjects_all"][:, 0] == subject)
    runs = np.concatenate(censor["pass_runs"][:, subject_i][0][0][0][0]).tolist()
    imag["FD"][subject], imag["DVARS"][subject] = read_motion(
        func_dir, Path(args.fp_dir, subject), subject, "ses-baselineYear1Arm1", runs)
imag_data = pd.DataFrame(imag)
subjectkey = "NDAR_" + imag_data.index.str.split("NDAR").str[1]
imag_data = imag_data.set_index(subjectkey)

sub_data = pd.concat([sub_data, imag_data], axis="columns").dropna()
sub_data_split = sub_data.copy()
sub_data_split.drop(columns=["sex", "demo_prnt_ed_v2", "demo_prtnr_ed_v2"], inplace=True)
sub_data.drop(columns=conf_cols_drop, inplace=True)
sub_data.to_csv(Path(args.out_dir, "abcd_subjects_pheno.csv"))

sub_data[["participant_id"]+list(colloq.values())].to_csv(
    Path(args.out_dir, "ABCD_y.csv"), index=None)
sub_data[["participant_id"]+conf_cols_pred].to_csv(Path(args.out_dir, "ABCD_conf.csv"), index=None)
sub_data_split[["participant_id"]+conf_cols].to_csv(
    Path(args.out_dir, "ABCD_conf_split.csv"), index=None)
sub_data[["participant_id"]].to_csv(
    Path(args.out_dir, "sublist_allbehavior.csv"), index=None, header=None)
with open(Path(args.out_dir, 'confound_list.txt'), 'w') as f:
    for item in conf_cols:
        f.write("%s\n" % item)

print(sub_data[['participant_id']+conf_cols_pred])
