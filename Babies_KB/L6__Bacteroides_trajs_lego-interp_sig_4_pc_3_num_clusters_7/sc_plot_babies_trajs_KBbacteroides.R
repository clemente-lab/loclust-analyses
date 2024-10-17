
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

######## Plotting trajectories after smoothing
# Load Data
# 4 clusters
# base_path <- "C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/outputs/Bacteroides_lego5/L6__Bacteroides_trajs_lego-interp_sig_5_pc_3_num_clusters_5/"
base_path <- "/sc/arion/projects/clemej05a/kevin/loclust/babies_mg/babies_mg_lego5_outputs/outputs/taxa_trajs_lego_interp/L6__Bacteroides_trajs_lego-interp_sig_4_pc_4_num_clusters_8/"
# infp_interp <- paste0(base_path, "L6__Bacteroides_trajs_lego-interp_sig_5_loclust_k5_3pca_R.tsv")
infp_interp <- paste0(base_path, "L6__Bacteroides_trajs_lego-interp_sig_4_loclust_k8_4pca_R.tsv")

# 5 clusters
# base_path <- "C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/outputs/Bacteroides_lego5/L6__Bacteroides_trajs_lego-interp_sig_5_pc_4_num_clusters_9/"
# infp_interp <- paste0(base_path, "L6__Bacteroides_trajs_lego-interp_sig_5_loclust_k9_4pca_R.tsv")
# Testing out interpolation on Nan's 12TP trajs
# base_path <- "C:/Users/mathr/Documents/GitHub/babies_mg/nointp_trjs_lego_interp/_R/"
# infp_interp <- paste0(base_path, 'Bacteroides.6_lego-interp_sig_5_R.tsv')

# base_path <- "C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/outputs/Bacteroides_nan_nointrp_lego/Bacteroides.6_lego-interp_sig_5_pc_3_num_clusters_8/"
# infp_interp <- paste0(base_path, 'Bacteroides.6_lego-interp_sig_5_loclust_k8_3pca_R.tsv')


b.df <- read.table(infp_interp, sep="\t", header=T, fill=TRUE)
b.df$ID <- as.factor(b.df$ID)
b.df$cluster <- as.factor(b.df$cluster)



ggplot() + 
  geom_point(b.df, mapping=aes(x=time,y=value,group=ID,color=delivery)) + 
  geom_line(b.df, mapping=aes(x=time,y=value,group=ID,color=delivery), alpha=0.5) + 
  labs(x = "Age [Months]", y = "Bacteroides Relative Abundance", color="Delivery Mode") +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) 

ggsave(paste(base_path, "Bacteroides_smooth-5.png"), height=10, width=12)

b.df2 <- b.df %>%
  group_by(delivery, time) %>%
  summarize(avg_value=mean(value))

agg.tbl <- b.df %>% 
  group_by(time, delivery) %>% 
  summarise(v_mean = mean(value),
            v_sd = sd(value),
            v_ct = n(),
            .groups = 'drop') 
agg.tbl <- na.omit(agg.tbl)
# AVEREAGES PLOT WITH TRAJS __ USED FOR PPT PRESENTATION
plt <- ggplot() + 
  # geom_point(b.df, mapping=aes(x=time,y=value,group=ID,color=delivery)) + 
  geom_line(b.df, mapping=aes(x=time,y=value,group=ID,color=delivery), alpha=0.3, linewidth=0.5, show.legend=FALSE) + 
  labs(x = "Age [Months]", y = "Bacteroides Relative Abundance", color="Delivery Mode") +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) 
  # geom_point(b.df2, mapping=aes(x=time,y=avg_value, group=delivery),color="black")

plt

plt + geom_ribbon(data = agg.tbl, aes(x=time, ymin=v_mean-v_sd/sqrt(v_ct), ymax=v_mean+v_sd/sqrt(v_ct),
                                      fill=delivery, group=delivery),
                  alpha = 0.3, show.legend=FALSE) +
  geom_line(b.df2, mapping=aes(x=time,y=avg_value, group=delivery, color=delivery),linewidth=2) +
  theme(legend.position = c(0.8, 0.8), legend.box.background = element_rect(colour="white"))

ggsave(paste(base_path, "Bacteroides_smooth-5_delivery-mean.png"), height=10, width=7.75)
ggsave(paste(base_path, "Bacteroides_smooth-5_delivery-mean.pdf"), height=10, width=7.75)

### Plotting each cluster as a separate panel, colored by delivery mode

# Calculate the average trajectory per cluster
b.df3 <- b.df %>%
  group_by(cluster, time) %>%
  summarize(avg_value=mean(value))

p <- ggplot() + 
  # geom_point(b.df, mapping=aes(x=time,y=value,group=ID,color=delivery)) + 
  geom_line(b.df, linewidth = 1, mapping=aes(x=time,y=value,group=ID,color=delivery), alpha=0.3) + 
  labs(x = "Age [Months]", y = "Bacteroides Relative Abundance", color="Delivery Mode") +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) 

p + facet_grid(cols = vars(cluster)) +
  geom_line(data = b.df3, mapping = aes(x=time, y=avg_value), linewidth=1.5) #+ 
  # geom_point()

ggsave(paste(base_path, "Bacteroides_smooth-5_delivery-mean-and-clusters_nopoints.png"), height=10, width=23)
ggsave(paste(base_path, "Bacteroides_smooth-5_delivery-mean-and-clusters_nopoints.pdf"), height=10, width=23)

### Plot each cluster as a separate panel, colored by each metadata variable
# mdata_list = colnames(b.df)[1:3]
mdata_list = colnames(b.df)[1:2]

for (mdata in mdata_list) {
  p <- ggplot() + 
    geom_point(b.df, mapping=aes_string(x="time",y="value",group="ID",color=mdata)) + 
    geom_line(b.df, mapping=aes_string(x="time",y="value",group="ID",color=mdata), alpha=0.5) + 
    labs(x = "Age [Months]", y = "Bacteroides Relative Abundance", color=mdata) +
    scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
    theme_minimal(base_size=26) 
  
  p + facet_grid(cols = vars(cluster)) +
    geom_line(data = b.df3, mapping = aes(x=time, y=avg_value), linewidth=1.5) + 
    geom_point()
  
  ggsave(paste(base_path, "Bacteroides_bL5_", mdata, "-mean-and-clusters.png", sep=""), height=10, width=23)
  ggsave(paste(base_path, "Bacteroides_bL5_", mdata, "-mean-and-clusters.pdf", sep=""), height=10, width=23)
}

mdata <- "delivery"
p <- ggplot() + 
  geom_point(b.df, mapping=aes_string(x="time",y="value",group="ID",color=mdata)) + 
  geom_line(b.df, mapping=aes_string(x="time",y="value",group="ID",color=mdata), alpha=0.5) + 
  labs(x = "Age [Months]", y = "Bacteroides Relative Abundance", color=mdata) +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) 

p + facet_wrap(~cluster, scales = "free_y", ncol=4) +
  geom_line(data = b.df3, mapping = aes(x=time, y=avg_value), linewidth=1.5) + 
  geom_point()

ggsave(paste(base_path, "Bacteroides_bL5_", mdata, "-mean-and-clusters_yfree.png", sep=""), height=10, width=23)
ggsave(paste(base_path, "Bacteroides_bL5_", mdata, "-mean-and-clusters_yfree.pdf", sep=""), height=10, width=23)



