#!/usr/bin/env Rscript
# Test the complete traj workflow with a simple dataset

library(traj)
library(data.table)

cat("Testing traj 2.2.1 workflow...\n\n")

# Load a real dataset to test
test_file <- "/sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple/input_trajs/8/3/0.04noise.exponential-hyperbolic-norm.200reps.2.tsv"

cat(sprintf("Reading: %s\n", test_file))
dt <- fread(test_file)

# Parse data
Ys <- as.numeric(unlist(strsplit(as.character(dt$Y), ',')))
Xs <- as.numeric(unlist(strsplit(as.character(dt$X), ',')))

rows <- nrow(dt)
cols <- length(strsplit(as.character(dt$Y[1]), ',')[[1]])

Y_matrix <- matrix(Ys, nrow=rows, ncol=cols, byrow=TRUE)
X_matrix <- matrix(Xs, nrow=rows, ncol=cols, byrow=TRUE)

cat(sprintf("Data: %d trajectories x %d timepoints\n\n", rows, cols))

# Test Step 1
cat("Step 1: Calculating measures...\n")
step1 <- Step1Measures(Y_matrix, Time=X_matrix, ID=FALSE)
cat(sprintf("  ✓ Computed measures for %d trajectories\n", nrow(step1$measures)))
cat(sprintf("  Available measures: %s\n", paste(colnames(step1$measures)[-1], collapse=", ")))

# Test Step 2 - automatic selection
cat("\nStep 2: Automatic measure selection...\n")
step2 <- Step2Selection(step1)
cat(sprintf("  ✓ Selected measures: %s\n", paste(colnames(step2$selection)[-1], collapse=", ")))
cat(sprintf("  Number of measures selected: %d\n", ncol(step2$selection)-1))

# Test Step 3 with k=3
cat("\nStep 3: Clustering with k=3...\n")
step3 <- Step3Clusters(step2, nclusters=3)
cat(sprintf("  ✓ Clustering complete\n"))
cat(sprintf("  Cluster distribution: %s\n", paste(table(step3$partition$Cluster), collapse=", ")))

# Verify we got the right number of clusters
unique_clusters <- length(unique(step3$partition$Cluster))
cat(sprintf("  Unique clusters: %d (expected: 3)\n", unique_clusters))

if (unique_clusters == 3) {
  cat("\n✅ WORKFLOW CORRECT: All steps completed successfully!\n")
} else {
  cat(sprintf("\n❌ PROBLEM: Expected 3 clusters but got %d\n", unique_clusters))
}

# Show comparison with buggy version
cat("\n" , strrep("=", 60), "\n")
cat("TESTING BUGGY VERSION (select=3)...\n")
cat(strrep("=", 60), "\n\n")

step2_buggy <- Step2Selection(step1, select=3)
cat(sprintf("Buggy Step2 - measures selected: %s\n", paste(colnames(step2_buggy$selection)[-1], collapse=", ")))
cat(sprintf("Buggy - Number of measures: %d (only measure #3!)\n", ncol(step2_buggy$selection)-1))

cat("\n✅ TEST COMPLETE\n")
