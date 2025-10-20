# LoClust Minimal Features Pipeline

**Date Created:** 2025-10-15
**Pipeline:** `2b_cluster_minimal_features/`
**Data Source:** `data_potentially_simple/` (same as `2b_cluster_potentially_simple/`)

---

## Purpose

This pipeline tests LoClust with **minimal baseline configuration** to evaluate the impact of:
1. **No interpolation** (raw trajectory data)
2. **Original 33 statistical features** (vs 54 extended features)
3. **Fixed 9 PCA components** (vs adaptive selection)

All other parameters remain identical to `2b_cluster_potentially_simple/`.

---

## LoClust Configuration Differences

### **Standard Pipeline** (`2b_cluster_potentially_simple/`)
```bash
python cluster_trajectories.py \
    --force-k ${NUM_CLASSES} \
    --pca_flag \
    --write_flag
    # Uses adaptive interpolation (default ON)
    # Uses all 54 statistical features (default)
    # Uses adaptive PCA selection (elbow method)
```

### **Minimal Features Pipeline** (`2b_cluster_minimal_features/`)
```bash
python cluster_trajectories.py \
    --force-k ${NUM_CLASSES} \
    --pca_flag \
    -pn 9 \
    --no-interpolate \
    --use-original-stats \
    --write_flag
    # Disables interpolation
    # Uses 33 original features
    # Forces exactly 9 PCA components
```

---

## Implementation Details

### **Modified LoClust Code**
See `/home/ewa/mnt/loclust/simulations/MINIMAL_FEATURES_MODIFICATIONS.md` for full details.

**Key changes:**
1. **`loclust/stats/data_processing.py`**
   - Created `ORIGINAL_STATS` constant (33 features)
   - Modified `ALL_STATS` to extend ORIGINAL_STATS (54 features)

2. **`loclust/clusterAnalysis.py`**
   - Added `stats_list="all"` parameter (backward compatible)
   - Passes custom feature list to `calculate_allstats()`

3. **`scripts/cluster_trajectories.py`**
   - Added `--no-interpolate` flag
   - Added `--use-original-stats` flag
   - Already had `-pn NUM` for fixed PCA components

### **Modified Job Scripts**
All 4 LoClust job scripts updated with new flags:
- `run_loclust_gmm.sh`
- `run_loclust_hierarchical.sh`
- `run_loclust_kmeans.sh`
- `run_loclust_spectral.sh`

**R method scripts unchanged** (kml, dtwclust, traj, mfuzz)

---

## Statistical Features

### **ORIGINAL_STATS (33 features)**
Used in this pipeline via `--use-original-stats`:

**Basic properties (7):**
- trange, mean, std
- coefficient_variation
- abs_integral, change, mean_change_per_timeunit

**Relative changes (3):**
- change_to_first, change_to_mid, change_to_mean

**Linear regression (2):**
- slope, r_square

**First derivatives (5):**
- max_first_diff, std_first_diff, std_first_diff_per_timeunit
- mean_abs_first_diff, max_abs_first_diff

**Second derivatives (4):**
- std_second_diff, mean_second_diff
- mean_abs_second_diff, max_abs_second_diff

**Third derivatives (1):**
- std_third_diff

**Temporal patterns (2):**
- rel_pos_of_max_first_diff
- rel_pos_of_max_second_diff

**Complex ratios (9):**
- ratio_max_abs_to_mean, ratio_max_abs_to_slope, ratio_std_to_slope
- ratio_late_to_total_change, ratio_early_to_total_change, ratio_early_to_later_change
- ratio_max_abs_second_diff_to_mean_over_time
- ratio_max_abs_second_diff_to_mean_abs_first_diff
- ratio_mean_abs_second_diff_to_mean_abs_first_diff

### **Extended Features (NOT used in this pipeline)**
Additional 21 features in `ALL_STATS` (excluded via `--use-original-stats`):
- Autocorrelation (2): lag1, lag2
- Peak detection (3): num_peaks, max_peak_prominence, peak_position
- Monotonicity (4): score, direction_changes, is_increasing, is_decreasing
- Frequency domain (3): dominant_frequency, spectral_entropy, low_freq_power
- Shape-specific (9): concavity, normalized values, AUC, quartile_coefficient, etc.

---

## Expected Behavior

### **Verification in Logs**
When jobs run, check `clustering_log.txt` for:

✅ **Fixed PCA:**
```
Using fixed 9 PCA components (user-specified)
Final: 9 PCA components explaining XX.X% of variance
```

✅ **No Interpolation:**
- Should NOT see "performing adaptive interpolation"
- Should see "Plotted 0 interpolated trajectories"

