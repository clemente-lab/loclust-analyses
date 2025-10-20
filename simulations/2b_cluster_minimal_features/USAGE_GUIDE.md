# Complete Usage Guide: Running Simulations on LSF Cluster

## Overview

This guide walks you through running the complete LoClust clustering benchmark on an LSF compute cluster.

**Workflow:**
1. Generate data **locally** (10-30 minutes)
2. Transfer data to cluster
3. Submit **job arrays** to cluster (14,700 parallel jobs)
4. Download results when complete

---

## Step 1: Generate Data Locally

Generate all 2,100 simulation datasets on your local machine:

```bash
cd ~/Dropbox/mssm_research/loclust/simulations/generation_scripts

# Review configuration
less simulation_config.yaml

# Generate all data (creates 2,100 datasets)
python generate_systematic.py --config simulation_config.yaml --yes
```

**Output:**
```
data/
├── 3_classes/     (1,200 datasets)
├── 6_classes/     (600 datasets)
└── 9_classes/     (300 datasets)
```

**Estimated time:** 10-30 minutes
**Disk space:** ~5-10 GB

---

## Step 2: Transfer Data to Cluster

Use `rsync` to transfer the data directory to the cluster:

```bash
# From local machine
cd ~/Dropbox/mssm_research/loclust/simulations

# Transfer to cluster (adjust hostname and path)
rsync -avz --progress data/ username@cluster.domain.edu:/path/to/loclust/simulations/data/

# Also transfer scripts
rsync -avz --progress cluster_scripts/ username@cluster.domain.edu:/path/to/loclust/simulations/cluster_scripts/
rsync -avz --progress clustering_scripts/ username@cluster.domain.edu:/path/to/loclust/simulations/clustering_scripts/
rsync -avz --progress analysis/ username@cluster.domain.edu:/path/to/loclust/simulations/analysis/
```

---

## Step 3: Configure Cluster Environment

SSH into the cluster and set up your environment:

```bash
ssh username@cluster.domain.edu
cd /path/to/loclust/simulations/cluster_scripts
```

### A. Check LSF queue names

```bash
bqueues  # List available queues
```

Update queue names in the LSF scripts if needed:
```bash
# Edit these files to match your cluster's queue names
nano run_loclust_array.sh    # Change #BSUB -q premium
nano run_r_method_array.sh   # Change #BSUB -q premium
nano run_vmeasure.sh         # Change #BSUB -q premium
```

### B. Set up Python environment

If using environment modules:
```bash
module load python/3.9
module load R/4.2.0
```

If using conda:
```bash
conda activate loclust_env
```

**Verify installations:**
```bash
python -c "import numpy, pandas, sklearn; print('Python packages OK')"
Rscript -e "library(kml); library(dtwclust); library(Mfuzz); cat('R packages OK\n')"
```

### C. Add module loads to scripts (if needed)

Edit the LSF scripts to add module loads:

```bash
# In run_loclust_array.sh, after the #BSUB lines:
module load python/3.9

# In run_r_method_array.sh, after the #BSUB lines:
module load R/4.2.0
```

---

## Step 4: Submit Jobs to Cluster

### Quick Submit (All Methods)

```bash
bash submit_all_clustering.sh
```

This submits **14,700 jobs** (7 methods × 2,100 datasets) plus the v-measure analysis job.

### Selective Submission

Submit only LoClust methods:
```bash
bash submit_all_clustering.sh --loclust-only
```

Submit only R methods:
```bash
bash submit_all_clustering.sh --r-only
```

### What Happens

The script will:
1. ✓ Generate `dataset_index.tsv` (maps job indices to datasets)
2. ✓ Create method-specific LSF scripts from templates
3. ✓ Submit 7 job arrays to LSF:
   - `loclust_gmm[1-2100]`
   - `loclust_hierarchical[1-2100]`
   - `loclust_kmeans[1-2100]`
   - `loclust_spectral[1-2100]`
   - `r_kml[1-2100]`
   - `r_dtwclust[1-2100]`
   - `r_mfuzz[1-2100]`
4. ✓ Submit `vmeasure_calculation` job with dependency on all clustering

**Output:**
```
==========================================
Submission Complete!
==========================================
LoClust jobs: 4
  gmm: 12345
  hierarchical: 12346
  kmeans: 12347
  spectral: 12348
R jobs: 3
  kml: 12349
  dtwclust: 12350
  mfuzz: 12351

V-measure job will run when all clustering jobs complete
==========================================
```

---

## Step 5: Monitor Progress

### Check job status

```bash
# All your jobs
bjobs -w

# Summary by job array
bjobs -sum

# Specific method
bjobs -J loclust_gmm

# Count running/pending jobs
bjobs | grep RUN | wc -l
bjobs | grep PEND | wc -l
```

### Check completion

```bash
# Count successful outputs for each method
for method in gmm hierarchical kmeans spectral kml dtwclust mfuzz; do
    count=$(find ../data -name "trajectories.clust.tsv" -path "*/${method}_k*" | wc -l)
    echo "$method: $count / 2100"
done
```

### Check logs

```bash
# List all log files
ls logs/

# Check recent errors
tail logs/*.err

# Check specific job
tail logs/loclust_gmm_123_456789.out
```

### Performance monitoring

```bash
# Job statistics
bjobs -l 12345

# Resource usage
bhist -l 12345
```

---

