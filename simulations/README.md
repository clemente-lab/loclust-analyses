# LoClust Systematic Simulation Benchmarks

Comprehensive clustering benchmarks using systematic synthetic trajectory datasets.

## Overview

This directory contains scripts to:
1. Generate systematic simulation datasets with known ground truth
2. Run multiple clustering methods (LoClust + R methods)
3. Calculate performance metrics (v-measure, ARI, etc.)
4. Compare methods across different conditions

## Quick Start

```bash
# 1. Generate all simulation datasets (2,100 datasets)
cd 1_generate
python generate_systematic.py --config simulation_config.yaml --yes

# 2a. Run LoClust clustering locally (4 methods × 2,100 datasets = 8,400 runs)
cd ../2a_cluster_local
python run_clustering.py --method all

# 2b. OR submit to HPC cluster (parallel execution)
cd ../2b_cluster_hpc
bash submit_all_clustering.sh

# 3. Run R methods clustering (4 methods × 2,100 datasets = 8,400 runs)
cd ../2a_cluster_local
Rscript run_r_methods.R --method all

# 4. Calculate performance metrics
cd ../3_analyze_results
python calculate_vmeasure.py

# 5. Generate comparison plots
Rscript plot_vmeasure.R
```

Results will be in `results/vmeasure_scores.tsv` and plots in `results/*.png`.

## Directory Structure

```
simulations/
├── 0_tests/                     # Validation and pilot tests
│
├── 1_generate/                  # Simulation data generation
│   ├── generate_systematic.py  # Main generation script
│   ├── simulation_config.yaml  # Dataset configuration (2,100 datasets)
│   ├── test_config.yaml        # Pilot test config (16 datasets)
│   └── README.md
│
├── 2a_cluster_local/            # Run clustering on local machine
│   ├── run_clustering.py       # LoClust methods (GMM, Hierarchical, K-means, Spectral)
│   ├── run_r_methods.R         # R methods (KML, DTWclust, Traj, Mfuzz)
│   └── README.md
│
├── 2b_cluster_hpc/              # Submit clustering jobs to HPC cluster
│   ├── submit_all_clustering.sh  # Master submission script
│   ├── run_loclust_array.sh     # LSF job array for LoClust
│   ├── run_r_method_array.sh    # LSF job array for R methods
│   └── README.md
│
├── 3_analyze_results/           # Metrics calculation and visualization
│   ├── calculate_vmeasure.py   # Calculate v-measure, ARI, NVI, etc.
│   ├── plot_vmeasure.R         # Generate comparison plots
│   └── README.md
│
├── data/                        # Generated simulation datasets
│   ├── 3_classes/              # 1,200 datasets (20 combos × 6 noise × 10 seeds)
│   ├── 6_classes/              # 600 datasets (10 combos × 6 noise × 10 seeds)
│   └── 9_classes/              # 300 datasets (5 combos × 6 noise × 10 seeds)
│
├── results/                     # Aggregated benchmark results
│   ├── vmeasure_scores.tsv     # Full results table
│   ├── vmeasure_summary.tsv    # Summary by method
│   └── plots/                  # Comparison visualizations
│
├── documentation/               # Session logs and design docs
└── legacy/                      # Archived old code
```

## Datasets

### Total: 2,100 Datasets

| Type | Combinations | Noise Levels | Seeds | Total |
|------|-------------|--------------|-------|-------|
| 3-class | 20 | 6 | 10 | 1,200 |
| 6-class | 10 | 6 | 10 | 600 |
| 9-class | 5 | 6 | 10 | 300 |

### Function Classes (11 total)

- **linear** - Linear growth/decline
- **exponential** - Exponential growth/decay
- **hyperbolic** - Hyperbolic decay
- **norm** - Normal/Gaussian curve
- **growth** - Logistic growth
- **poly** - Polynomial
- **scurve** - Sigmoid/S-curve
- **sin** - Sinusoidal
- **tan** - Tangent
- **stage** - Step function
- **flat** - Constant/flat line

### Noise Levels (6 total)

- **0.0** - No noise (perfect data)
- **0.04** - Low noise
- **0.08** - Moderate noise
- **0.12** - Moderate-high noise
- **0.16** - High noise
- **0.20** - Very high noise

### Seeds (10 per condition)

- Seeds 1-10 for independent replicates
- Ensures reproducibility and statistical power

## Clustering Methods

### LoClust Methods (Python)

| Method | Description | Expected ARI |
|--------|-------------|--------------|
| **GMM** | Gaussian Mixture Model | 0.857 |
| **Hierarchical** | Ward linkage | 0.792 |
| **K-means** | Standard k-means | 0.744 |
| **Spectral** | Spectral clustering (RBF) | 0.000 (fails) |

**All use:** 100-pt adaptive interpolation + 52 statistical features + PCA

### R Methods

| Method | Description | Expected ARI |
|--------|-------------|--------------|
| **KML** | K-means for Longitudinal data | 0.928 |
| **DTWclust** | Dynamic Time Warping | 0.838 |
| **Traj** | Group-based trajectory | 0.663 |
| **Mfuzz** | Fuzzy c-means | 0.608 |

