#!/usr/bin/env Rscript
#' ---
#' title: '12_merge_weather_regions_data'
#' date: "18.Aug.2025"
#' date-modified: "today"
#' date-format: "DD.MMM.YYYY"
#' execute:
#'   echo: true
#'   warning: false
#'   #message: false
#' 
#' from: markdown+emoji
#' categories: [snakemake, rounding_numbers]
#' toc: true
#' toc-title: "Index"
#' smooth-scroll: true
#' toc-depth: 3
#' #fig-dpi: 300
#' format:
#'   html:
#'     embed-resources: true
#'     df-print: kable
#'     page-layout: full
#'     #code-overflow: wrap
#'     fig-width: 8
#'     fig-height: 6
#' code-line-numbers: true
#' number-sections: true
#' ## to wrap output
#' include-in-header:
#'   - text: |
#'       <style>
#'       .cell-output-stdout code {
#'         word-break: break-wor !important;
#'         white-space: pre-wrap !important;
#'       }
#'       </style>
#' ---
#' 
## -----------------------------------------------------------------------------
#| label: setup
#| echo: false

all_times <- list()  # store the time for each chunk

knitr::knit_hooks$set(time_it = local({
  now <- NULL
  function(before, options) {
    if (before) {
      now <<- Sys.time()
    } else {
      res <- difftime(Sys.time(), now, units = "mins")
      all_times[[options$label]] <<- res
    }
  }
})
)

knitr::opts_chunk$set(
  # don't use, has issues with a lot of symbols
  # https://yihui.org/formatr/
  #tidy = TRUE,
  time_it = TRUE,
  fig.align = 'center',
  highlight = TRUE, 
  cache.lazy = FALSE,
  #comment = "#>",
  collapse = TRUE
)

## to crop the empty white space around the pdf plots
knitr::knit_hooks$set(crop = knitr::hook_pdfcrop)

#' 
## -----------------------------------------------------------------------------
#| label: libraries_packages
#| output: false

## conda env: ./env_tar/smk_env1/

x <- c("tidyverse", "magrittr", "lubridate")

## Load libraries
invisible(lapply(x, library, character.only = TRUE))

#' 
#' 
#' # load data
#' 
## -----------------------------------------------------------------------------

prcp_data <- read_tsv("data/9_ghcnd_tidy.tsv.gz") %T>% 
  {head(.) %>% print()} %T>%
  {dim(.) %>% print()} 

region_data <- read_tsv("data/11_ghcnd_regions_years.tsv") %T>% 
  {head(.) %>% print()} %T>%
  {dim(.) %>% print()} 

#' 
#' 
#' # Summarize mean precipitation by region and year
#' 
#' Remove partial data (where the year is not whole)
#' 
## -----------------------------------------------------------------------------
## remove regions where you have partial data BUT keep the last year you have on record

## what is the last year?
last_yr <- inner_join(prcp_data, 
           region_data,
           by = "id") %>%  
  arrange(desc(year)) %>% 
  slice_head(n=1) %>% 
  pull(year) 


lat_long_prcp <- inner_join(prcp_data, 
           region_data,
           by = "id") %T>% 
  {head(.) %>% print()} %T>%
  {dim(.) %>% print()} %>% 
  filter( (year != first_year & year != last_year) | year == last_yr) %>% 
  ## group by region; add the rest of the variables to keep them
  ## region is not really necessary in this analysis
  #group_by(region, latitude, longitude, year) %>% 
  group_by(latitude, longitude, year) %>% 
  summarize(mean_prcp = mean(prcp),
            .groups = "drop"
            ) %T>%
  {head(.) %>% print()} %T>%
  dim() 

#' 
#' 
#' # calculate the Z-score statistics for each region for 2025
#' 
#' You need the mean and stdev, and to make sure to keep all the regions with precipitation data for 2025. The Z-score is the number of stdevs away from the mean that your data represents.
#' 
#' ## get 2025 (last year's) precipitation and that of all years
#' 
## -----------------------------------------------------------------------------
## get regions (lat + long) that have data for 2025
this_year <- lat_long_prcp %>%
  filter(year == 2025) %>%
  select(-year)
       by = c("latitude", "longitude")

