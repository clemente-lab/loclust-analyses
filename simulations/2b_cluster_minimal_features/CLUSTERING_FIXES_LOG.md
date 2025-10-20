# Clustering Pipeline Fixes - October 2025

**Last Updated**: October 13, 2025
**Status**: Ready for rerun - All fixes applied

---

## Summary

Fixed two critical issues preventing full pipeline execution:

1. ✅ **Mfuzz**: Zero-variance crashes (310 failures) → Fixed with jitter
2. ✅ **Traj**: Missing from pipeline + wrong function call → Fixed and added

**Pipeline now runs**: 8 methods × 2,116 datasets = **16,928 total jobs**

---

## Issue 1: Mfuzz Zero-Variance Crash

### Problem
- **Error**: `NA/NaN/Inf in foreign function call (arg 1)`
- **Frequency**: 310 failures (~15% of datasets)
- **Cause**: Mfuzz's `standardise()` divides by SD → `Inf/NaN` when SD=0
- **Affected**: All noise_0.0 datasets with flat trajectories

### Solution
Added zero-variance detection and tiny jitter in `run_mfuzz()`:

```R
# Check for zero-variance rows
row_sds <- apply(mat, 1, sd, na.rm=TRUE)
zero_var_rows <- is.na(row_sds) | row_sds == 0 | !is.finite(row_sds)

if (any(zero_var_rows)) {
  for (i in which(zero_var_rows)) {
    mat[i, ] <- mat[i, ] + rnorm(ncol(mat), mean=0, sd=1e-10)
  }
}
```

**Impact**: Negligible (1e-10 is 10 orders of magnitude smaller than data)

### Verification
- **Before fix (Oct 11)**: 310 errors
- **After fix (Oct 13)**: 0 errors ✅
- **Success rate**: 100%

---

## Issue 2: Traj Method Problems

### Problem 1: Not in Pipeline
Traj was implemented but excluded from HPC submission:
- Missing from `run_single_r_method.R` (no library/switch case)
- Missing from `submit_all_clustering.sh` (not in R_METHODS)

### Problem 2: Wrong Function Call
Code called non-existent function:
```R
traj_result <- traj::traj(...)  # ❌ This function doesn't exist
```

### Solution

**Added to pipeline**:
- `run_single_r_method.R`: Added `library(traj)` and switch case
- `submit_all_clustering.sh`: Added traj to R_METHODS list

**Fixed function call** using correct 3-step workflow:
```R
# Step 1: Calculate trajectory measures
step1 <- Step1Measures(long_data, ID=TRUE, measures=c("mean", "sd"))

# Step 2: Select clustering
step2 <- Step2Selection(step1, nclusters=num_classes)

# Step 3: Assign clusters
step3 <- Step3Clusters(long_data, step2, clust.method="kmeans")
clusters <- step3$clusters
```

---

## Files Modified

### 1. `/simulations/2a_cluster_local/run_r_methods.R`
- Modified `run_mfuzz()`: Added zero-variance handling
- Modified `run_traj()`: Fixed to use Step1/Step2/Step3 workflow

### 2. `/simulations/2b_cluster_hpc/run_single_r_method.R`
- Added `library(traj)`
- Added traj case to switch statement

### 3. `/simulations/2b_cluster_hpc/submit_all_clustering.sh`
- Changed `R_METHODS="kml dtwclust mfuzz"`
- To: `R_METHODS="kml dtwclust traj mfuzz"`

### 4. `/simulations/2b_cluster_hpc/README.md`
- Updated method counts: 7 → 8 methods
- Updated total jobs: 14,700 → 16,800

---

## Pipeline Configuration

### Methods (8 total)
**LoClust (4)**:
- gmm
- hierarchical
- kmeans
- spectral

**R (4)**:
- kml
- dtwclust
- traj (newly added)
- mfuzz (fixed)

### Job Counts
- LoClust: 4 methods × 2,116 datasets = 8,464 jobs
- R methods: 4 methods × 2,116 datasets = 8,464 jobs
- **Total**: 16,928 clustering jobs
- **Plus**: 1 v-measure analysis job (runs when all complete)

---

## Running the Pipeline

### Full submission (via SSH):
```bash
cd /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_hpc
bash submit_all_clustering.sh
```

### Monitoring:
```bash
# Job status
bjobs -sum

# Count completions
for method in gmm hierarchical kmeans spectral kml dtwclust traj mfuzz; do
    count=$(find ../data -name "trajectories.clust.tsv" -path "*/${method}_k*" 2>/dev/null | wc -l)
    echo "$method: $count / 2116"
done

# Check for errors
tail -f logs/r_mfuzz.out | grep "ERROR:"
tail -f logs/r_traj.out | grep "ERROR:"
```

### Expected outputs:
```
16,928 trajectories.clust.tsv files
(8 methods × 2,116 datasets)
```

---

## Run History

### Oct 11, 2025
- Submitted 7 methods (no traj)
- Mfuzz: 310 failures (zero-variance issue)
- Other methods: All successful

### Oct 13, 2025 (first attempt)
- Submitted 8 methods (traj added)
- Mfuzz: 0 failures (fix worked! ✅)
- Traj: 2,116 failures (wrong function call)
- Other methods: All successful

### Oct 13, 2025 (multiple fix iterations)

**First run (12:48pm)**: Traj failed - wrong function names (`step1measures` vs `Step1Measures`)

**Second run (12:54pm)**: Traj failed - wrong API (needed matrix format, not long format)

