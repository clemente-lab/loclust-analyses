# Analysis Scripts

Scripts for calculating clustering performance metrics and generating visualizations.

## Overview

After running clustering on simulation datasets, these scripts:
1. Calculate v-measure, ARI, NVI, and other metrics
2. Aggregate results across all methods and datasets
3. Generate comparative visualizations

## Files

```
analysis/
├── calculate_vmeasure.py      # Calculate metrics for all clustered datasets
├── plot_vmeasure.R            # Generate comparison plots
├── compare_clustering.py      # Legacy v-measure calculator (for reference)
├── graph.R                    # Legacy plotting script (for reference)
└── sc_plot_v_measure_results_loclust6.R  # Legacy (for reference)
```

## Workflow

### 1. Run Clustering First

Before running analysis, you must cluster the datasets:

```bash
# LoClust methods (Python)
cd ../clustering_scripts
python run_clustering.py --method all

# R methods
Rscript run_r_methods.R --method all
```

This creates `trajectories.clust.tsv` files with cluster assignments.

### 2. Calculate Metrics

Calculate v-measure and other metrics for all clustered datasets:

```bash
cd ../analysis

# Calculate for all methods
python calculate_vmeasure.py

# Calculate for specific method
python calculate_vmeasure.py --method gmm

# Calculate for specific batch
python calculate_vmeasure.py --batch 3_classes
```

**Output:**
- `../results/vmeasure_scores.tsv` - Full results (one row per dataset)
- `../results/vmeasure_summary.tsv` - Summary by method

**Metrics calculated:**
- **ARI** (Adjusted Rand Index) - Primary metric, accounts for chance
- **V-Measure** - Harmonic mean of homogeneity and completeness
- **NVI** (Normalized Variation of Information)
- **F-Measure** - Harmonic mean of precision and recall
- **Homogeneity** - All clusters contain only members of a single class
- **Completeness** - All members of a class are in the same cluster
- **k-accuracy** - Whether detected k matches true number of classes

### 3. Generate Plots

Create visualization plots from the aggregated results:

```bash
Rscript plot_vmeasure.R
```

**Plots generated** (saved to `../results/`):
1. `vmeasure_by_noise.png` - V-measure vs noise level by method
2. `ari_by_noise.png` - ARI vs noise level by method
3. `method_comparison_heatmap.png` - Heatmap of mean ARI
4. `method_ranking.png` - Overall method performance bar chart

## Output Format

### vmeasure_scores.tsv

Each row represents one clustered dataset:

| Column | Description |
|--------|-------------|
| method | Clustering method (gmm, kml, etc.) |
| num_classes | True number of classes (3, 6, or 9) |
| function_combo | Function combination name |
| noise_level | Y-axis noise level (0.0-0.20) |
| seed | Random seed used |
| k_detected | Number of clusters found |
| k_correct | Boolean: k_detected == num_classes |
| nvi | Normalized Variation of Information |
| v_measure | V-measure score (0-1, higher better) |
| homogeneity | Homogeneity score |
| completeness | Completeness score |
| f_measure | F-measure score |
| ari | Adjusted Rand Index (-1 to 1, higher better) |

### vmeasure_summary.tsv

Summary statistics by method:

| Metric | Description |
|--------|-------------|
| ari mean | Average ARI across all datasets |
| ari std | Standard deviation of ARI |
| ari count | Number of datasets processed |
| v_measure mean | Average v-measure |
| k_correct mean | Proportion of correct k selections |

## Expected Performance

Based on prior benchmarks (see `../docs/R_METHODS_COMPARISON.md`):

| Rank | Method | Expected ARI | K-Selection |
|------|--------|-------------|-------------|
| 1 | KML | 0.928 ± 0.101 | 100% |
| 2 | LoClust GMM | 0.857 ± 0.145 | 89% |
| 3 | DTWclust | 0.838 ± 0.110 | 100% |
| 4 | LoClust Hierarchical | 0.792 ± 0.128 | 100% |
| 5 | LoClust K-means | 0.744 ± 0.093 | 100% |
| 6 | Traj | 0.663 ± 0.332 | 33% |
| 7 | Mfuzz | 0.608 ± 0.128 | 44% |
| 8 | LoClust Spectral | 0.000 ± 0.000 | 0% |

**Note:** These are from previous 4-class datasets. Results may differ for 3/6/9-class systematic simulations.

## Troubleshooting

### No clustered files found

Make sure you've run clustering first:
```bash
cd ../clustering_scripts
python run_clustering.py --method gmm --dry-run  # Preview
python run_clustering.py --method gmm           # Actually run
```

### Import errors

The scripts require loclust package:
```bash
# Install in development mode from repo root
cd /home/ewa/Dropbox/mssm_research/loclust
pip install -e .
```

### Missing R packages

Install required R packages:
```R
install.packages(c("tidyverse", "ggplot2"))
```

## Legacy Scripts

The following scripts were copied from legacy codebase for reference:
- `compare_clustering.py` - Original v-measure calculator (uses old 'lodi' imports)
- `graph.R` - Complex legacy plotting script
- `sc_plot_v_measure_results_loclust6.R` - Simple legacy plotter

These are **NOT used** in the current workflow - they're kept for reference only. Use `calculate_vmeasure.py` and `plot_vmeasure.R` instead.
