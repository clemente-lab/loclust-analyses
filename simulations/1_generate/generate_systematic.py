#!/usr/bin/env python3
"""
Systematic simulation generation for LoClust clustering validation.

This script generates organized simulation datasets where each dataset contains
trajectories from N different function classes (for testing clustering algorithms).

Usage:
    python generate_systematic.py --config simulation_config.yaml
    python generate_systematic.py --config simulation_config.yaml --batch 3_class
    python generate_systematic.py --config simulation_config.yaml --dry-run
"""

import sys
import argparse
import yaml
from pathlib import Path
import json
import hashlib
from datetime import datetime
import subprocess

# Add loclust repo to path
LOCLUST_REPO = Path("/home/ewa/cleme/hilary/repos/loclust")
sys.path.insert(0, str(LOCLUST_REPO))

from random import seed as set_random_seed
import numpy as np
from loclust.simulate import simu
from loclust.parse import write_trajectories


def load_config(config_path):
    """Load YAML configuration file."""
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    return config


def generate_single_dataset(functions, noise_level, seed, params, output_dir):
    """
    Generate a single dataset with trajectories from multiple function classes.

    Parameters:
    -----------
    functions : list
        List of function names (e.g., ['exponential', 'hyperbolic', 'norm'])
    noise_level : float
        Y-axis noise level
    seed : int
        Random seed for reproducibility
    params : dict
        Common parameters from config
    output_dir : Path
        Output directory for this dataset

    Returns:
    --------
    dict : Metadata about the generated dataset
    """
    # Set random seeds
    set_random_seed(seed)
    np.random.seed(seed)

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    # Start generation log
    log_file = output_dir / "generation_log.txt"
    log = []
    log.append(f"Generation started: {datetime.now().isoformat()}")
    log.append(f"Functions: {functions}")
    log.append(f"Noise level: {noise_level}")
    log.append(f"Random seed: {seed}")
    log.append("")

    # Generate trajectories for each function class
    all_trajectories = []

    for func_name in functions:
        log.append(f"Generating {params['num_trajectories_per_class']} trajectories for {func_name}...")

        # Generate trajectories for this function class
        # Use combine_funcs=1 to get PURE trajectories (not combined)
        trajectories = simu(
            num_traj=params['num_trajectories_per_class'],
            num_points=params['num_points'],
            noise_lev=str(noise_level),  # Single noise level
            funcs=func_name,              # Single function
            rep=params['rep'],
            combine_funcs=1,              # CRITICAL: 1 = pure trajectories
            params=params['function_params'],
            percent_remove=params['percent_remove'],
            end=params['end'],
            x_noise=str(params['x_noise'])
        )

        all_trajectories.extend(trajectories)
        log.append(f"  Generated {len(trajectories)} trajectories")

    log.append("")
    log.append(f"Total trajectories: {len(all_trajectories)}")

    # Write trajectories to file
    output_file = output_dir / "trajectories.tsv"
    write_trajectories(all_trajectories, output_file)

    log.append(f"Written to: {output_file}")

    # Compute MD5 checksum
    md5_hash = hashlib.md5()
    with open(output_file, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b""):
            md5_hash.update(chunk)
    checksum = md5_hash.hexdigest()

    log.append(f"MD5 checksum: {checksum}")

    # Get file size
    file_size = output_file.stat().st_size
    log.append(f"File size: {file_size:,} bytes")

    # Write generation log
    log.append(f"\nGeneration completed: {datetime.now().isoformat()}")
    with open(log_file, 'w') as f:
        f.write('\n'.join(log))

    # Create metadata
    metadata = {
        "generation": {
            "date": datetime.now().isoformat(),
            "script": "generate_systematic.py",
            "loclust_repo": str(LOCLUST_REPO)
        },
        "parameters": {
            "num_classes": len(functions),
            "function_classes": functions,
            "num_trajectories_per_class": params['num_trajectories_per_class'],
            "total_trajectories": len(all_trajectories),
            "num_points": params['num_points'],
            "noise_level_y": noise_level,
            "noise_level_x": params['x_noise'],
            "rep": params['rep'],
            "percent_remove": params['percent_remove'],
            "end": params['end'],
            "function_params": params['function_params']
        },
        "randomization": {
            "python_seed": seed,
            "numpy_seed": seed
        },
        "output": {
            "file": "trajectories.tsv",
            "num_trajectories": len(all_trajectories),
            "file_size_bytes": file_size,
            "md5_checksum": checksum
        },
        "provenance": {
            "command": " ".join(sys.argv),
            "working_directory": str(Path.cwd())
        }
    }

    # Write metadata
    metadata_file = output_dir / "metadata.json"
    with open(metadata_file, 'w') as f:
        json.dump(metadata, f, indent=2)

    return metadata


