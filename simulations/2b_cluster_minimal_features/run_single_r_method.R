#!/usr/bin/env Rscript
# Run R clustering method on a single dataset
#
# Usage:
#   Rscript run_single_r_method.R <method> <traj_file> <num_classes>
#
# Example:
#   Rscript run_single_r_method.R kml data/3_classes/.../trajectories.tsv 3

library(data.table)
library(kml)
library(dtwclust)
library(traj)
library(Mfuzz)

# Parse arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  cat("Usage: Rscript run_single_r_method.R <method> <traj_file> <num_classes> [output_dir] [output_basename]\n")
  quit(status = 1)
}

method <- args[1]
traj_file <- args[2]
num_classes <- as.integer(args[3])
output_dir_arg <- if (length(args) >= 4) args[4] else NULL
output_basename_arg <- if (length(args) >= 5) args[5] else NULL

# Source the functions from run_r_methods.R
# Use absolute path like the LoClust scripts do
# Set flag to prevent command line parsing when sourcing
sourced_run_r_methods <- TRUE
source("/sc/arion/projects/CVDlung/earl/loclust/simulations/2a_cluster_local/run_r_methods.R")

# Read trajectory data
cat(sprintf("Reading data from: %s\n", traj_file))
data <- read_trajectory_data(traj_file)

# Create output directory (use passed output_dir if provided, otherwise construct from input)
if (!is.null(output_dir_arg)) {
  output_dir <- output_dir_arg
} else {
  traj_dir <- dirname(traj_file)
  output_dir <- file.path(traj_dir, "clustering", sprintf("%s_k%d", method, num_classes))
}
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Run clustering
cat(sprintf("Running %s clustering (k=%d)...\n", method, num_classes))

result <- tryCatch({
  output_file <- switch(method,
    kml = run_kml(traj_file, num_classes, data, output_dir, output_basename_arg),
    dtwclust = run_dtwclust(traj_file, num_classes, data, output_dir, output_basename_arg),
    traj = run_traj(traj_file, num_classes, data, output_dir, output_basename_arg),
    mfuzz = run_mfuzz(traj_file, num_classes, data, output_dir, output_basename_arg),
    {
      cat(sprintf("ERROR: Unknown method '%s'\n", method))
      NULL
    }
  )

  if (!is.null(output_file)) {
    cat(sprintf("SUCCESS: %s\n", output_file))
    TRUE
  } else {
    FALSE
  }
}, error = function(e) {
  cat(sprintf("ERROR: %s\n", e$message))
  FALSE
})

if (!result) {
  quit(status = 1)
}
