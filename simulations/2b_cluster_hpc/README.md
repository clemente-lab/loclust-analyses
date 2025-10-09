# LSF Cluster Scripts for LoClust Simulations

This directory contains LSF job array scripts for running clustering benchmarks on a compute cluster.

## Quick Start

### 1. Generate data locally

```bash
cd ../generation_scripts
python generate_systematic.py --config simulation_config.yaml --yes
```

This creates 2,100 datasets in `../data/`

### 2. Submit all clustering jobs to cluster

```bash
cd ../cluster_scripts
bash submit_all_clustering.sh
```

This will:
- Generate dataset index file
- Submit 7 job arrays (4 LoClust methods + 3 R methods)
- Each array has 2,100 elements (one per dataset)
- Submit v-measure calculation job with dependency on all clustering

**Total: 14,700 clustering jobs + 1 analysis job**

### 3. Monitor progress

```bash
bjobs -w                  # Check job status
bjobs -sum                # Summary by job array
bjobs -u $USER            # All your jobs
ls logs/                  # Check log files
```

### 4. Collect results

Once all jobs complete, results are in:
```
../results/
├── vmeasure_scores.tsv      # All individual results
└── vmeasure_summary.tsv     # Aggregated by method
```

## Advanced Usage

### Submit only LoClust methods

```bash
bash submit_all_clustering.sh --loclust-only
```

### Submit only R methods

```bash
bash submit_all_clustering.sh --r-only
```

### Submit individual method

```bash
# First generate the dataset index
python generate_dataset_index.py

# Then submit specific method
# (Edit the template to replace METHOD with actual method name)
bsub < run_loclust_gmm.sh
```

### Resubmit failed jobs

Find failed jobs and resubmit:
```bash
# Find failed datasets (no output file)
python check_completion.py > failed_datasets.txt

# Resubmit only failed indices
# (You'll need to modify the job array range)
```

## File Structure

```
cluster_scripts/
├── README.md                      # This file
├── submit_all_clustering.sh       # Master submission script
├── generate_dataset_index.py      # Create dataset index file
├── run_loclust_array.sh           # Template for LoClust job arrays
├── run_r_method_array.sh          # Template for R job arrays
├── run_single_r_method.R          # R wrapper for single dataset
├── run_vmeasure.sh                # V-measure calculation job
├── dataset_index.tsv              # Generated: maps indices to datasets
├── logs/                          # Job output logs
│   ├── loclust_gmm_*.{out,err}
│   ├── r_kml_*.{out,err}
│   └── vmeasure_*.{out,err}
└── run_loclust_*.sh               # Generated: method-specific scripts
```

## Job Array Details

### LoClust Methods (Python)

- **Methods:** gmm, hierarchical, kmeans, spectral
- **Array size:** 2,100 (one per dataset)
- **Resources:** 1 core, 4GB RAM, 30 min
- **Queue:** premium

Each job:
1. Reads dataset info from index file using `LSB_JOBINDEX`
2. Runs `cluster_trajectories.py` with fixed k
3. Writes `trajectories.clust.tsv` to clustering output directory

### R Methods

- **Methods:** kml, dtwclust, mfuzz
- **Array size:** 2,100 (one per dataset)
- **Resources:** 1 core, 4GB RAM, 60 min
- **Queue:** premium

Each job:
1. Reads dataset info from index file
2. Calls `run_single_r_method.R` wrapper
3. Writes `trajectories.clust.tsv` to clustering output directory

### V-Measure Calculation

- **Dependency:** Waits for ALL clustering jobs to complete
- **Resources:** 1 core, 8GB RAM, 10 min
- **Queue:** premium

Single job that:
1. Finds all `trajectories.clust.tsv` files
2. Calculates ARI, V-measure, NVI for each
3. Aggregates results by method
4. Writes summary to `results/`

## Configuration

### LSF Parameters

Edit the `#BSUB` headers in template scripts to adjust:
- `-q premium`: Queue (change to your cluster's queue names)
- `-W 0:30`: Wall time (HH:MM)
- `-R "rusage[mem=4GB]"`: Memory request
- `-n 1`: Number of cores

### Cluster-Specific Setup

If your cluster uses environment modules, uncomment these lines:

```bash
# In run_loclust_array.sh
# module load python/3.9

# In run_r_method_array.sh
# module load R/4.2.0
```

## Troubleshooting

### Job fails with "command not found"

Add module loads or activate conda environment:
```bash
# In LSF script before running python/R
module load python/3.9
# OR
source activate loclust_env
```

### R jobs fail with missing packages

Install required packages on cluster:
```R
install.packages(c("kml", "dtwclust", "Mfuzz", "data.table"))
```

### Jobs timeout

Increase wall time in `#BSUB -W` directive:
- LoClust methods: Usually < 5 min per dataset
- KML: ~2-5 sec per dataset
- DTWclust: 2-40 sec depending on k
- Mfuzz: < 1 sec per dataset

### Check completion status

```bash
# Count successful outputs
find ../data -name "trajectories.clust.tsv" -path "*/gmm_k*" | wc -l

# Expected: 2100 per method
```

## Performance Estimates

Based on pilot testing:

| Method       | Time/Dataset | Total Time (2100 datasets) |
|--------------|--------------|----------------------------|
| GMM          | ~5 min       | ~1 hour (parallel)         |
| Hierarchical | ~5 min       | ~1 hour (parallel)         |
| K-means      | ~3 min       | ~1 hour (parallel)         |
| Spectral     | ~5 min       | ~1 hour (parallel)         |
| KML          | ~2-5 sec     | ~10 min (parallel)         |
| DTWclust     | ~2-40 sec    | ~30 min (parallel)         |
| Mfuzz        | ~0.1 sec     | ~5 min (parallel)          |

**With 2,100 cores available:** All jobs complete in ~1-2 hours

**With limited cores (e.g., 100):** Jobs complete in ~10-20 hours

## Contact

For issues or questions, contact the LoClust team or check documentation:
- Main docs: `../documentation/`
- Pipeline verification: `../documentation/PIPELINE_VERIFICATION.md`
