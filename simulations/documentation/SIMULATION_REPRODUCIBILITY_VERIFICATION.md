# Simulation Reproducibility Verification Report

**Date**: October 8, 2025
**Purpose**: Verify exact reproducibility of existing simulations
**Status**: ⚠️ **PARTIAL REPRODUCIBILITY** - See Critical Findings

---

## Executive Summary

### ✅ What We CAN Reproduce Exactly:
1. **Trajectory shapes and mathematical functions** - Deterministic
2. **Parameter combinations** (function types, noise levels, num_trajectories, etc.)
3. **TSV file format and structure** - Well-documented

### ⚠️ What We CANNOT Reproduce Exactly:
1. **Random noise values** - No random seed tracking in original simulations
2. **Exact numeric values** - Random number generator state not preserved

### ✅ Analysis Scripts Safety:
- Both scripts are **READ-ONLY** and safe to run
- No data modification or deletion
- Generate JSON/YAML reports only

---

## 1. SIMULATION CODE LOCATIONS

### Primary Simulation Code (THE SOURCE OF TRUTH)
**Location**: `/home/ewa/cleme/hilary/repos/loclust/`

**Files**:
1. **`loclust/simulate.py`** (680 lines)
   - Core library module with `simu()` function
   - 11 trajectory shape functions:
     - linear, stage, flat, polynomial, sin, tan
     - S_curve, hyperbolic, exponential, norm, growth
   - Noise addition: `np.random.normal(0, noise_level, len(values))`
   - Function combination methods (append or average)

2. **`scripts/simulate_trajectories.py`** (110 lines)
   - CLI wrapper using Click
   - Calls `simu()` from library
   - Writes TSV output using `write_trajectories()`

### Secondary Paths (OLD UTILITY SCRIPTS - NOT SIMULATION GENERATORS)
**Path 1**: `/home/ewa/cleme/hilary/loclust_simulations/select_sims_testing/`
- Contains: `select_simulations_htm.py`
- Purpose: FILTER/SELECT from already-generated simulations
- Does NOT generate new simulations

**Path 2**: `/home/ewa/cleme/cooccurrence/lodi_simu_test/scripts/`
- Contains: `select_simulations.py`, `split_simulations.py`, etc.
- Purpose: POST-PROCESSING of existing simulations
- Does NOT generate new simulations

---

## 2. TSV FILE FORMAT VERIFICATION

### Format (VERIFIED from actual files):
```
ID	X	Y	func	noise	original_trajectory
99237	0,1,2,3,...,19	281.49,253.49,...,133.35	exponential	0.04	88000
```

### Column Details:
- **ID**: Trajectory identifier (integer)
- **X**: Comma-separated time points (with noise if x_noise > 0)
- **Y**: Comma-separated abundance values (with noise)
- **func**: Function name or combination (e.g., "exponential-hyperbolic-norm")
- **noise**: Y-axis noise level applied (float)
- **original_trajectory**: ID of the noiseless parent trajectory

### Sample File Analysis:
**File**: `0.04noise.exponential-hyperbolic-linear-poly-scurve-sin.200reps.2.tsv`
- Number of functions: 6 (combined via append method)
- Noise level: 0.04
- Replicate: 2
- Number of repetitions: 200
- Time points: 20

**Format Matches Documentation**: ✅ VERIFIED

---

## 3. SIMULATION PARAMETER EXTRACTION

### Parameters Encoded in `simu()` Function:

#### Required Parameters:
1. **num_traj** (`-N`): Number of original (noiseless) trajectories per function
2. **num_points** (`-n`): Number of time points per trajectory
3. **noise_lev** (`-s`): Comma-separated Y-axis noise levels (e.g., "0.0,0.04,0.08")
4. **funcs** (`-f`): Comma-separated function list (e.g., "exponential,hyperbolic,norm")
5. **rep**: Number of noised replicates per original trajectory per noise level
6. **combine_funcs** (`-c`): Number of functions to combine per trajectory
7. **params** (`-p`): "default" or custom parameters
8. **percent_remove** (`-r`): Fraction of time points to remove (0.0 to 1.0)
9. **end** (`-e`): Remove from end (True) or randomly (False)
10. **x_noise** (`-x`): Comma-separated X-axis noise levels

