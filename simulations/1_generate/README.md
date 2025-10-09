# Simulation Generation Scripts

**Tools for systematic, reproducible simulation generation.**

---

## Files

### Main Generation
- **`generate_systematic.py`** - Main simulation generation script
  - Reads `simulation_config.yaml`
  - Sets random seeds
  - Creates organized output structure
  - Generates metadata automatically

### Configuration
- **`simulation_config.yaml`** - Master configuration file
  - Defines all function combinations
  - Sets noise levels and seeds
  - Controls output organization

### Verification & Analysis
- **`verify_simulations.py`** - Verify checksums and metadata
- **`create_inventory.py`** - Generate parameter inventory report

### Testing
- **`test_seed_reproducibility.py`** - Verify random seed reproducibility
- **`analyze_existing_simulations.py`** - Analyze legacy data structure
- **`extract_simulation_parameters.py`** - Extract parameters from legacy TSV files

---

## Usage

### Generate All Simulations

```bash
python generate_systematic.py \
    --config simulation_config.yaml \
    --output-dir ../data
```

### Generate Specific Batch

```bash
python generate_systematic.py \
    --config simulation_config.yaml \
    --batch "3_function_combinations" \
    --output-dir ../data
```

### Custom Seeds

```bash
python generate_systematic.py \
    --config simulation_config.yaml \
    --seed-start 100 \
    --seed-count 5
```

### Verify Generated Data

```bash
python verify_simulations.py --data-dir ../data
```

### Create Inventory

```bash
python create_inventory.py \
    --data-dir ../data \
    --output ../documentation/parameter_inventory.md
```

---

## Configuration Format

**`simulation_config.yaml`**:

```yaml
simulation_batches:
  - name: "3_function_combinations"
    num_functions: 3
    combinations:
      - [exponential, hyperbolic, norm]
      - [exponential, linear, sin]

common_parameters:
  num_trajectories: 200
  num_points: 20
  rep: 5

noise_levels:
  y_axis: [0.0, 0.04, 0.08]

seeds:
  start: 1
  num_replicates: 10
```

---

## Requirements

```bash
# Python packages
pip install pyyaml pandas numpy click
```

---

## Workflow

1. **Edit** `simulation_config.yaml` with desired parameters
2. **Run** `generate_systematic.py`
3. **Verify** with `verify_simulations.py`
4. **Document** with `create_inventory.py`
5. **Analyze** using LoClust pipeline

---

## Output Structure

```
../data/
├── 3_functions/
│   ├── exponential-hyperbolic-norm/
│   │   ├── noise_0.00/
│   │   │   ├── seed_001/
│   │   │   │   ├── trajectories.tsv
│   │   │   │   ├── metadata.json
│   │   │   │   └── generation_log.txt
│   │   │   ├── seed_002/
│   │   │   └── ...
│   │   ├── noise_0.04/
│   │   └── ...
│   └── ...
└── ...
```

---

## Metadata Format

Each `metadata.json` contains:
- Generation date and script version
- Complete simulation parameters
- Random seeds used
- Output file information
- MD5 checksum
- Full provenance (command, directory, user)

---

**Status**: Scripts ready for implementation
**Next Step**: Create `generate_systematic.py` and `simulation_config.yaml`
