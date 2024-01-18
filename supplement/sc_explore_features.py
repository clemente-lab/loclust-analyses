# Plot the most similar features
# %%
import pandas as pd
import numpy as np
from copy import deepcopy
from glob import glob
from sklearn.metrics import pairwise_distances

# %% Import feature matrix
analysis_base_dir = 'C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs_wff/0.2noise.exponential-growth-hyperbolic-linear-norm-poly-scurve-sin-tan.200reps.0_loclust_3pca_pc_3_num_clusters_9/'
feature_fn = glob(f'{analysis_base_dir}/*features.csv')
df_feat = pd.read_csv(feature_fn[0], header=0)
df_nfeat = deepcopy(df_feat)

# %% Normalize the features - Min-Max feature scaling - subtract the min, divide by max-min
feat_cols = df_nfeat.columns[5:]
for feat in feat_cols:
    df_nfeat[feat] = (df_nfeat[feat] - df_nfeat[feat].min()) / (df_nfeat[feat].max() - df_nfeat[feat].min())

# %% Determine the average value for each feature split by function type 
g = df_nfeat.groupby(by='func').mean()
# %% Determine 
def custom_calc(x,y):
    return abs(y-x)

def feat_comp(df_nfeat, feat):
    # Calculte the pairwise distances in the input dataframe
    matrix = pairwise_distances(df_nfeat[feat].to_numpy().reshape(-1,1), metric=custom_calc)
    # Isolate relevant metadata
    df_mini = df_feat.loc[:, ['ID', 'func']]
    # Setup dataframe with the pairwise information for the given feature
    df_matrix = pd.DataFrame(matrix, columns=list(df_feat['ID']))
    df_matrix['ID'] = deepcopy(df_feat['ID'])
    # Melt dataframe
    df_mm = df_matrix.melt(id_vars="ID", var_name="ID_pair", value_name=feat)
    df_mmm = df_mm.merge(df_mini, how='left', on="ID")
    df_mf = df_mmm.merge(df_mini, how='left', left_on="ID_pair", right_on="ID")
    df_mf.rename(columns={"ID_x":"ID", "func_x": "func", "func_y":"func_pair"}, inplace=True)
    df_mf.drop(columns="ID_y", inplace=True)
    # TODO -- are there duplicates that need to be dropped? 
    # Group-by traj ID and calculate the average of each feature
    gg = df_mf.groupby(["func", "func_pair"])[feat].agg(func=['mean'])
    gg['feat'] = feat
    return gg

feat_cols = df_nfeat.columns[5:]
# feat = feat_cols[1]
gg_all = pd.DataFrame()
for feat in feat_cols:
    gg = feat_comp(df_nfeat, feat)
    gg_all = pd.concat([gg_all, gg], axis=0)

gg_all.to_csv(analysis_base_dir+'_feats.tsv', sep='\t')


# %% Hypothesis: Relative values of the features matter
"""
The relative values of the features matter in cluster assignment. 
Sin-tan feature comparisons are showing differences, but they're small 
differences when they're next to a function with very different 
dynamics like exp or linear or scurve
"""

# Compare the values of the features by function
# df_matrix.loc[:,0].hist(bins=10)
df_feat = pd.read_csv(feature_fn[0], header=0)
df_mini = df_feat.loc[:, ['ID', 'func']]
df = df_feat.merge(df_mini, how='left', on="ID")
df_n = df_nfeat.merge(df_mini, how='left', on="ID")
df.rename(columns={"func_x": "func"}, inplace=True)
df.drop(columns="func_y", inplace=True)
df_n.rename(columns={"func_x": "func"}, inplace=True)
df_n.drop(columns="func_y", inplace=True)
# %%
gg = df.groupby(["func"])[feat_cols].agg(func=['mean'])
grg = df.groupby(["func"])[feat_cols]
grgn = df_n.groupby(["func"])[feat_cols]

# %% PLOTTING
import matplotlib.pyplot as plt
import seaborn as sns
sns.heatmap(gg, cmap='PiYG')

# %%
box = sns.boxplot(data=df.loc[:,feat_cols])
box.set_xticklabels(box.get_xticklabels(), rotation=90)

# %% Checking to see if the questionable function types still look similar 
from sklearn.preprocessing import QuantileTransformer
qt = QuantileTransformer()
# Next line assumes the row order doesn't change in 
df_qt = pd.DataFrame(data=qt.fit_transform(df_feat.loc[:, feat_cols].to_numpy()), columns=feat_cols, index=df_feat["ID"])
dfq = df_qt.merge(df_mini, how='left', on="ID")
dfq.rename(columns={"func_x": "func"}, inplace=True)

# %%
ggq = dfq.groupby(["func"])[feat_cols].agg(func=['mean'])
fig, ax = plt.subplots(figsize=(12,6))
sns.heatmap(ggq, cmap='PiYG', ax=ax)

# %% Save quartile fit_transform matrix with relevant metadata
ggq.columns = [x[0] for x in ggq.columns]
ggq = ggq.reset_index()
ggq.to_csv(analysis_base_dir + 'features_qt.tsv', sep='\t', index=False)

# %% Calculate the euclidean distance between all func vectors (pairwise)
from scipy.cluster.hierarchy import dendrogram, linkage
linkage_data = linkage(ggq, method='ward', metric='euclidean')
dendrogram(linkage_data, labels=ggq.index, leaf_rotation=90)