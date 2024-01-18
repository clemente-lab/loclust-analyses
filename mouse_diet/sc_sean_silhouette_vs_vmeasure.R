# Imports

library(data.table)
library(dplyr)
library(ggplot2)
library(optparse)
library(tools)
library(tidyverse)
library(reshape2)

######################
## Calculate the mean value for all taxa and save output file with aggregate info and taxa name
# SEAN
base.path <- "C:/Users/mathr/Documents/GitHub/Sean/taxa_trajs/_R/"
# pre-allocate base table
df_relabd <- data.frame(matrix(ncol = 4, nrow = 0))
colnames(df_relabd) <- c("base.path", "taxa_fn", "taxa_name", "mean_rel_abd")

taxa_fn_list <- Sys.glob(file.path(base.path, "*_R.tsv"))

for (taxa_fn in taxa_fn_list){
  # Specific to sean filename construction
  taxa_name <- str_split(str_split(taxa_fn, 'L6_')[[1]][2],'_')[[1]][1]
  
  df.m <- read.table(paste(taxa_fn, sep=""), sep="\t", header=T)
  df.m$taxa_name <- taxa_name
  df.m <- drop_na(df.m)
  
  df.agg <- df.m %>%
    group_by(taxa_name) %>%
    mutate(mean_rel_abd=mean(value)) %>%
    ungroup()
  
  write.table(df.agg, paste(taxa_fn, sep=""), sep="\t", row.names=FALSE)
  
  mean_rel_abd <- df.agg$mean_rel_abd[1]
  df <- data.frame(t(c(base.path, taxa_fn, taxa_name, mean_rel_abd)))
  colnames(df) <- c("base.path", "taxa_fn", "taxa_name", "mean_rel_abd")
  
  df_relabd <- rbind(df_relabd, df)
}

write.table(df_relabd, paste(base.path, "mean_rel_abd_by_taxa.tsv", sep=""), sep="\t", row.names=FALSE)




#########################
base.path <- "C:/Users/mathr/Documents/GitHub/Sean/outputs/"
base.path.relabd <- "C:/Users/mathr/Documents/GitHub/Sean/taxa_trajs/_R/"

df.m <- read.table(paste(base.path, 'silhouette_v-measure_merge.tsv', sep=""), sep="\t", header=T)
df.m$taxa_name <- as.factor(df.m$taxa_name)
df.relabd <- read.table(paste(base.path.relabd, "mean_rel_abd_by_taxa.tsv", sep=""), sep="\t", header=T)
df.relabd$taxa_name <- as.factor(df.relabd$taxa_name)
df.m <- merge(x = df.m, y = df.relabd, by = "taxa_name")

tt <- df.m %>%
  group_by(taxa_name) %>%
  mutate(max_ss=max(silhouette_score)) %>%
  ungroup()

df.agg <- tt %>%
  filter(silhouette_score == max_ss)

# Sean taxa list generation
sean_taxa = c("Bacteroides", 
              "Carnobacterium",
              "Dorea", 
              "Enterococcus",
              "Jeotgalicoccus"
              )
## Create mask for taxa labels
df.agg <- transform(df.agg, taxa_mask=ifelse(taxa_name %in% sean_taxa, as.character(taxa_name), NA))

p <- ggplot(data=df.agg, mapping=aes(x=v_measure_score, y=silhouette_score)) + 
  geom_point(aes(size=mean_rel_abd)) + 
  geom_text(aes(label = taxa_mask), hjust = 0, nudge_x = 0.005, nudge_y = 0.001) + 
  scale_x_continuous(limits = c(0, max(df.agg$v_measure_score)*1.1)) +
  xlab("V-measure") + 
  ylab("Silhouette Score") + 
  labs(size="Mean Relative \n Abundance") +
  theme_light(base_size = 20)
p

ggsave(paste(base.path, 'vscore_vs_maxSilhouette.png', sep=""), height=10, width=12)
ggsave(paste(base.path, 'vscore_vs_maxSilhouette.svg', sep=""), height=10, width=12)

p <- ggplot(data=df.agg, mapping=aes(x=v_measure_score, y=silhouette_score)) + 
  geom_point(aes(size=mean_rel_abd)) + 
  geom_text(aes(label = taxa_name), hjust = 0, nudge_x = 0.005, nudge_y = 0.001) + 
  scale_x_continuous(limits = c(0, max(df.agg$v_measure_score)*1.2)) +
  xlab("V-measure") + 
  ylab("Silhouette Score") + 
  labs(size="Mean Relative \n Abundance") +
  theme_light(base_size = 20)
p

ggsave(paste(base.path, 'vscore_vs_maxSilhouette_alltaxalabeled.png', sep=""), height=10, width=12)
ggsave(paste(base.path, 'vscore_vs_maxSilhouette_alltaxalabeled.svg', sep=""), height=10, width=12)

p <- ggplot(data=df.agg, mapping=aes(x=v_measure_score, y=silhouette_score)) + 
  geom_point(aes(size=mean_rel_abd)) + 
  scale_x_continuous(limits = c(0, max(df.agg$v_measure_score)*1.2)) +
  xlab("V-measure") + 
  ylab("Silhouette Score") + 
  labs(size="Mean Relative \n Abundance") +
  theme_light(base_size = 20)
p

ggsave(paste(base.path, 'vscore_vs_maxSilhouette_notaxalabeled.png', sep=""), height=10, width=12)
ggsave(paste(base.path, 'vscore_vs_maxSilhouette_notaxalabeled.svg', sep=""), height=10, width=12)

p <- ggplot(data=df.agg, mapping=aes(x=v_measure_score, y=silhouette_score)) + 
  geom_point(aes(size=mean_rel_abd)) +
  geom_text(aes(label = taxa_mask), hjust = 0, nudge_x = 0.001, nudge_y = 0.001) +
  scale_x_continuous(limits = c(0, 1)) + 
  scale_y_continuous(limits = c(0, 1)) + 
  xlab("V-measure") + 
  ylab("Silhouette Score") + 
  labs(size="Mean Relative \n Abundance") +
  theme_light(base_size = 20)
p

ggsave(paste(base.path, 'vscore_vs_maxSilhouette_0to1.png', sep=""), height=10, width=12)
ggsave(paste(base.path, 'vscore_vs_maxSilhouette_0to1.svg', sep=""), height=10, width=12)

