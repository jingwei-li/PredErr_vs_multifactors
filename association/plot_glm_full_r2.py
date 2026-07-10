from pathlib import Path
import argparse

from matplotlib.ticker import PercentFormatter
from statsmodels.stats.multitest import multipletests
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

n_clusters = {"SVR": {"ABCD": 4, "HCP-D": 2, "HCP": 3}, "KRR": {"ABCD": 4, "HCP-D": 2, "HCP": 4}}
clusters = {
    "ABCD": ["Verbal memory", "Cognition", "CBCL", "Prodromal psychosis"],
    "HCP-D": ["Cognition", "Emotion recognition"],
    "HCP": [
        "Social cognition", "Negative / positive feelings", "Emotion recognition",
        "Positive feelings"]}
dataset_names = {
    "ABCD": "ABCD (Pred)-Adolescence", "HCP-D": "HCP Development", "HCP": "HCP Young Adult"}

parser = argparse.ArgumentParser(
    description="plot pseudo R2 for all full models in the GLM analysis",
    formatter_class=lambda prog: argparse.ArgumentDefaultsHelpFormatter(prog, width=100))
parser.add_argument("--out_dir", type=Path, help="absolute path to results directory")
parser.add_argument("--out_stem", type=str, help="output file name stem")
args = parser.parse_args()

# GLM results
res = []
p_vals = []
for method in ["SVR", "KRR"]:
    for dataset, n_cluster in n_clusters[method].items():
        indir = Path(args.out_dir, dataset, "multivariate_association")
        for cluster in range(n_cluster):
            cluster_name = clusters[dataset][cluster]
            res_r2 = pd.read_csv(Path(indir, f"{method}_err{cluster+1}_goodness.csv"))
            r2_curr = res_r2["pseudo_r_squared"].loc[res_r2["model"] == "Full model"].values[0]
            p_curr = res_r2["p_against_null"].loc[res_r2["model"] == "Full model"].values[0]
    
            p_vals.append(p_curr)
            res_curr = {
                "Behavioral cluster": f"{dataset_names[dataset]} {cluster_name}",
                "Machine learning model": method, "Variance explained (pseudo R-squared)": r2_curr,
                "P-value": p_curr}
            res_curr = pd.DataFrame(res_curr, index=[f"{method}_{dataset}_{cluster+1}"])
            res.append(res_curr)
res = pd.concat(res, axis="index")

# Multiple comparison correction
h = multipletests(p_vals, method="fdr_bh")
res = res.assign(**{"P (adjusted)": h[1], "Rejected": h[0]})

# Plot and save results
sns.set_theme(style="white", context="paper", font_scale=1.5)
g = sns.catplot(
    kind="bar", data=res, x="Variance explained (pseudo R-squared)", y="Behavioral cluster",
    hue="Machine learning model", orient="h", palette=["white", "lightgray"], edgecolor="gray",
    height=8, aspect=1.2)
for ax in g.axes.flat:
    ax.xaxis.set_major_formatter(PercentFormatter(1))
plt.savefig(Path(args.out_dir, f"{args.out_stem}.png"), dpi=500)
res.to_csv(Path(args.out_dir, f"{args.out_stem}.csv"))

