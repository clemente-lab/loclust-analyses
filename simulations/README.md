# Minimal Features Pipeline with Traj 1.2 Overwrite

**Created:** 2025-10-20
**Pipeline Variant:** `data_minimal_features/` + `2b_cluster_minimal_features/`
**Key Feature:** LoClust minimal configuration + **Traj 1.2 algorithm (local overwrite)**

---

## Overview

This pipeline is a **modified version** of `data_potentially_simple/` with TWO key differences:

1. **LoClust uses minimal features** (33 stats, no interpolation, fixed PCA)
2. **Traj results are overwritten locally** using the old traj 1.2 algorithm

### Why This Pipeline Exists

The standard pipeline uses **traj 1.3** (current CRAN version), but historical data was generated with **traj 1.2** (2015 version). The two versions produce different cluster assignments due to different factor selection algorithms. This pipeline ensures numerical consistency for comparisons.

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: HPC Clustering (on cluster)                            │
│  Source: data_potentially_simple/                               │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │  4 LoClust Methods (minimal config)  │
        │  - gmm_k{3,6,9}                      │
        │  - hierarchical_k{3,6,9}             │
        │  - kmeans_k{3,6,9}                   │
        │  - spectral_k{3,6,9}                 │
        │                                      │
        │  4 R Methods (standard)              │
        │  - kml_k{3,6,9}                      │
        │  - dtwclust_k{3,6,9}                 │
        │  - traj_k{3,6,9} ← Uses traj 1.3     │
        │  - mfuzz_k{3,6,9}                    │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌─────────────────────────────────────┐
        │  Initial Results in:                │
        │  data_minimal_features/input_trajs/ │
        └──────────────┬──────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│  STEP 2: Traj 1.2 Overwrite (LOCAL on your computer)            │
│  Script: standalone_overwrite.R                                  │
└──────────────────────────────┬───────────────────────────────────┘
                               │
                               ▼
        ┌──────────────────────────────────────┐
        │  Overwrites ONLY traj results        │
        │  - Reads input from:                 │
        │    data_potentially_simple/          │
        │  - Applies traj 1.2 algorithm:       │
        │    step1measures → step2factors →    │
        │    step3clusters                     │
        │  - Overwrites results in:            │
        │    data_minimal_features/input_trajs/│
        │    .../clustering/traj_k*/           │
        │                                      │
        │  ✅ kml, dtwclust, mfuzz: UNCHANGED  │
        │  ✅ gmm, hierarchical, kmeans,       │
        │     spectral: UNCHANGED              │
        │  🔄 traj: OVERWRITTEN with 1.2       │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌─────────────────────────────────────┐
        │  Final Results:                     │
        │  data_minimal_features/input_trajs/ │
        │  (ready for analysis)               │
        └─────────────────────────────────────┘
```

---

## Pipeline Differences vs Standard

### Data Source
- **Input:** Same as `data_potentially_simple/` (flat 8-timepoint structure)
- **Output:** `data_minimal_features/` (separate directory)

### LoClust Configuration

**Standard (`2b_cluster_potentially_simple/`):**
```bash
cluster_trajectories.py --force-k K --pca_flag --write_flag
# Uses: adaptive interpolation, 54 features, adaptive PCA
```

**Minimal Features (`2b_cluster_minimal_features/`):**
```bash
cluster_trajectories.py --force-k K --pca_flag -pn 9 \
    --no-interpolate --use-original-stats --write_flag
