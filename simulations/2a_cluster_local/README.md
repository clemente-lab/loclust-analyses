# Clustering Scripts

Scripts for running systematic clustering benchmarks on simulation datasets.

## Overview

These scripts run multiple clustering methods on all generated simulation datasets with **fixed k** values (based on the number of classes in each dataset) to enable fair comparison across methods.

## Structure

```
clustering_scripts/
├── run_clustering.py          # Run LoClust methods (Python)
├── run_r_methods.R            # Run R methods (KML, DTWclust, Traj, Mfuzz)
└── README.md                  # This file
```

## LoClust Methods (Python)

### Available Methods
- **gmm** - Gaussian Mixture Model (best overall LoClust method)
- **hierarchical** - Ward linkage hierarchical clustering
- **kmeans** - K-means clustering
- **spectral** - Spectral clustering (RBF kernel)

### Usage

```bash
# Run single method on all datasets
python run_clustering.py --method gmm

# Run all LoClust methods
python run_clustering.py --method all

# Run on specific batch only
python run_clustering.py --method gmm --batch 3_classes

# Dry run (preview without executing)
python run_clustering.py --method gmm --dry-run
```

### How it Works

1. Finds all `trajectories.tsv` files in `../data/`
2. Determines **k** from directory structure:
   - `3_classes/` → k=3
   - `6_classes/` → k=6
   - `9_classes/` → k=9
3. Runs clustering with `--force-k` (no automatic k-selection)
4. Outputs to: `data/.../clustering/{method}_k{k}/trajectories.clust.tsv`
5. Logs results to: `clustering_log.txt`

### Output Structure

```
data/3_classes/exponential-hyperbolic-norm/noise_0.04/seed_042/
├── trajectories.tsv              # Original simulation data
├── metadata.json
├── generation_log.txt
└── clustering/                   # Clustering results
    ├── gmm_k3/
    │   ├── trajectories.clust.tsv        # For v-measure calculation
    │   ├── clustering_log.txt            # Clustering details
    │   ├── cluster_summary.png           # Visualization
    │   └── confusion_matrix.png
    ├── hierarchical_k3/
    │   └── ...
    ├── kmeans_k3/
    │   └── ...
    └── spectral_k3/
        └── ...
```

## R Methods

### Available Methods
- **KML** - K-means for Longitudinal data (#1 overall method)
- **DTWclust** - Dynamic Time Warping clustering
- **Traj** - Group-based trajectory modeling
- **Mfuzz** - Fuzzy c-means clustering

### Usage

```bash
# TODO: Create run_r_methods.R script
Rscript run_r_methods.R --method kml
Rscript run_r_methods.R --method all
```

## Fixed k Values

| Dataset Type | k Value | Example |
|-------------|---------|---------|
| 3_classes | k=3 | exponential, hyperbolic, norm |
| 6_classes | k=6 | 6 different function types |
| 9_classes | k=9 | 9 different function types |

**Why fixed k?**
- Fair comparison: R methods (KML, DTWclust) don't all support automatic k-selection
- Benchmark focus: Testing clustering accuracy when k is known (ground truth)
- Reproducibility: Same k across all methods enables direct comparison

## Performance Expectations

Based on R_METHODS_COMPARISON.md:

| Method | Expected ARI | K-Selection | Speed |
|--------|-------------|-------------|-------|
| KML (R) | 0.928 | Perfect (100%) | Fast (~5s) |
| LoClust GMM | 0.857 | Near-perfect (89%) | Fast (~8s) |
| DTWclust (R) | 0.838 | Perfect (100%) | Slow (~140s) |
| LoClust Hierarchical | 0.792 | Perfect (100%) | Fast (~8s) |
| LoClust K-means | 0.744 | Perfect (100%) | Fast (~8s) |
| Traj (R) | 0.663 | Poor (33%) | Fast (~2s) |
| Mfuzz (R) | 0.608 | Poor (44%) | Very fast (~1s) |
| LoClust Spectral | 0.000 | Failed (0%) | Fast (~8s) |

## Next Steps

After clustering, run v-measure analysis:
```bash
cd ../analysis
python calculate_vmeasure.py
```

This will aggregate all clustering results and calculate performance metrics.
