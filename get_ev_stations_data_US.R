#
# Download EV charging station data from AFDC API for all US stations
#
#
#
#


library(httr)
library(jsonlite)
library(dplyr)


# API key is stored in my .Renviron file
api_key <- Sys.getenv("AFDC_KEY")

# base url for AFDC alternative fuel stations API
target <- "https://developer.nrel.gov/api/alt-fuel-stations/v1"

# Return data for all electric stations in US
api_path <- ".json?&fuel_type=ELEC&country=US&limit=all"

complete_api_path <- paste0(target, api_path, "&api_key=", api_key)

response <- httr::GET(url = complete_api_path)

if (response$status_code != 200) {
  print(paste("Warning, API call returned error code", response$status_code))
}

response$status_code


saveRDS(response, paste0("./data/", Sys.Date(), "_Elec_Stations_US_All"))
response <- readRDS(paste0("./data/", Sys.Date(), "_Elec_Stations_US_All"))

ev_dat <- jsonlite::fromJSON(httr::content(response, "text"))

class(ev_dat)
names(ev_dat)

ev_dat$total_results

print( paste("Data contains", ev_dat$station_counts$fuels$ELEC$stations$total, "stations"))
print( paste("Data contains", ev_dat$station_counts$fuels$ELEC$total, "chargers/plugs"))

ev_dat$station_counts$fuels$ELEC

# Finally, the data we want to analyze is in the *fuel_stations* data frame.

ev <- ev_dat$fuel_stations


# filter out non-EV related fields
ev <- ev %>%
  select(-dplyr::starts_with("lng")) %>%
  select(-starts_with("cng")) %>%
  select(-starts_with("lpg")) %>%
  select(-starts_with("hy")) %>%
  select(-starts_with("ng")) %>%
  select(-starts_with("e85")) %>%
  select(-starts_with("bd")) %>%
  select(-starts_with("rd")) %>%
  filter(status_code == "E")


# change date field to date type and add a year opened variable
ev$open_date <- lubridate::ymd(ev$open_date)
ev$open_year <- lubridate::year(ev$open_date)

#colnames(ev)
saveRDS(ev, paste0("./data/", Sys.Date(), "_Elec_Stations_US_All_df"))




# ------------ further processing
ev <- readRDS(paste0("./data/", Sys.Date(), "_Elec_Stations_US_All_df"))


# drop some extra columns (can always join back by station id later if needed)
# also add columns indicating charging levels station has
ev2 <- ev %>% 
  select(access_code, id, open_date, state:ev_network, open_year) %>% 
  mutate(has_L1 = ifelse(!is.na(ev_level1_evse_num) & ev_level1_evse_num > 0, TRUE, FALSE),
         has_L2 = ifelse(!is.na(ev_level2_evse_num) & ev_level2_evse_num > 0, TRUE, FALSE),
         has_DC = ifelse(!is.na(ev_dc_fast_num) & ev_dc_fast_num > 0, TRUE, FALSE))


# Add indicators for connector types station has
# Do we need to use 'rowwise' for this?
unique(unlist(ev2$ev_connector_types))

ev3 <- ev2 %>%
  rowwise() %>%
  mutate(has_J1772 = if_else("J1772" %in% ev_connector_types, 1, 0)) %>%
  mutate(has_J1772COMBO = if_else("J1772COMBO" %in% ev_connector_types, 1, 0)) %>%
  mutate(has_CHADEMO = if_else("CHADEMO" %in% ev_connector_types, 1, 0)) %>%
  mutate(has_TESLA = if_else("TESLA" %in% ev_connector_types, 1, 0)) %>%
  mutate(has_NEMA520 = if_else("NEMA520" %in% ev_connector_types, 1, 0)) %>%
  mutate(has_NEMA515 = if_else("NEMA515" %in% ev_connector_types, 1, 0)) %>%
  mutate(has_NEMA1450 = if_else("NEMA1450" %in% ev_connector_types, 1, 0))

View(head(ev3,50)) 


saveRDS(ev3, paste0("./data/", Sys.Date(), "_Elec_Stations_US_All_df_levels_connectors"))

