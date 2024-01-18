###
# This script is to transform baby microbiome data into loclust trajectory objects
# 
# Author: Hilary Monaco
###
# %%
import os
import numpy as np
import pandas as pd
from pathlib import Path
from copy import deepcopy
from loclust.parse import create_trajs_from_dataframe
from glob import glob

# %%
# Step 1a: Load Data
level = 'L6'
data_fp_orig = f'C:/Users/mathr/Documents/GitHub/sean/taxa_summaries/ILL46_Sean_otu_table_{level}.txt'
df = pd.read_csv(data_fp_orig, sep='\t', header=1)

# Step 1b: Load Metadata
mdata_fp_orig = 'C:/Users/mathr/Documents/GitHub/sean/ILL46_Sean_Mapping.txt'
mdata = pd.read_csv(mdata_fp_orig, sep='\t', header=0)

# Step 2: Transpose and prep the data matrix
df.set_index('#OTU ID', inplace=True)
df = df.T

df.reset_index(inplace=True)
df = df.rename(columns = {'index':'sample_ID'})

# Step 3: Merge metadata
df_merged = df.merge(mdata, how='outer', left_on="sample_ID", right_on="#SampleID")

# Step 3.5: Filter data to only the experiment with 7 timepoints *SPECIFIC FOR SEAN DATASET*
df_merged = deepcopy(df_merged.loc[df_merged['Experiment'] == "MOT"])

# Step 4: Create a time column from metadata information
df_merged['time_extracted'] = deepcopy(df_merged['Timepoint'])
# Save
data_fp_for_trajs = f'C:/Users/mathr/Documents/GitHub/sean/ILL46_Sean_otu_table_with_mdata.tsv'
df_merged.to_csv(data_fp_for_trajs, sep='\t', index=False)

# %%
# Step 5: Generate trajectories
## Setup variables for parsing data to trajectory objects
data_fp = data_fp_for_trajs
tsv_flag = True
sample_ID_col = "#SampleID"
subject_ID_col = "Sample"
diversity_cols = [],
time_col = "time_extracted"
value_cols = []
not_value_cols = [
    "Sample", 
    "sample_ID",
    "time_extracted",
    "Timepoint",
    "AnalysisGroup",
    "MicrobiotaReceived",
    "BarcodeSequence",
    "LinkerPrimerSequence"
    ]
relative_abundance_flag = False
taxonomic_level = None
cross_sectional_meta_cols = [ 
    "Experiment",
    "Diet", 
    "Description"
    ]

temporal_meta_cols = [
    "Description", 
    "#SampleID",
    "BarcodePlate", 
    "BarcodeWell",
    "Compare"
    ]

multi_value_per_timepoint_meta_cols = None
taxonomy_cols = None
transpose_flag = False
skiprows = None
header = 0
# filename_base = "taxa_trajs/" + Path(data_fp_orig).stem
# name_tag_base = Path(data_fp_orig).parents[1]/filename_base
# name_tag = f'{name_tag_base}_trajs'

filename_base = f"taxa_trajs/"
name_tag_base = Path(data_fp_orig).parents[1]/filename_base
data_indicator = level
name_tag = f'{name_tag_base}/{data_indicator}'

## Generate all Value columns
for col in df_merged.columns:
    if col in cross_sectional_meta_cols:
        continue
    elif col in temporal_meta_cols:
        continue
    elif col in not_value_cols:
        continue
    else:
        value_cols.append(col)

# %% Remove nans from dataframe in the value columns
if df_merged[value_cols].isnull().values.any():
    df_merged = df_merged.dropna(subset=value_cols)
df_merged.to_csv(data_fp_for_trajs, sep='\t', index=False)

# %%
# Make the folder to store trajectories
os.makedirs(name_tag_base, exist_ok=True)
# Make trajectories
for value_col in value_cols:

    g_trajs = create_trajs_from_dataframe(data_fp, 
                                          subject_ID_col=subject_ID_col,
                                          time_col=time_col,
                                          value_cols=value_col,
                                          cross_sectional_meta_cols=cross_sectional_meta_cols,
                                          temporal_meta_cols=temporal_meta_cols,
                                          name_tag=name_tag)
# %%
