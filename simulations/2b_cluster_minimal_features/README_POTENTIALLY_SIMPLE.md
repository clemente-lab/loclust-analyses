# 2b_cluster_potentially_simple

**Parallel pipeline for data_potentially_simple (loclust_tool_comp data)**

This directory is a modified copy of `2b_cluster_hpc/` adapted to work with the `data_potentially_simple/` directory structure.

## Key Differences from Original Pipeline

### Data Structure
- **Original (`./data/`):** Nested directories `{N}_classes/{functions}/noise_{X}/seed_{Y}/trajectories.tsv`
- **This pipeline (`./data_potentially_simple/`):** Flat structure `input_trajs/8/{3,6,9}/*.tsv`

### File Naming
- **Original:** Fixed filename `trajectories.tsv` in nested directories
- **This pipeline:** Metadata in filename `{noise}noise.{functions}.200reps.{rep}.tsv`

### Results Output
- **Original:** `../results/`
- **This pipeline:** `../results_potentially_simple/`

## Modified Files

### `generate_dataset_index.py`
- Updated glob pattern: `input_trajs/8/*/*.tsv` (was `*_classes/*/*/*/trajectories.tsv`)
- Updated metadata parsing to extract from filename instead of directory structure
- Points to `data_potentially_simple` instead of `data`

### All `run_*.sh` scripts
- Updated `SCRIPT_DIR` references from `/2b_cluster_hpc` to `/2b_cluster_potentially_simple`
- Updated `TRAJ_FILENAME` to use actual filename instead of hardcoded `trajectories.tsv`
- Updated output filenames to match input filename pattern

### `run_vmeasure.sh`
- Points to `../results_potentially_simple/` instead of `../results/`

### `submit_all_clustering.sh`
- Updated path references in comments

## Usage

### Step 1: Generate Dataset Index
```bash
cd /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_potentially_simple
python generate_dataset_index.py
```

Expected output:
```
Created dataset index: dataset_index.tsv
Total datasets: 1740 (or similar)

Datasets by class:
  3-class: 1200
  6-class: 480
  9-class: 60
```

### Step 2: Submit Clustering Jobs
```bash
# Submit all methods
bash submit_all_clustering.sh

# Or submit individually
bsub < run_loclust_kmeans.sh
bsub < run_r_kml.sh
# etc.
```

### Step 3: Calculate V-Measure (after jobs complete)
```bash
cd /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_potentially_simple
python calculate_vmeasure.py
```

### Step 4: Generate Plots
```bash
cd /sc/arion/projects/CVDlung/earl/loclust/simulations/3_analyze_potentially_simple
Rscript plot_vmeasure.R
```

## Results Location

All results will be stored in:
- Clustering outputs: `data_potentially_simple/input_trajs/8/{3,6,9}/clustering/{method}_k{k}/`
- Aggregated metrics: `results_potentially_simple/vmeasure_scores.tsv`
- Plots: `results_potentially_simple/*.png`

## Safety

✓ Original pipeline (`2b_cluster_hpc/`) is untouched
✓ Original data (`./data/`) is untouched
✓ Original results (`./results/`) are untouched
✓ All modifications are isolated in this parallel directory

## Comparison with Original Data

This allows direct comparison of:
- **Original data** (`./data/`) - Current systematic simulations (200 unique trajectories/class)
- **Potentially simple data** (`./data_potentially_simple/`) - loclust_tool_comp data (also 200 unique/class)

Both can be run through their respective pipelines and results compared to understand method performance on different datasets.
