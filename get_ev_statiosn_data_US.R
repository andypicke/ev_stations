

library(httr)
library(jsonlite)
library(dplyr)


# API key is stored in my .Renviron file
api_key <- Sys.getenv("AFDC_KEY")

# base url for AFDC alternative fuel stations API
target <- "https://developer.nrel.gov/api/alt-fuel-stations/v1"

# Return data for all electric stations in US
api_path <-".json?&fuel_type=ELEC&country=US&limit=all"

complete_api_path <- paste0(target,api_path,'&api_key=',api_key)

response <- httr::GET(url=complete_api_path)

if (response$status_code !=200){
 print(paste('Warning, API call returned error code',response$status_code))
}

response$status_code


saveRDS(response,paste0('./data/',Sys.Date(),'_Elec_Stations_US_All'))
response <- readRDS(paste0('./data/',Sys.Date(),'_Elec_Stations_US_All'))

ev_dat <- jsonlite::fromJSON(httr::content(response,"text"))

class(ev_dat)
names(ev_dat)

ev_dat$total_results

#In this case, there are `r ev_dat$station_counts$fuels$ELEC$stations$total` stations, and a total of `r ev_dat$station_counts$fuels$ELEC$total` chargers/plugs.

ev_dat$station_counts$fuels$ELEC

#Finally, the data we want to analyze is in the *fuel_stations* data frame.

ev <- ev_dat$fuel_stations


# filter out non-EV related fields
ev <- ev %>% select(-dplyr::starts_with("lng")) %>% 
  select(-starts_with("cng")) %>%
  select(-starts_with("lpg")) %>%
  select(-starts_with("hy")) %>% 
  select(-starts_with("ng")) %>% 
  select(-starts_with("e85")) %>% 
  select(-starts_with("bd")) %>% 
  select(-starts_with("rd")) %>% 
  filter(status_code=='E')


# change date field to date type and add a year opened variable
ev$open_date <- lubridate::ymd(ev$open_date)
ev$open_year <- lubridate::year(ev$open_date)

colnames(ev)
saveRDS(ev,paste0('./data/',Sys.Date(),'_Elec_Stations_US_All_df'))
ev <- readRDS(paste0('./data/',Sys.Date(),'_Elec_Stations_US_All_df'))
