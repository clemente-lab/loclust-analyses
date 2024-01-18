### Plot complex heatmap of the 9 func data at 0.2 noise 

library(data.table)
library(dplyr)
library(ggplot2)
library(optparse)
library(tools)
library(tidyverse)
library(reshape2)
library(ComplexHeatmap)
library(circlize)

base.dir <- 'C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs_wff/'
folder <- '0.2noise.exponential-growth-hyperbolic-linear-norm-poly-scurve-sin-tan.200reps.0_loclust_3pca_pc_3_num_clusters_9/'
fn <- 'features_qt.tsv'

df <- read.table(paste0(base.dir, folder, fn), sep="\t", header=T)

# Generate the complex heatmap
col_fun = colorRamp2(c(0, 0.5, 1), c("blue", "white", "red"))
col_fun(seq(-3, 3))
lgd = Legend(col_fun = col_fun, title = "Feature Value")

rownames(df) <- df$func
df$func <- NULL
png(file=paste0(base.dir, folder, 'features_qt_heatmap.png'), width=18, height=12, units='in', res=300)
mat <- data.matrix(df, rownames.force = TRUE)
ht <- Heatmap(mat, col = col_fun, name="Features", width=ncol(mat)*unit(10, "mm"), height = nrow(mat)*unit(10, "mm"))
draw(ht)
dev.off()
