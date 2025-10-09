# LoClust Simulations

**Clean, organized, reproducible trajectory simulations for LoClust testing and validation.**

---

## Directory Structure

```
simulations/
├── README.md                    # This file
├── generation_scripts/          # Simulation generation code
│   ├── generate_systematic.py   # Main generation script
│   ├── simulation_config.yaml   # Master configuration
│   ├── verify_simulations.py    # Verification tools
│   └── README.md               # Generation documentation
├── data/                        # Generated simulation data
│   ├── 3_functions/
│   ├── 6_functions/
│   └── 9_functions/
├── analysis/                    # Analysis results
│   ├── clustering_results/
│   └── validation_metrics/
├── documentation/               # Technical documentation
│   ├── REPRODUCIBILITY_VERIFIED.md
│   ├── CLEAN_SIMULATION_ORGANIZATION_PLAN.md
│   └── ...
└── legacy/                      # Archive of old work
    ├── seed_test/              # Reproducibility tests
    └── README_LEGACY.md        # Legacy data documentation
```

---

## Quick Start

### Generate Simulations

```bash
cd /home/ewa/Dropbox/mssm_research/loclust/simulations

# Generate all simulations from config
python generation_scripts/generate_systematic.py \
    --config generation_scripts/simulation_config.yaml

# Or generate specific batch
python generation_scripts/generate_systematic.py \
    --config generation_scripts/simulation_config.yaml \
    --batch "3_function_combinations"
```

### Verify Simulations

```bash
# Verify checksums and metadata
python generation_scripts/verify_simulations.py --data-dir data/
```

### Analyze Simulations

```bash
# Run clustering analysis
cd analysis/
# ... analysis scripts here
```

---

## Key Principles

### ✅ Reproducibility
- Every simulation has a documented random seed
- Complete parameter metadata in JSON
- MD5 checksums for verification

### ✅ Organization
- Hierarchical structure: functions → noise → seeds
- Self-documenting directory names
- Consistent naming conventions

### ✅ Clean Code
- Single source of truth for generation
- Configuration-driven (no hardcoded parameters)
- Comprehensive documentation

---

## Simulation Output Format

Each simulation batch contains:

```
data/3_functions/exponential-hyperbolic-norm/noise_0.04/seed_042/
├── trajectories.tsv        # Trajectory data
├── metadata.json           # Complete parameters + provenance
└── generation_log.txt      # Execution log
```

**File Format** (`trajectories.tsv`):
```
ID	X	Y	func	noise	original_trajectory
0	0,1,2,...,19	0.85,0.41,...,11.51	exponential-hyperbolic-norm	0.04	0
```

---

## Configuration

All simulation parameters are defined in:
**`generation_scripts/simulation_config.yaml`**

Edit this file to:
- Add/remove function combinations
- Change noise levels
- Adjust number of trajectories
- Set seed ranges

---

## Documentation

See `documentation/` for:
- **REPRODUCIBILITY_VERIFIED.md** - Proof that seeding works
- **CLEAN_SIMULATION_ORGANIZATION_PLAN.md** - Detailed organization plan
- **TWO_STEP_WORKFLOW_ANALYSIS.md** - Legacy workflow documentation

---

## Legacy Data

Old disorganized simulation data is archived in `legacy/` with documentation explaining its structure and provenance.

**Do not use legacy data for new analyses** - regenerate with the clean organized approach.

---

## Contact

Hilary Monaco - htm24@cornell.edu

---

**Status**: Clean organization implemented ✅
**Last Updated**: October 8, 2025
