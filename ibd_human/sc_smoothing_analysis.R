### This script contains the functions necessary to run 
### data loading/user inputs for all trajectory files and visualizing
### the babies_mg data
###
### Authors: Hilary Monaco

library(data.table)
library(dplyr)
library(ggplot2)
library(optparse)
library(tools)
library(tidyverse)
library(reshape2)

######## Smoothing investigation
# Load data
base_path <- "C:/Users/mathr/Documents/GitHub/knight_ibd/taxa_trajs_test_lego_interp/_R/"
infp_nointerp <- "C:/Users/mathr/Documents/GitHub/knight_ibd/taxa_trajs_test_lego_interp/_R/L6_trajs_Bacteroides_trajs_lego-interp_sig_0_R.tsv"
df <- read.table(infp_nointerp, sep="\t", header=T)
df$interp <- -1

smooth_levels <- c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
for (s in smooth_levels) {
  infp_interp <- paste(base_path, "L6_trajs_Bacteroides_trajs_lego-interp_sig_", s ,"_R.tsv", sep="")
  df_interp <- read.table(infp_interp, sep="\t", header=T)
  df_interp$interp <- s
  df <- rbind(df, df_interp)
}

# Trajectory Plots of smoothed data
ggplot(df, aes(x=time,y=value,group=ID,color=uc_extent)) + 
  geom_point(size=1) + 
  geom_line() + 
  theme_minimal() + 
  facet_grid(ID~interp, scales="free")

ggsave(paste(base_path, "smooth_comparisons_uc_extent_mode.pdf", sep=""), height=50, width=20, limitsize = FALSE)

# Trajectory plots of average data (un-smoothed)
df_nointerp_summary <- df_nointerp %>%
  group_by(delivery, time) %>%
  summarize(avg_value=mean(value))

ggplot(df_nointerp_summary, aes(x=time, y=avg_value, group=delivery, color=delivery)) + 
  geom_point() +
  geom_line() + 
  theme_minimal()

# ggsave(paste("C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/taxa_trajs_stool_child_test/avg_per_delivery_mode.pdf", sep=""), height=10, width=12)
ggsave(paste("C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/taxa_trajs_stool_child_test_lowess_interp/avg_per_delivery_mode.pdf", sep=""), height=10, width=12)

df_nointerp_summary2 <- df_nointerp %>%
  mutate(time.bin = cut(time, breaks=seq(0, 391, by=30), include.lowest=TRUE, labels=seq(0, 360, by=30))) %>%
  group_by(delivery, time.bin) %>%
  summarize(avg_bin_value=mean(value))

df_nointerp_summary2$time.bin.months = (as.numeric(df_nointerp_summary2$time.bin)-1)

# Trajectory data smoothed
smooth_levels <- c(0, 1, 2, 3, 4, 5, 6, 7, 8)
s <- 7
for (s in smooth_levels) {
  infp_interp <- paste(base_path, paste("otu_table_merged.0-12m.stool.child_L6_trajs_Bacteroides_trajs_smooth-", paste(s, "_interp_R.tsv", sep=""), sep=""), sep="")
  df_interp_OI <- read.table(infp_interp, sep="\t", header=T)
  df_interp_OI$interp <- s
  # Trajectory plots of average data (un-smoothed)
  df_interp_summary <- df_interp_OI %>%
    group_by(delivery, time) %>%
    summarize(avg_value=mean(value))
  # Trajectory Plots of smoothed data
  ggplot(df_interp_summary, aes(x=time,y=avg_value,group=delivery,color=delivery)) + 
    geom_point() + 
    geom_line() + 
    theme_minimal() 
  ggsave(paste(base_path,"/avg_per_delivery_mode_smooth-",s,".png", sep=""), height=5, width=6)
}

# Tried the below, it doesn't match the published figure 4b as well as the above does. 
# df_nointerp_summary2 <- df_nointerp %>%
#   mutate(time.bin = cut(time, breaks=c(0, seq(15, 391, by=30)), include.lowest=TRUE, labels=seq(0, 360, by=30))) %>%
#   group_by(delivery, time.bin) %>%
#   summarize(avg_bin_value=mean(value))

ggplot(df_nointerp_summary2, aes(x=time.bin.months, y=avg_bin_value, group=delivery, color=delivery)) + 
  geom_point() +
  geom_line() + 
  labs(x = "Age [Months]", y = "Bacteroides Relative Abundance", color="Delivery Mode") + 
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) + 
  theme_minimal(base_size=13) 

ggsave(paste("C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/taxa_trajs_stool_child_test/avg_per_delivery_mode_binned_30days.png", sep=""), height=5, width=6)


#%% Plot clusters
bacteroides_clusters_infp <- "C:/Users/mathr/Documents/GitHub/babies_mg/bacteroides/Bacteroides_smooth-4_loclust_k5_9pca_R.tsv"
b.df <- read.table(bacteroides_clusters_infp, sep="\t", header=T)
b.df$time.months <- b.df$time/30
b.df2 <- b.df %>%
  mutate(time.bin = cut(time, breaks=seq(0, 391, by=30), include.lowest=TRUE, labels=seq(0, 360, by=30))) %>%
  group_by(cluster, time.bin) %>%
  summarize(avg_value=mean(value))
b.df2$time.bin.months = (as.numeric(b.df2$time.bin)-1)

ggplot(b.df, aes(x=time.months,y=value,group=ID,color=delivery)) + 
  geom_point() + 
  geom_line() + 
  labs(x = "Age [Months]", y = "Bacteroides Relative Abundance", color="Delivery Mode") +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) + 
  facet_wrap(vars(cluster), scales="fixed")

ggsave("C:/Users/mathr/Documents/GitHub/babies_mg/bacteroides/Bacteroides_smooth-4_loclust_k5_9pca_clusters.png", height=10, width=12)

# Adding mean line
ggplot() + 
  geom_point(b.df, mapping=aes(x=time.months,y=value,group=ID,color=delivery)) + 
  geom_line(b.df, mapping=aes(x=time.months,y=value,group=ID,color=delivery), alpha=0.5) + 
  labs(x = "Age [Months]", y = "Bacteroides Relative Abundance", color="Delivery Mode") +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) + 
  facet_wrap(vars(cluster), scales="fixed") + 
  geom_point(b.df2, mapping=aes(x=time.bin.months,y=avg_value),color="black") + 
  geom_line(b.df2, mapping=aes(x=time.bin.months,y=avg_value),size=1,linetype="dashed",color="black") + 
  facet_wrap(vars(cluster), scales="fixed")

ggsave("C:/Users/mathr/Documents/GitHub/babies_mg/bacteroides/Bacteroides_smooth-4_loclust_k5_9pca_clusters_w-mean.png", height=10, width=12)