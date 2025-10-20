#!/usr/bin/env Rscript
# Check traj package version and available functions

library(traj)

# Get package info
info <- packageDescription("traj")
cat("Traj Package Information:\n")
cat(sprintf("Version: %s\n", info$Version))
cat(sprintf("Date: %s\n", info$Date))
cat(sprintf("Built: %s\n", info$Built))

# List all exported functions
cat("\nExported functions:\n")
funcs <- ls("package:traj")
for (f in sort(funcs)) {
  cat(sprintf("  %s\n", f))
}

# Check if both old and new function names exist
cat("\nFunction name check:\n")
cat(sprintf("  step1measures exists: %s\n", exists("step1measures")))
cat(sprintf("  Step1Measures exists: %s\n", exists("Step1Measures")))
cat(sprintf("  step2factors exists: %s\n", exists("step2factors")))
cat(sprintf("  Step2Selection exists: %s\n", exists("Step2Selection")))
cat(sprintf("  step3clusters exists: %s\n", exists("step3clusters")))
cat(sprintf("  Step3Clusters exists: %s\n", exists("Step3Clusters")))
