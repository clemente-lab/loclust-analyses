#!/usr/bin/env Rscript
# Run R clustering methods on simulation datasets
# Methods: KML, DTWclust, Traj, Mfuzz
#
# Usage:
#   Rscript run_r_methods.R --method kml
#   Rscript run_r_methods.R --method all
#   Rscript run_r_methods.R --method kml --batch 3_classes

library(optparse)
library(kml)
library(dtwclust)
library(traj)
library(Mfuzz)
library(data.table)

# Parse command line arguments
option_list <- list(
  make_option(c("-m", "--method"), type="character", default="kml",
              help="Clustering method: kml, dtwclust, traj, mfuzz, or all"),
  make_option(c("-b", "--batch"), type="character", default=NULL,
              help="Run only specific batch: 3_classes, 6_classes, or 9_classes"),
  make_option(c("-d", "--data-dir"), type="character", default="../data",
              help="Path to data directory"),
  make_option(c("--dry-run"), action="store_true", default=FALSE,
              help="Print what would be run without executing")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

# Available methods
METHODS <- c("kml", "dtwclust", "traj", "mfuzz")

# Determine which methods to run
if (opt$method == "all") {
  methods_to_run <- METHODS
} else if (opt$method %in% METHODS) {
  methods_to_run <- c(opt$method)
} else {
  cat(sprintf("Error: Unknown method '%s'\n", opt$method))
  cat(sprintf("Available methods: %s\n", paste(METHODS, collapse=", ")))
  quit(status=1)
}

cat(sprintf("Data directory: %s\n", opt$`data-dir`))
cat(sprintf("Methods to run: %s\n", paste(methods_to_run, collapse=", ")))

# Find all trajectory files
find_datasets <- function(data_dir, batch_filter=NULL) {
  # Pattern: data/{N}_classes/{functions}/noise_{X}/seed_{Y}/trajectories.tsv

  traj_files <- list.files(
    path = data_dir,
    pattern = "trajectories\\.tsv$",
    recursive = TRUE,
    full.names = TRUE
  )

  datasets <- list()

  for (traj_file in traj_files) {
    # Parse path components
    parts <- strsplit(traj_file, "/")[[1]]

    # Find classes directory
    classes_idx <- grep("_classes$", parts)
    if (length(classes_idx) == 0) next

    classes_dir <- parts[classes_idx]
    num_classes <- as.integer(strsplit(classes_dir, "_")[[1]][1])

    # Skip if batch filter specified
    if (!is.null(batch_filter) && classes_dir != batch_filter) next

    # Extract metadata
    func_combo <- parts[classes_idx + 1]
    noise_dir <- parts[classes_idx + 2]
    seed_dir <- parts[classes_idx + 3]

    noise_level <- as.numeric(strsplit(noise_dir, "_")[[1]][2])
    seed <- as.integer(strsplit(seed_dir, "_")[[1]][2])

    datasets[[length(datasets) + 1]] <- list(
      file = traj_file,
      num_classes = num_classes,
      func_combo = func_combo,
      noise_level = noise_level,
      seed = seed,
      classes_dir = classes_dir,
      noise_dir = noise_dir,
      seed_dir = seed_dir
    )
  }

  return(datasets)
}

# Read trajectory data from TSV file
read_trajectory_data <- function(file_path) {
  # Read TSV file
  data <- fread(file_path, sep="\t", header=TRUE)

  # Parse X and Y columns (comma-separated values)
  # X: time points, Y: values

  trajs <- list()

  for (i in 1:nrow(data)) {
    x_vals <- as.numeric(strsplit(as.character(data$X[i]), ",")[[1]])
    y_vals <- as.numeric(strsplit(as.character(data$Y[i]), ",")[[1]])

    trajs[[i]] <- list(
      id = data$ID[i],
      time = x_vals,
      values = y_vals,
      func = data$func[i]  # True label
    )
  }

  return(list(trajectories = trajs, metadata = data))
}

# Convert trajectories to wide format matrix for KML/Mfuzz
# Each row is a trajectory, columns are time points
trajectories_to_matrix <- function(trajs) {
  # Find common time grid
  all_times <- unique(unlist(lapply(trajs, function(t) t$time)))
  time_grid <- sort(all_times)

  # Interpolate all trajectories to common grid
  mat <- matrix(NA, nrow=length(trajs), ncol=length(time_grid))

  for (i in seq_along(trajs)) {
    if (length(trajs[[i]]$time) > 1) {
      mat[i, ] <- approx(trajs[[i]]$time, trajs[[i]]$values,
                        xout=time_grid, rule=2)$y
    }
  }

  return(mat)
}

# Run KML clustering
run_kml <- function(file_path, num_classes, metadata, output_dir) {
  cat(sprintf("  Running KML (k=%d)...\n", num_classes))

  # Read data
  data <- read_trajectory_data(file_path)

  # Convert to matrix format
  mat <- trajectories_to_matrix(data$trajectories)

  # Create ClusterLongData object
  cld <- clusterLongData(traj=mat, idAll=data$metadata$ID, time=1:ncol(mat))

  # Run KML with fixed k
  kml(cld, nbClusters=num_classes, nbRedrawing=20)

  # Get cluster assignments using getClusters function
  clusters <- getClusters(cld, num_classes)

  # Write output in same format as input but with cluster column
  # IMPORTANT: Insert cluster column BEFORE the ",," marker (position 4)
  output_data <- data$metadata
  output_data <- data.table(
    ID = output_data$ID,
    X = output_data$X,
    Y = output_data$Y,
    cluster = clusters,
    output_data[, !c("ID", "X", "Y"), with=FALSE]
  )

  # Write trajectories.clust.tsv
  output_file <- file.path(output_dir, "trajectories.clust.tsv")
  fwrite(output_data, output_file, sep="\t")

  cat(sprintf("    ✓ Success - wrote %s\n", output_file))

  return(output_file)
}

# Run DTWclust clustering
run_dtwclust <- function(file_path, num_classes, metadata, output_dir) {
  cat(sprintf("  Running DTWclust (k=%d)...\n", num_classes))

  # Read data
  data <- read_trajectory_data(file_path)

  # Convert to list of time series
  ts_list <- lapply(data$trajectories, function(t) {
    ts(t$values, start=min(t$time), frequency=1)
  })

  # Run DTW clustering with hierarchical method
  clust <- tsclust(ts_list, type="h", k=num_classes,
                   distance="dtw_basic",
                   control=hierarchical_control(method="ward.D2"),
                   seed=42)

  # Get cluster assignments
  clusters <- clust@cluster

  # Write output
  # IMPORTANT: Insert cluster column BEFORE the ",," marker (position 4)
  output_data <- data$metadata
  output_data <- data.table(
    ID = output_data$ID,
    X = output_data$X,
    Y = output_data$Y,
    cluster = clusters,
    output_data[, !c("ID", "X", "Y"), with=FALSE]
  )

  output_file <- file.path(output_dir, "trajectories.clust.tsv")
  fwrite(output_data, output_file, sep="\t")

  cat(sprintf("    ✓ Success - wrote %s\n", output_file))

  return(output_file)
}

# Run Traj clustering
run_traj <- function(file_path, num_classes, metadata, output_dir) {
  cat(sprintf("  Running Traj (k=%d)...\n", num_classes))

  # Read data
  data <- read_trajectory_data(file_path)

  # Prepare data for traj package (needs long format)
  # ID, time, value format
  long_data <- data.frame()

  for (i in seq_along(data$trajectories)) {
    traj <- data$trajectories[[i]]
    for (j in seq_along(traj$time)) {
      long_data <- rbind(long_data, data.frame(
        ID = traj$id,
        time = traj$time[j],
        value = traj$values[j]
      ))
    }
  }

  # Run traj clustering
  # Note: traj uses CNORM models, may need adjustment for specific data
  tryCatch({
    traj_result <- traj::traj(long_data, id="ID", time="time", y="value",
                              model="CNORM", ng=num_classes)

    # Get cluster assignments
    clusters <- traj_result$assigned

    # Write output
    # IMPORTANT: Insert cluster column BEFORE the ",," marker (position 4)
    output_data <- data$metadata
    output_data <- data.table(
      ID = output_data$ID,
      X = output_data$X,
      Y = output_data$Y,
      cluster = clusters,
      output_data[, !c("ID", "X", "Y"), with=FALSE]
    )

    output_file <- file.path(output_dir, "trajectories.clust.tsv")
    fwrite(output_data, output_file, sep="\t")

    cat(sprintf("    ✓ Success - wrote %s\n", output_file))

    return(output_file)
  }, error = function(e) {
    cat(sprintf("    ✗ Error: %s\n", e$message))
    return(NULL)
  })
}

# Run Mfuzz clustering
run_mfuzz <- function(file_path, num_classes, metadata, output_dir) {
  cat(sprintf("  Running Mfuzz (k=%d)...\n", num_classes))

  # Read data
  data <- read_trajectory_data(file_path)

  # Convert to matrix format
  mat <- trajectories_to_matrix(data$trajectories)

  # Create ExpressionSet object
  eset <- new("ExpressionSet", exprs=mat)

  # Standardize data
  eset.s <- standardise(eset)

  # Run fuzzy c-means clustering
  cl <- mfuzz(eset.s, c=num_classes, m=1.25)

  # Get hard cluster assignments (max membership)
  clusters <- apply(cl$membership, 1, which.max)

  # Write output
  # IMPORTANT: Insert cluster column BEFORE the ",," marker (position 4)
  output_data <- data$metadata
  output_data <- data.table(
    ID = output_data$ID,
    X = output_data$X,
    Y = output_data$Y,
    cluster = clusters,
    output_data[, !c("ID", "X", "Y"), with=FALSE]
  )

  output_file <- file.path(output_dir, "trajectories.clust.tsv")
  fwrite(output_data, output_file, sep="\t")

  cat(sprintf("    ✓ Success - wrote %s\n", output_file))

  return(output_file)
}

# Main clustering dispatcher
run_clustering <- function(dataset, method, dry_run=FALSE) {
  # Create output directory
  parent_dir <- dirname(dataset$file)
  output_dir <- file.path(parent_dir, "clustering",
                         sprintf("%s_k%d", method, dataset$num_classes))

  if (!dry_run) {
    dir.create(output_dir, recursive=TRUE, showWarnings=FALSE)
  }

  # Dataset description
  desc <- sprintf("%s/%s/noise_%.2f/seed_%03d",
                 dataset$classes_dir, dataset$func_combo,
                 dataset$noise_level, dataset$seed)

  cat(sprintf("  %-12s k=%d → %s\n", method, dataset$num_classes, desc))

  if (dry_run) {
    cat(sprintf("    Would create: %s/trajectories.clust.tsv\n", output_dir))
    return(NULL)
  }

  # Run appropriate method
  start_time <- Sys.time()

  result <- tryCatch({
    switch(method,
      kml = run_kml(dataset$file, dataset$num_classes, dataset, output_dir),
      dtwclust = run_dtwclust(dataset$file, dataset$num_classes, dataset, output_dir),
      traj = run_traj(dataset$file, dataset$num_classes, dataset, output_dir),
      mfuzz = run_mfuzz(dataset$file, dataset$num_classes, dataset, output_dir)
    )
  }, error = function(e) {
    cat(sprintf("    ✗ Error: %s\n", e$message))
    return(NULL)
  })

  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units="secs"))

  if (!is.null(result)) {
    cat(sprintf("    Duration: %.1fs\n", duration))
  }

  return(result)
}

