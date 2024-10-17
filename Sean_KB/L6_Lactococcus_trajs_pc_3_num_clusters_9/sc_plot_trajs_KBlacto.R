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

# install.packages('svglite')
# library(svglite)

######## Plotting trajectories after smoothing
# Load Data
# 4 clusters
# base_path <- "C:/Users/mathr/Documents/GitHub/babies_mg/otu_tables_and_mapping_files/outputs/Bacteroides_lego5/L6__Bacteroides_trajs_lego-interp_sig_5_pc_3_num_clusters_5/"
# base_path <- "/sc/arion/projects/clemej05a/kevin/loclust/babies_mg/babies_mg_lego5_outputs/outputs/taxa_trajs_lego_interp/L6__Bacteroides_trajs_lego-interp_sig_5_pc_3_num_clusters_5/"
# infp_interp <- paste0(base_path, "L6__Bacteroides_trajs_lego-interp_sig_5_loclust_k5_3pca_R.tsv")
# infp_interp <- paste0(base_path, "L6__Bacteroides_trajs_lego-interp_sig_5_loclust_k5_3pca_R.tsv")
base_path <- "/sc/arion/projects/clemej05a/kevin/loclust/sean/outputs/taxa_trajs/L6_Lactococcus_trajs_pc_3_num_clusters_9/"
infp_interp <- Sys.glob(file.path(base_path, "*_R.tsv"))

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
  geom_point(b.df, mapping=aes(x=time,y=value,group=ID,color=Diet)) + 
  geom_line(b.df, mapping=aes(x=time,y=value,group=ID,color=Diet), alpha=0.5) + 
  labs(x = "Time [Days]", y = "Lactococcus Relative Abundance", color="Diet Mode") +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) 

ggsave(paste(base_path, "Lactococcus_smooth-5.pdf"), height=10, width=12)

b.df2 <- b.df %>%
  group_by(Diet, time) %>%
  summarize(avg_value=mean(value))

agg.tbl <- b.df %>% 
  group_by(time, Diet) %>% 
  summarise(v_mean = mean(value),
            v_sd = sd(value),
            v_ct = n(),
            .groups = 'drop') 
agg.tbl <- na.omit(agg.tbl)
# AVEREAGES PLOT WITH TRAJS __ USED FOR PPT PRESENTATION
plt <- ggplot() + 
  # geom_point(b.df, mapping=aes(x=time,y=value,group=ID,color=Diet)) + 
  geom_line(b.df, mapping=aes(x=time,y=value,group=ID,color=Diet), alpha=0.3, linewidth=0.5, show.legend=FALSE) + 
  labs(x = "Time [Days]", y = "Lactococcus Relative Abundance", color="Diet Mode") +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) 
  # geom_point(b.df2, mapping=aes(x=time,y=avg_value, group=Diet),color="black")

plt

plt + geom_ribbon(data = agg.tbl, aes(x=time, ymin=v_mean-v_sd/sqrt(v_ct), ymax=v_mean+v_sd/sqrt(v_ct),
                                      fill=Diet, group=Diet),
                  alpha = 0.3, show.legend=FALSE) +
  geom_line(b.df2, mapping=aes(x=time,y=avg_value, group=Diet, color=Diet),linewidth=2) +
  theme(legend.position = c(0.8, 0.8), legend.box.background = element_rect(colour="white"))

ggsave(paste(base_path, "Lactococcus_smooth-5_Diet-mean.pdf"), height=10, width=7.75)


### Plotting each cluster as a separate panel, colored by Diet mode

# Calculate the average trajectory per cluster
b.df3 <- b.df %>%
  group_by(cluster, time) %>%
  summarize(avg_value=mean(value))

p <- ggplot() + 
  # geom_point(b.df, mapping=aes(x=time,y=value,group=ID,color=Diet)) + 
  geom_line(b.df, linewidth = 1, mapping=aes(x=time,y=value,group=ID,color=Diet), alpha=0.3) + 
  labs(x = "Time [Days]", y = "Lactococcus Relative Abundance", color="Diet") +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) 

p + facet_grid(cols = vars(cluster)) +
  geom_line(data = b.df3, mapping = aes(x=time, y=avg_value), linewidth=1.5) #+ 
  # geom_point()

