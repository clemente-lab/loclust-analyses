#!/usr/bin/env Rscript
# Run R clustering method on a single dataset
#
# Usage:
#   Rscript run_single_r_method.R <method> <traj_file> <num_classes>
#
# Example:
#   Rscript run_single_r_method.R kml data/3_classes/.../trajectories.tsv 3

library(optparse)
library(data.table)
library(kml)
library(dtwclust)
library(Mfuzz)

# Parse arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 3) {
  cat("Usage: Rscript run_single_r_method.R <method> <traj_file> <num_classes>\n")
  quit(status = 1)
}

method <- args[1]
traj_file <- args[2]
num_classes <- as.integer(args[3])

# Source the functions from run_r_methods.R
script_dir <- dirname(sys.frame(1)$ofile)
source(file.path(script_dir, "run_r_methods.R"))

# Read trajectory data
cat(sprintf("Reading data from: %s\n", traj_file))
data <- read_trajectory_data(traj_file)

# Create output directory
traj_dir <- dirname(traj_file)
output_dir <- file.path(traj_dir, "clustering", sprintf("%s_k%d", method, num_classes))
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Run clustering
cat(sprintf("Running %s clustering (k=%d)...\n", method, num_classes))

result <- tryCatch({
  output_file <- switch(method,
    kml = run_kml(traj_file, num_classes, data, output_dir),
    dtwclust = run_dtwclust(traj_file, num_classes, data, output_dir),
    mfuzz = run_mfuzz(traj_file, num_classes, data, output_dir),
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