## Step 6: Troubleshooting Failed Jobs

### Find failed jobs

```bash
# Jobs that exited with error
bjobs -a | grep EXIT

# Find datasets missing output files
python -c "
import sys
sys.path.insert(0, '../clustering_scripts')
from run_clustering import find_all_datasets

datasets = find_all_datasets('../data')
for traj_file, num_classes, metadata in datasets:
    traj_dir = traj_file.parent
    for method in ['gmm', 'kml', 'dtwclust']:
        output = traj_dir / 'clustering' / f'{method}_k{num_classes}' / 'trajectories.clust.tsv'
        if not output.exists():
            print(f'Missing: {metadata[\"function_combo\"]} / noise_{metadata[\"noise_level\"]} / seed_{metadata[\"seed\"]:03d} / {method}')
"
```

### Resubmit specific jobs

```bash
# Resubmit single dataset for specific method
# Find the dataset index from dataset_index.tsv, then:
LSB_JOBINDEX=42 bash run_loclust_gmm.sh  # Run locally (for testing)

# Or resubmit through LSF
bsub -J loclust_gmm_retry -a "loclust_gmm[42]" < run_loclust_gmm.sh
```

### Common issues

**"Command not found"**
- Add module loads to LSF scripts
- Or add `source activate conda_env`

**"Package not found" (R)**
```bash
# Install missing R packages on cluster
module load R/4.2.0
R
> install.packages(c("kml", "dtwclust", "Mfuzz", "data.table"))
```

**Jobs timeout (TERM_RUNLIMIT)**
- Increase wall time in `#BSUB -W` directive
- Most jobs finish in < 5 minutes, so 30 min should be safe

**Memory errors (TERM_MEMLIMIT)**
- Increase memory in `#BSUB -R "rusage[mem=4GB]"`
- Try 8GB for large k=9 datasets

---

## Step 7: Collect Results

Once the `vmeasure_calculation` job completes:

### Check results on cluster

```bash
# View summary
column -t -s$'\t' ../results/vmeasure_summary.tsv

# Check file exists
ls -lh ../results/
```

### Download results to local machine

From your **local machine**:

```bash
cd ~/Dropbox/mssm_research/loclust/simulations

# Download results
rsync -avz --progress \
    username@cluster.domain.edu:/path/to/loclust/simulations/results/ \
    results/

# Optionally download all clustered files (WARNING: large!)
rsync -avz --progress \
    username@cluster.domain.edu:/path/to/loclust/simulations/data/ \
    data_clustered/
```

---

## Step 8: Analyze Results Locally

Back on your local machine:

```bash
cd ~/Dropbox/mssm_research/loclust/simulations/analysis

# View summary
python -c "
import pandas as pd
df = pd.read_csv('../results/vmeasure_summary.tsv', sep='\t', index_col=0)
print(df)
"

# Generate plots
python plot_results.py  # (if you create this script)
```

---

## Resource Estimates

Based on pilot testing with 16 datasets:

| Resource          | Per Job         | Total (14,700 jobs) |
|-------------------|-----------------|---------------------|
| **Cores**         | 1               | 14,700              |
| **Memory**        | 4 GB            | 58.8 TB (parallel)  |
| **Wall Time**     | 0.5-30 min      | 1-2 hours (if enough cores) |
| **Disk (input)**  | 5 MB/dataset    | 10 GB               |
| **Disk (output)** | 5 MB/result     | 70 GB               |

**With 1,000 cores available:** Jobs complete in 2-3 hours
**With 100 cores available:** Jobs complete in 20-30 hours

---

## Expected Outputs

After all jobs complete:

```
data/
└── {N}_classes/{combo}/noise_{X}/seed_{Y}/
    ├── trajectories.tsv           (input)
    └── clustering/
        ├── gmm_k{N}/
        │   ├── trajectories.clust.tsv     ← Required for v-measure
        │   └── clustering_log.txt
        ├── hierarchical_k{N}/
        │   └── ...
        ├── kml_k{N}/
        │   └── ...
        └── ...                            (7 methods total)

results/
├── vmeasure_scores.tsv      ← 14,700 rows (one per method × dataset)
└── vmeasure_summary.tsv     ← Aggregated by method
```

---

## Quick Reference

### Essential Commands

```bash
# Submit all jobs
bash submit_all_clustering.sh

# Check status
bjobs -sum

# Count completed
find ../data -name "trajectories.clust.tsv" | wc -l  # Should be 14,700

# Kill all your jobs (if needed)
bkill 0

# View results
column -t -s$'\t' ../results/vmeasure_summary.tsv
```

### File Locations

| File/Directory                  | Description                          |
|---------------------------------|--------------------------------------|
| `dataset_index.tsv`             | Job index → dataset mapping          |
| `logs/`                         | Job stdout/stderr logs               |
| `run_loclust_*.sh`              | Generated method-specific scripts    |
| `../data/`                      | Input trajectories                   |
| `../data/.../clustering/`       | Output clustered files               |
| `../results/vmeasure_*.tsv`     | Final metrics                        |

---

## Support

For issues:
1. Check logs in `logs/` directory
2. Verify environment setup (Python/R packages)
3. Test single job locally before submitting array
4. Consult cluster documentation for LSF-specific issues

Documentation:
- Pipeline overview: `../documentation/PIPELINE_VERIFICATION.md`
- LSF scripts: `README.md` (this directory)
