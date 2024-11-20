##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                                                            ~~
##    INTERSECTING CENSUS METROPOLITAN AREAS WITH FORWARD SORTATION AREAS   ----
##                                                                            ~~
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(tidyverse)
library(magrittr)
library(sf)
library(rsdmx)
library(patchwork)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                                                                            --
##------------------- LOADING AND INTERSECTING SHAPEFILES-----------------------
##                                                                            --
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#  Shapefiles taken from                                                                                                                        
#  https://www12.statcan.gc.ca/census-recensement/2021/geo/sip-pis/boundary-limites/index2021-eng.cfm?year=21 
#  NOTE: Use digital boundary files, not cartographic boundary files.

intersect_FSAs_join_data <- function(
    chosen_CMA = "Edmonton",
    path_to_FSA_sf = "lfsa000a21a_e/lfsa000a21a_e.shp",
    path_to_CMA_sf = "lcma000a21a_e/lcma000a21a_e.shp",
    path_to_CMA_ids = "CMA_IDs.csv",
    intersect_threshold = 0.1
){
  CMA_ids <- read_csv(
    path_to_CMA_ids,
    col_types = "ccccccc"
  )
  
  chosen_CMA_DGUID <- CMA_ids %>% 
    filter(CMANAME == chosen_CMA) %>% 
    pull(DGUID) %>% 
    unique()
  
  chosen_CMA_prov <- CMA_ids %>% 
    filter(CMANAME == chosen_CMA) %>% 
    pull(PRUID) %>% 
    unique()
  
  if(
    (length(chosen_CMA_DGUID) != 1) |
    (length(chosen_CMA_prov) != 1)
    ){
    stop("ERROR: Non-unique geographic ID, check CMA IDs")
  }
  
  CMA_sf <- read_sf(path_to_CMA_sf) %>% 
    filter(DGUID == chosen_CMA_DGUID)
  gc()
  
  FSA_sf <- read_sf(path_to_FSA_sf) %>% 
    filter(PRUID == chosen_CMA_prov)
  gc()
  
  CMA_FSA_intersection <- st_intersection(CMA_sf, FSA_sf) %>% 
    mutate(
      intersect_area = as.numeric(st_area(.))/1e6,
      PercentIntersection = intersect_area / LANDAREA.1
      ) %>% 
    filter(PercentIntersection > intersect_threshold)
  
  rm(FSA_sf)
  gc()
  
  FSA_DGUIDs_for_intersection <- CMA_FSA_intersection %>% 
    as_tibble() %>% 
    pull(DGUID.1) %>% 
    unique()
  
  FSA_data_url <- paste(
    "https://api.statcan.gc.ca/census-recensement/profile/sdmx/rest/data/STC_CP,DF_FSA/A5.",
    paste0(FSA_DGUIDs_for_intersection, collapse = "+"),
    ".1.115.1",
    sep = ""
  )
  
  FSA_data <- readSDMX(FSA_data_url) %>% 
    as_tibble() %>% 
    select(
      ALT_GEO_CODE, obsValue
    ) %>% 
    drop_na(obsValue) %>% 
    rename(
      "FSA" = "ALT_GEO_CODE",
      "MedianIncome" = "obsValue"
    )
  
  intersected_FSAs_w_data <- left_join(
    CMA_FSA_intersection, FSA_data,
    by = c("CFSAUID" = "FSA")
  )
  
  return_list <- 
    list(
      CMA_shapefile = CMA_sf,
      FSA_shapefile = intersected_FSAs_w_data
    )
}

FSA_income_histogram <- function(
    output_from_intersect_function
){
  FSA_incomes_hist <- output_from_intersect_function[["FSA_shapefile"]] %>% 
    as_tibble() %>% 
    drop_na(MedianIncome) %>% 
    select(MedianIncome) %>% 
    ggplot(
      aes(
        x = MedianIncome,
        fill = after_stat(x)
        )
      ) + 
    geom_histogram(
      binwidth = 2500,
      boundary = 0
    ) +
    scale_fill_continuous(guide = "none") +
    scale_y_continuous(
      breaks = function(x) seq(ceiling(x[1]), floor(x[2]), by = 1),
      expand = expand_scale(mult = c(0, 0.05))
    ) + 
    labs(
      x = "Median Household After-tax Income",
      y = "Number of FSAs"
    ) + 
    theme_minimal() + 
    theme(panel.grid.minor = element_blank(),
          panel.grid.major.x = element_blank(),
          axis.text = element_text(size = 12),
          axis.title = element_text(size = 24))
}

FSA_income_map <- function(
    output_from_intersect_function
){
  FSA_sf <- output_from_intersect_function[["FSA_shapefile"]]
  CMA_sf <- output_from_intersect_function[["CMA_shapefile"]]
  
  output_map <- ggplot(data = FSA_sf) +
    geom_sf(
      aes(fill = MedianIncome),
      colour = "grey"
    ) + 
    geom_sf(
      data = CMA_sf,
      colour = "red",
      alpha = 0
    ) +
    coord_sf(crs = 4267) + 
    theme_void() + 
    scale_fill_continuous(guide = "none")
}

FSA_CMA_plot <- function(
    output_from_intersect_function
){
  CMA_name <- output_from_intersect_function[["CMA_shapefile"]] %>% 
    pull(CMANAME)
  
  out_plot <- 
    FSA_income_map(output_from_intersect_function) / 
    FSA_income_histogram(output_from_intersect_function) + 
    plot_layout(heights = c(2,1)) +
    plot_annotation(
      title = CMA_name,
      theme = theme(plot.title = element_text(size = 32))
    )
  
  return(out_plot)
}

FSA_CMA_df <- function(
    output_from_intersect_function
){
  output_from_intersect_function[["FSA_shapefile"]] %>% 
    as_tibble() %>% 
    select(CMANAME, CFSAUID, MedianIncome) %>% 
    rename(
      "CMA" = "CMANAME", "FSA" = "CFSAUID"
    )
}
