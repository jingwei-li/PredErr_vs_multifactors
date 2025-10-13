from pathlib import Path
import argparse
import pandas as pd

parser = argparse.ArgumentParser(
    description="generate subject lists for HCP datasets",
    formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument("pheno_dir", type=Path, help="absolute path to phenotype directory")
parser.add_argument("out_dir", type=Path, help="absolute path to output directory")
parser.add_argument("hcpya_exclude", type=Path, help="absolute path to HCP-YA exclusion list")
args = parser.parse_args()

# HCP-YA
hcpya_pheno_file = Path(args.pheno_dir, "unrestricted_hcpya.csv")
hcpya_scores = ["Subject", "T1_Count", "3T_RS-fMRI_Count", "3T_tMRI_PctCompl", "3T_dMRI_PctCompl"]
hcpya_data = pd.read_csv(hcpya_pheno_file, usecols=hcpya_scores)[hcpya_scores]
hcpya_exclude = pd.read_csv(args.hcpya_exclude, header=None).squeeze().to_list()
hcpya_data.drop(hcpya_data.loc[hcpya_data["Subject"].isin(hcpya_exclude)].index, inplace=True)
hcpya_data.drop(hcpya_data.loc[hcpya_data["T1_Count"] == 0].index, inplace=True)
hcpya_data.drop(hcpya_data.loc[hcpya_data["3T_RS-fMRI_Count"] == 0].index, inplace=True)
hcpya_data.drop(hcpya_data.loc[hcpya_data["3T_tMRI_PctCompl"] != 100].index, inplace=True)
hcpya_data.drop(hcpya_data.loc[hcpya_data["3T_dMRI_PctCompl"] != 100].index, inplace=True)
hcpya_out_file = Path(args.out_dir, "HCP-YA_allRun.csv")
hcpya_data["Subject"].to_csv(hcpya_out_file, header=False, index=False)