#' 
#' ## get Z-score
#' 
## -----------------------------------------------------------------------------
## get z-score for last year compared to data from at least 50 years of precipitation          
zscore_data <- lat_long_prcp %>% 
  group_by(latitude, longitude) %>% 
  mutate( z_score = (mean_prcp - mean(mean_prcp)) / sd(mean_prcp),
          n = n() ) %>% 
  ungroup() %>% 
  filter(n >=50 & year == last_yr) %>% 
  select(-n, -year, - mean_prcp) %T>% 
  {head(.) %>% print()} %T>%
  {dim(.) %>% print()}

#' 
#' # plot
#' 
## -----------------------------------------------------------------------------
zscore_data %>% 
  ggplot(aes(x = longitude, 
             y = latitude, 
             fill = z_score)) +
  #geom_raster()
  geom_tile() +
  ## make sure the spacing on x and y is the same
  coord_fixed() +
  ## change fill colors - divergent color scale
  ## this turns too washed out:
  #scale_fill_gradient2(low = "blue", mid = "white", high = "red",
  #                     midpoint = 0)
  ## turn to ColorBrewer2.org -> choose color scheme -> copy the color codes
  ## same washed out
  scale_fill_gradient2(low = "#d8b365", mid = "#f5f5f5", high = "#5ab4ac",
                       midpoint = 0) +
  ## change background color
  theme(plot.background = element_rect(fill = "black"),
        panel.background = element_rect(fill = "black"), 
        panel.grid = element_blank())

  ## color range - still not a lot of dynamic range

#' 
#' 
## -----------------------------------------------------------------------------
## change the values for z-scale:
zscore_data %>% 
    ## this is necessary for the next step in determining how to change the dynamic range
  summarize(min = min(z_score), max = max(z_score))

end <- format(today(), "%B %d, %Y")
end
start <- format(today() - 30, "%B %d, %Y")
start

#' 
#' 
## -----------------------------------------------------------------------------
## set limits to the color scale:
## all values <= -2 and all values >=2 
zscore_data %>% 
  mutate(z_score = ifelse(z_score > 2, 2, z_score),
         z_score = ifelse(z_score < -2, -2, z_score)) %>% 
  ggplot(aes(x = longitude, 
             y = latitude, 
             fill = z_score)) +
  #geom_raster()
  geom_tile() +
  ## make sure the spacing on x and y is the same
  coord_fixed() +
  ## change fill colors - divergent color scale
  ## this turns too washed out:
  #scale_fill_gradient2(low = "blue", mid = "white", high = "red",
  #                     midpoint = 0)
  ## turn to ColorBrewer2.org -> choose color scheme -> copy the color codes
  ## same washed out
  scale_fill_gradient2(low = "#d8b365", mid = "#f5f5f5", high = "#5ab4ac",
                       midpoint = 0,
                       breaks = c(-2, -1, 0, 1, 2),
                       labels = c("<-2", "-1", "0", "1", ">2")) +
  ## change background color
  theme(plot.background = element_rect(fill = "black",
                                       color = "black"),
        panel.background = element_rect(fill = "black"), 
        plot.title = element_text(color = "#f5f5f5",
                                  size = 18),
        plot.subtitle = element_text(color = "#f5f5f5"),
        plot.caption = element_text(color = "#f5f5f5"),
        
        panel.grid = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.background = element_blank(),
        legend.text = element_text(color = "#f5f5f5"),
        ## move legend
        legend.position = c(0.1, 0.3),
        legend.direction = "horizontal",
        legend.key.height = unit(0.25, "cm") ) +
  labs(title = paste("Amount of precipitation for ", start, " to ", end),
       subtitle = "standardized z-scores for at least the past 50 years",
       caption = "Precipitation data collected from GHCN daily data at NOAA") 

ggsave("results/5_world_drought.png", 
       width = 8,
       height = 4)

#' 
#' 
#' 
#' 
#' # Save time
#' 
## -----------------------------------------------------------------------------
#| label: save_times

t(as.data.frame(all_times))

#' 
#' # Session information
#' 
## -----------------------------------------------------------------------------
#| label: sessionInfo

sessionInfo()

