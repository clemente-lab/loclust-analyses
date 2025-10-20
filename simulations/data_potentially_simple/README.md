# loclust_tool_comp Data - Copied for Re-analysis

**Date Copied:** 2025-10-14
**Source:** `/sc/arion/projects/clemej05a/hilary/loclust_tool_comp/input_trajs/`
**Destination:** `/home/ewa/mnt/loclust/simulations/data_loclust_tool_comp/`
**Size:** 468M

## Purpose

This data was copied to re-run all clustering methods (including R methods like kml, hierarchical, kmeans, etc.) on the loclust_tool_comp dataset, which contains **200 unique trajectories per function class** (proper diverse data).

## Data Characteristics

- **Unique trajectories per class:** 200 ✓ (Verified in DATA_COMPARISON_FINDINGS.md)
- **Total datasets:**
  - 3-class: 1,200 files
  - 6-class: 480 files
  - 9-class: 60 files
- **Noise levels:** 0.0, 0.04, 0.08, 0.12, 0.16, 0.2
- **Replicates per combination:** 10 (seeds 0-9)

## Directory Structure

```
data_loclust_tool_comp/
└── input_trajs/
    └── 8/
        ├── 3/    # 3-class datasets
        ├── 6/    # 6-class datasets
        ├── 9/    # 9-class datasets
        └── sample/
```

### File Naming Convention

```
{noise}noise.{function_combination}.200reps.{replicate_num}.tsv
```

Examples:
- `0.0noise.exponential-hyperbolic-norm.200reps.0.tsv`
- `0.04noise.exponential-growth-linear-norm-poly-scurve.200reps.5.tsv`

### 3-Class Combinations (1,200 files)

**20 function combinations × 6 noise levels × 10 replicates**

Example combinations:
- exponential-hyperbolic-norm
- exponential-hyperbolic-sin
- exponential-norm-tan
- [... 17 more combinations]

### 6-Class Combinations (480 files)

**8 function combinations × 6 noise levels × 10 replicates**

Combinations:
1. exponential-growth-linear-norm-poly-scurve
2. exponential-growth-linear-norm-poly-tan
3. exponential-growth-linear-poly-scurve-sin
4. exponential-growth-linear-poly-sin-tan
5. exponential-hyperbolic-linear-norm-poly-scurve
6. exponential-hyperbolic-linear-norm-poly-tan
7. exponential-hyperbolic-linear-poly-scurve-sin
8. exponential-hyperbolic-linear-poly-sin-tan

### 9-Class Combinations (60 files)

**1 function combination × 6 noise levels × 10 replicates**

Combination:
- exponential-growth-hyperbolic-linear-norm-poly-scurve-sin-tan

## File Format

TSV format with columns:
```
ID  X  Y  func  noise  original_trajectory
```

- **ID:** Trajectory identifier
- **X:** Comma-separated time points (0,1,2,...,19)
- **Y:** Comma-separated Y values (20 points)
- **func:** Function type (exponential, growth, hyperbolic, linear, norm, poly, scurve, sin, tan)
- **noise:** Noise level (0.0, 0.04, 0.08, 0.12, 0.16, 0.2)
- **original_trajectory:** Original trajectory ID

Each file contains:
- 3-class: 600 trajectories (200 per function × 3 functions)
- 6-class: 1,200 trajectories (200 per function × 6 functions)
- 9-class: 1,800 trajectories (200 per function × 9 functions)

## Differences from Current Data Structure

### Current data (`./data/`):
```
data/
├── 3_classes/
│   └── {function_combination}/
│       └── noise_{noise_level}/
│           └── seed_{seed_num}/
│               ├── trajectories.tsv
│               └── metadata.json
├── 6_classes/
└── 9_classes/
```

### loclust_tool_comp data (this directory):
```
data_loclust_tool_comp/
└── input_trajs/
    └── 8/
        ├── 3/
        │   └── {noise}noise.{functions}.200reps.{replicate}.tsv
        ├── 6/
        └── 9/
```

## Key Differences

| Aspect | Current Data | loclust_tool_comp Data |
|--------|-------------|------------------------|
| **Structure** | Nested directories by class/combo/noise/seed | Flat directory per class count |
| **File naming** | `trajectories.tsv` (inside seed folder) | `{noise}noise.{combo}.200reps.{rep}.tsv` |
| **Metadata** | Separate `metadata.json` files | Embedded in filename |
| **Seed naming** | `seed_001`, `seed_002`, etc. | Replicate numbers: 0, 1, 2, ... 9 |
| **Directory depth** | 4 levels deep | 2 levels deep |
| **Class count label** | `3_classes`, `6_classes`, `9_classes` | Single digit: `3`, `6`, `9` |
| **Number format** | Noise: `noise_0.00`, `noise_0.04` | Noise: `0.0noise`, `0.04noise` |

## Pipeline Adaptation Required

To run the current clustering pipeline on this data, we'll need to:

1. **Option A - Restructure the data:** Convert flat structure to nested structure matching current format
2. **Option B - Adapt the pipeline:** Modify scripts to handle flat file structure
3. **Option C - Create mapping/adapter:** Write a script to present flat structure as nested to pipeline

Recommendation: **Option B or C** - Keep original data structure and adapt pipeline reading logic.

## Next Steps

1. Examine current pipeline scripts (in `2a_cluster_local/` and `2b_cluster_hpc/`)
2. Identify file discovery and loading logic
3. Determine best adaptation strategy
4. Implement changes to support flat file structure
5. Run all clustering methods on this dataset
6. Compare results with:
   - Current data results (proper diverse data)
   - Old loclust_tool_comp_dev results (duplicate data)

## Verification

```bash
# Verify copy integrity
du -sh data_loclust_tool_comp/input_trajs/
# Expected: 468M

# Count files
ls data_loclust_tool_comp/input_trajs/8/3/ | wc -l  # Expected: 1200
ls data_loclust_tool_comp/input_trajs/8/6/ | wc -l  # Expected: 480
ls data_loclust_tool_comp/input_trajs/8/9/ | wc -l  # Expected: 60

# Verify data quality (should show 200 unique per function)
tail -n +2 data_loclust_tool_comp/input_trajs/8/6/0.0noise.exponential-growth-linear-norm-poly-scurve.200reps.0.tsv | grep exponential | cut -f3 | sort -u | wc -l
# Expected: 200
```

## Safety Notes

✓ **No overwrites:** Data copied to new directory `data_loclust_tool_comp/`
✓ **Original preserved:** Source data at `/sc/arion/...` remains untouched
✓ **Current data safe:** Existing `./data/` directory unmodified
