# LoClust Scripts Fixed - 2025-10-15 20:47

## Problem Identified

Jobs were submitted with **INCORRECT configuration** - missing minimal features flags.

### **What Was Wrong:**

**Log evidence showing wrong configuration:**
```
❌ Interpolation: ENABLED
   "...performing adaptive interpolation"
   "• LOWESS (dense): 600 trajectories"

❌ PCA Components: ADAPTIVE (2 selected, NOT 9!)
   "Using elbow method for optimal PCA component selection..."
   "Selected (median): 2 components"
   "Variance explained: 100.00%"

✅ Forced k: CORRECT (only this worked)
   "Using forced k=3 (skipping optimization)"
```

**Root cause:**
- Scripts had wrong `SCRIPT_DIR` path (pointed to `2b_cluster_potentially_simple`)
- Scripts missing 3 critical flags: `-pn 9`, `--no-interpolate`, `--use-original-stats`

---

## What Was Fixed

### **All 4 LoClust Job Scripts Updated:**

1. **`run_loclust_gmm.sh`**
2. **`run_loclust_hierarchical.sh`**
3. **`run_loclust_kmeans.sh`**
4. **`run_loclust_spectral.sh`**

### **Changes Made:**

**1. Fixed SCRIPT_DIR (all 4 scripts):**
```bash
# OLD (WRONG):
SCRIPT_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_potentially_simple"

# NEW (CORRECT):
SCRIPT_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features"
```

**2. Added 3 Critical Flags (all 4 scripts):**
```bash
# OLD (WRONG):
python "$CLUSTER_SCRIPT" \
    -fi "$TRAJ_FILENAME" \
    ...
    --force-k "$NUM_CLASSES" \
    --write_flag \
    --pca_flag \
    --no_cluster_plots_flag \
    > "$LOG_FILE" 2>&1

# NEW (CORRECT):
# Run clustering with minimal features configuration:
# - No interpolation (--no-interpolate)
# - Original 33 statistical features (--use-original-stats)
# - Fixed 9 PCA components (-pn 9)
python "$CLUSTER_SCRIPT" \
    -fi "$TRAJ_FILENAME" \
    ...
    --force-k "$NUM_CLASSES" \
    --write_flag \
    --pca_flag \
    -pn 9 \
    --no-interpolate \
    --use-original-stats \
    --no_cluster_plots_flag \
    > "$LOG_FILE" 2>&1
```

---

## Jobs Status

**Old jobs:** ✅ **Killed** (seen in logs/loclust_gmm.err - all show "Terminated")

**New jobs:** Ready to submit with correct configuration

---

## Next Steps

### **1. Clean Output Directories (Optional but Recommended)**

Remove incorrectly generated results:
```bash
cd /sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple

# Check what's there
find . -name "clustering_log.txt" -type f | head -5 | xargs grep "PCA component"

# If you see "elbow method" instead of "fixed 9", clean up:
find . -type d -name "gmm_k*" -exec rm -rf {} + 2>/dev/null
find . -type d -name "hierarchical_k*" -exec rm -rf {} + 2>/dev/null
find . -type d -name "kmeans_k*" -exec rm -rf {} + 2>/dev/null
find . -type d -name "spectral_k*" -exec rm -rf {} + 2>/dev/null
```

### **2. Resubmit Jobs with Fixed Scripts**

```bash
cd /sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features

# Verify scripts are correct
grep "SCRIPT_DIR=" run_loclust_gmm.sh
# Should show: SCRIPT_DIR="/sc/arion/projects/CVDlung/earl/loclust/simulations/2b_cluster_minimal_features"

grep -A 2 "no-interpolate" run_loclust_gmm.sh
# Should show: --no-interpolate, --use-original-stats, -pn 9

# Resubmit
bash submit_all_clustering.sh
# Or just LoClust methods:
bash submit_all_clustering.sh --loclust-only
```

### **3. Monitor New Jobs**

```bash
# Watch for jobs starting
bjobs -w

# Check new logs (wait a few minutes)
tail -100 logs/loclust_gmm.out | grep -E "PCA|interpolat|forced"
```

### **4. Verify Configuration in Logs**

After jobs start running, check one clustering log:
```bash
find /sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple \
    -name "clustering_log.txt" -newer logs/loclust_gmm.err \
    | head -1 | xargs head -80
```

**Expected output:**
```
✅ NO "performing adaptive interpolation" message
✅ "Using fixed 9 PCA components (user-specified)"
✅ "Final: 9 PCA components explaining XX.X% of variance"
✅ "Using forced k=N (skipping optimization)"
```

---

## Verification Checklist

After resubmission, check logs for:

- [ ] **No interpolation messages** (should NOT see "performing adaptive interpolation")
- [ ] **Fixed 9 PCA components** (should see "Using fixed 9 PCA components (user-specified)")
- [ ] **Forced k** (should see "Using forced k=N (skipping optimization)")
- [ ] **33 features** (feature matrix dimensions in logs should show 33 columns)

---

## Files Status

**Fixed files:**
- ✅ `run_loclust_gmm.sh` - SCRIPT_DIR + 3 flags added
- ✅ `run_loclust_hierarchical.sh` - SCRIPT_DIR + 3 flags added
- ✅ `run_loclust_kmeans.sh` - SCRIPT_DIR + 3 flags added
- ✅ `run_loclust_spectral.sh` - SCRIPT_DIR + 3 flags added

**Unchanged files:**
- ✅ R method scripts (no changes needed)
- ✅ `submit_all_clustering.sh` (already correct)
- ✅ `generate_dataset_index.py` (already correct)

---

**All scripts now ready for resubmission with correct minimal features configuration!**
