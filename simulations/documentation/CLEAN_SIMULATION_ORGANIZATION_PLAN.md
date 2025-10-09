# Clean Simulation Organization Plan

**Date**: October 8, 2025
**Approach**: Option A (Main repo method with combine_funcs during generation)
**Priority**: CLEAN, ORGANIZED, REPRODUCIBLE

---

## Design Principles

### 1. **Self-Documenting Structure**
- Directory names indicate parameters
- No cryptic abbreviations
- Metadata files for every batch

### 2. **Full Reproducibility**
- Every simulation has a random seed
- Complete parameter recording
- Version-controlled generation scripts

### 3. **Single Source of Truth**
- All simulation code in ONE location
- No scattered scripts
- Clear execution workflow

### 4. **Organized Output**
- Hierarchical directory structure
- Consistent naming conventions
- Easy to navigate and analyze

---

## Proposed Directory Structure

```
loclust/
├── simulations/                          # All simulation-related code and data
│   │
│   ├── generation_scripts/               # Simulation generation code
│   │   ├── generate_systematic.py        # Main generation script
│   │   ├── simulation_config.yaml        # Master configuration
│   │   └── README.md                     # Usage documentation
│   │
│   ├── data/                             # Generated simulation data
│   │   ├── 3_functions/                  # Group by number of functions
│   │   │   ├── exponential-hyperbolic-norm/
│   │   │   │   ├── noise_0.00/
│   │   │   │   │   ├── seed_001/         # Separate directory per seed
│   │   │   │   │   │   ├── trajectories.tsv
│   │   │   │   │   │   ├── metadata.json
│   │   │   │   │   │   └── generation_log.txt
│   │   │   │   │   ├── seed_002/
│   │   │   │   │   └── ...
│   │   │   │   ├── noise_0.04/
│   │   │   │   │   ├── seed_001/
│   │   │   │   │   └── ...
│   │   │   │   └── noise_0.08/
│   │   │   │       └── ...
│   │   │   ├── exponential-linear-sin/
│   │   │   └── ...
│   │   ├── 6_functions/
│   │   └── 9_functions/
│   │
│   ├── analysis/                         # Analysis of simulations
│   │   ├── clustering_results/
│   │   ├── validation_metrics/
│   │   └── comparative_analysis/
│   │
│   ├── documentation/                    # Simulation documentation
│   │   ├── parameter_inventory.md       # All parameters used
│   │   ├── generation_workflow.md       # How to generate
│   │   └── analysis_guide.md            # How to analyze
│   │
│   └── legacy/                           # Archive of old disorganized data
│       ├── README_LEGACY.md             # Explanation of legacy data
│       └── archived_simulations/        # Old data (read-only)
│
└── ... (rest of loclust repo)
```

---

## Naming Conventions

### Function Combination Names
- **Format**: `function1-function2-function3` (alphabetically sorted)
- **Examples**:
  - `exponential-hyperbolic-norm`
  - `exponential-growth-linear-poly-scurve-sin`

### Noise Level Directories
- **Format**: `noise_X.XX` (zero-padded to 2 decimal places)
- **Examples**: `noise_0.00`, `noise_0.04`, `noise_0.20`

### Seed Directories
- **Format**: `seed_XXX` (zero-padded to 3 digits)
- **Examples**: `seed_001`, `seed_042`, `seed_100`

### Trajectory Files
- **Name**: Always `trajectories.tsv` (consistent across all batches)
- **Location**: Within seed directory

---

## Metadata Format

### `metadata.json` (per seed directory)

```json
{
  "generation": {
    "date": "2025-10-08T15:30:00",
    "script": "generate_systematic.py",
    "script_version": "1.0.0",
    "loclust_version": "0.2.0"
  },
  "parameters": {
    "num_trajectories": 200,
    "num_points": 20,
    "num_functions": 3,
    "functions": ["exponential", "hyperbolic", "norm"],
    "combine_funcs": 3,
    "combination_method": "append",
    "noise_level_y": 0.04,
    "noise_level_x": 0.0,
    "rep": 5,
    "percent_remove": 0.0,
    "end": false
  },
  "randomization": {
    "python_seed": 42,
    "numpy_seed": 42,
    "function_params": "default"
  },
  "output": {
    "file": "trajectories.tsv",
    "num_trajectories_generated": 1000,
    "file_size_bytes": 1234567,
    "md5_checksum": "a1b2c3d4e5f6..."
  },
  "provenance": {
    "command": "python generate_systematic.py --config simulation_config.yaml --seed 42",
    "working_directory": "/home/ewa/Dropbox/mssm_research/loclust",
    "hostname": "compute-node-01",
    "user": "ewa"
  }
}
```