# Main execution
main <- function() {
  # Find all datasets
  cat("\nFinding datasets...\n")
  datasets <- find_datasets(opt$`data-dir`, opt$batch)

  if (length(datasets) == 0) {
    cat("No datasets found!\n")
    quit(status=1)
  }

  # Summary
  by_classes <- table(sapply(datasets, function(d) d$num_classes))
  cat(sprintf("\nFound %d datasets:\n", length(datasets)))
  for (k in sort(as.integer(names(by_classes)))) {
    cat(sprintf("  %d-class: %d datasets\n", k, by_classes[as.character(k)]))
  }

  if (opt$`dry-run`) {
    cat("\n*** DRY RUN MODE ***\n")
  }

  # Run clustering
  total_runs <- length(datasets) * length(methods_to_run)
  successful <- 0
  failed <- 0

  cat("\n")
  cat(strrep("=", 80), "\n")
  cat(sprintf("STARTING CLUSTERING: %d runs\n", total_runs))
  cat(strrep("=", 80), "\n\n")

  start_time <- Sys.time()

  for (method in methods_to_run) {
    cat(sprintf("\n[METHOD: %s]\n", toupper(method)))

    for (dataset in datasets) {
      result <- run_clustering(dataset, method, opt$`dry-run`)

      if (!opt$`dry-run`) {
        if (!is.null(result)) {
          successful <- successful + 1
        } else {
          failed <- failed + 1
        }
      }
    }
  }

  end_time <- Sys.time()
  duration <- difftime(end_time, start_time, units="auto")

  # Summary
  cat("\n")
  cat(strrep("=", 80), "\n")
  cat("CLUSTERING COMPLETE\n")
  cat(strrep("=", 80), "\n")

  if (!opt$`dry-run`) {
    cat(sprintf("Total runs: %d\n", total_runs))
    cat(sprintf("Successful: %d\n", successful))
    cat(sprintf("Failed: %d\n", failed))
    cat(sprintf("Duration: %s\n", format(duration)))
  } else {
    cat(sprintf("Would run: %d clustering jobs\n", total_runs))
  }

  cat(strrep("=", 80), "\n\n")
}

# Run main function
main()
