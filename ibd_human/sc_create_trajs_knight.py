###
# This script is to transform knight lab ibd microbiome data into loclust trajectory objects
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

# %%
# Dataset
# Step 1: Load data and metadata
base_dir = 'C:/Users/mathr/Documents/GitHub/knight_ibd/'
level = 'L6'
data_fp_orig = f'{base_dir}rel-table-{level}.tsv'
df = pd.read_csv(data_fp_orig, sep='\t', header=1)

# Metadata
mdata_fp_orig = f'{base_dir}mapping-file.tsv'
mdata = pd.read_csv(mdata_fp_orig, sep='\t', header=0)

# %%
# Step 2: Transpose the matrix
df = df.set_index(['#OTU ID'])
df = df.T

df.reset_index(inplace=True)
df = df.rename(columns = {'index':'sample_ID'})
# %%
# Step 3: Merge metadata
df_merged = df.merge(mdata, how='inner', left_on="sample_ID", right_on="#SampleID")

# Save
# data_fp_for_trajs = f'{base_dir}otu_table_{level}_with_mdata.tsv'
data_fp_for_trajs = f'{base_dir}rel_otu_table_{level}_with_mdata.tsv'
df_merged.to_csv(data_fp_for_trajs, sep='\t', index=False)

# %%
# Step 4: Generate trajectories
## Setup variables for parsing data to trajectory objects
data_fp = f'{data_fp_for_trajs}'
tsv_flag = True
sample_ID_col = "#SampleID"
subject_ID_col = "patientnumber"
diversity_cols = [],
time_col = "timepoint"
not_value_cols = [
    'sample_ID',
    'BarcodeSequence',
    'LinkerPrimerSequence',
    'experiment_design_description',
    'instrument_model',
    'library_construction_protocol',
    'linker',
    'pcr_primers',
    'platform',
    'run_center',
    'sequencing_meth',
    'target_gene',
    'target_subfragment',
    'body_habitat',
    'body_product',
    'body_site',
    'dna_extracted',
    'env_biome',
    'env_feature',
    'env_material',
    'env_package',
    'geo_loc_name',
    'host_common_name',
    'host_scientific_name',
    'host_taxid',
    'latitude',
    'longitude',
    'physical_specimen_location',
    'physical_specimen_remaining',
    'sample_type',
    'scientific_name',
    'study',
    'study_id',
    'Description',
    'diagnosis_full',
]
cross_sectional_meta_cols = [ 
    'host_subject_id',
    'ibd_subtype',
    'patientnumber',
    'sex',
    'year_diagnosed',
    'center_name'
    ]

temporal_meta_cols = [
    '#SampleID',
    'run_prefix',
    'calprotectin',
    'cd_behavior',
    'cd_location',
    'collection_timestamp',
    'fecal_date',
    'perianal_disease',
    'timepoint',
    'bmi',
    'cd_resection',
    'uc_extent'
    ]

relative_abundance_flag = False
taxonomic_level = None 
multi_value_per_timepoint_meta_cols = None
taxonomy_cols = None
transpose_flag = False
skiprows = None
header = 0

os.makedirs(f'{base_dir}taxa_trajs/', exist_ok=True)
filename_base = f"{base_dir}taxa_trajs/" + Path(data_fp_orig).stem.split('-')[-1]
name_tag_base = Path(data_fp_orig).parents[1]/filename_base
name_tag = f'{name_tag_base}_trajs'

## Generate all Value columns
value_cols = []
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
# Step 5: Make trajectories
for value_col in value_cols:
    g_trajs = create_trajs_from_dataframe(data_fp, 
                                        subject_ID_col=subject_ID_col,
                                        time_col=time_col,
                                        value_cols=value_col,
                                        cross_sectional_meta_cols=cross_sectional_meta_cols,
                                        temporal_meta_cols=temporal_meta_cols,
                                        name_tag=name_tag)
# %%
