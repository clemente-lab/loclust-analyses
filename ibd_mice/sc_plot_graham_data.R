### This script contains the functions necessary to run 
### data loading/user inputs for all trajectory files and visualizing
### Knight IBD data
###
### Authors: Hilary Monaco

library(data.table)
library(dplyr)
library(ggplot2)
library(optparse)
library(tools)
library(tidyverse)
library(reshape2)

# Load data
base_path <- "C:/Users/mathr/Documents/GitHub/graham/outputs/"

### Calculate per-taxa averages by Donor_disease_state and plot results
trajs_folders <- Sys.glob(file.path(base_path, "*"))
taxa_files <- c()

for (traj_folder in trajs_folders){
  
  # Get all taxa files
  files_found <- Sys.glob(file.path(traj_folder, "*_R.tsv"))
  taxa_files <- append(taxa_files, files_found)
}

for (taxa_file in taxa_files){
  df_taxa_OI <- read.table(taxa_file, sep="\t", header=T) %>%
    drop_na()
  
  # Extract last section of filename with taxa name information
  sep_from_base <- strsplit(taxa_file, '//')[[1]][2]
  output_folder_name <- strsplit(sep_from_base[[1]], '/')[[1]][1]
  taxa_label <- "weight"

  # Calculate averages per microbiome type
  df_summary3 <- df_taxa_OI %>% 
    drop_na() %>%
    group_by(time, Donor_disease_state) %>% 
    summarise(v_mean = mean(value),
              v_sd = sd(value),
              na.rm = TRUE,
              .groups = 'drop') 
  
  # SD
  p <- ggplot(df_summary3, aes(x=time, y=v_mean, group=Donor_disease_state, color=Donor_disease_state)) + 
    geom_line(linewidth = 1.5) + 
    labs(x = "Time (days)", y = "% Original Weight", color="Donor_disease_state") + 
    scale_x_continuous(breaks=seq(0, 21, by=7), labels=seq(0, 21, by=7)) +
    theme_minimal(base_size=20) 
  p
  
  p + geom_ribbon(data = df_summary3, aes(x=time, ymin=v_mean-v_sd, ymax=v_mean+v_sd,
                                          fill=Donor_disease_state, group=Donor_disease_state),
                  alpha = 0.2)
  
  ggsave(paste(base_path, output_folder_name, '/', taxa_label, '_trajs_avg_by_Donor_disease_state_withSD.png', sep=""), 
         height=12, 
         width=13)
  
  ggsave(paste(base_path, output_folder_name, '/', taxa_label, 'trajs_avg_by_Donor_disease_state_withSD.svg', sep=""), 
         height=12, 
         width=13)
  
  # SE
  num_trajs <- length(unique(df_taxa_OI$ID))
  p <- ggplot(df_summary3, aes(x=time, y=v_mean, group=Donor_disease_state, color=Donor_disease_state)) + 
    # geom_point(size = 3) +
    geom_line(linewidth = 1.5) + 
    labs(x = "Time (days)", y = "% Original Weight", color="Donor_disease_state") + 
    scale_x_continuous(breaks=seq(0, 21, by=7), labels=seq(0, 21, by=7)) +
    theme_minimal(base_size=20) 
  p
  
  p + geom_ribbon(data = df_summary3, aes(x=time, ymin=v_mean-v_sd/sqrt(num_trajs), ymax=v_mean+v_sd/sqrt(num_trajs),
                                          fill=Donor_disease_state, group=Donor_disease_state),
                  alpha = 0.2)
  
  ggsave(paste(base_path, output_folder_name, '/', taxa_label, '_trajs_avg_by_Donor_disease_state_withSE.png', sep=""), 
         height=12, 
         width=13)
  
  ggsave(paste(base_path, output_folder_name, '/', taxa_label, 'trajs_avg_by_Donor_disease_state_withSE.svg', sep=""), 
         height=12, 
         width=13)
  
  # Plot clusters
  df_cluster_mean <- df_taxa_OI %>%
    group_by(cluster, time) %>%
    summarize(avg_value=mean(value))
  
  ggplot() + 
    geom_line(df_taxa_OI, mapping=aes(x=time,y=value,group=ID,color=Donor_disease_state), linewidth = 1, alpha=0.3) + 
    labs(x = "Time (days)", y = "% Original Weight", color="Donor_disease_state") +
    scale_x_continuous(breaks=seq(0, 42, by=7), labels=seq(0, 42, by=7)) +
    theme_minimal(base_size=20) + 
    facet_wrap(vars(cluster), scales="fixed") +
    geom_line(df_cluster_mean, mapping=aes(x=time,y=avg_value),linewidth=1.5,color="black") + 
    facet_wrap(vars(cluster), scales="fixed")
  
  ggsave(paste(base_path, output_folder_name, '/', taxa_label, '_clusters_with_mean.png', sep=""), 
         height=10, 
         width=15)
  ggsave(paste(base_path, output_folder_name, '/', taxa_label, '_clusters_with_mean.svg', sep=""), 
         height=10, 
         width=15)
  
}
