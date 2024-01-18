# Plot function types (no smoothing, no noise)
library(data.table)
library(dplyr)
library(tidyverse)

base.path <- "C:/Users/mathr/Documents/GitHub/loclust_simulations/sm_noise_investigation/func_types_diagram/"
f.fp <- paste0(base.path, '9func_noise_0.0_R.tsv')


df.orig <- read.table(f.fp, sep='\t', header=T)


df <- df.orig

p <- ggplot(df, aes(x=time, y=value, color=func)) + 
            geom_line() + 
            scale_x_continuous(limits = c(0, 20)) + 
            xlab("Time") + 
            ylab("Value")
p <- p + facet_wrap(vars(func), nrow = 3, ncol = 3, scales = "free", labeller = label_both) + 
            theme_light(base_size = 18)
p
ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/sm_noise_investigation/func_types_diagram/', 'funcs.png'), 
       width=24, height=34, units="cm", dpi=300)
ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/sm_noise_investigation/func_types_diagram/', 'funcs.svg'), 
       width=24, height=24, units="cm", dpi=300)


### 0.2 noise
f.fp.n <- paste0(base.path, '9func_noise_0.2_R.tsv')
df.n.0.2 <- read.table(f.fp.n, sep='\t', header=T)

df_summary <- df.n.0.2 %>% 
  drop_na() %>%
  group_by(time, func) %>% 
  summarise(v_mean = mean(value),
            v_sd = sd(value),
            na.rm = TRUE,
            .groups = 'drop') 

p <- ggplot(df_summary, aes(x=time, y=v_mean, color=func)) + 
            geom_line() + 
            scale_x_continuous(limits = c(0, 20)) + 
            xlab("Time") + 
            ylab("Value")
p <- p + facet_wrap(vars(func), nrow = 3, ncol = 3, scales = "free", labeller = label_both) + 
          theme_light(base_size = 18)
p

ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/sm_noise_investigation/func_types_diagram/', 'funcs_noise0.2.png'), 
       width=24, height=34, units="cm", dpi=300)
ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/sm_noise_investigation/func_types_diagram/', 'funcs_noise0.2.svg'), 
       width=24, height=24, units="cm", dpi=300)

# Plot a few tan trajs to show noise

df.tan <- df.n.0.2 %>%
  filter(func == 'tan') %>%
  filter(ID %in% unique(df.tan$ID)[1:20])
df.tan.mean <- df_summary %>%
  filter(func == 'tan')
df.tan.mean.20 <- df.tan %>%
  group_by(time) %>%
  summarise(v_mean = mean(value),
            v_sd = sd(value),
            ID = any(ID),
            na.rm = TRUE,
            .groups = 'drop')
p <- ggplot(df.tan, aes(x=time, y=value, group=ID, color=as.factor(ID))) +
            geom_line() + 
            scale_x_continuous(limits = c(0, 20)) + 
            xlab("Time") + 
            ylab("Value") +
            geom_line(df.tan.mean.20, mapping = aes(x=time, y=v_mean), color='black', linewidth=1.5)
p

ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/sm_noise_investigation/func_types_diagram/', 'funcs_noise0.2_20.png'), 
       width=24, height=34, units="cm", dpi=300)
ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/sm_noise_investigation/func_types_diagram/', 'funcs_noise0.2_20.svg'), 
       width=24, height=24, units="cm", dpi=300)

# Plot a few sin trajs to show noise

df.sin <- df.n.0.2 %>%
  filter(func == "sin")
df.sin <- df.sin %>%
  filter(ID %in% unique(df.sin$ID)[1:20])
df.sin.mean.20 <- df.sin %>%
  group_by(time) %>%
  summarise(v_mean = mean(value),
            v_sd = sd(value),
            ID = any(ID),
            na.rm = TRUE,
            .groups = 'drop')
p <- ggplot(df.sin, aes(x=time, y=value, group=ID, color=as.factor(ID))) +
  geom_line() + 
  scale_x_continuous(limits = c(0, 20)) + 
  xlab("Time") + 
  ylab("Value") +
  geom_line(df.sin.mean.20, mapping = aes(x=time, y=v_mean), color='black', linewidth=1.5)
p

ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/sm_noise_investigation/func_types_diagram/', 'funcs_noise0.2_20.png'), 
       width=24, height=34, units="cm", dpi=300)
ggsave(paste0('C:/Users/mathr/Documents/GitHub/loclust_simulations/sm_noise_investigation/func_types_diagram/', 'funcs_noise0.2_20.svg'), 
       width=24, height=24, units="cm", dpi=300)
