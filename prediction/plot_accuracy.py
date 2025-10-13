from pathlib import Path
import argparse

from scipy.io import loadmat
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

parser = argparse.ArgumentParser(
    description="plot accuracies using all prediction results from one folder",
    formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument("--dataset", type=str, help="dataset name")
parser.add_argument("--method", type=str, help="algorithm used for prediction (SVR or KRR)")
parser.add_argument("--colloq_txt", type=Path, help="absolute path to colloquial name list")
parser.add_argument("--pred_dir", type=Path, help="absolute path to prediction outcome")
parser.add_argument("--out_dir", type=Path, help="absolute path to output directory")
parser.add_argument("--out_stem", type=str, help="output file name stem")
args = parser.parse_args()

# Colloquial names and corresponding file stems
colloq_names = pd.read_table(args.colloq_txt, sep="\t", header=None).squeeze()
filestems = colloq_names.str.replace(" ", "_")
filestems = filestems.str.replace("/", "-")

# Read accuracies
n_repeats = {"HCP-D": 4, "HCP": 10, "ABCD": 120}
acc = np.zeros((n_repeats[args.dataset], len(filestems)))
for i in range(len(filestems)):
    acc_file = Path(args.pred_dir, f"wbCBPP_{args.method}_standard_{filestems[i]}_SchMel4.mat")
    acc_curr = loadmat(acc_file)["r_test"]
    acc_curr = np.nan_to_num(acc_curr) # Use zero for nan values
    if args.dataset == "HCP":
        acc[:, i] = acc_curr.mean(axis=1)
    else:
        acc[:, i] = acc_curr.flatten()

# Sort in descending order
idx = np.argsort(acc.mean(axis=0))[::-1]
acc_sort = acc[:, idx]
colloq_sort = colloq_names[idx]

# Plot accuracies
acc_pd = pd.DataFrame(acc_sort, columns=colloq_sort)
cat_height = {"HCP-D": 5, "HCP": 10, "ABCD": 7}
cat_aspect = {"HCP-D": 1, "HCP": 0.5, "ABCD": 0.7}
g = sns.catplot(
    kind="violin", data=acc_pd, orient="h", cut=0, width=0.6, linewidth=1, color=".9",
    linecolor=".7", height=cat_height[args.dataset], aspect=cat_aspect[args.dataset],
    order=colloq_sort, inner_kws={"color": ".6", "box_width": 2, "whis_width": 0.5})
g.axes[0][0].xaxis.tick_top()
g.axes[0][0].set(xlabel="Cross-validated Pearson's correlation", ylabel=None)
g.axes[0][0].xaxis.set_label_position("top")
g.axes[0][0].axvline(color=".5", linestyle="--")
sns.despine(bottom=True, right=True, top=False)
plt.tight_layout()
plt.savefig(Path(args.out_dir, f"{args.method}_{args.out_stem}.png", dpi=500))
