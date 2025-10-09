# Branch Compatibility Note

**Important**: This simulations directory was developed and tested on the `master` branch.

## Pipeline Compatibility

The clustering pipeline in this simulations directory relies on **updated LoClust scripts** that are only present on the `master` branch:

- `scripts/cluster_trajectories.py` - Updated with bug fixes and new features
- `loclust/clusterAnalysis.py` - Fixed numpy array handling
- `loclust/stats/trajectory_properties.py` - Modular stats implementation

## If This Directory Is Shared to Another Branch

⚠️ **Warning**: If you copy or merge this `simulations/` directory to another branch, the clustering scripts (`2a_cluster_local/run_clustering.py` and related tools) **may not work correctly** because they depend on the updated pipeline code.

### What Will Work
- ✅ Data generation (`1_generate/`) - Uses standalone simulation code
- ✅ Analysis scripts (`3_analyze_results/`) - Standalone metrics calculation
- ✅ All generated data files in `data/` - Pure data, no dependencies

### What May Not Work
- ❌ Local clustering (`2a_cluster_local/run_clustering.py`) - Requires updated `cluster_trajectories.py`
- ❌ HPC cluster scripts (`2b_cluster_hpc/`) - Calls the same updated pipeline

## Recommended Approach

If you need to use the simulations on another branch:

**Option A: Use the data only**
- Copy just the `simulations/data/` directory
- Write new clustering scripts compatible with that branch's pipeline

**Option B: Cherry-pick the pipeline updates**
- Merge the updated pipeline scripts from `master` to your branch
- Then the full simulations directory will work

**Option C: Run clustering on master branch**
- Generate/access data on your branch
- Switch to `master` to run clustering
- Copy results back to your branch

## Branch Information

- **Developed on**: `master` branch
- **Last updated**: October 8, 2025
- **LoClust commit**: 07f7a6c - "Add systematic simulation benchmarking system with 2,116 datasets"
- **Pipeline status**: ✅ Fully functional on `master` branch

---

**Bottom line**: For full functionality, use this simulations directory on the `master` branch. If using elsewhere, you may need to adapt the clustering scripts to match that branch's pipeline implementation.
