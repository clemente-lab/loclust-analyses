#!/usr/bin/env Rscript
# Diagnostic script to understand why traj produces degenerate clusterings
# Compares trajectory characteristics and intermediate measures between
# failing (old Hilary) and successful (new potentially_simple) traj runs

library(data.table)
library(traj)

# Function to load trajectories
load_trajectories <- function(file_path) {
  dt <- fread(file_path)
  Ys <- as.numeric(unlist(strsplit(as.character(dt$Y), ',')))
  Xs <- as.numeric(unlist(strsplit(as.character(dt$X), ',')))

  rows <- nrow(dt)
  cols <- length(strsplit(as.character(dt$Y[1]), ',')[[1]])

  trajs <- list()
  trajs$Y <- matrix(Ys, nrow=rows, ncol=cols, byrow=TRUE)
  trajs$X <- matrix(Xs, nrow=rows, ncol=cols, byrow=TRUE)
  trajs$func <- dt$func

  return(trajs)
}

# Function to check if clustering is degenerate
is_degenerate <- function(clusters, threshold=0.8) {
  cluster_counts <- table(clusters)
  max_prop <- max(cluster_counts) / sum(cluster_counts)
  return(max_prop > threshold)
}

# Function to calculate diagnostics
calculate_diagnostics <- function(trajs) {
  Y <- trajs$Y
  X <- trajs$X

  # Basic statistics
  diagnostics <- list()
  diagnostics$n_trajs <- nrow(Y)
  diagnostics$n_timepoints <- ncol(Y)

  # Value ranges
  diagnostics$min_value <- min(Y)
  diagnostics$max_value <- max(Y)
  diagnostics$range <- max(Y) - min(Y)
  diagnostics$mean_value <- mean(Y)
  diagnostics$sd_value <- sd(Y)

  # Per-trajectory statistics
  traj_means <- rowMeans(Y)
  traj_sds <- apply(Y, 1, sd)
  diagnostics$mean_traj_mean <- mean(traj_means)
  diagnostics$sd_traj_mean <- sd(traj_means)
  diagnostics$mean_traj_sd <- mean(traj_sds)
  diagnostics$min_traj_sd <- min(traj_sds)
  diagnostics$n_zero_variance <- sum(traj_sds < 1e-10)

  # Correlation structure
  cor_matrix <- cor(t(Y))
  diag(cor_matrix) <- NA
  diagnostics$mean_correlation <- mean(cor_matrix, na.rm=TRUE)
  diagnostics$median_correlation <- median(cor_matrix, na.rm=TRUE)
  diagnostics$max_correlation <- max(cor_matrix, na.rm=TRUE)
  diagnostics$min_correlation <- min(cor_matrix, na.rm=TRUE)

  # Within-class correlations
  within_class_cors <- c()
  for (func_name in unique(trajs$func)) {
    idx <- which(trajs$func == func_name)
    if (length(idx) > 1) {
      class_Y <- Y[idx, , drop=FALSE]
      class_cor <- cor(t(class_Y))
      diag(class_cor) <- NA
      within_class_cors <- c(within_class_cors, mean(class_cor, na.rm=TRUE))
    }
  }
  diagnostics$mean_within_class_cor <- mean(within_class_cors)

  # Check for perfectly correlated trajectories
  n_perfect <- sum(cor_matrix > 0.9999, na.rm=TRUE) / 2  # Divide by 2 because matrix is symmetric
  diagnostics$n_perfect_correlations <- n_perfect

  # Try to run traj step1 and step2 to see where it might fail
  diagnostics$step1_success <- FALSE
  diagnostics$step2_success <- FALSE
  diagnostics$n_factors <- NA

  tryCatch({
    s1 <- step1measures(Y, X, ID=FALSE)
    diagnostics$step1_success <- TRUE

    # Check for NA/Inf in measures
    measures_mat <- s1$measdata
    diagnostics$measures_has_na <- any(is.na(measures_mat))
    diagnostics$measures_has_inf <- any(is.infinite(measures_mat))
    diagnostics$measures_mean <- colMeans(measures_mat, na.rm=TRUE)
    diagnostics$measures_sd <- apply(measures_mat, 2, sd, na.rm=TRUE)
    diagnostics$measures_n_zero_sd <- sum(diagnostics$measures_sd < 1e-10)

    # Try step2
    tryCatch({
      s2 <- step2factors(s1)
      diagnostics$step2_success <- TRUE
      diagnostics$n_factors <- ncol(s2$factors)

      # Check factor loadings
      factor_mat <- s2$factors
      diagnostics$factor_has_na <- any(is.na(factor_mat))
      diagnostics$factor_has_inf <- any(is.infinite(factor_mat))
      diagnostics$factor_sd <- apply(factor_mat, 2, sd, na.rm=TRUE)
      diagnostics$factor_n_zero_sd <- sum(diagnostics$factor_sd < 1e-10)

    }, error = function(e) {
      diagnostics$step2_error <<- as.character(e)
    })

  }, error = function(e) {
    diagnostics$step1_error <<- as.character(e)
  })

  return(diagnostics)
}

# Main analysis
cat("=== TRAJ FAILURE DIAGNOSTIC ANALYSIS ===\n\n")

# OLD DATA: Known failure case (Hilary directory)
cat("Loading OLD data (known failure case from Hilary directory)...\n")
old_fail_file <- "/sc/arion/projects/clemej05a/hilary/loclust_tool_comp/input_trajs/8/3/0.08noise.hyperbolic-norm-poly.200reps.2.tsv"
old_fail_clust <- "/sc/arion/projects/clemej05a/hilary/loclust_tool_comp/traj_outputs/8/3/0.08noise.hyperbolic-norm-poly.200reps.2._traj_clust.tsv"

if (file.exists(old_fail_file) && file.exists(old_fail_clust)) {
  trajs_old_fail <- load_trajectories(old_fail_file)
  clust_old_fail <- fread(old_fail_clust)

  cat("\nOLD DATA - Cluster distribution:\n")
  print(table(clust_old_fail$cluster))
  cat(sprintf("Degenerate: %s\n", is_degenerate(clust_old_fail$cluster)))

  cat("\nOLD DATA - Diagnostics:\n")
  diag_old_fail <- calculate_diagnostics(trajs_old_fail)
  print(data.frame(metric=names(diag_old_fail), value=as.character(diag_old_fail)))
} else {
  cat("OLD failure case files not found\n")
}

# NEW DATA: Known success case (potentially_simple pipeline)
cat("\n\nLoading NEW data (known success case from potentially_simple)...\n")
new_success_file <- "/sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple/input_trajs/8/3/0.04noise.hyperbolic-norm-poly.200reps.2.tsv"
new_success_clust <- "/sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple/input_trajs/8/3/clustering/traj_k3/0.04noise.hyperbolic-norm-poly.200reps.2.clust.tsv"

if (file.exists(new_success_file) && file.exists(new_success_clust)) {
  trajs_new_success <- load_trajectories(new_success_file)
  clust_new_success <- fread(new_success_clust)

  cat("\nNEW DATA - Cluster distribution:\n")
  print(table(clust_new_success$cluster))
  cat(sprintf("Degenerate: %s\n", is_degenerate(clust_new_success$cluster)))

  cat("\nNEW DATA - Diagnostics:\n")
  diag_new_success <- calculate_diagnostics(trajs_new_success)
  print(data.frame(metric=names(diag_new_success), value=as.character(diag_new_success)))
} else {
  cat("NEW success case files not found\n")
}

cat("\n=== COMPARISON COMPLETE ===\n")