## Key Design Decisions

### Fixed k (No Automatic Selection)

**All methods use fixed k = true number of classes:**
- 3_classes → k=3
- 6_classes → k=6
- 9_classes → k=9

**Rationale:**
- Fair comparison: Not all R methods support automatic k-selection
- Benchmark focus: Testing clustering accuracy when k is known
- Reproducibility: Same k across all methods

### Pure Trajectories (combine_funcs=1)

Each trajectory comes from a single function class:
- **NOT combined** (e.g., not "exponential then linear")
- **Pure shapes** (only exponential, only linear, etc.)
- **Mixed in datasets** to test if clustering can separate them

### Hierarchical Organization

```
data/3_classes/exponential-hyperbolic-norm/noise_0.04/seed_042/
├── trajectories.tsv              # Raw simulation (200 traj/class × 3 = 600 total)
├── metadata.json                 # Complete parameters + provenance
├── generation_log.txt            # Generation details
└── clustering/                   # Clustering results
    ├── gmm_k3/
    │   ├── trajectories.clust.tsv      # For v-measure calculation
    │   ├── clustering_log.txt
    │   ├── cluster_summary.png
    │   └── confusion_matrix.png
    ├── hierarchical_k3/
    ├── kmeans_k3/
    ├── spectral_k3/
    ├── kml_k3/
    ├── dtwclust_k3/
    ├── traj_k3/
    └── mfuzz_k3/
```

**Benefits:**
- Self-documenting (directories encode metadata)
- Easy to filter/process
- Complete provenance tracking
- Parallel-friendly (independent seeds)

## Performance Expectations

Based on prior benchmarks (4-class datasets):

| Rank | Method | ARI | K-Selection | Speed |
|------|--------|-----|-------------|-------|
| 🥇 1 | KML | 0.928 ± 0.101 | 100% | ~5s |
| 🥈 2 | LoClust GMM | 0.857 ± 0.145 | 89% | ~8s |
| 🥉 3 | DTWclust | 0.838 ± 0.110 | 100% | ~140s |
| 4 | LoClust Hierarchical | 0.792 ± 0.128 | 100% | ~8s |
| 5 | LoClust K-means | 0.744 ± 0.093 | 100% | ~8s |
| 6 | Traj | 0.663 ± 0.332 | 33% | ~2s |
| 7 | Mfuzz | 0.608 ± 0.128 | 44% | ~1s |
| 8 | LoClust Spectral | 0.000 ± 0.000 | 0% | ~8s |

**Note:** These are from 4-class evaluation matrix. Current systematic benchmarks use 3/6/9 classes and may show different results.

## Estimated Runtime

**Generation** (~5-10 min):
- 2,100 datasets × ~0.3s each = ~10 minutes

**Clustering** (~24-48 hours):
- LoClust: 2,100 datasets × 4 methods × ~8s = ~18 hours
- R methods: 2,100 datasets × 4 methods × ~40s = ~90 hours
- **Total: ~108 hours** (can parallelize by batch)

**Analysis** (~5 min):
- Metrics calculation: 16,800 files × <1s = ~5 minutes
- Plot generation: ~1 minute

## Reproducibility

### Random Seeds

All randomness is controlled:
- **Generation:** Seeds 1-10 for data generation
- **Clustering:** Seed 42 for clustering algorithms (LoClust)
- **R methods:** Seed 42 where applicable

### Complete Provenance

Each dataset includes `metadata.json`:
```json
{
  "generation": {
    "date": "2025-10-08T18:03:08",
    "script": "generate_systematic.py",
    "loclust_repo": "/path/to/loclust"
  },
  "parameters": {
    "num_classes": 3,
    "function_classes": ["exponential", "hyperbolic", "norm"],
    "noise_level_y": 0.04,
    "num_trajectories_per_class": 200
  },
  "randomization": {
    "python_seed": 42,
    "numpy_seed": 42
  },
  "output": {
    "md5_checksum": "fc7e4b97e84c3bc30499e47b83cb2e6b"
  }
}
```

### Version Control

- All scripts version-controlled in git
- Session logs in `documentation/sessions/`
- MD5 checksums for all generated data

## Next Steps After Generation

Once datasets are generated:

1. **Test on pilot data (16 datasets)**:
   ```bash
   cd 2a_cluster_local
   python run_clustering.py --batch 3_classes --method gmm --dry-run
   ```

2. **Run single method first** (test ~2 hours):
   ```bash
   python run_clustering.py --method gmm
   ```

3. **If successful, run all methods** (~108 hours):
   ```bash
   python run_clustering.py --method all
   Rscript run_r_methods.R --method all
   ```

4. **Analyze and visualize**:
   ```bash
   cd ../3_analyze_results
   python calculate_vmeasure.py
   Rscript plot_vmeasure.R
   ```

## References

- **R Methods Comparison:** `../docs/R_METHODS_COMPARISON.md`
- **PCA Analysis:** `../documentation/sessions/SESSION_2025_10_06_PCA_ELBOW_METHOD_FIX.md`
- **Bug Fixes:** `../documentation/sessions/SESSION_2025_10_02_EVALUATION_UPDATE.md`
