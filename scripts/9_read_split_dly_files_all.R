#!/usr/bin/env Rscript
#' ---
#' title: '9_read_dly_files_all'
#' date: "13.Aug.2025"
#' date-modified: "today"
#' date-format: "DD.MMM.YYYY"
#' execute:
#'   echo: true
#'   warning: false
#'   #message: false
#' 
#' from: markdown+emoji
#' categories: [snakemake, process_a_file_at_a_time]
#' toc: true
#' toc-title: "Index"
#' smooth-scroll: true
#' toc-depth: 3
#' #fig-dpi: 300
#' format:
#'   html:
#'     embed-resources: true
#'     df-print: kable
#'     #page-layout: full
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
      # record the current time before each chunk
      now <<- Sys.time()
    } else {
      # calculate the time difference after a chunk
      res <- difftime(Sys.time(), now, units = "auto")
      all_times[[options$label]] <<- res
      ## return a character string to show the time
      #paste("Time for the chunk", options$label, "to run:", res)
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
#' 
## -----------------------------------------------------------------------------
#| label: libraries_packages
#| output: false

## conda env: ./env_tar/smk_env1/

x <- c("tidyverse", "magrittr", 
       "archive")

## Load libraries
invisible(lapply(x, library, character.only = TRUE))

#' 
#' 
#' This analysis is focused on loading weather data correctly from fixed-width formatted file, not a regular format such as TSV or CSV.
#' 
#' It is an upgraded version of script 7, where we load split files from a tag.gz archive.
#' 
#' # extract correct parameters for loading
#' 
## -----------------------------------------------------------------------------
#| label: load_metadata

## what each column from the files means - find it in the "annotations/readme.txt"
# wget -nc https://www.ncei.noaa.gov/pub/data/ghcn/daily/readme.txt -P annotations/

lines <- "Variable   Columns   Type
ID            1-11   Character
YEAR         12-15   Integer
MONTH        16-17   Integer
ELEMENT      18-21   Character
VALUE1       22-26   Integer
MFLAG1       27-27   Character
QFLAG1       28-28   Character
SFLAG1       29-29   Character
VALUE2       30-34   Integer
MFLAG2       35-35   Character
QFLAG2       36-36   Character
SFLAG2       37-37   Character
  .           .          .
  .           .          .
  .           .          .
VALUE31    262-266   Integer
MFLAG31    267-267   Character
QFLAG31    268-268   Character
SFLAG31    269-269   Character"
con <- textConnection(lines)
meta.tsv <- read.delim(con)
close(con)
meta.tsv 

## loaded as dataframe with only 1 column
## split into 3 columns by multiple whitespaces and name colunms
meta.tsv <- meta.tsv %>%  
  separate(col = colnames(meta.tsv), into = c("variable", "columns", "type"), sep = "\\s+")

meta.tsv %>% head()

## the dots mean that you have a repeating pattern of 4 rows ("VALUE", "MFLAG", "QFLAG", "SFLAG") 
## that repeats 31 times (so you have the value of c(5,1,1,1,) repeating 31 times)
## so we can rebuild the "width" vector we need by separating it from the dataframe
meta.tsv %>% 
  slice(12:17) 

meta_with_widths <- meta.tsv %>% 
  filter(c(variable %in% c("ID", "YEAR", "MONTH", "ELEMENT", "VALUE1", "MFLAG1", "QFLAG1", "SFLAG1"))) %>% 
  ## split middle column and convert them to numeric
  separate(col = "columns", into = c("start", "end"), sep = "-", convert = T, remove = F) %>% 
  ## if variable has no name, set as "rep"
  ## calculate nr of spaces
  mutate(width = end - start +1) 

meta_with_widths %>% 
  head() 

## rebuild the "widths" vector - add the repeat 30 more times -> 31 repeats
widths <- meta_with_widths %>% 
  pull(width) %>% 
  append(., rep(tail(., n = 4), 30) )
head(widths)
length(widths)

## should have 269 rows
sum(widths)

## rebuild the name vector from the "variable" column - add the repeat 30 more times -> 31 repeats
variable_quad_repeats <- meta_with_widths %>% 
  pull(variable) %>% 
  tail(., n = 4) %>% 
  gsub(".{1}$", "", .)

headers <- meta_with_widths %>% 
  pull(variable) %>% 
  append(., paste0(variable_quad_repeats, 
                   rep(seq(2,31,1), each = 4 )   ) )

head(headers)
length(headers)



#| label: create_function_extraction

## create a function from previous code the apply it to all files
window <- 100 # days

fp1.process_fwf_files <- function(x) {
  print(paste0("*** processing file ", x, " ***") )
  data_in <- read_fwf(x,
                      col_positions = fwf_widths(widths, headers),   
                      na = c("NA", "-9999"),
                      col_types = cols(.default = col_character()),
                      col_select = c(ID, YEAR, MONTH, starts_with("VALUE")) ) %>%
    rename_all(tolower) %>%
    pivot_longer(cols = starts_with("value"),
                 names_to = "day",
                 values_to = "prcp") %>% 
    ## questionable; what exactly did they use NA for?
    ## missed recordings, bad sensor. What about months without 31 days?
    # drop_na() %>% 
    ## you could remove stations that register no precipitations
    ## BUT if the station is in a desert, this might be a loss of actual data
    # filter(prcp != 0) %>% 
    mutate(day = str_replace(day, "value", ""),
           date = ymd(paste0(year, "-", month, "-", day),
                      quiet = TRUE ),  ## necessary because we have removed the NA filter
           ## 'prcp' column has NA values 
           prcp = replace_na(prcp, "0"), ## to remove the NA from the PRCP col; PRCP is read as string, so put columns around the value 
           prcp = as.numeric(prcp)/100) %>% 
    ## get rid of the values that transform into NA as a result of quieting the messages from the "ymd" function
    drop_na() %>% # %T>% 
    #{head(.) %>% print()} %>%
    select(id, date, prcp) %>%
    
    ## convert to Julian date
    mutate(julian_day = yday(date), 
           ## the distance between today and each of the days in column "julian_day"
           ## days before today (AS JULIAN DAY of the year) are negative
           ## any date after today are positive
           diff_date = yday(today()) - julian_day,
           is_in_window = case_when(
                                   ## because it has to be in the past and smaller than window (positive!)
                                   diff_date < window & diff_date > 0 ~ TRUE,  
                                   ## special case for days at the beginning of the year, 
                                   ## where the window would spill into the year before
                                   yday(today()) < window & diff_date + 365 < window ~ TRUE, 
                                   diff_date > window ~ FALSE,
                                   diff_date < 0 ~ FALSE),
           ## get values that are within the same year; 
           ## if window catches dates from a different year, and your calculate precipitation per year, 
           ## then fix the year value by adding 1.
           year = year(date),
           year = if_else(diff_date < 0 & is_in_window, year + 1, year) ) %>%
    
      filter(is_in_window) %>% # %T>%
      #{head(.) %>% print()} %>%
      group_by(id, year) %>% 
      summarize(prcp = sum(prcp), .groups = "drop") 
    }

#' 
#' 
#' 
## -----------------------------------------------------------------------------
#| label: info_extraction_for_all_files

path_split_files <- list.files("data/temp", 
                               all.files = TRUE,  # because the split files start with a dot
                               full.names = TRUE,
                               no.. = TRUE)
path_split_files %>% head()

#' 
#' 
## -----------------------------------------------------------------------------
#| label: apply_to_all_files

results_no_duplicates <- map_dfr(path_split_files, fp1.process_fwf_files) %>% 
  #map(path_split_files, ~fp1.process_fwf_files(.x)) %>% list_rbind() %>%#  or bind_rows() 

  ## DO NOT DELETE
  ## because some files are split between 2 split archives, 
  ## it is possible to have multiple summarizations 
  ## that concern the same year
  group_by(id, year) %>% 
  summarize(prcp = sum(prcp), .groups = "drop") %>% 
  write_tsv("data/9_ghcnd_tidy.tsv.gz") %T>% 
  {head(.) %>% print()} %>%
  {dim(.) %>% print()} 

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

