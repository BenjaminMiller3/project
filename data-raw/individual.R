## code to prepare `individual` dataset goes here
## Setup ---- 
library(dplyr)
source(here::here("R", "geolocate.R"))
## Combine individual tables ----
## Create paths to inputs
raw_data_path <- here::here("data-raw", 
                            "wood-survey-data-master")

individual_paths <- fs::dir_ls(
  fs::path(raw_data_path, "individual") 
  )


usethis::use_data(individual, overwrite = TRUE)

# Combine NEON data tables ----
# read in additional tables

## Join map and plot info

maptag<- readr::read_csv(
  fs::path(raw_data_path, "vst_mappingandtagging.csv")
) %>%
  select(-eventID) #to remove a col

perplot <-readr::read_csv(
  fs::path(raw_data_path, "vst_perplotperyear.csv"),
  show_col_types = FALSE
) %>%
  select(-eventID)

# Left join tables to individual

individual %<>%
  left_join(maptag, by = "individualID",
            suffix = c("", "_map")) %>%
  left_join(perplot, by = "plotID",
            suffix = c("", "_ppl")) %>%
  assertr::assert(
    assertr::not_na, stemDistance, stemAzimuth, pointID, decimalLatitude, decimalLongitude)


# Geolocate individuals ----
individual <- individual %>% mutate(
  stemLat = get_stem_location(
    decimalLongitude, decimalLatitude, 
    stemAzimuth, stemDistance
  )$lat,
  stemLong = get_stem_location(
    decimalLongitude, decimalLatitude, 
    stemAzimuth, stemDistance
)$lon
) %>% 
  janitor::clean_names()

fs::dir_create("data")

individual %>%
  readr::write_csv(
    here::here("data", "individual.csv")
  )
