#!/usr/bin/env Rscript
# Plot v-measure results from clustering benchmarks
#
# Usage:
#   Rscript plot_vmeasure.R
#   Rscript plot_vmeasure.R --input ../results/vmeasure_scores.tsv

library(tidyverse)
library(ggplot2)

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  input_file <- args[1]
} else {
  input_file <- '../results_minimal_features/vmeasure_scores.tsv'
}

output_dir <- dirname(input_file)

# Check if input file exists
if (!file.exists(input_file)) {
  cat(sprintf("Error: Input file not found: %s\n", input_file))
  cat("Run calculate_vmeasure.py first to generate results.\n")
  quit(status=1)
}

cat(sprintf("Reading results from: %s\n", input_file))
df <- read_tsv(input_file, show_col_types = FALSE)

cat(sprintf("Loaded %d results\n", nrow(df)))
cat(sprintf("Methods: %s\n", paste(unique(df$method), collapse=", ")))
cat(sprintf("Classes: %s\n", paste(unique(df$num_classes), collapse=", ")))

# Color palette for methods
method_colors <- c(
  "gmm" = "#FF6B6B",
  "hierarchical" = "#4ECDC4",
  "kmeans" = "#6BCF7F",
  "spectral" = "#9B59B6",
  "kml" = "#FFD93D",
  "dtwclust" = "#FF8E53",
  "traj" = "#95A5A6",
  "mfuzz" = "#DDA0DD"
)

# =============================================================================
# Plot 1: V-Measure by Noise Level (separate facets by num_classes)
# =============================================================================
cat("\nGenerating Plot 1: V-measure by noise level...\n")

# Calculate mean and std for each method/noise/num_classes combination
df_grouped <- df %>%
  group_by(method, noise_level, num_classes) %>%
  summarise(
    v_mean = mean(v_measure, na.rm=TRUE),
    v_sd = sd(v_measure, na.rm=TRUE),
    v_se = v_sd / sqrt(n()),
    .groups = "drop"
  )

# Also keep individual points for transparency
df_points <- df %>%
  select(method, noise_level, num_classes, v_measure)

p1 <- ggplot() +
  # Individual points (semi-transparent)
  geom_point(data = df_points,
            aes(x = noise_level, y = v_measure, color = method),
            alpha = 0.3, size = 1) +
  # Mean line
  geom_line(data = df_grouped,
           aes(x = noise_level, y = v_mean, group = method, color = method),
           linewidth = 1.2) +
  # Mean points
  geom_point(data = df_grouped,
            aes(x = noise_level, y = v_mean, color = method),
            size = 3) +
  # Error bars (standard error)
  geom_errorbar(data = df_grouped,
               aes(x = noise_level, ymin = v_mean - v_se, ymax = v_mean + v_se,
                   color = method),
               width = 0.005, alpha = 0.7) +
  # Facet by num_classes
  facet_wrap(~num_classes, labeller = label_both) +
  scale_color_manual(values = method_colors) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, by = 0.25)) +
  labs(
    title = "V-Measure Performance Across Noise Levels",
    subtitle = "Points = individual runs, Lines = mean ± SE",
    x = "Noise Level",
    y = "V-Measure Score",
    color = "Method"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )

output_file <- file.path(output_dir, "vmeasure_by_noise.png")
ggsave(output_file, p1, width = 12, height = 8, dpi = 300)
cat(sprintf("  Saved: %s\n", output_file))

# =============================================================================
# Plot 2: ARI by Noise Level
# =============================================================================
cat("\nGenerating Plot 2: ARI by noise level...\n")

df_grouped_ari <- df %>%
  group_by(method, noise_level, num_classes) %>%
  summarise(
    ari_mean = mean(ari, na.rm=TRUE),
    ari_sd = sd(ari, na.rm=TRUE),
    ari_se = ari_sd / sqrt(n()),
    .groups = "drop"
  )

df_points_ari <- df %>%
  select(method, noise_level, num_classes, ari)