#### Default Parameters (from `simulate.py`):
Each function has a `*_params()` function that generates random parameters:

**Example - Exponential function**:
```python
def exponential_params(min_a=-100, max_a=100, min_b=1.5, max_b=10,
                      min_delay=0, max_delay=5):
    return {
        'a': uniform(min_a, max_a),      # Random from uniform distribution
        'b': uniform(min_b, max_b),       # Random from uniform distribution
        'delay': randint(min_delay, max_delay)  # Random integer
    }
```

**All 11 functions use randomized parameters when params="default"**

---

## 4. CRITICAL REPRODUCIBILITY ISSUE

### ⚠️ Random Seed Not Tracked

**Problem**: The simulation code uses Python's `random` module and NumPy's random number generator, but:

1. **No explicit seed setting** in `simulate_trajectories.py`
2. **No seed parameter** in CLI arguments
3. **No seed recording** in output metadata

**Code Analysis**:
```python
# loclust/simulate.py line 7
from random import uniform, seed, randint

# seed() function is imported but NEVER CALLED in the code
# This means random state is initialized from system time/entropy
```

**Impact on Reproducibility**:
- ✅ Can reproduce **function shapes and parameter ranges**
- ✅ Can reproduce **number of trajectories and time points**
- ✅ Can reproduce **noise levels and function combinations**
- ❌ **CANNOT** reproduce exact numeric values in Y columns
- ❌ **CANNOT** reproduce exact noise added to trajectories
- ❌ **CANNOT** reproduce exact parameter values drawn from random ranges

### What This Means:
If we regenerate simulations with the same parameters, we will get:
- ✅ Same number of trajectories
- ✅ Same function types and combinations
- ✅ Same general shape families
- ❌ Different exact Y-values (different random draws)
- ❌ Different exact noise patterns
- ❌ Different exact parameter values (slope, intercept, etc.)

**Recommendation**:
- Run analysis scripts to extract ALL parameters from existing files
- Decide if we need exact reproduction (copy existing data) or
- Accept new random draws (regenerate with extracted parameters)

---

## 5. ANALYSIS SCRIPT VERIFICATION

### Script 1: `analyze_existing_simulations.py`

**Purpose**: Scan directory structure and categorize files

**What it does**:
1. Scans `/home/ewa/cleme/hilary/loclust_simulations` directory
2. Matches directory names against 4 regex patterns
3. Extracts function combinations, noise levels, sigma values
4. Finds trajectory TSV files
5. Reads sample TSV files (first 10 by default)
6. Generates JSON report

**Data Safety**: ✅ READ-ONLY
- Uses `Path.iterdir()` to list directories
- Uses `open(file, 'r')` for reading only
- NO file writes to simulation directory
- Writes report ONLY to current working directory

**Output**: `simulation_analysis_report.json` (local directory)

### Script 2: `extract_simulation_parameters.py`

**Purpose**: Read TSV files to extract exact simulation parameters

**What it does**:
1. Recursively finds all .tsv files in simulation directory
2. Parses each TSV file to extract:
   - Number of trajectories
   - Number of time points
   - Function names (from 'func' column)
   - Noise levels (from 'noise' column)
   - Original trajectory IDs
3. Groups files by unique parameter combinations
4. Generates YAML configuration template

**Data Safety**: ✅ READ-ONLY
- Uses `Path.rglob('*.tsv')` to find files
- Opens files with `open(path, 'r')` for reading
- NO file writes to simulation directory
- Writes reports ONLY to current working directory

**Outputs**:
- `extracted_parameters.json` (detailed results)
- `simulation_config_template.yaml` (YAML config for regeneration)

### Both Scripts: Safety Confirmed ✅

**No operations that modify simulation data**:
- ❌ No file deletion
- ❌ No file modification
- ❌ No file moving/renaming
- ❌ No writes to simulation directory
- ✅ Only reads and local report generation

---

## 6. EXACT COMMAND NEEDED TO REPRODUCE