# Uses: NO interpolation, 33 original features, fixed 9 PCA components
```

See: `2b_cluster_minimal_features/README_MINIMAL_FEATURES.md` for details.

### R Methods Configuration

**Standard R methods:** All 4 methods use default CRAN package versions
- kml (unchanged)
- dtwclust (unchanged)
- **traj 1.3** - Uses `Step1Measures()`, `Step2Selection()`, `Step3Clusters()`
- mfuzz (unchanged)

**Minimal features R methods:** Same as standard, **BUT**:
- kml (unchanged)
- dtwclust (unchanged)
- **traj 1.2 (overwritten locally)** - Uses `step1measures()`, `step2factors()`, `step3clusters()`
- mfuzz (unchanged)

---

## Traj 1.2 vs 1.3: What's Different?

### Function Names
| Version | Step 1 | Step 2 | Step 3 |
|---------|--------|--------|--------|
| **Traj 1.2** | `step1measures()` | `step2factors()` | `step3clusters()` |
| **Traj 1.3** | `Step1Measures()` | `Step2Selection()` | `Step3Clusters()` |

### Factor Selection Algorithm (Step 2)

**Traj 1.2:**
- Uses custom `reduced.eigen()` function
- Applies SMC (squared multiple correlation) for factor reliability
- Checks for m17/m18 correlation only if both columns exist
- More conservative factor selection

**Traj 1.3:**
- Uses built-in R factor selection
- Different criteria for selecting factors
- Different handling of missing measures
- Generally selects more factors

### Why This Matters

The different factor selection leads to **different cluster assignments** even on identical input data. For consistency with historical benchmarks, we use traj 1.2.

---

## Local Traj 1.2 Overwrite Process

### Prerequisites

**On your local computer (NOT the cluster):**

1. **Install traj 1.2:**
   ```r
   # In R console
   install.packages("https://cran.r-project.org/src/contrib/Archive/traj/traj_1.2.tar.gz",
                    repos=NULL, type="source")

   library(traj)
   packageVersion("traj")  # Should show '1.2'
   ```

2. **Required R packages:**
   ```r
   install.packages(c("data.table", "psych", "pastecs", "NbClust", "GPArotation"))
   ```

3. **Transfer the overwrite script:**
   ```bash
   # From cluster to local
   scp username@cluster:/path/to/simulations/standalone_overwrite.R ~/
   ```

### Running the Overwrite

**On your local computer:**

```bash
cd /path/to/simulations/
Rscript standalone_overwrite.R
```

**What it does:**
1. Finds all traj result files in `data_minimal_features/input_trajs/.../clustering/traj_k*/`
2. For each traj result:
   - Identifies corresponding input in `data_potentially_simple/`
   - Reads trajectory data
   - Applies traj 1.2 algorithm (step1 → step2 → step3)
   - Overwrites the `.clust.tsv` file with traj 1.2 cluster assignments
3. Preserves exact file naming and structure

**Processing stats (last run):**
- Total files: 1,740
- Success: 1,740
- Failed: 0
- Time: ~2.5 hours

### Files Involved

**Input:** `data_potentially_simple/input_trajs/8/{3,6,9}/*.tsv`
**Output:** `data_minimal_features/input_trajs/8/{3,6,9}/clustering/traj_k{3,6,9}/*.clust.tsv`

**Scripts:**
- `standalone_overwrite.R` - Main overwrite script (self-contained)
- `overwrite_traj_with_1.2.R` - Traj 1.2 functions (can be sourced separately)
- `standalone_traj_1.2.R` - Test script for verification

**Documentation:**
- `TRAJ_1.2_OVERWRITE_DOCUMENTATION.md` - Detailed technical documentation

---

## Why Overwrite Locally?

**Why not run traj 1.2 on the HPC cluster?**

1. **Library compatibility:** Traj 1.2 (from 2015) has dependency conflicts on modern HPC systems
2. **R version conflicts:** HPC cluster uses newer R versions with incompatible libraries
3. **Module system restrictions:** Can't easily install archived CRAN packages
4. **Local control:** Local computers can use older R versions and libraries without restrictions

**Why overwrite instead of clustering from scratch?**

1. **Efficiency:** Only need to rerun 1 of 8 methods (traj), not all 8
2. **Consistency:** All other methods (kml, mfuzz, dtwclust, LoClust) remain identical
3. **Reproducibility:** Same input data → only traj algorithm changes
4. **Flexibility:** Can re-overwrite if needed without rerunning HPC jobs

---

## Directory Structure

```
data_minimal_features/
└── input_trajs/
    └── 8/                    # 8 timepoints (flat structure)
        ├── 3/                # 3 classes
        │   ├── 0.04noise.exponential-hyperbolic-norm.200reps.0.tsv
        │   └── clustering/
        │       ├── gmm_k3/
        │       │   └── 0.04noise.exponential-hyperbolic-norm.200reps.0.clust.tsv
        │       ├── hierarchical_k3/
        │       ├── kmeans_k3/
        │       ├── spectral_k3/
        │       ├── kml_k3/
        │       ├── dtwclust_k3/
        │       ├── traj_k3/           ← OVERWRITTEN with traj 1.2
        │       │   └── *.clust.tsv
        │       └── mfuzz_k3/
        ├── 6/                # 6 classes
        │   └── clustering/
        │       └── traj_k6/           ← OVERWRITTEN with traj 1.2
        └── 9/                # 9 classes
            └── clustering/
                └── traj_k9/           ← OVERWRITTEN with traj 1.2
```

---

## Verification

After overwriting traj results, verify:

### 1. Check File Counts

```bash
# Should have same number of traj results as other methods
find data_minimal_features -path "*/traj_k*/*.clust.tsv" | wc -l     # 1740
find data_minimal_features -path "*/kml_k*/*.clust.tsv" | wc -l      # 1740
find data_minimal_features -path "*/mfuzz_k*/*.clust.tsv" | wc -l    # 1740
```

### 2. Check Cluster Assignments

```bash
# Traj results should differ from standard pipeline
diff data_potentially_simple/input_trajs/8/3/clustering/traj_k3/0.04noise.*.clust.tsv \
     data_minimal_features/input_trajs/8/3/clustering/traj_k3/0.04noise.*.clust.tsv

# Other methods should be identical (if copied)
diff data_potentially_simple/input_trajs/8/3/clustering/kml_k3/0.04noise.*.clust.tsv \
     data_minimal_features/input_trajs/8/3/clustering/kml_k3/0.04noise.*.clust.tsv
```

### 3. Run V-measure Calculation

```bash
cd 2b_cluster_minimal_features
python calculate_vmeasure.py
```

Expected: Traj 1.2 may show different performance than traj 1.3.

---

## Complete Workflow

### Step 1: HPC Cluster (Initial Clustering)

```bash
# On HPC cluster
cd /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features

# Generate dataset index
python generate_dataset_index.py

# Submit all clustering jobs
bash submit_all_clustering.sh

# Wait for jobs to complete (~24-48 hours)
bjobs -w

# Results written to data_minimal_features/
```

### Step 2: Transfer to Local Computer

```bash
# On local computer
# Transfer results directory
rsync -avz --progress \
    username@cluster:/path/to/simulations/data_minimal_features/ \
    ~/simulations/data_minimal_features/

# Transfer input data (if not already present)
rsync -avz --progress \
    username@cluster:/path/to/simulations/data_potentially_simple/ \
    ~/simulations/data_potentially_simple/

# Transfer overwrite script
scp username@cluster:/path/to/simulations/standalone_overwrite.R ~/simulations/
```

### Step 3: Local Overwrite (Traj 1.2)

```bash
# On local computer
cd ~/simulations/

# Verify traj 1.2 is installed
R
> library(traj)
> packageVersion("traj")  # Should be '1.2'
> quit()

# Run overwrite
Rscript standalone_overwrite.R

# Expected output:
# Processing 1740 files...
# [Progress messages]
# Completed: 1740/1740 (100%)
# Time: ~2.5 hours
```

### Step 4: Transfer Back to Cluster

```bash
# On local computer
# Transfer overwritten results back
rsync -avz --progress \
    ~/simulations/data_minimal_features/ \
    username@cluster:/path/to/simulations/data_minimal_features/
```

### Step 5: Analysis

```bash
# On cluster (or locally)
cd 2b_cluster_minimal_features
python calculate_vmeasure.py

# Results in: results_minimal_features/vmeasure_scores.tsv
```

---

## Troubleshooting

### Traj 1.2 Installation Fails

**Problem:** Can't install traj 1.2 from archive

**Solution:** Use older R version (3.6.x) or conda environment:
```bash
conda create -n traj_local r-base=3.6.3 -c conda-forge
conda activate traj_local
R
> install.packages("https://cran.r-project.org/src/contrib/Archive/traj/traj_1.2.tar.gz",
                   repos=NULL, type="source")
```

See: `test_traj_versions/local_setup_guide.md`

### Overwrite Script Can't Find Files

**Problem:** "No corresponding file found"

**Solution:** Ensure directory structure matches:
- Input data: `data_potentially_simple/input_trajs/8/{3,6,9}/`
- Output data: `data_minimal_features/input_trajs/8/{3,6,9}/clustering/traj_k*/`

### Different Cluster Counts

**Problem:** Traj picks different k than expected

**Solution:** The script forces k to match the directory name (traj_k3 → k=3). Check log messages.

---

## Related Documentation

- **LoClust minimal config:** `2b_cluster_minimal_features/README_MINIMAL_FEATURES.md`
- **Traj overwrite details:** `TRAJ_1.2_OVERWRITE_DOCUMENTATION.md`
- **Code modifications:** `MINIMAL_FEATURES_MODIFICATIONS.md`
- **Local testing guide:** `test_traj_versions/local_setup_guide.md`
- **Standard pipeline:** `2b_cluster_potentially_simple/README_POTENTIALLY_SIMPLE.md`

---

## Summary

This pipeline combines:
1. **Minimal LoClust configuration** (33 stats, no interpolation, fixed PCA) - run on HPC
2. **Traj 1.2 algorithm** (historical version) - overwritten locally
3. **Standard R methods** (kml, dtwclust, mfuzz) - run on HPC

The two-step process (HPC → local overwrite → HPC) ensures compatibility with historical data while leveraging HPC resources for the majority of clustering work.

---

**Last Updated:** 2025-10-20
**Contact:** See TRAJ_1.2_OVERWRITE_DOCUMENTATION.md for technical details
