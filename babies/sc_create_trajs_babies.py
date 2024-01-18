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
# Dataset
# Step 1: Load data and metadata
level = 'L6'
data_fp_orig = f'C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/otu_table_merged.0-12m.stool.child_{level}.txt'
df = pd.read_csv(data_fp_orig, sep='\t', header=1)
df_orig = deepcopy(df)

# Metadata
mdata_fp_orig = 'C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/mapping_file_merged.0-12m.stool.child.joincol.tsv'
mdata = pd.read_csv(mdata_fp_orig, sep='\t', header=0)

# %%
# Step 2: Transpose the matrix
df.set_index('#OTU ID', inplace=True)
df = df.T

df.reset_index(inplace=True)
df = df.rename(columns = {'index':'sample_ID'})

# Step 3: Merge metadata
df_merged = df.merge(mdata, how='outer', left_on="sample_ID", right_on="#SampleID")

# Step 4: Create a time column from metadata information
df_merged['time_extr_mon'] = round(deepcopy(df_merged['day_of_life'])/30, 1)
# Save
data_fp_for_trajs = f'C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/otu_table_merged.0-12m.stool.child.with_mdata.tsv'
df_merged.to_csv(data_fp_for_trajs, sep='\t', index=False)

# %%
# Step 5: Generate trajectories
## Setup variables for parsing data to trajectory objects
data_fp = data_fp_for_trajs
sample_ID_col = "#SampleID"
subject_ID_col = "host_subject_id"
time_col = "time_extr_mon"
value_cols = []
not_value_cols = [
    "#SampleID", 
    "host_subject_id", 
    "time_extr_mon",
    "collection_timestamp",
    "Description", 
    "BarcodeSequence",
    "sample_summary"
    ]
cross_sectional_meta_cols = [
    "sample_ID", 
    "mom_prenatal_abx", 
    "mom_prenatal_abx_class",
    "mom_prenatal_abx_trimester", 
    "diet", 
    "diet_2",
    "diet_3",
    "studyid",
    "delivery",
    "sex",
    "mom_ld_abx",
    "abx_ever",
    "delivery_abx",
    "diet_abx",
    "delivery_diet",
    "delivery_diet_abx"
    ]

temporal_meta_cols = [
    "abx1_pmp_all_bymonth", 
    "abx_all_sources",
    "diet_2_month",
    "run_prefix",
    "month",
    "day_of_life",
    "month_of_life",
    "samplewell",
    "run_date",
    "abx_name",
    "antiexposedall",
    "abx_pmp_all",
    "course_num",
    "barcodewell"
    ]

multi_value_per_timepoint_meta_cols = None
taxonomy_cols = None
transpose_flag = False
skiprows = None
header = 0
filename_base = Path(data_fp_orig).parent / "taxa_trajs/"
os.makedirs(filename_base, exist_ok=True)
name_tag = f'{filename_base}/{level}_'

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

# %%
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
