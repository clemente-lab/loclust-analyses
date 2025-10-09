# Pilot Test Results

**Date**: October 8, 2025
**Status**: ✅ SUCCESS

---

## Summary

Successfully generated **16 validation datasets** using the systematic generation pipeline.

### Generated Datasets:

**3-Class Datasets** (8 total):
- `exponential-hyperbolic-norm` × 2 noise × 2 seeds = 4 datasets
- `exponential-linear-sin` × 2 noise × 2 seeds = 4 datasets

**6-Class Datasets** (4 total):
- `exponential-growth-hyperbolic-linear-norm-sin` × 2 noise × 2 seeds = 4 datasets

**9-Class Datasets** (4 total):
- `exponential-growth-hyperbolic-linear-norm-poly-scurve-sin-tan` × 2 noise × 2 seeds = 4 datasets

### Parameters:
- **Noise levels**: 0.0, 0.04
- **Seeds**: 42, 43
- **Trajectories per class**: 50
- **Total trajectories per dataset**:
  - 3-class: 150 trajectories
  - 6-class: 300 trajectories
  - 9-class: 450 trajectories

---

## Directory Structure (Clean ✅)

```
data/
├── 3_classes/
│   ├── exponential-hyperbolic-norm/
│   │   ├── noise_0.00/
│   │   │   ├── seed_042/
│   │   │   │   ├── trajectories.tsv
│   │   │   │   ├── metadata.json
│   │   │   │   └── generation_log.txt
│   │   │   └── seed_043/
│   │   └── noise_0.04/
│   │       ├── seed_042/
│   │       └── seed_043/
│   └── exponential-linear-sin/
│       ├── noise_0.00/
│       │   ├── seed_042/
│       │   └── seed_043/
│       └── noise_0.04/
│           ├── seed_042/
│           └── seed_043/
├── 6_classes/
│   └── exponential-growth-hyperbolic-linear-norm-sin/
│       ├── noise_0.00/
│       │   ├── seed_042/
│       │   └── seed_043/
│       └── noise_0.04/
│           ├── seed_042/
│           └── seed_043/
└── 9_classes/
    └── exponential-growth-hyperbolic-linear-norm-poly-scurve-sin-tan/
        ├── noise_0.00/
        │   ├── seed_042/
        │   └── seed_043/
        └── noise_0.04/
            ├── seed_042/
            └── seed_043/
```

---

## Verification

✅ **All 16 datasets generated**
✅ **Clean directory structure** (hierarchical, self-documenting)
✅ **Complete metadata** for each dataset (parameters + provenance)
✅ **Generation logs** for debugging/verification
✅ **Reproducible** with documented seeds

---

## Next Steps

**Option 1: Proceed with Full Generation**
```bash
python generate_systematic.py --config simulation_config.yaml --yes
```
This will generate:
- 3-class: 1,200 datasets
- 6-class: 600 datasets
- 9-class: 300 datasets
- **TOTAL: 2,100 datasets**

**Option 2: Test Clustering on Pilot Data**
Run LoClust clustering on the 16 pilot datasets to verify they work with the pipeline before generating all 2,100.

**Option 3: Adjust Configuration**
Modify `simulation_config.yaml` to add/remove function combinations, noise levels, or seeds.

---

## Files Generated

Each dataset contains:
- **trajectories.tsv** - Trajectory data in standard format
- **metadata.json** - Complete parameters, seeds, checksum
- **generation_log.txt** - Generation details and timing

---

**Ready for full-scale generation!** 🚀
