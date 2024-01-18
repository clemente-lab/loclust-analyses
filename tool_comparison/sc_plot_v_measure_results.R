# Plot Results of v-measure calculations
# Author: Hilary Monaco
# Contact email: htm24@cornell.edu

library(optparse)
library(tidyverse)
library(ggplot2)


### Define user inputs
option_list <- list(
  make_option(c("-i", "--in_dir"), 
              type="character",
              default='None',
              help="The directory to read input files from"),
  make_option(c("-o", "--out_dir"), 
              type="character", 
              default="None", 
              help="Directory to write output files"),
  make_option(c("-l", "--local_flag"),
              type="logical",
              default=FALSE,
              help="Directory to write output files"),
  make_option(c("-d", "--run_date"),
              help="date the analysis was run, used for naming files."),
  make_option(c("-b", "--tool_comp_dir"),
              help="tool_comp directory, full path")
)
opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)
base_dir <- opt$in_dir
out_dir <- opt$out_dir
run_date <- opt$run_date
tool_comp_dir <- opt$tool_comp_dir

if (out_dir == 'None'){
  out_dir <- './'
}
local_flag <- opt$local_flag


loc_outputs <- paste('/loclust_outputs/', run_date, '_all_v_measure_scores.tsv', sep="")
kml_outputs <- paste('kml_outputs/', run_date, '_all_v_measure_scores.tsv', sep="")
kmlShape_outputs <- paste('kmlShape_outputs/', run_date, '_all_v_measure_scores.tsv', sep="")
traj_outputs <- paste('traj_outputs/', run_date, '_all_v_measure_scores.tsv', sep="")
dtw_outputs <- paste('dtw_outputs/',  run_date, '_all_v_measure_scores.tsv', sep="")
dbaGak_outputs <- paste('dbaGak_outputs/',  run_date, '_all_v_measure_scores.tsv', sep="")
pic_outputs <- paste('pic_outputs/',  run_date, '_all_v_measure_scores.tsv', sep="")

vmeasure_file_list <- list(
    loc_outputs,
    kml_outputs,
    kmlShape_outputs,
    traj_outputs,
    dtw_outputs,
    dbaGak_outputs,
    pic_outputs

)

if (base_dir == 'None'){
  if (local_flag){
    base_dir <- 'C:/Users/mathr/Documents/GitHub/loclust_simulations/'
  }else{
    base_dir <- paste(tool_comp_dir, '/', sep="")
  }
}

# Load data
base_tibble <- tibble()
dfv <- base_tibble
for (vfile in vmeasure_file_list) {
  tool <- str_split(vfile, '_')[[1]][1]
  print(tool)
  tibble_OI <- read_tsv(paste(base_dir, vfile, sep=''))
  if (tool == "dtwClust"){
    tibble_OI$tool <- 'dtw'
  }
  dfv <- rbind(dfv, tibble_OI)
}
# Save output file
out_base_fn <- 'v-measure_results_loclust.kml.kmlShape.traj.dtw.dbaGak.pic.963'
out_fn_data <- paste(out_dir, paste(out_base_fn, '.tsv', sep=''), sep='')
write.table(dfv, 
            file=out_fn_data, 
            sep="\t", 
            row.names=FALSE)




##################################
######### MAKE FIGURE ############
##################################
base.dir <- 'C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/'
vmeasure_file_l <- paste0(base.dir, 'v-measure_results_loclust.kml.kmlShape.traj.dtw.dbagak.pic.963.tsv')

dfv <- read_tsv(vmeasure_file_l)
dfv$tool <- as.factor(dfv$tool)

