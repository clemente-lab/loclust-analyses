#!/usr/bin/env python3
"""
Extract simulation parameters from existing trajectory TSV files.

This script reads actual trajectory files and extracts:
- Number of time points
- Number of trajectories
- Function types used
- Noise levels
- Original trajectory IDs (to understand replicates)

Creates a detailed parameter inventory for each discovered simulation batch.
"""

import sys
from pathlib import Path
import pandas as pd
import json
from collections import defaultdict
import re


def parse_trajectory_file(tsv_path):
    """
    Parse a trajectory TSV file and extract parameters.

    TSV format (from inspection):
    ID	X	Y	func	noise	original_trajectory
    """
    try:
        # Read just the first few lines to get structure
        with open(tsv_path, 'r') as f:
            header = f.readline().strip().split('\t')

            # Read all data lines
            lines = f.readlines()

        if len(lines) == 0:
            return None

        # Parse sample of trajectories
        trajectories = []
        original_trajs = set()
        funcs = set()
        noise_levels = set()

        for line in lines[:100]:  # Sample first 100
            parts = line.strip().split('\t')
            if len(parts) < 6:
                continue

            traj_id = parts[0]
            x_values = [float(x) for x in parts[1].split(',') if x]
            y_values = [float(y) for y in parts[2].split(',') if y]
            func = parts[3]
            noise = parts[4]
            orig_traj = parts[5].rstrip(',')

            trajectories.append({
                'id': traj_id,
                'num_points': len(x_values),
                'func': func,
                'noise': noise,
                'original_trajectory': orig_traj
            })

            original_trajs.add(orig_traj)
            funcs.add(func)
            noise_levels.add(noise)

        # Parse function names - may be combined with hyphens
        func_list = list(funcs)
        if len(func_list) == 1:
            # Check if it's a combined function
            func_parts = func_list[0].split('-')
            num_functions = len(func_parts)
            function_names = func_parts
        else:
            num_functions = len(func_list)
            function_names = func_list

        return {
            'file': str(tsv_path),
            'num_trajectories': len(lines),
            'num_points': trajectories[0]['num_points'] if trajectories else 0,
            'num_original_trajectories': len(original_trajs),
            'num_functions': num_functions,
            'functions': sorted(function_names),
            'noise_levels': sorted(list(noise_levels)),
            'sample_trajectory_ids': [t['id'] for t in trajectories[:5]]
        }

    except Exception as e:
        print(f"Error parsing {tsv_path}: {e}")
        return None


def scan_directory_for_tsvs(root_dir, max_files=None):
    """
    Recursively scan directory for TSV files and extract parameters.
    """
    root_path = Path(root_dir)

    print(f"Scanning {root_dir} for trajectory files...")

    # Find all TSV files
    tsv_files = list(root_path.rglob('*.tsv'))
    print(f"Found {len(tsv_files)} TSV files")

    if max_files:
        tsv_files = tsv_files[:max_files]
        print(f"Processing first {max_files} files...")

    results = []
    for i, tsv_path in enumerate(tsv_files, 1):
        if i % 10 == 0:
            print(f"  Processed {i}/{len(tsv_files)} files...")

        params = parse_trajectory_file(tsv_path)
        if params:
            # Add directory context
            params['relative_path'] = str(tsv_path.relative_to(root_path))
            params['parent_directory'] = tsv_path.parent.name
            results.append(params)

    return results


def group_by_parameters(results):
    """
    Group results by parameter combinations to identify unique simulation configs.
    """
    grouped = defaultdict(list)

    for result in results:
        # Create a key from the parameters
        key = (
            result['num_functions'],
            tuple(result['functions']),
            result['num_points'],
            result['num_trajectories'],
            tuple(result['noise_levels'])
        )

        grouped[key].append(result)

    return grouped


def create_parameter_summary(grouped_results):
    """
    Create a summary of unique parameter combinations found.
    """
    summaries = []

    for key, files in grouped_results.items():
        num_funcs, funcs, num_points, num_trajs, noise_levels = key

        summary = {
            'num_functions': num_funcs,
            'functions': list(funcs),
            'num_points': num_points,
            'num_trajectories': num_trajs,
            'noise_levels': list(noise_levels),
            'num_files_with_this_config': len(files),
            'example_files': [f['relative_path'] for f in files[:3]]
        }

        summaries.append(summary)

    # Sort by number of functions, then alphabetically
    summaries.sort(key=lambda x: (x['num_functions'], x['functions']))

    return summaries


def generate_simulation_config_template(summaries, output_file):
    """
    Generate a YAML template based on discovered parameters.
    """
    yaml_content = """# Simulation Configuration Template
# Generated from analysis of existing simulation data

simulation_batches:
"""

    for i, summary in enumerate(summaries, 1):
        func_str = '-'.join(summary['functions'])
        yaml_content += f"""
  - batch_id: {i:03d}
    name: "{summary['num_functions']}_funcs_{func_str}"
    parameters:
      num_functions: {summary['num_functions']}
      functions: {summary['functions']}
      num_trajectories: {summary['num_trajectories']}
      num_points: {summary['num_points']}
      noise_levels_y: {summary['noise_levels']}
      noise_level_x: 0.0
      combine_funcs: {summary['num_functions']}
      rep: 5  # Adjust based on needs
      percent_remove: 0.0
      end: false
    # Found {summary['num_files_with_this_config']} existing files with this configuration
"""

    with open(output_file, 'w') as f:
        f.write(yaml_content)

    print(f"\nConfiguration template written to: {output_file}")


def main():
    if len(sys.argv) > 1:
        sim_dir = sys.argv[1]
    else:
        sim_dir = "/home/ewa/cleme/hilary/loclust_simulations"

    max_files = 100  # Limit for faster testing
    if len(sys.argv) > 2:
        max_files = int(sys.argv[2])

    # Scan and extract parameters
    print("="*80)
    print("EXTRACTING SIMULATION PARAMETERS FROM TSV FILES")
    print("="*80)

    results = scan_directory_for_tsvs(sim_dir, max_files=max_files)

    print(f"\nSuccessfully parsed {len(results)} files")

    # Group by parameter combinations
    print("\nGrouping by parameter combinations...")
    grouped = group_by_parameters(results)

    print(f"Found {len(grouped)} unique parameter combinations")

    # Create summaries
    summaries = create_parameter_summary(grouped)

    # Save detailed results
    output_json = "extracted_parameters.json"
    with open(output_json, 'w') as f:
        json.dump({
            'individual_files': results,
            'unique_configurations': summaries,
            'summary': {
                'total_files_analyzed': len(results),
                'unique_configurations': len(summaries)
            }
        }, f, indent=2)

    print(f"\nDetailed results saved to: {output_json}")

    # Generate config template
    config_output = "simulation_config_template.yaml"
    generate_simulation_config_template(summaries, config_output)

    # Print summary
    print("\n" + "="*80)
    print("PARAMETER SUMMARY")
    print("="*80)

    for summary in summaries:
        func_str = '-'.join(summary['functions'])
        print(f"\n{summary['num_functions']} functions: {func_str}")
        print(f"  Trajectories: {summary['num_trajectories']}")
        print(f"  Time points: {summary['num_points']}")
        print(f"  Noise levels: {summary['noise_levels']}")
        print(f"  Files found: {summary['num_files_with_this_config']}")

    print("\n" + "="*80)
    print("Analysis complete!")
    print("="*80)


if __name__ == "__main__":
    main()
