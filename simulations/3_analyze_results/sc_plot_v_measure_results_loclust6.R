# Plot Results of v-measure calculations
# Author: Hilary Monaco
# Contact email: htm24@cornell.edu

library(tidyverse)
library(ggplot2)

vmeasure_file_l <- 'C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/22-05-09_all_v_measure_scores.tsv'
dfv <- read_tsv(vmeasure_file_l)

dfvg.6 <- dfv %>% 
  filter(num_gen_functions == 6) %>%
  group_by(noise_level, tool)

dfvg.6m <- dfv %>% 
  filter(num_gen_functions == 6) %>%
  group_by(noise_level, tool) %>%
  summarise(v_mean = mean(v_measure_score), .groups="keep")


ggplot() +
  geom_point(data = dfvg.6, aes(x=noise_level, y=v_measure_score, colour=tool)) + 
  geom_line(data = dfvg.6m, aes(x=noise_level, y=v_mean, group=tool, color=tool)) +
  scale_y_continuous(limits = c(0,1), breaks = seq(0, 1, by=0.25)) + 
  theme_minimal() 
  
ggsave('loclust_v-results_v1.png', width=12, height=7, units="cm", dpi=300)