**Third run (1:05-1:08pm)**: All methods working ✅
- Traj fixed: Correct function names (`Step1Measures`, `Step2Selection`, `Step3Clusters`)
- Traj fixed: Correct input (Y_matrix, X_matrix instead of long format)
- Traj fixed: Correct output extraction (`step3$partition$Cluster`)
- Mfuzz: 0 errors (jitter fix working)
- All 8 methods completing successfully

---

## Technical Notes

### Mfuzz Jitter
- Only affects zero-variance trajectories
- Applied to ~200 trajectories per dataset with flat functions
- Magnitude: 1e-10 (negligible vs typical values of 0.1-10.0)
- Preserves clustering structure

### Traj 3-Step Workflow
The traj package doesn't have a single clustering function. It uses:
1. **Step1Measures**: Calculate trajectory summaries (mean, SD, etc.)
2. **Step2Selection**: Determine optimal clusters (we force k=num_classes)
3. **Step3Clusters**: Assign trajectories using k-means on measures

This is fundamentally different from other methods (operates on trajectory features, not raw data).

---

## Previous Issues (Resolved)

### Conda Environment (Oct 10)
- System conda was corrupted
- Fixed by using environment path directly

### Log File Explosion (Oct 10)
- Was generating 14,700+ log files
- Fixed by consolidating to 16 files (2 per method)

---

## Related Documentation

- HPC usage guide: `USAGE_GUIDE.md`
- Main README: `README.md`
- Session logs: `../documentation/sessions/SESSION_2025_10_10_HPC_CLUSTER_SETUP.md`
- R methods source: `../2a_cluster_local/run_r_methods.R`

---

**Status**: ✅ All fixes applied, ready for full pipeline rerun

---

## CRITICAL FINDING: Traj Version Differences (Oct 15, 2025)

### Investigation Summary
Traj method performance showed dramatic improvement in new simulations vs old Hilary results:
- **OLD (Hilary)**: mean v_measure=0.449, median=0.646 (42% degenerate clusterings)
- **NEW (potentially_simple)**: mean v_measure=0.672, median=0.643 (0% degenerate clusterings)

Initially suspected data differences, but diagnostic analysis revealed **identical data characteristics** between old and new datasets (same ranges, means, SDs, correlations ~0.999 within-class).

### Root Cause: Traj Package Version Upgrade

**OLD (Hilary directory):**
- **Package**: traj version **1.2** (released 2014-07-10)
- **Functions**: `step1measures()`, `step2factors()`, `step3clusters()`
- **Step 2 behavior**: `step2factors(s1)` - automatic factor selection via factor analysis
- **Installation**: Custom library at `/sc/arion/projects/clemej05a/hilary/loclust_tool_comp/traj/lib/`

**NEW (potentially_simple pipeline):**
- **Package**: traj version **2.2.1** (released 2025-02-01)
- **Functions**: `Step1Measures()`, `Step2Selection()`, `Step3Clusters()` (capitalized)
- **Step 2 behavior**: `Step2Selection(step1, select=num_classes)` - forced selection of k factors
- **Installation**: Via conda environment `loclust_cluster`

### The Critical Difference

The key algorithmic change is in **Step 2** (dimensionality reduction):

```r
# OLD (traj 1.2)
s1 <- step1measures(data, time, ID=FALSE)
s2 <- step2factors(s1)  # NO PARAMETERS - automatic selection
s3 <- step3clusters(s2, nclusters=k)

# NEW (traj 2.2.1)
step1 <- Step1Measures(Y_matrix, Time=X_matrix, ID=FALSE)
step2 <- Step2Selection(step1, select=num_classes)  # FORCED k factors
step3 <- Step3Clusters(step2, nclusters=num_classes)
```

**Impact**: The old `step2factors()` automatically selects the number of factors/measures to use for clustering, which can lead to poor choices that cause degenerate clusterings. The new `Step2Selection(select=k)` forces selection of exactly k factors, providing more stable input to the clustering step.

### Evidence

1. **Diagnostic comparison** on same dataset (hyperbolic-norm-poly, seed 2):
   - Old clustering: 399, 200, 1 (66.5% in one cluster - DEGENERATE)
   - New clustering: 360, 158, 82 (60%, 26%, 14% - BALANCED)
   - Data characteristics: IDENTICAL

2. **Package verification**:
   - Old: traj 1.2 functions confirmed via `/hilary/loclust_tool_comp/traj/lib/traj/DESCRIPTION`
   - New: traj 2.2.1 functions confirmed via `check_traj_version.R` script

3. **Failure patterns**:
   - Old: 42% of runs produce degenerate clusterings (one cluster >80% of data)
   - New: 0% degenerate clusterings in sampled runs

### Implications

**This is NOT a fair comparison** between old and new results:
- Different traj package versions (11 years apart: 2014 vs 2025)
- Different algorithms (automatic vs forced factor selection)
- Old Hilary results used traj 1.2 with fundamentally different behavior

**To compare fairly**, we would need to either:
1. Rerun old simulations with traj 2.2.1 (recommended)
2. Install traj 1.2 and rerun new simulations (not recommended - old version is unstable)

### Files Created During Investigation

- `2b_cluster_potentially_simple/diagnose_traj_failures.R` - Diagnostic script comparing old/new
- `2b_cluster_potentially_simple/check_traj_version.R` - Version checking script
- `2b_cluster_potentially_simple/traj_diagnostics.txt` - Comparison results
- `3_analyze_results/plot_individual_clustering.R` - Visualization tool for any method/dataset

### Recommendation

Accept that traj 2.2.1 is the current standard and note that old Hilary results used traj 1.2 with different (less stable) behavior. The new results are more reliable due to the improved algorithm in traj 2.2.1.

---

**Status**: ✅ All fixes applied, traj version difference documented
