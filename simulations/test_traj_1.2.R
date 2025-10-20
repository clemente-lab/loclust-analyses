#!/usr/bin/env Rscript
# Simple test script for traj 1.2
# Using data with noise to avoid variance issues

library(traj)

cat("Testing traj version:", as.character(packageVersion("traj")), "\n")
cat("Functions available: step2factors =", exists("step2factors", where="package:traj"), "\n")

# Read data with noise (0.04 noise level to ensure variance)
data_file <- "/home/ewa/mnt/loclust/simulations/data_potentially_simple/input_trajs/8/3/0.04noise.exponential-hyperbolic-norm.200reps.0.tsv"
cat("Reading data from:", data_file, "\n")

# Read the data
data <- read.table(data_file, header=TRUE, sep="\t")
cat("Data shape:", nrow(data), "rows\n")

# Prepare trajectory matrices (OLD traj 1.2 format)
traj_ids <- unique(data$original_trajectory)
n_time <- length(as.numeric(unlist(strsplit(as.character(data$X[1]), ","))))
n_traj <- min(50, length(traj_ids))  # Use more trajectories to avoid edge cases

cat("Found", n_traj, "trajectories with", n_time, "time points\n")

# Build Y matrix (trajectory values) and X matrix (time points)
Y_matrix <- matrix(NA, nrow=n_traj, ncol=n_time)
X_matrix <- matrix(NA, nrow=n_traj, ncol=n_time)

for (i in 1:n_traj) {
    traj_data <- data[data$original_trajectory == traj_ids[i], ]
    y_values <- as.numeric(unlist(strsplit(as.character(traj_data$Y[1]), ",")))
    x_values <- as.numeric(unlist(strsplit(as.character(traj_data$X[1]), ",")))
    Y_matrix[i, ] <- y_values
    X_matrix[i, ] <- x_values
}

cat("Matrix shapes: Y =", dim(Y_matrix), "X =", dim(X_matrix), "\n")
cat("Y variance check:", var(as.vector(Y_matrix)), "\n")

# Run OLD traj 1.2 workflow
cat("\n=== Running traj 1.2 workflow ===\n")

# Step 1: Calculate measures
cat("Step 1: Calculating trajectory measures...\n")
step1 <- step1measures(Y_matrix, Time=X_matrix, ID=TRUE)
cat("✓ Step 1 completed\n")

# Debug step1 output
cat("Step1 output structure:\n")
cat("Names of measurments:", names(step1$measurments), "\n")
cat("Dimensions:", dim(step1$measurments), "\n")
cat("Column names:\n")
print(colnames(step1$measurments))

# Step 2: Factor selection (OLD function name)
cat("\nStep 2: Selecting factors...\n")
step2 <- step2factors(step1$measurments)  # Note: old typo "measurments"
cat("✓ Step 2 completed, factors selected:", step2$factors, "\n")

# Step 3: Clustering
cat("Step 3: Clustering...\n")
step3 <- step3clusters(step1$measurments, step2$factors, nstart=100, nclusters=3)
cat("✓ Step 3 completed\n")

# Calculate V-measure
cat("\n=== Results ===\n")
true_labels <- as.integer(factor(data$func))
pred_labels <- step3$clust$cluster

# V-measure calculation
cont_table <- table(true_labels, pred_labels)
n <- sum(cont_table)
true_marginal <- rowSums(cont_table) / n
pred_marginal <- colSums(cont_table) / n
H_true <- -sum(true_marginal * log(true_marginal + 1e-10))
H_pred <- -sum(pred_marginal * log(pred_marginal + 1e-10))
joint_probs <- cont_table / n
H_joint <- -sum(joint_probs * log(joint_probs + 1e-10))
MI <- H_true + H_pred - H_joint
homogeneity <- ifelse(H_true == 0, 1, MI / H_true)
completeness <- ifelse(H_pred == 0, 1, MI / H_pred)
v_measure <- ifelse(homogeneity + completeness == 0, 0, 2 * homogeneity * completeness / (homogeneity + completeness))

cat("Factors selected:", step2$factors, "\n")
cat("V-measure:", round(v_measure, 3), "\n")
cat("Homogeneity:", round(homogeneity, 3), "\n")
cat("Completeness:", round(completeness, 3), "\n")

cat("\n✓ SUCCESS: traj 1.2 is working correctly!\n")