### IF we had the random seed:
```bash
python scripts/simulate_trajectories.py \
    -N 200 \                           # 200 original trajectories
    -n 20 \                            # 20 time points
    --rep 5 \                          # 5 replicates per noise level
    -s "0.04" \                        # Noise level
    -x "0.0" \                         # No X-axis noise
    -f "exponential,hyperbolic,linear,poly,scurve,sin" \
    -c 6 \                             # Combine all 6 functions
    -p "default" \                     # Use random parameters
    -r 0.0 \                           # Don't remove time points
    -e False \                         # N/A
    -do output_dir \
    -fo output_filename.tsv
```

### WITHOUT random seed (current situation):
We can use the same command but will get **different random values**.

---

## 7. RECOMMENDED WORKFLOW

### Option A: Extract and Document Existing Simulations
**Best if**: You need to understand what exists but don't need exact reproduction

1. ✅ Run `analyze_existing_simulations.py`
2. ✅ Run `extract_simulation_parameters.py`
3. ✅ Review JSON reports to understand parameter space
4. Document which simulations are scientifically important
5. **Keep existing data as-is** for reproducibility

### Option B: Regenerate Fresh Simulations (Recommended)
**Best if**: You want clean, organized, well-documented new simulations

1. ✅ Run analysis scripts to understand parameter space
2. Design organized directory structure (already documented in `proposed_directory_structure.md`)
3. Create systematic generation script with:
   - **EXPLICIT random seed setting** for reproducibility
   - Metadata JSON files recording all parameters + seed
   - Organized directory hierarchy
   - Version control of generation scripts
4. Generate new simulation batches systematically
5. Archive old disorganized data (read-only)

### Option C: Hybrid Approach
1. Run analysis scripts on existing data
2. Identify scientifically critical simulation batches
3. **Copy** (don't regenerate) critical batches to organized structure
4. Regenerate non-critical simulations with proper seed tracking
5. Document provenance (which are original, which are regenerated)

---

## 8. CONCLUSIONS

### ✅ Verified Facts:
1. **Simulation code is at**: `/home/ewa/cleme/hilary/repos/loclust/loclust/simulate.py`
2. **CLI wrapper is at**: `/home/ewa/cleme/hilary/repos/loclust/scripts/simulate_trajectories.py`
3. **TSV format is well-defined** and consistent
4. **Analysis scripts are READ-ONLY** and safe to run
5. **Two paths in paths.txt** are old utility scripts, not simulation generators

### ⚠️ Reproducibility Limitations:
1. **Random seeds NOT tracked** in original simulations
2. **Exact numeric values CANNOT be reproduced** without seeds
3. **Parameter ranges and function types CAN be reproduced**
4. **Statistical properties will be similar** but not identical

### 📋 Safe to Proceed:
- ✅ Running `analyze_existing_simulations.py` is SAFE
- ✅ Running `extract_simulation_parameters.py` is SAFE
- ✅ Both scripts only READ data, no modifications
- ✅ Reports written to local directory only

### 🎯 Recommendation:
**Run the analysis scripts NOW** to understand the existing parameter space, then make an informed decision about:
- Copying vs regenerating simulations
- Which parameters to use going forward
- How to organize the new simulation structure

The analysis scripts will give you complete visibility into what exists without any risk to the data.

---

## APPENDIX A: Random Seed Fix for Future Simulations

To ensure exact reproducibility in future, modify `simulate_trajectories.py`:

```python
# Add to imports
import numpy as np
from random import seed

# Add CLI option
@click.option(
    "--seed",
    required=False,
    type=int,
    default=None,
    help="Random seed for reproducibility"
)

# In run_simu() function, before calling simu():
def run_simu(..., seed_val, ...):
    if seed_val is not None:
        seed(seed_val)          # Set Python random seed
        np.random.seed(seed_val) # Set NumPy random seed

    # ... rest of function
```

This would allow commands like:
```bash
simulate_trajectories.py ... --seed 42
```

And enable EXACT reproduction of all random values.

---

**Report prepared for**: Session 2025-10-08
**Verified by**: Claude Code analysis of simulation source code
**Status**: Ready for user review and decision on next steps
