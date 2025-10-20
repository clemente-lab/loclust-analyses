#!/usr/bin/env Rscript
# Plot v-measure results - LEGACY STYLE
# Matches the original legacy plotting approach focusing on V-measure
#
# Usage:
#   Rscript plot_vmeasure_legacy_style.R

library(tidyverse)
library(ggplot2)

# Read results
input_file <- '../results_minimal_features/vmeasure_scores.tsv'

if (!file.exists(input_file)) {
  cat(sprintf("Error: Input file not found: %s\n", input_file))
  cat("Run calculate_vmeasure.py first to generate results.\n")
  quit(status=1)
}

cat(sprintf("Reading results from: %s\n", input_file))
df <- read_tsv(input_file, show_col_types = FALSE)

cat(sprintf("Loaded %d results\n", nrow(df)))
cat(sprintf("Methods: %s\n", paste(unique(df$method), collapse=", ")))

output_dir <- dirname(input_file)

# Add "LoClust" prefix to LoClust methods for clarity
loclust_methods <- c("gmm", "hierarchical", "kmeans", "spectral", "consensus")
df <- df %>%
  mutate(method_label = ifelse(method %in% loclust_methods,
                                paste0("LoClust ", toupper(substring(method, 1, 1)), substring(method, 2)),
                                toupper(method)))

# Highly distinct color palette - maximum contrast between all methods
method_colors <- c(
  # LoClust methods - widely separated on color wheel
  "LoClust Gmm" = "#0000FF",           # Pure blue
  "LoClust Hierarchical" = "#00FF00",  # Pure green
  "LoClust Kmeans" = "#FF00FF",        # Pure magenta
  "LoClust Spectral" = "#00FFFF",      # Pure cyan
  "LoClust Consensus" = "#808080",     # Gray
  # R methods - bold, highly distinct colors
  "KML" = "#FF8000",                   # Bright orange
  "DTWCLUST" = "#FF0000",              # Pure red
  "TRAJ" = "#FFFF00",                  # Pure yellow
  "MFUZZ" = "#800080"                  # Purple
)

# =============================================================================
# MAIN PLOT: V-Measure by Noise Level (Legacy Style)
# Separate plots for each num_classes value
# =============================================================================

for (n_classes in sort(unique(df$num_classes))) {
  cat(sprintf("\nGenerating V-measure plot for %d classes...\n", n_classes))

  # Filter for this number of classes
  df_subset <- df %>% filter(num_classes == n_classes)

  # Calculate means
  df_means <- df_subset %>%
    group_by(noise_level, method_label) %>%
    summarise(v_mean = mean(v_measure, na.rm=TRUE), .groups="drop")

  # Create plot (matching sc_plot_v_measure_results_loclust6.R style)
  p <- ggplot() +
    # Individual points (semi-transparent)
    geom_point(data = df_subset,
               aes(x=noise_level, y=v_measure, colour=method_label),
               alpha = 0.4, size = 2) +
    # Mean line
    geom_line(data = df_means,
              aes(x=noise_level, y=v_mean, group=method_label, color=method_label),
              linewidth = 1) +
    scale_color_manual(values = method_colors) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by=0.25)) +
    guides(color = guide_legend(nrow = 2, byrow = TRUE)) +
    labs(
      title = sprintf("V-Measure Results (%d-class simulations)", n_classes),
      x = "Noise Level",
      y = "V-Measure Score",
      color = "Method"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "bottom",
      legend.text = element_text(size = 6),
      legend.title = element_text(size = 7),
      legend.key.size = unit(0.4, "cm")
    )

  output_file <- file.path(output_dir, sprintf("vmeasure_%dclass_legacy.png", n_classes))
  ggsave(output_file, p, width=12, height=9, units="cm", dpi=300)
  cat(sprintf("  Saved: %s\n", output_file))
}

# =============================================================================
# Combined plot (all classes on one plot with facets)
# =============================================================================
cat("\nGenerating combined V-measure plot...\n")

df_means_all <- df %>%
  group_by(noise_level, method_label, num_classes) %>%
  summarise(v_mean = mean(v_measure, na.rm=TRUE), .groups="drop")

p_combined <- ggplot() +
  geom_point(data = df,
             aes(x=noise_level, y=v_measure, colour=method_label),
             alpha = 0.3, size = 1.5) +
  geom_line(data = df_means_all,
            aes(x=noise_level, y=v_mean, group=method_label, color=method_label),
            linewidth = 0.8) +
  facet_wrap(~num_classes, labeller = labeller(num_classes = function(x) paste(x, "classes"))) +
  scale_color_manual(values = method_colors) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by=0.25)) +
  guides(color = guide_legend(nrow = 2, byrow = TRUE)) +
  labs(
    title = "V-Measure Performance Across All Simulations",
    x = "Noise Level",
    y = "V-Measure Score",
    color = "Method"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom",
    legend.text = element_text(size = 6),
    legend.title = element_text(size = 7),
    legend.key.size = unit(0.4, "cm")
  )

output_file <- file.path(output_dir, "vmeasure_combined_legacy.png")
ggsave(output_file, p_combined, width=20, height=14, units="cm", dpi=300)
cat(sprintf("  Saved: %s\n", output_file))

# =============================================================================
# Summary statistics (matching legacy format)
# =============================================================================
cat("\n")
cat(strrep("=", 80), "\n")
cat("V-MEASURE SUMMARY BY METHOD\n")
cat(strrep("=", 80), "\n\n")

summary_stats <- df %>%
  group_by(method_label, num_classes) %>%
  summarise(
    v_mean = mean(v_measure, na.rm=TRUE),
    v_sd = sd(v_measure, na.rm=TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  arrange(num_classes, desc(v_mean))

print(summary_stats)

cat("\n")
cat(strrep("=", 80), "\n")
cat("Overall Performance (all classes combined):\n")
cat(strrep("=", 80), "\n\n")

overall_stats <- df %>%
  group_by(method_label) %>%
  summarise(
    v_mean = mean(v_measure, na.rm=TRUE),
    v_sd = sd(v_measure, na.rm=TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(v_mean))

print(overall_stats)

cat("\n")
cat(strrep("=", 80), "\n")
cat("All plots saved to:", output_dir, "\n")
cat(strrep("=", 80), "\n\n")
