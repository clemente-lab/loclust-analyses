# Proposed Organized Directory Structure for Loclust Simulations

## Overview
This document outlines a clean, systematic directory structure for organizing simulated trajectory data.

## Directory Hierarchy

```
simulations/
├── config/
│   ├── simulation_parameters.yaml    # Master configuration file
│   └── function_definitions.yaml     # Function parameter ranges
│
├── data/
│   ├── raw/                          # Raw simulated trajectories
│   │   ├── 3_functions/
│   │   │   ├── exponential-hyperbolic-norm/
│   │   │   │   ├── noise_0.00/
│   │   │   │   │   ├── rep_01/
│   │   │   │   │   │   ├── trajectories.tsv
│   │   │   │   │   │   └── metadata.json
│   │   │   │   │   ├── rep_02/
│   │   │   │   │   └── ...
│   │   │   │   ├── noise_0.04/
│   │   │   │   ├── noise_0.08/
│   │   │   │   ├── noise_0.12/
│   │   │   │   ├── noise_0.16/
│   │   │   │   └── noise_0.20/
│   │   │   ├── exponential-linear-sin/
│   │   │   └── ...
│   │   ├── 6_functions/
│   │   │   └── [same structure]
│   │   └── 9_functions/
│   │       └── [same structure]
│   │
│   └── processed/                    # Processed/analyzed data
│       ├── clustering_results/
│       ├── distance_matrices/
│       └── summary_statistics/
│
├── scripts/
│   ├── generate_simulations.py      # Main simulation generator
│   ├── analyze_existing_simulations.py
│   └── batch_simulate.sh             # Batch job runner
│
├── logs/
│   ├── simulation_runs/
│   │   ├── 2024-10-07_run001.log
│   │   └── ...
│   └── errors/
│
└── reports/
    ├── simulation_analysis_report.json
    └── parameter_sweep_summary.pdf
```

## Naming Conventions

### Function Combinations
- Format: `func1-func2-func3-...`
- Alphabetically sorted within each group
- Examples:
  - `exponential-hyperbolic-norm`
  - `growth-linear-sin`
  - `exponential-growth-linear-poly-sin-tan` (for 6 functions)

### Noise Levels
- Format: `noise_X.XX`
- Zero-padded to 2 decimal places
- Examples: `noise_0.00`, `noise_0.04`, `noise_0.12`

### Replicate Directories
- Format: `rep_XX`
- Zero-padded to 2 digits (or 3 if >99 replicates)
- Examples: `rep_01`, `rep_02`, ..., `rep_10`

### File Names
- Trajectories: `trajectories.tsv`
- Metadata: `metadata.json`
- Logs: `YYYY-MM-DD_runXXX.log`

## Metadata Structure

Each replicate directory contains a `metadata.json` file:

```json
{
  "simulation_date": "2024-10-07T14:30:00",
  "parameters": {
    "num_trajectories": 200,
    "num_points": 63,
    "num_functions": 3,
    "functions": ["exponential", "hyperbolic", "norm"],
    "combine_funcs": 3,
    "noise_level_y": 0.04,
    "noise_level_x": 0.0,
    "percent_remove": 0.0,
    "end": false,
    "rep": 5,
    "random_seed": 42
  },
  "output": {
    "file": "trajectories.tsv",
    "num_trajectories_generated": 1000,
    "file_size_bytes": 1234567
  },
  "provenance": {
    "script": "simulate_trajectories.py",
    "loclust_version": "0.1.0",
    "command": "simulate_trajectories.py -N 200 -n 63 -f exponential,hyperbolic,norm ..."
  }
}
```

## Configuration File Structure

### Master Configuration: `simulation_parameters.yaml`

```yaml
# Master configuration for systematic simulation generation

simulation_sets:
  - name: "3_function_sweep"
    description: "Systematic sweep of 3-function combinations"
    num_functions: 3
    functions:
      - [exponential, hyperbolic, norm]
      - [exponential, linear, sin]
      - [growth, hyperbolic, norm]
      # ... more combinations

  - name: "6_function_sweep"
    description: "Systematic sweep of 6-function combinations"
    num_functions: 6
    functions:
      - [exponential, growth, linear, poly, sin, tan]
      # ... more combinations

common_parameters:
  num_trajectories: 200
  num_points: 63
  combine_funcs_mode: "append"  # or "average"
  rep_per_condition: 5
  x_noise: 0.0
  percent_remove: 0.0
  end: false

noise_levels:
  y_axis: [0.0, 0.04, 0.08, 0.12, 0.16, 0.20]

replicates:
  num_replicates: 10
  random_seeds: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

function_parameters:
  mode: "default"  # Use default parameters from loclust
  # Could specify custom parameters here if needed
```

## Advantages of This Structure

1. **Clear hierarchy**: Easy to navigate by number of functions → function combination → noise level → replicate
2. **Self-documenting**: Directory and file names clearly indicate parameters
3. **Scalable**: Easy to add new function combinations or parameter sweeps
4. **Metadata tracking**: Each simulation run has complete provenance
5. **Version control friendly**: Configuration files are human-readable YAML
6. **Analysis-ready**: Systematic structure makes bulk analysis straightforward
7. **Reproducible**: Complete parameter information enables exact reproduction

## Migration Plan

1. Run `analyze_existing_simulations.py` on old data
2. Create new organized structure
3. Write migration script to:
   - Parse old directory names
   - Extract parameters
   - Copy/reorganize files into new structure
   - Generate metadata.json for each replicate
4. Validate migrated data
5. Use new structure for all future simulations