✅ **33 Features:**
- Feature matrix should have 33 columns (check logs)

✅ **Forced k:**
```
Using forced k=N (skipping optimization)
```

---

## Usage

### **1. Generate Dataset Index**
```bash
cd /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features
python generate_dataset_index.py
```

### **2. Submit Jobs**
```bash
# Submit all methods (4 LoClust + 4 R)
bash submit_all_clustering.sh

# Or submit only LoClust methods
bash submit_all_clustering.sh --loclust-only

# Or submit only R methods
bash submit_all_clustering.sh --r-only
```

### **3. Monitor Progress**
```bash
bjobs -w                    # All jobs
bjobs | grep loclust        # LoClust jobs only
ls logs/                    # Check log files
```

### **4. Calculate V-measure**
```bash
python calculate_vmeasure.py
```

---

## Datasets

**Source:** `data_potentially_simple/`
- **Structure:** Flat directory with 8 timepoints, k={2,3,4,5,6} classes
- **Total datasets:** ~1,740
- **Path:** `/sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple/`

**Dataset naming:**
```
{noise}.{func1}-{func2}-...-norm.{reps}reps.{seed}.tsv
```

**Example:**
```
0.04noise.exponential-hyperbolic-norm.200reps.0.tsv
→ 4% noise, 2 function classes, 200 trajectories/class, seed 0
```

---

## Output Structure

```
data_potentially_simple/
└── input_trajs/
    └── 8/               # 8 timepoints
        └── 3/           # 3 classes
            ├── 0.04noise.exponential-hyperbolic-norm.200reps.0.tsv
            └── clustering/
                ├── gmm_k3/
                │   ├── 0.04noise.exponential-hyperbolic-norm.200reps.0.clust.tsv
                │   └── clustering_log.txt
                ├── hierarchical_k3/
                ├── kmeans_k3/
                ├── spectral_k3/
                ├── kml_k3/
                ├── dtwclust_k3/
                ├── traj_k3/
                └── mfuzz_k3/
```

---

## Comparison to Other Pipelines

| Feature | `2b_cluster_hpc` | `2b_cluster_potentially_simple` | `2b_cluster_minimal_features` |
|---------|------------------|--------------------------------|-------------------------------|
| Data Source | `data/` (hierarchical) | `data_potentially_simple/` | `data_potentially_simple/` |
| Interpolation | ✅ Adaptive | ✅ Adaptive | ❌ **Disabled** |
| Stats Features | 54 (all) | 54 (all) | **33 (original)** |
| PCA Components | Adaptive | Adaptive | **Fixed at 9** |
| Forced k | ✅ | ✅ | ✅ |
| R Methods | ✅ | ✅ | ✅ |

---

## Testing

**Test command** (single dataset):
```bash
unset PYTHONPATH
python /sc/arion/projects/CVDlung/earl/loclust/scripts/cluster_trajectories.py \
    -fi "0.04noise.exponential-hyperbolic-norm.200reps.0.tsv" \
    -di "/sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple/input_trajs/8/3/" \
    -fo "test_output.clust.tsv" \
    -do "./test_minimal_features/" \
    -c "gmm" \
    -tk "func" \
    -ak "cluster" \
    --force-k 3 \
    -pn 9 \
    -pf \
    --no-interpolate \
    --use-original-stats \
    --write_flag \
    -rs 42
```

**Expected output:**
- ✅ Fixed 9 PCA components
- ✅ No interpolation messages
- ✅ Forced k=3
- ✅ Output file created

---

## Troubleshooting

### **PYTHONPATH conflicts:**
```bash
unset PYTHONPATH
export PYTHONPATH="/sc/arion/projects/CVDlung/earl/loclust"
```

### **Check if flags are working:**
```bash
# Grep log files for verification
grep "PCA components" logs/*.out
grep "interpolat" logs/*.out
grep "forced k" logs/*.out
```

### **Compare to standard pipeline:**
```bash
# Check differences in job scripts
diff ../2b_cluster_potentially_simple/run_loclust_gmm.sh run_loclust_gmm.sh
```

---

## Related Documentation

- **Code modifications:** `/home/ewa/mnt/loclust/simulations/MINIMAL_FEATURES_MODIFICATIONS.md`
- **Standard pipeline:** `../2b_cluster_potentially_simple/README_POTENTIALLY_SIMPLE.md`
- **Original pipeline:** `../2b_cluster_hpc/README.md`

---

## Contact

For questions about this pipeline or LoClust modifications, see:
- MINIMAL_FEATURES_MODIFICATIONS.md
- LoClust documentation: `/sc/arion/projects/CVDlung/earl/loclust/docs/`
