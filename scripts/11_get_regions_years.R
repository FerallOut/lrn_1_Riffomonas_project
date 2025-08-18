#!/usr/bin/env Rscript
#' ---
#' title: '11_merge_lat_long'
#' date: "16.Aug.2025"
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
#| label: libraries_packages
#| output: false

## conda env: ./env_tar/smk_env1/

x <- c("tidyverse", "magrittr", "archive")

## Load libraries
invisible(lapply(x, library, character.only = TRUE))

#' 
#' 
#' # get stations and type of data 
#' 
#' - this info is in the "ghcnd-inventory.txt"
#' 
#' ## load inventory data 
## -----------------------------------------------------------------------------
"
Variable   Columns   Type
------------------------------
ID            1-11   Character
LATITUDE     13-20   Real
LONGITUDE    22-30   Real
ELEMENT      32-35   Character
FIRSTYEAR    37-40   Integer
LASTYEAR     42-45   Integer
------------------------------"

inventory_in <- read_fwf("data/ghcnd-inventory.txt",
         col_positions = fwf_cols(
           id = c(1, 11),
           latitude = c(13, 20),
           longitude = c(22, 30),
           element = c(32, 35),
           first_year = c(37, 40),
           last_year = c(42, 45) )) %T>%
  {head(.) %>% print()} %>% 
  ## filter to keep only rows with "PRCP" data type
  filter(element == "PRCP") %T>% 
  {head(.) %>% print()} %>% 
  ## same processing as above
  mutate(latitude = round(latitude, 0),
         longitude = round(longitude, 0) ) %>% 
  group_by(longitude, latitude) %>%
  mutate(region = cur_group_id()) %T>%
  {head(.) %>% print()} %>%
  select(-element) %>%  
  write_tsv("data/11_ghcnd_regions_years.tsv")

# Session information

sessionInfo()