for (n in c(3, 6, 9)){
  
  dfvg.n <- dfv %>% 
    filter(num_gen_functions == n) %>%
    group_by(noise_level, tool)
  
  dfvg.nm <- dfv %>% 
    filter(num_gen_functions == n) %>%
    group_by(noise_level, tool) %>%
    summarise(v_mean = mean(v_measure_score), .groups="keep")
  
  
  ggplot() +
    geom_point(data = dfvg.n, aes(x=noise_level, y=v_measure_score, colour=tool)) + 
    geom_line(data = dfvg.nm, aes(x=noise_level, y=v_mean, group=tool, color=tool)) +
    scale_y_continuous(limits = c(0,1), breaks = seq(0, 1, by=0.25)) + 
    theme_minimal() 
  
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_v1.png'), 
         width=12, height=7, units="cm", dpi=300)
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_v1.svg'), 
         width=12, height=7, units="cm", dpi=300)
  
  
  ######### 
  ##Figure
  #########
  agg.tbl <- dfvg.n %>% 
    group_by(noise_level, tool) %>% 
    summarise(v_mean = mean(v_measure_score),
              v_sd = sd(v_measure_score),
              v_ct = n(),
              .groups = 'drop') %>%
    filter(tool != 'traj_clust')
  
  agg.tbl$noise_level <- as.numeric(agg.tbl$noise_level)
  
  
  plt <- ggplot(data = agg.tbl, aes(x=noise_level, y=v_mean, group=tool, color=tool)) +
    geom_point() +
    geom_line() + 
    scale_y_continuous(limits = c(0,1), breaks = seq(0, 1.03, by=0.25)) +
    scale_color_manual(values=c("#e36899", "#ab190c", "#56B4E9", "#4df0ed", "#312da6", "#6432a8", "#E69F00")) +
    theme_minimal()
  plt
  
  plt <- plt + geom_ribbon(data = agg.tbl, aes(x=noise_level, ymin=v_mean-v_sd, ymax=v_mean+v_sd,
                                               fill=tool, group=tool),
                           alpha = 0.1) + 
    scale_fill_manual(values=c("#e36899", "#ab190c", "#56B4E9", "#4df0ed", "#312da6", "#6432a8", "#E69F00"))
  plt
  
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results.png'), 
         width=20, height=15, units="cm", dpi=300)
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results.svg'), 
         width=20, height=15, units="cm", dpi=300)
  
  
  ####### 
  # Figure, no traj, sd
  #######
  agg.tbl <- dfvg.n %>% 
    group_by(noise_level, tool) %>% 
    summarise(v_mean = mean(v_measure_score),
              v_sd = sd(v_measure_score),
              v_ct = n(),
              .groups = 'drop') %>%
    filter(tool != 'traj_clust')
  
  plt <- ggplot(data = agg.tbl, aes(x=noise_level, y=v_mean, group=tool, color=tool)) +
    scale_y_continuous(limits = c(0,1), breaks = seq(0, 1.03, by=0.25)) +
    scale_color_manual(values=c("#4df0ed", "#ab190c", "#e36899", "#E69F00", "#312da6", "#6432a8", "#56B4E9")) +
    theme_minimal()
  # plt
  
  plt <- plt + geom_ribbon(data = agg.tbl, aes(x=noise_level, ymin=v_mean-v_sd, ymax=v_mean+v_sd,
                                               fill=tool, group=tool),
                           alpha = 0.25) + 
    scale_fill_manual(values=c("#4df0ed", "#ab190c", "#e36899", "#E69F00", "#312da6", "#6432a8", "#56B4E9"))
  # plt
  
  plt <- plt + geom_line(data = agg.tbl, aes(x=noise_level, y=v_mean, group=tool, color=tool), size=2) +
    geom_point(size = 5) +
    theme_minimal(base_size=15)
  plt
  
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_no-traj.png'), 
         width=20, height=15, units="cm", dpi=300)
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_no-traj.svg'), 
         width=20, height=15, units="cm", dpi=300)
  
  
  
  ## Figure with standard error NO Traj
  #######
  agg.tbl <- dfvg.n %>% 
    group_by(noise_level, tool) %>% 
    summarise(v_mean = mean(v_measure_score),
              v_sd = sd(v_measure_score),
              v_ct = n(),
              .groups = 'drop') %>%
    mutate(tool = fct_rev(tool)) %>%
    filter(tool != 'traj_clust')
  
  plt <- ggplot(data = agg.tbl, aes(x=noise_level, y=v_mean, group=tool, color=tool)) +
    geom_point(size=2) +
    geom_line(linewidth=1) + 
    scale_x_continuous(limits = c(0,0.20), breaks = seq(0, 0.2, by=0.04)) +
    scale_y_continuous(limits = c(0,1), breaks = seq(0, 1.03, by=0.25)) +
    scale_color_manual(values=c("#E69F00", "#312da6", "#6432a8", "#56B4E9", "#4df0ed", "#e36899", "#ab190c")) +
    theme_minimal()
  plt
  
  plt <- plt + geom_ribbon(data = agg.tbl, aes(x=noise_level, ymin=v_mean-v_sd/sqrt(v_ct), ymax=v_mean+v_sd/sqrt(v_ct),
                                               fill=tool, group=tool),
                           alpha = 0.2) + 
    scale_fill_manual(values=c("#E69F00", "#312da6", "#6432a8", "#56B4E9", "#4df0ed", "#e36899", "#ab190c"))
  plt
  
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_SE_no-traj.png'), 
         width=20, height=15, units="cm", dpi=300)
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_SE_no-traj.svg'), 
         width=20, height=15, units="cm", dpi=300)
  
  
  
  ## Figure with standard error and Traj
  #######
  agg.tbl <- dfvg.n %>% 
    group_by(noise_level, tool) %>% 
    summarise(v_mean = mean(v_measure_score),
              v_sd = sd(v_measure_score),
              v_ct = n(),
              .groups = 'drop') %>%
    mutate(tool = fct_rev(tool))
  
  plt <- ggplot(data = agg.tbl, aes(x=noise_level, y=v_mean, group=tool, color=tool)) +
    geom_point(size=2) +
    geom_line(linewidth=1) + 
    scale_x_continuous(limits = c(0,0.20), breaks = seq(0, 0.2, by=0.04)) +
    scale_y_continuous(limits = c(0,1), breaks = seq(0, 1.03, by=0.25)) +
    scale_color_manual(values=c("#8A8888", "#E69F00", "#312da6", "#6432a8", "#56B4E9", "#4df0ed", "#e36899", "#ab190c")) +
    theme_minimal()
  plt
  
  plt <- plt + geom_ribbon(data = agg.tbl, aes(x=noise_level, ymin=v_mean-v_sd/sqrt(v_ct), ymax=v_mean+v_sd/sqrt(v_ct),
                                               fill=tool, group=tool),
                           alpha = 0.2) + 
    scale_fill_manual(values=c("#8A8888", "#E69F00", "#312da6", "#6432a8", "#56B4E9", "#4df0ed", "#e36899", "#ab190c"))
  plt
  
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_SE_traj.png'), 
         width=20, height=15, units="cm", dpi=300)
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_SE_traj.svg'), 
         width=20, height=15, units="cm", dpi=300)
  
  
  ## Figure with standard deviation and Traj
  #######
  agg.tbl$SDpos <- pmin(agg.tbl$v_mean+agg.tbl$v_sd, 1)
  agg.tbl$SDneg <- pmax(agg.tbl$v_mean-agg.tbl$v_sd, 0)
  
  plt <- ggplot(data = agg.tbl, aes(x=noise_level, y=v_mean, group=tool, color=tool)) +
    scale_x_continuous(limits = c(0,0.20), breaks = seq(0, 0.2, by=0.04)) +
    scale_y_continuous(limits = c(0,1), breaks = seq(0, 1.03, by=0.25)) +
    scale_color_manual(values=c("#8A8888", "#56B4E9", "#312da6", "#6432a8", "#E69F00", "#e36899", "#ab190c", "#4df0ed")) +
    theme_minimal()
  
  plt <- plt + geom_ribbon(data = agg.tbl, aes(x=noise_level, ymin=pmax(v_mean-v_sd, 0), ymax=pmin(v_mean+v_sd, 1),
                                               fill=tool, group=tool),
                           alpha = 0.2) + 
    scale_fill_manual(values=c("#8A8888", "#56B4E9", "#312da6", "#6432a8", "#E69F00", "#e36899", "#ab190c", "#4df0ed"))
  
  plt <- plt + geom_line(data = agg.tbl, aes(x=noise_level, y=v_mean, group=tool, color=tool), size=1) +
    geom_point(size = 5) +
    theme_minimal(base_size=15)
  plt
  
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_SD_traj.png'), 
         width=20, height=15, units="cm", dpi=300)
  ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/loclust_outputs/', n, 'loclust_v-results_SD_traj.svg'), 
         width=20, height=15, units="cm", dpi=300)
}

