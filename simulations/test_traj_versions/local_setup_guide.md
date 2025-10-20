# Local Traj 1.2 Setup Guide

**Created:** October 17, 2025  
**Purpose:** Install traj 1.2 locally for numerical comparison with traj 2.2.1

## Quick Local Setup

### Step 1: Create Local Conda Environment

```bash
# On your local machine
conda create -n traj_local_test r-base=3.6.3 -c conda-forge -y
conda activate traj_local_test
conda install -c conda-forge r-essentials r-devtools -y
```

### Step 2: Install Traj 1.2

```bash
R
```

```r
# In R console
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Install dependencies
install.packages(c("pastecs", "NbClust", "GPArotation", "psych"))

# Install traj 1.2 from archive
install.packages("https://cran.r-project.org/src/contrib/Archive/traj/traj_1.2.tar.gz", 
                 repos=NULL, type="source")

# Test
library(traj)
packageVersion("traj")  # Should show 1.2
exists("step2factors", where="package:traj")  # Should be TRUE

# Quick test
test_data <- matrix(rnorm(50), 10, 5)
result <- step2factors(test_data)
cat("step2factors selected", result$factors, "factors\n")

quit()
```

### Step 3: Copy Test Data

Copy one test file to your local machine:
```bash
# From cluster to local
scp windae01@login.minerva.icahn.edu:/sc/arion/projects/CVDlung/earl/loclust/simulations/data_potentially_simple/input_trajs/8/3/0.04noise.exponential-hyperbolic-norm.200reps.0.tsv ~/Desktop/
```

### Step 4: Run Comparison Script

```r
# test_comparison.R
library(traj)

# Load data
data <- read.table("0.04noise.exponential-hyperbolic-norm.200reps.0.tsv", header=TRUE, sep="\t")

# Prepare trajectory matrix
traj_ids <- unique(data$original_trajectory)
n_time <- length(as.numeric(unlist(strsplit(as.character(data$X[1]), ","))))
traj_matrix <- matrix(NA, nrow=length(traj_ids), ncol=n_time)

for (i in 1:length(traj_ids)) {
    traj_data <- data[data$original_trajectory == traj_ids[i], ]
    y_values <- as.numeric(unlist(strsplit(as.character(traj_data$Y[1]), ",")))
    traj_matrix[i, ] <- y_values
}

cat("Data loaded:", nrow(traj_matrix), "trajectories x", ncol(traj_matrix), "timepoints\n")

# Test OLD algorithm (if available)
if (exists("step2factors", where="package:traj")) {
    cat("\nTesting OLD traj 1.2 (step2factors):\n")
    step1 <- step1measures(traj_matrix, ID=TRUE)
    step2 <- step2factors(step1$measurments)  # Note: old typo
    step3 <- step3clusters(step1$measurments, step2$factors, nstart=1000, nclusters=3)
    
    cat("OLD - Factors selected:", step2$factors, "\n")
    
    # Calculate v-measure
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
    
    cat("OLD - V-measure:", round(v_measure, 3), "\n")
}

# Test NEW algorithm (if available)
if (exists("Step2Selection", where="package:traj")) {
    cat("\nTesting NEW traj (Step2Selection):\n")
    step1 <- Step1Measures(traj_matrix, ID=TRUE)
    step2 <- Step2Selection(step1$Measurements)
    step3 <- Step3Clusters(step1$Measurements, step2$Selection, nstart=1000, nclusters=3)
    
    cat("NEW - Factors selected:", ncol(step2$Selection), "\n")
    
    # Calculate v-measure (same calculation)
    true_labels <- as.integer(factor(data$func))
    pred_labels <- step3$Cluster$cluster
    
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
    
    cat("NEW - V-measure:", round(v_measure, 3), "\n")
}
```

## Why This Should Work Locally

1. **Full control** over R version and dependencies
2. **Better library compatibility** on modern OS
3. **No HPC restrictions** or module conflicts
4. **Easier debugging** with full error messages
5. **Can install multiple traj versions** in different environments

## Next Steps

1. Try local setup
2. If traj 1.2 installs successfully, copy more test files
3. Run full numerical comparison
4. Generate results table

This avoids all the HPC cluster library compatibility issues we've been fighting.