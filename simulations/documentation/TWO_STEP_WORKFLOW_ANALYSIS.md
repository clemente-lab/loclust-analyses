# Two-Step Simulation Workflow Analysis

**Date**: October 8, 2025
**Critical Discovery**: Simulations use a TWO-STEP process

---

## The Two Workflows: Critical Difference

### Path 1: `/home/ewa/cleme/hilary/loclust_simulations/select_sims_testing/`

**STEP 1: Generate Master Pool**
- **File**: `sim1.tsv` (162 MB, 484,000 trajectories)
- **Method**: Single large generation run
- **Structure**:
  - 11 individual functions (NOT combined)
  - 11 noise levels: 0.0, 0.02, 0.04, 0.06, 0.08, 0.1, 0.12, 0.14, 0.16, 0.18, 0.2
  - 20 time points per trajectory
  - ~4,000 trajectories per function-noise combination

**Reconstructed Command**:
```bash
simulate_trajectories.py \
    -N 4000 \                          # 4000 original trajectories per function
    -n 20 \                            # 20 time points
    --rep 1 \                          # 1 replicate (noise added via -s parameter)
    -s "0,0.02,0.04,0.06,0.08,0.1,0.12,0.14,0.16,0.18,0.2" \
    -f "linear,stage,flat,poly,sin,tan,scurve,hyperbolic,exponential,norm,growth" \
    -c 1 \                             # CRITICAL: combine_funcs=1 (individual only!)
    -p "default" \
    -x "0.0" \
    -r 0.0 \
    -e False \
    -do /home/ewa/cleme/hilary/loclust_simulations/select_sims_testing \
    -fo sim1.tsv
```

**STEP 2: Create Function Combination Batches**
- **Script**: `select_simulations_htm.py`
- **Input**: `sim1.tsv` (master pool)
- **Output**: `sims_output/8/6/*.tsv` (organized batches)
- **Method**: Random sampling + selection

**What it does**:
1. Reads master pool (sim1.tsv)
2. Filters to specific noise level (e.g., 0.04)
3. Filters to specific function combination (e.g., exponential + hyperbolic + linear + poly + scurve + sin)
4. Randomly samples trajectories from each function
5. Combines them into a single file
6. Creates multiple replicates (subsample parameter)

**Example output**:
- `0.04noise.exponential-hyperbolic-linear-poly-scurve-sin.200reps.2.tsv`
- Meaning:
  - noise = 0.04
  - 6 functions combined: exponential, hyperbolic, linear, poly, scurve, sin
  - 200 repetitions per function (trajectories sampled)
  - Replicate #2 (different random sample from master pool)

**Output Directory Structure**:
```
sims_output/
├── 8/                    # 8 total functions to choose from
│   ├── 3/                # Combine 3 at a time
│   ├── 6/                # Combine 6 at a time
│   └── 9/                # Combine 9 at a time
```

### Path 2: `/home/ewa/cleme/cooccurrence/lodi_simu_test/`

**Similar Structure**:
- `outputs/11/3/` - 11 functions total, combine 3
- `outputs/11/6/` - 11 functions total, combine 6
- `outputs/11/9/` - 11 functions total, combine 9

**Scripts**:
- `split_simulations.py` - Creates all combinations of N functions
- `select_simulations.py` - Creates specific user-defined combinations

---

## Key Differences from Main `simulate.py` Approach

### Method A: Main loclust repo approach (combine during generation)
**Location**: `/home/ewa/cleme/hilary/repos/loclust/scripts/simulate_trajectories.py`

**Command Example**:
```bash
simulate_trajectories.py \
    -N 200 \
    -n 20 \
    --rep 5 \
    -s "0.04" \
    -f "exponential,hyperbolic,norm" \
    -c 3 \                             # COMBINE during generation!
    -p "default"
```

**What happens**:
- Generates 200 original trajectories
- Each trajectory COMBINES 3 functions (appended or averaged)
- Creates 5 noised replicates of each
- Result: Each trajectory has segments from exponential + hyperbolic + norm

**Function combination**: Done by `combine_functions()` in `simulate.py`
- Splits time points into sections (e.g., 3 functions = 3 sections)
- Uses Y-values from function 1 for points 0-6
- Uses Y-values from function 2 for points 7-13
- Uses Y-values from function 3 for points 14-19
- Optionally adjusts continuity between sections

### Method B: Two-step approach (combine during selection)
**Location**: `/home/ewa/cleme/hilary/loclust_simulations/select_sims_testing/`