def generate_batch(batch_name, combinations, noise_levels, seeds, params, base_dir):
    """
    Generate a complete batch of simulations.

    Parameters:
    -----------
    batch_name : str
        Name of the batch (e.g., "3_classes", "6_classes")
    combinations : list
        List of function combinations
    noise_levels : list
        List of noise levels to test
    seeds : range
        Range of random seeds
    params : dict
        Common parameters
    base_dir : Path
        Base output directory
    """
    print(f"\n{'='*80}")
    print(f"GENERATING BATCH: {batch_name}")
    print(f"{'='*80}")
    print(f"Combinations: {len(combinations)}")
    print(f"Noise levels: {len(noise_levels)}")
    print(f"Seeds: {len(list(seeds))}")
    print(f"Total datasets: {len(combinations) * len(noise_levels) * len(list(seeds))}")
    print(f"{'='*80}\n")

    total_generated = 0

    for combo_idx, functions in enumerate(combinations, 1):
        # Sort functions alphabetically for consistent naming
        functions = sorted(functions)
        combo_name = '-'.join(functions)

        print(f"\n[{combo_idx}/{len(combinations)}] Function combination: {combo_name}")

        for noise_idx, noise in enumerate(noise_levels, 1):
            noise_dir = f"noise_{noise:.2f}"

            print(f"  [{noise_idx}/{len(noise_levels)}] Noise level: {noise}")

            for seed_idx, seed in enumerate(seeds, 1):
                seed_dir = f"seed_{seed:03d}"

                # Create output directory path
                output_dir = base_dir / batch_name / combo_name / noise_dir / seed_dir

                # Check if already exists
                if (output_dir / "trajectories.tsv").exists():
                    print(f"    [{seed_idx:2d}/{len(list(seeds))}] Seed {seed:03d}: SKIPPED (already exists)")
                    continue

                print(f"    [{seed_idx:2d}/{len(list(seeds))}] Seed {seed:03d}: Generating...", end='', flush=True)

                try:
                    metadata = generate_single_dataset(
                        functions=functions,
                        noise_level=noise,
                        seed=seed,
                        params=params,
                        output_dir=output_dir
                    )
                    print(f" ✓ ({metadata['output']['num_trajectories']} trajectories)")
                    total_generated += 1

                except Exception as e:
                    print(f" ✗ ERROR: {e}")
                    continue

    print(f"\n{'='*80}")
    print(f"BATCH COMPLETE: {batch_name}")
    print(f"Generated: {total_generated} datasets")
    print(f"{'='*80}\n")

    return total_generated


def main():
    parser = argparse.ArgumentParser(
        description="Generate systematic simulation datasets for LoClust clustering validation"
    )
    parser.add_argument(
        '--config',
        type=str,
        required=True,
        help='Path to YAML configuration file'
    )
    parser.add_argument(
        '--batch',
        type=str,
        choices=['3_class', '6_class', '9_class', 'all'],
        default='all',
        help='Which batch to generate (default: all)'
    )
    parser.add_argument(
        '--output-dir',
        type=str,
        default=None,
        help='Override output directory from config'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Print what would be generated without actually generating'
    )
    parser.add_argument(
        '--yes', '-y',
        action='store_true',
        help='Skip confirmation prompt'
    )

    args = parser.parse_args()

    # Load configuration
    print(f"Loading configuration from: {args.config}")
    config = load_config(args.config)

    # Determine output directory
    if args.output_dir:
        base_dir = Path(args.output_dir)
    else:
        script_dir = Path(__file__).parent
        base_dir = script_dir / config['output']['base_directory']

    base_dir = base_dir.resolve()

    print(f"Output directory: {base_dir}")

    if args.dry_run:
        print("\n*** DRY RUN MODE - No files will be generated ***\n")

    # Get common parameters
    params = config['common_parameters']
    noise_levels = config['noise_levels']['values']
    seeds = range(config['seeds']['start'], config['seeds']['start'] + config['seeds']['count'])

    # Determine which batches to generate
    batches_to_generate = []

    if args.batch == 'all' or args.batch == '3_class':
        batches_to_generate.append({
            'name': '3_classes',
            'combinations': config['three_function_combinations']['combinations']
        })

    if args.batch == 'all' or args.batch == '6_class':
        batches_to_generate.append({
            'name': '6_classes',
            'combinations': config['six_function_combinations']['combinations']
        })

    if args.batch == 'all' or args.batch == '9_class':
        batches_to_generate.append({
            'name': '9_classes',
            'combinations': config['nine_function_combinations']['combinations']
        })

    # Print summary
    print("\n" + "="*80)
    print("GENERATION SUMMARY")
    print("="*80)

    total_datasets = 0
    for batch in batches_to_generate:
        num_datasets = len(batch['combinations']) * len(noise_levels) * len(list(seeds))
        total_datasets += num_datasets
        print(f"{batch['name']:12s}: {len(batch['combinations']):3d} combos × {len(noise_levels)} noise × {len(list(seeds)):2d} seeds = {num_datasets:,} datasets")

    print(f"{'TOTAL':12s}: {total_datasets:,} datasets")
    print("="*80)

    if args.dry_run:
        print("\nDry run complete. No files generated.")
        return 0

    # Confirm before generating
    if not args.yes:
        response = input("\nProceed with generation? [y/N]: ")
        if response.lower() not in ['y', 'yes']:
            print("Generation cancelled.")
            return 0
    else:
        print("\nProceeding with generation (--yes flag set)...")

    # Generate all batches
    total_generated = 0
    start_time = datetime.now()

    for batch in batches_to_generate:
        num_generated = generate_batch(
            batch_name=batch['name'],
            combinations=batch['combinations'],
            noise_levels=noise_levels,
            seeds=seeds,
            params=params,
            base_dir=base_dir
        )
        total_generated += num_generated

    end_time = datetime.now()
    duration = end_time - start_time

    # Final summary
    print("\n" + "="*80)
    print("GENERATION COMPLETE")
    print("="*80)
    print(f"Total datasets generated: {total_generated:,}")
    print(f"Duration: {duration}")
    print(f"Output directory: {base_dir}")
    print("="*80)

    return 0


if __name__ == "__main__":
    sys.exit(main())