---

## Configuration File

### `simulation_config.yaml`

```yaml
# Master Simulation Configuration
# Used by generate_systematic.py

simulation_batches:
  - name: "3_function_combinations"
    description: "Systematic 3-function combinations"
    num_functions: 3
    combinations:
      - [exponential, hyperbolic, norm]
      - [exponential, linear, sin]
      - [growth, hyperbolic, norm]
      - [exponential, growth, linear]
      # ... more combinations

  - name: "6_function_combinations"
    description: "Systematic 6-function combinations"
    num_functions: 6
    combinations:
      - [exponential, growth, linear, norm, poly, scurve]
      - [exponential, hyperbolic, linear, poly, scurve, sin]
      # ... more combinations

common_parameters:
  num_trajectories: 200        # Trajectories per batch
  num_points: 20               # Time points per trajectory
  rep: 5                       # Replicates per noise level
  combination_method: "append" # How to combine functions
  percent_remove: 0.0          # No time point removal
  end: false
  x_noise: 0.0                 # No X-axis noise

noise_levels:
  y_axis: [0.0, 0.04, 0.08, 0.12, 0.16, 0.20]

seeds:
  start: 1
  num_replicates: 10          # Generate 10 seeds per condition
  # Generates seeds: 1, 2, 3, ..., 10

function_parameters:
  mode: "default"             # Use default random parameter ranges
  # Could specify custom ranges here if needed

output:
  base_directory: "simulations/data"
  organize_by: "num_functions" # Primary organization
  include_metadata: true
  include_logs: true
  compute_checksums: true
```

---

## Generation Script

### `generate_systematic.py` (Enhanced)

**Key Features**:
1. **Reads YAML configuration**
2. **Sets seeds explicitly**
3. **Generates metadata automatically**
4. **Creates organized directory structure**
5. **Logs all operations**
6. **Computes checksums for verification**

**Usage**:
```bash
# Generate all simulations from config
python simulations/generation_scripts/generate_systematic.py \
    --config simulations/generation_scripts/simulation_config.yaml

# Generate specific batch only
python simulations/generation_scripts/generate_systematic.py \
    --config simulation_config.yaml \
    --batch "3_function_combinations"

# Generate with custom seeds
python simulations/generation_scripts/generate_systematic.py \
    --config simulation_config.yaml \
    --seed-start 100 \
    --seed-count 5
```

---

## Enhanced simulate_trajectories.py

**Add seed parameter** to main loclust repo:

```python
# In /home/ewa/cleme/hilary/repos/loclust/scripts/simulate_trajectories.py

@click.option(
    "--seed",
    required=False,
    type=int,
    default=None,
    help="Random seed for reproducibility"
)
def run_simu(..., seed, ...):
    """Runs the library function simu, then writes trajectories"""

    # Set seeds if provided
    if seed is not None:
        from random import seed as set_random_seed
        import numpy as np
        set_random_seed(seed)
        np.random.seed(seed)

    # ... rest of function
```

**This modification should be made to the original loclust repo.**

---

## Execution Workflow

### Phase 1: Setup
```bash
cd /home/ewa/Dropbox/mssm_research/loclust

# Create directory structure
mkdir -p simulations/{generation_scripts,data,analysis,documentation,legacy}

# Create configuration file
# (edit simulation_config.yaml with desired parameters)

# Enhance simulate_trajectories.py with seed parameter
# (modify /home/ewa/cleme/hilary/repos/loclust/scripts/simulate_trajectories.py)
```

### Phase 2: Generation
```bash
# Generate all systematic simulations
python simulations/generation_scripts/generate_systematic.py \
    --config simulations/generation_scripts/simulation_config.yaml \
    --output-dir simulations/data
```

### Phase 3: Verification
```bash
# Verify checksums
python simulations/generation_scripts/verify_simulations.py \
    --data-dir simulations/data

# Generate inventory report
python simulations/generation_scripts/create_inventory.py \
    --data-dir simulations/data \
    --output simulations/documentation/parameter_inventory.md
```

### Phase 4: Archive Legacy Data
```bash
# Document legacy data
# Copy (don't move) important legacy simulations to archive
# Update README_LEGACY.md with provenance information
```

---

## Benefits of This Organization

### ✅ Reproducibility
- Every simulation has documented seed
- Complete parameter recording
- Checksums for verification
- Version-controlled generation code

### ✅ Navigability
- Hierarchical structure
- Self-documenting names
- Consistent conventions
- Clear separation of concerns

### ✅ Maintainability
- Single generation script
- Centralized configuration
- Comprehensive metadata
- Clear documentation