p2 <- ggplot() +
  geom_point(data = df_points_ari,
            aes(x = noise_level, y = ari, color = method),
            alpha = 0.3, size = 1) +
  geom_line(data = df_grouped_ari,
           aes(x = noise_level, y = ari_mean, group = method, color = method),
           linewidth = 1.2) +
  geom_point(data = df_grouped_ari,
            aes(x = noise_level, y = ari_mean, color = method),
            size = 3) +
  geom_errorbar(data = df_grouped_ari,
               aes(x = noise_level, ymin = ari_mean - ari_se,
                   ymax = ari_mean + ari_se, color = method),
               width = 0.005, alpha = 0.7) +
  facet_wrap(~num_classes, labeller = label_both) +
  scale_color_manual(values = method_colors) +
  scale_y_continuous(limits = c(-0.1, 1), breaks = seq(0, 1, by = 0.25)) +
  labs(
    title = "Adjusted Rand Index Across Noise Levels",
    subtitle = "Points = individual runs, Lines = mean ± SE",
    x = "Noise Level",
    y = "Adjusted Rand Index (ARI)",
    color = "Method"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "bottom"
  )

output_file <- file.path(output_dir, "ari_by_noise.png")
ggsave(output_file, p2, width = 12, height = 8, dpi = 300)
cat(sprintf("  Saved: %s\n", output_file))

# =============================================================================
# Plot 3: Method Comparison Heatmap (mean ARI)
# =============================================================================
cat("\nGenerating Plot 3: Method comparison heatmap...\n")

df_heatmap <- df %>%
  group_by(method, num_classes, noise_level) %>%
  summarise(mean_ari = mean(ari, na.rm=TRUE), .groups = "drop")

p3 <- ggplot(df_heatmap, aes(x = factor(noise_level), y = method, fill = mean_ari)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", mean_ari)), color = "black", size = 3) +
  facet_wrap(~num_classes, labeller = label_both) +
  scale_fill_gradient2(
    low = "#d73027",
    mid = "#ffffbf",
    high = "#1a9850",
    midpoint = 0.5,
    limits = c(0, 1),
    name = "Mean ARI"
  ) +
  labs(
    title = "Mean ARI Heatmap by Method and Noise Level",
    x = "Noise Level",
    y = "Method"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(angle = 0, hjust = 0.5)
  )

output_file <- file.path(output_dir, "method_comparison_heatmap.png")
ggsave(output_file, p3, width = 12, height = 8, dpi = 300)
cat(sprintf("  Saved: %s\n", output_file))

# =============================================================================
# Plot 4: Overall Method Ranking (bar plot)
# =============================================================================
cat("\nGenerating Plot 4: Overall method ranking...\n")

df_ranking <- df %>%
  group_by(method) %>%
  summarise(
    mean_ari = mean(ari, na.rm=TRUE),
    sd_ari = sd(ari, na.rm=TRUE),
    se_ari = sd_ari / sqrt(n()),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_ari))

p4 <- ggplot(df_ranking, aes(x = reorder(method, mean_ari), y = mean_ari, fill = method)) +
  geom_col(width = 0.7) +
  geom_errorbar(aes(ymin = mean_ari - se_ari, ymax = mean_ari + se_ari),
               width = 0.2, alpha = 0.7) +
  geom_text(aes(label = sprintf("%.3f", mean_ari)),
           vjust = -0.5, size = 3) +
  scale_fill_manual(values = method_colors) +
  scale_y_continuous(limits = c(0, 1.1), breaks = seq(0, 1, by = 0.25)) +
  labs(
    title = "Overall Method Performance (Mean ARI ± SE)",
    subtitle = "Numbers show: ARI / (k-selection accuracy)",
    x = "Method",
    y = "Mean Adjusted Rand Index"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

output_file <- file.path(output_dir, "method_ranking.png")
ggsave(output_file, p4, width = 10, height = 6, dpi = 300)
cat(sprintf("  Saved: %s\n", output_file))

# =============================================================================
# Summary Statistics
# =============================================================================
cat("\n")
cat(strrep("=", 80), "\n")
cat("SUMMARY STATISTICS\n")
cat(strrep("=", 80), "\n\n")

print(df_ranking)

cat("\n")
cat(strrep("=", 80), "\n")
cat("All plots saved to:", output_dir, "\n")
cat(strrep("=", 80), "\n\n")