**Step 1**: Generate individual functions only (combine_funcs=1)
**Step 2**: Sample different function types and put them in same file

**What happens**:
- Master pool has pure individual function trajectories
- Selection script randomly picks:
  - Some exponential trajectories
  - Some hyperbolic trajectories
  - Some norm trajectories
- Puts them all in one TSV file together
- Each trajectory is PURE (not combined within a trajectory)
- But the FILE contains MIXED function types

**Function combination**: None! Each trajectory is a single pure function.
- The "combination" is just putting different function types in the same file
- For clustering purposes (multiple classes in one dataset)

---

## Critical Reproducibility Differences

### Method A (Main repo - combine during generation):
**Random elements**:
1. Function parameters (slope, intercept, etc.) - random for each trajectory
2. Noise values - random for each replicate
3. Function combination parameters

**To reproduce exactly**: Need random seed for ALL of above

### Method B (Two-step - combine during selection):
**Random elements in Step 1 (master pool generation)**:
1. Function parameters - random for each of 4000 trajectories per function
2. Noise values - random for each noise level

**Random elements in Step 2 (batch selection)**:
1. Which specific trajectories are sampled from master pool
2. Order of trajectories in output file

**To reproduce exactly**:
- Step 1: Need random seed for master pool generation
- Step 2: Need random seed for sampling OR just keep using same master pool

**CRITICAL INSIGHT**:
If you have the original `sim1.tsv` master pool, you can:
- ✅ Reproduce Step 2 exactly (with random seed for sampling)
- ✅ Create NEW combinations from same master pool
- ❌ Cannot reproduce master pool without original random seed

---

## Which Method Is Better?

### Method A (Main repo):
**Pros**:
- Single-step process
- Creates true multi-phase trajectories (growth → plateau → decline)
- Smaller file sizes

**Cons**:
- Must regenerate everything for new combinations
- Can't reuse trajectories across different combination sets

### Method B (Two-step):
**Pros**:
- Flexible: Generate master pool once, sample many times
- Can create many different combination batches from same pool
- Each trajectory is "pure" (good for interpretability)
- Master pool is reusable

**Cons**:
- Requires large storage for master pool (162 MB)
- Two-step process more complex
- Trajectories are NOT actually combined (just mixed in same file)

---

## Current Situation Assessment

### Existing Data:
1. **Master pool exists**: `sim1.tsv` (484,000 trajectories)
2. **Many batches exist**: In `sims_output/` directories
3. **Selection scripts exist**: To create new batches

### Reproducibility Status:
- ⚠️ **Master pool (sim1.tsv)**: Cannot reproduce exactly without seed
- ✅ **Batch files**: Can reproduce IF we have master pool + seed for sampling
- ✅ **New batches**: Can create from existing master pool with ANY combination

### Key Question:
**Do you need to reproduce the master pool, or can you use the existing one?**

**Option 1**: Keep existing `sim1.tsv`
- ✅ Can create any new combination batches
- ✅ Exact reproducibility of batch sampling (with seed)
- ⚠️ Cannot verify master pool creation

**Option 2**: Regenerate master pool
- ⚠️ Will get different random values
- ✅ Full reproducibility going forward (with seed tracking)
- ⚠️ Existing batch files won't match

**Option 3**: Use Method A (main repo approach)
- ✅ Single-step process
- ✅ Full reproducibility (with seed tracking)
- ✅ True combined trajectories (not just mixed files)
- ⚠️ Different from existing data structure

---

## Recommendation

### If existing simulations are scientifically important:
1. **Keep master pool** (`sim1.tsv`) as-is
2. **Archive it** in organized directory structure
3. **Document** its parameters (already done above)
4. **Use it** to create new batches as needed
5. **Add seed tracking** to future batch selection

### If starting fresh:
1. **Use Method A** (main repo approach) with seed tracking
2. **Generate** systematically organized simulations
3. **Document** all parameters and seeds
4. **Create** metadata JSON files for each batch

### The Random Seed=42 Hypothesis:
You mentioned finding seed=42 elsewhere. Let's check if we can find any evidence of seed usage in the existing code or logs.

**Action needed**: Search for:
- Any log files from Feb 2018 (when sim1.tsv was created)
- Any wrapper scripts that might have set seed=42
- Any configuration files with simulation parameters

Would you like me to search for these?

---

**Status**: Workflow understood, two methods documented
**Next**: Decide which approach to use going forward
