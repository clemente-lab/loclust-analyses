#!/usr/bin/env python3
"""
Analyze existing simulation data to extract parameters used.

This script scans the disorganized simulation directory and extracts:
1. Directory naming patterns
2. Function combinations used
3. Noise levels
4. Number of replicates
5. Actual trajectory file parameters (by reading TSV files)

Output: A comprehensive JSON report of all parameters found.
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict
import sys


class SimulationAnalyzer:
    def __init__(self, sim_dir):
        self.sim_dir = Path(sim_dir)
        self.patterns = {
            'jobs_pattern_1': re.compile(r'jobs_(\d+)_func__([0-9.]+)_sub_func_lego__sig_(\d+)'),
            'jobs_pattern_2': re.compile(r'jobs_(\d+)func_k(\d+)_([0-9.]+)_sub_func_lego_interp_sig_(\d+)_sig_(\d+)'),
            'jobs_pattern_3': re.compile(r'jobs_(\d+)func_k(\d+)_noise_([0-9.]+)_sub_sig_(\d+)'),
            'input_trajs_pattern': re.compile(r'(\d+)funcs?_([\w-]+)_noise_([0-9.]+)_sub_(?:func_)?lego(?:_interp)?_sig_(\d+)'),
        }

        self.data = {
            'directories': [],
            'function_combinations': defaultdict(int),
            'noise_levels': set(),
            'num_functions': set(),
            'sigma_values': set(),
            'trajectory_files': [],
            'directory_patterns': defaultdict(list)
        }

    def analyze_directory_names(self):
        """Scan all directories and categorize them by pattern."""
        print(f"Scanning {self.sim_dir}...")

        for item in self.sim_dir.iterdir():
            if not item.is_dir():
                continue

            dir_name = item.name
            matched = False

            # Try each pattern
            for pattern_name, pattern in self.patterns.items():
                match = pattern.search(dir_name)
                if match:
                    self.data['directory_patterns'][pattern_name].append({
                        'name': dir_name,
                        'groups': match.groups()
                    })
                    matched = True
                    break

            if not matched and not dir_name.startswith('.'):
                self.data['directory_patterns']['unmatched'].append(dir_name)

            self.data['directories'].append(dir_name)

    def analyze_trajectory_directories(self):
        """Analyze directories containing actual trajectory files."""
        input_traj_dirs = [d for d in self.sim_dir.iterdir()
                          if d.is_dir() and 'input_trajs' in d.name]

        print(f"Found {len(input_traj_dirs)} input trajectory directories")

        for traj_dir in input_traj_dirs:
            print(f"  Analyzing {traj_dir.name}...")
            self._analyze_traj_subdir(traj_dir)

    def _analyze_traj_subdir(self, traj_dir):
        """Recursively analyze trajectory subdirectories."""
        for item in traj_dir.iterdir():
            if item.is_dir():
                match = self.patterns['input_trajs_pattern'].search(item.name)
                if match:
                    num_funcs, func_combo, noise, sigma = match.groups()

                    self.data['num_functions'].add(int(num_funcs))
                    self.data['noise_levels'].add(float(noise))
                    self.data['sigma_values'].add(int(sigma))
                    self.data['function_combinations'][func_combo] += 1

                    # Look for TSV files
                    tsv_files = list(item.glob('*.tsv'))
                    if tsv_files:
                        for tsv in tsv_files:
                            self.data['trajectory_files'].append({
                                'path': str(tsv),
                                'num_functions': int(num_funcs),
                                'functions': func_combo,
                                'noise': float(noise),
                                'sigma': int(sigma),
                                'size_bytes': tsv.stat().st_size
                            })

    def analyze_tsv_file(self, tsv_path, max_files=10):
        """Read a sample TSV file to extract actual parameters."""
        print(f"\nAnalyzing sample TSV files (max {max_files})...")

        tsv_info = []
        count = 0

        for traj_info in self.data['trajectory_files'][:max_files]:
            tsv_path = Path(traj_info['path'])
            if not tsv_path.exists():
                continue

            count += 1
            try:
                with open(tsv_path, 'r') as f:
                    lines = f.readlines()

                info = {
                    'file': str(tsv_path),
                    'num_lines': len(lines),
                    'header': lines[0].strip() if lines else None,
                }

                # Parse first data line to get metadata
                if len(lines) > 1:
                    parts = lines[1].strip().split('\t')
                    if len(parts) >= 6:
                        info['sample_id'] = parts[0]
                        info['sample_x_points'] = len([x for x in parts[1].split(',') if x])
                        info['sample_y_points'] = len([y for y in parts[2].split(',') if y])
                        info['func'] = parts[3]
                        info['noise'] = parts[4]
                        info['original_trajectory'] = parts[5]

                tsv_info.append(info)

            except Exception as e:
                print(f"  Error reading {tsv_path}: {e}")

        return tsv_info

    def generate_report(self, output_file):
        """Generate comprehensive JSON report."""

        # Convert sets to sorted lists for JSON serialization
        report = {
            'summary': {
                'total_directories': len(self.data['directories']),
                'num_functions_found': sorted(list(self.data['num_functions'])),
                'noise_levels_found': sorted(list(self.data['noise_levels'])),
                'sigma_values_found': sorted(list(self.data['sigma_values'])),
                'unique_function_combos': len(self.data['function_combinations']),
                'total_trajectory_files': len(self.data['trajectory_files'])
            },
            'directory_patterns': {k: v for k, v in self.data['directory_patterns'].items()},
            'function_combinations': dict(self.data['function_combinations']),
            'sample_trajectory_files': self.data['trajectory_files'][:50],  # First 50
            'tsv_file_analysis': self.analyze_tsv_file(None)
        }

        with open(output_file, 'w') as f:
            json.dump(report, f, indent=2)

        print(f"\nReport written to: {output_file}")
        return report

    def print_summary(self):
        """Print a human-readable summary."""
        print("\n" + "="*80)
        print("SIMULATION ANALYSIS SUMMARY")
        print("="*80)

        print(f"\nTotal directories: {len(self.data['directories'])}")
        print(f"Number of functions used: {sorted(list(self.data['num_functions']))}")
        print(f"Noise levels: {sorted(list(self.data['noise_levels']))}")
        print(f"Sigma/replicate values: {sorted(list(self.data['sigma_values']))}")
        print(f"\nUnique function combinations: {len(self.data['function_combinations'])}")

        print("\nTop 10 function combinations:")
        for func_combo, count in sorted(self.data['function_combinations'].items(),
                                       key=lambda x: x[1], reverse=True)[:10]:
            print(f"  {func_combo}: {count} instances")

        print(f"\nTotal trajectory TSV files found: {len(self.data['trajectory_files'])}")

        print("\nDirectory pattern breakdown:")
        for pattern_name, items in self.data['directory_patterns'].items():
            print(f"  {pattern_name}: {len(items)} matches")


def main():
    if len(sys.argv) > 1:
        sim_dir = sys.argv[1]
    else:
        sim_dir = "/home/ewa/cleme/hilary/loclust_simulations"

    output_file = "simulation_analysis_report.json"

    analyzer = SimulationAnalyzer(sim_dir)

    print("Step 1: Analyzing directory structure...")
    analyzer.analyze_directory_names()

    print("\nStep 2: Analyzing trajectory directories...")
    analyzer.analyze_trajectory_directories()

    print("\nStep 3: Generating report...")
    analyzer.generate_report(output_file)

    analyzer.print_summary()

    print("\n" + "="*80)
    print("Analysis complete!")
    print(f"Full report saved to: {output_file}")
    print("="*80)


if __name__ == "__main__":
    main()