### ✅ Extensibility
- Easy to add new function combinations
- Easy to add new noise levels
- Easy to add new parameter sets
- Configuration-driven (no code changes)

### ✅ Collaboration-Friendly
- Clear README files
- Complete provenance
- Standardized format
- Version control ready

---

## Migration from Current State

### Step 1: Archive Legacy Data
```bash
# Create legacy archive
mkdir -p simulations/legacy/archived_simulations

# Document what's being archived
cat > simulations/legacy/README_LEGACY.md << 'EOF'
# Legacy Simulation Data Archive

This directory contains the original disorganized simulation data
from the two-step workflow (master pool + selection).

**Original locations**:
- `/home/ewa/cleme/hilary/loclust_simulations/select_sims_testing/`
- `/home/ewa/cleme/cooccurrence/lodi_simu_test/`

**Data characteristics**:
- Method: Two-step (master pool + random sampling)
- Random seeds: Unknown/not tracked
- Organization: By function count and subsample number
- Total files: ~thousands

**Important files**:
- `sim1.tsv` - Master pool (484,000 trajectories)
- Various `sims_output/` batches

**Note**: This data is kept for reference only.
All new simulations use the systematic organized approach.
EOF
```

### Step 2: Extract Key Information
```bash
# Run analysis scripts to document what exists
cd /home/ewa/Dropbox/mssm_research/loclust/simulations

python analyze_existing_simulations.py \
    /home/ewa/cleme/hilary/loclust_simulations \
    > legacy_analysis.json

python extract_simulation_parameters.py \
    /home/ewa/cleme/hilary/loclust_simulations \
    > legacy_parameters.json
```

### Step 3: Identify Critical Simulations
Review analysis results and identify:
- Which parameter combinations are scientifically important?
- Which noise levels are needed?
- How many replicates are required?

### Step 4: Generate Clean Simulations
Based on Step 3, update `simulation_config.yaml` and run generation.

---

## Implementation Checklist

### Code Modifications
- [ ] Add `--seed` parameter to `simulate_trajectories.py` (in main loclust repo)
- [ ] Create `generate_systematic.py`
- [ ] Create `verify_simulations.py`
- [ ] Create `create_inventory.py`

### Configuration
- [ ] Create `simulation_config.yaml` with all desired parameter combinations
- [ ] Define noise levels
- [ ] Define seed ranges

### Documentation
- [ ] Create README files for each directory
- [ ] Document generation workflow
- [ ] Document analysis procedures
- [ ] Create parameter inventory

### Execution
- [ ] Run legacy data analysis
- [ ] Archive legacy data with documentation
- [ ] Generate new organized simulations
- [ ] Verify checksums
- [ ] Create inventory report

### Version Control
- [ ] Commit generation scripts
- [ ] Commit configuration files
- [ ] Commit documentation
- [ ] Tag release version (e.g., `simulations-v1.0`)

---

## Timeline Estimate

- **Code modifications**: 2-3 hours
- **Configuration creation**: 1 hour
- **Legacy data analysis**: 30 min
- **Documentation**: 1 hour
- **Generation execution**: Varies (depends on number of batches)
  - ~1-2 minutes per seed/noise/function combination
  - For 100 combinations: ~2-3 hours
- **Verification**: 30 min

**Total**: ~5-7 hours + generation time

---

## Questions to Resolve Before Implementation

1. **Which function combinations do you want?**
   - All possible combinations of 3 functions?
   - Specific combinations only?
   - Include 6 and 9 function combinations?

2. **How many seeds per condition?**
   - 10 replicates? 20?

3. **Which noise levels?**
   - Keep 0.0, 0.04, 0.08, 0.12, 0.16, 0.20?
   - Add more granular levels?

4. **Number of trajectories per batch?**
   - 200 (current)? More? Less?

5. **Should we enhance the main loclust repo or keep modifications in this repo only?**
   - Option A: Modify `/home/ewa/cleme/hilary/repos/loclust/` (benefits everyone)
   - Option B: Create wrapper in this repo only

---

## Recommendation

**Start with a PILOT**:
1. Choose 2-3 function combinations
2. 2 noise levels (0.0, 0.04)
3. 3 seeds
4. Generate ~6 batches
5. Verify organization works well
6. Then scale up to full systematic generation

This allows testing the workflow before committing to generating hundreds of simulation batches.

---

**Ready to proceed?** Let me know:
1. Which function combinations to include
2. Seed range and count
3. Whether to modify main loclust repo or create wrapper
4. If you want to start with pilot or go full-scale

I can then create all the necessary scripts and configurations.