ggsave(paste(base_path, "Lactococcus_smooth-5_Diet-mean-and-clusters_nopoints.pdf"), height=10, width=23)

### Plot each cluster as a separate panel, colored by each metadata variable
# mdata_list = colnames(b.df)[1:3]
mdata_list = colnames(b.df)[1:2]

for (mdata in mdata_list) {
  p <- ggplot() + 
    geom_point(b.df, mapping=aes_string(x="time",y="value",group="ID",color=mdata)) + 
    geom_line(b.df, mapping=aes_string(x="time",y="value",group="ID",color=mdata), alpha=0.5) + 
    labs(x = "Time [Days]", y = "Lactococcus Relative Abundance", color=mdata) +
    scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
    theme_minimal(base_size=26) 
  
  p + facet_grid(cols = vars(cluster)) +
    geom_line(data = b.df3, mapping = aes(x=time, y=avg_value), linewidth=1.5) + 
    geom_point()
  
  ggsave(paste(base_path, "Lactococcus_bL5_", mdata, "-mean-and-clusters.pdf", sep=""), height=10, width=23)
}

mdata <- "Diet"
p <- ggplot() + 
  geom_point(b.df, mapping=aes_string(x="time",y="value",group="ID",color=mdata)) + 
  geom_line(b.df, mapping=aes_string(x="time",y="value",group="ID",color=mdata), alpha=0.5) + 
  labs(x = "Time [Days]", y = "Lactococcus Relative Abundance", color=mdata) +
  scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
  theme_minimal(base_size=26) 

p + facet_wrap(~cluster, scales = "free_y", ncol=4) +
  geom_line(data = b.df3, mapping = aes(x=time, y=avg_value), linewidth=1.5) + 
  geom_point()

ggsave(paste(base_path, "Lactococcus_bL5_", mdata, "-mean-and-clusters_yfree.pdf", sep=""), height=10, width=23)



##############################################################
### Plot other traj clusters that associate with metadata
##############################################################
# NEEDS TO BE UPDATED!!!!! 2023.10.30
# base_path <-"C:/Users/mathr/Documents/GitHub/babies_mg/outputs/allT_L5/otu_table_merged.0-12m.stool.child_L6_trajs_Lactococcus_trajs_lego-interp_sig_5_pc_None_num_clusters_5/"
# base_path <-"C:/Users/mathr/Documents/GitHub/babies_mg/outputs/allT_L5/otu_table_merged.0-12m.stool.child_L6_trajs_Morganella_trajs_lego-interp_sig_5_pc_None_num_clusters_9/"
# base_path <- "/sc/arion/projects/clemej05a/kevin/loclust/babies_mg/babies_mg_lego5_outputs/outputs/taxa_trajs_lego_interp/L6__Lactococcus_trajs_lego-interp_sig_4_pc_None_num_clusters_5/"
# infp_interp <- Sys.glob(file.path(base_path, "*_R.tsv"))
# print(infp_interp)
# # base_path <-"C:/Users/mathr/Documents/GitHub/babies_mg/outputs/allT_L5/otu_table_merged.0-12m.stool.child_L6_trajs_Parabacteroides_trajs_lego-interp_sig_5_pc_None_num_clusters_4/"
# # infp_interp <- paste(base_path, "Parabacteroides_trajs_lego-interp_sig_5_loclust_k4_fa_R.tsv", sep="")
# # base_path <-"C:/Users/mathr/Documents/GitHub/babies_mg/outputs/allT_L5/otu_table_merged.0-12m.stool.child_L6_trajs_Ruminococcus_trajs_lego-interp_sig_5_pc_None_num_clusters_4/"
# # infp_interp <- paste(base_path, "Ruminococcus_trajs_lego-interp_sig_5_loclust_k4_fa_R.tsv", sep="")


# b.df <- read.table(infp_interp, sep="\t", header=T)
# b.df$ID <- as.factor(b.df$ID)
# # b.df$abx_ever <- as.factor(b.df$abx_ever)
# # taxa.name = strsplit(strsplit(infp_interp, split = "otu_table_merged.0-12m.stool.child_L6_trajs_")[[1]][2], split = "_")[[1]][1] # Uses the folder name
# taxa.name = strsplit(strsplit(infp_interp, split = "L6__")[[1]][2], split = "_")[[1]][1] # Uses the folder name

