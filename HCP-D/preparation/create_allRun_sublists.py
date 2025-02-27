from pathlib import Path
import argparse
import pandas as pd

parser = argparse.ArgumentParser(
    description="generate subject lists for HCP datasets",
    formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument("pheno_dir", type=Path, help="absolute path to phenotype directory")
parser.add_argument("out_dir", type=Path, help="absolute path to output directory")
parser.add_argument("hcpd_exclude", type=Path, help="absolute path to HCP-D exclusion list")
args = parser.parse_args()

# HCP-D
hcpd_pheno_file = Path(args.pheno_dir, "HCP-D", "ndar_subject01.txt")
hcpd_data = pd.read_table(
    hcpd_pheno_file, sep="\t", header=0, skiprows=[1], usecols=["src_subject_id"])
hcpd_data["src_subject_id"] = hcpd_data["src_subject_id"].str.cat(["_V1_MR"]*len(hcpd_data))
hcpd_exclude = pd.read_csv(args.hcpd_exclude, header=None).squeeze().to_list()
hcpd_data.drop(hcpd_data.loc[hcpd_data["src_subject_id"].isin(hcpd_exclude)].index, inplace=True)
hcpd_out_file = Path(args.out_dir, "HCP-D_allRun.csv")
hcpd_data.to_csv(hcpd_out_file, header=False, index=False)
