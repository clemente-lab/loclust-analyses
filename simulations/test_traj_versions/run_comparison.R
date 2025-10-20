# Numerical comparison between traj 1.2 and traj 2.2.1
# Run this in ~/traj_comparison_test/ directory
# Created: October 17, 2025

cat("================================================\n")
cat("NUMERICAL COMPARISON: Traj 1.2 vs Traj 2.2.1\n")  
cat("================================================\n\n")

library(traj)
cat("Traj version:", as.character(packageVersion('traj')), "\n\n")

# Load test data
data_file <- "0.04noise.exponential-hyperbolic-norm.200reps.0.tsv"
if (!file.exists(data_file)) {
    stop("Test data file not found: ", data_file)
}

cat("Loading data from:", data_file, "\n")
data <- read.table(data_file, header=TRUE, sep="\t")

# Prepare trajectory matrix
traj_ids <- unique(data$original_trajectory)
n_time <- length(as.numeric(unlist(strsplit(as.character(data$X[1]), ","))))
traj_matrix <- matrix(NA, nrow=length(traj_ids), ncol=n_time)

for (i in 1:length(traj_ids)) {
    traj_data <- data[data$original_trajectory == traj_ids[i], ]
    y_values <- as.numeric(unlist(strsplit(as.character(traj_data$Y[1]), ",")))
    traj_matrix[i, ] <- y_values
}

cat("Data loaded:", nrow(traj_matrix), "trajectories x", ncol(traj_matrix), "timepoints\n\n")

# Determine which version we have and run appropriate algorithm
if (exists("step2factors", where="package:traj")) {
    cat("RUNNING OLD TRAJ 1.2 (step2factors algorithm)\n")
    cat("=============================================\n")
    
    # Run OLD traj pipeline
    step1 <- step1measures(traj_matrix, ID=TRUE)
    step2 <- step2factors(step1$measurments)  # Note: old version has typo
    step3 <- step3clusters(step1$measurments, step2$factors, nstart=1000, nclusters=3)
    
    factors_selected <- step2$factors
    cluster_assignments <- step3$clust$cluster
    version_type <- "OLD_1.2"
    
} else if (exists("Step2Selection", where="package:traj")) {
    cat("RUNNING NEW TRAJ 2.2.1 (Step2Selection algorithm)\n")
    cat("=================================================\n")
    
    # Run NEW traj pipeline
    step1 <- Step1Measures(traj_matrix, ID=TRUE)
    step2 <- Step2Selection(step1$Measurements)
    step3 <- Step3Clusters(step1$Measurements, step2$Selection, nstart=1000, nclusters=3)
    
    factors_selected <- ncol(step2$Selection)
    cluster_assignments <- step3$Cluster$cluster
    version_type <- "NEW_2.2.1"
    
} else {
    stop("Neither old nor new traj functions found!")
}

cat("Factors selected:", factors_selected, "\n")
cat("Cluster assignments:", length(cluster_assignments), "trajectories\n\n")

# Calculate v-measure
true_labels <- as.integer(factor(data$func))
pred_labels <- cluster_assignments

cat("Calculating v-measure...\n")
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

cat("\n================================================\n")
cat("RESULTS\n")
cat("================================================\n")
cat("Version:", version_type, "\n")
cat("Factors selected:", factors_selected, "\n")
cat("V-measure:", round(v_measure, 3), "\n")
cat("Homogeneity:", round(homogeneity, 3), "\n")
cat("Completeness:", round(completeness, 3), "\n")

# Save results
result <- data.frame(
    version = version_type,
    traj_version = as.character(packageVersion('traj')),
    factors = factors_selected,
    v_measure = v_measure,
    homogeneity = homogeneity,
    completeness = completeness,
    n_trajectories = nrow(traj_matrix),
    dataset = basename(data_file)
)

output_file <- paste0(tolower(version_type), "_result.tsv")
write.table(result, output_file, sep="\t", row.names=FALSE, quote=FALSE)
cat("\nResults saved to:", output_file, "\n")
cat("================================================\n")