# # Calculate the average trajectory per cluster
# b.df3 <- b.df %>%
#   group_by(cluster, time) %>%
#   summarize(avg_value=mean(value))

# # mdata_list = colnames(b.df)[3:9]
# mdata_list = colnames(b.df)[1:2]

# for (mdata in mdata_list) {
#   # m <- enquo(mdata)
#   p <- ggplot() + 
#     geom_point(b.df, mapping=aes_string(x='time',y='value',group='ID',color='mdata')) + 
#     geom_line(b.df, mapping=aes_string(x='time',y='value',group='ID',color='mdata'), alpha=0.5) +
#     labs(x = "Time [Days]", y = paste(taxa.name, "Relative Abundance"), color=mdata) +
#     scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
#     theme_minimal(base_size=26) 
  
#   p + facet_grid(cols = vars(cluster)) +
#     geom_line(data = b.df3, mapping = aes_string(x='time', y='avg_value'), linewidth=1.5) + 
#     geom_point()
  
#   ggsave(paste(base_path, taxa.name, "_bL5_", mdata, "-mean-and-clusters.png", sep=""), height=10, width=23)
#   ggsave(paste(base_path, taxa.name, "_bL5_", mdata, "-mean-and-clusters.pdf", sep=""), height=10, width=23)
# }

# # Show the average per Diet mode
# agg.tbl <- b.df %>% 
#   group_by(time, Diet) %>% 
#   summarise(v_mean = mean(value),
#             v_sd = sd(value),
#             v_ct = n(),
#             .groups = 'drop') 

# # Plot data
# agg.tbl <- na.omit(agg.tbl)

# plt <- ggplot() + 
#   # geom_point(b.df, mapping=aes(x=time,y=value,group=ID,color=Diet)) + 
#   geom_line(b.df, mapping=aes(x=time,y=value,group=ID,color=Diet), alpha=0.3, linewidth=0.5, show.legend=FALSE) + 
#   labs(x = "Time [Days]", y = "Bacteroides Relative Abundance", color="Diet Mode") +
#   scale_x_continuous(breaks=seq(0, 12, by=3), labels=seq(0, 12, by=3)) +
#   theme_minimal(base_size=26) 
#   # geom_point(b.df2, mapping=aes(x=time,y=avg_value, group=Diet),color="black")

# plt

# plt + geom_ribbon(data = agg.tbl, aes(x=time, ymin=v_mean-v_sd/sqrt(v_ct), ymax=v_mean+v_sd/sqrt(v_ct),
#                                       fill=Diet, group=Diet),
#                   alpha = 0.3, show.legend=FALSE) +
#   geom_line(b.df2, mapping=aes(x=time,y=avg_value, group=Diet, color=Diet),linewidth=2) +
#   theme(legend.position = c(0.8, 0.8), legend.box.background = element_rect(colour="white"))

# ggsave(paste(base_path, "Bacteroides_smooth-5_Diet-mean.png"), height=10, width=7.75)

# plt <- ggplot(data = agg.tbl, aes(x=time, y=v_mean, group=Diet, color=Diet)) +
#   geom_point() +
#   geom_line() +
#   xlab("Time (months)") + 
#   ylab("Relative Abundance")+
#   # scale_y_continuous(limits = c(0,1), breaks = seq(0, 1.03, by=0.25)) +
#   theme_minimal()
# plt

# plt + geom_ribbon(data = agg.tbl, aes(x=time, ymin=v_mean-v_sd/sqrt(v_ct), ymax=v_mean+v_sd/sqrt(v_ct),
#                                       fill=Diet, group=Diet),
#                   alpha = 0.3) 
#     + geom_line(b.df2, mapping=aes(x=time,y=avg_value, group=Diet, color=Diet),linewidth=2) 
#     + theme(legend.position = c(0.8, 0.8), legend.box.background = element_rect(colour="white"))


# ggsave(paste(base_path, taxa.name, "-mean-by-Diet.png", sep=""), 
#        width=15, height=13, units="cm", dpi=300)
# ggsave(paste(base_path, taxa.name, "-mean-by-Diet.pdf", sep=""), 
#        width=15, height=13, units="cm", dpi=300)
