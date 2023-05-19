

#
# https://developer.nrel.gov/api/alt-fuel-stations/v1.json?api_key=DEMO_KEY&fuel_type=E85,ELEC&state=CA&limit=2


library(httr)
library(jsonlite)
library(ggplot2)

# API key stored in .Renviron
api_key <- Sys.getenv("AFDC_KEY")

# base url for AFDC API
#target <- "https://api.eia.gov/v2/"
target <- "https://developer.nrel.gov/api/alt-fuel-stations/v1"

#.json?api_key=DEMO_KEY&fuel_type=E85,ELEC&state=CA&limit=2

api_path <-".json?api_key=DEMO_KEY&fuel_type=ELEC&state=CO&limit=all"

complete_api_path <- paste0(target,api_path,'&api_key=',api_key)

dat <- httr::GET(url=complete_api_path)

dat2 <- jsonlite::fromJSON(httr::content(dat,"text"))

df <- dat2$fuel_stations

df$open_date <- lubridate::ymd(df$open_date)
df$open_year <- lubridate::year(df$open_date)

library(dplyr)
library(ggplot2)
df_opened <- df %>% group_by(open_year) %>% summarise(nopened=n())# %>% View()
df_opened %>% ggplot(aes(open_year, nopened)) + 
  geom_col()+
  xlab("Year Opened")+
  ylab("# Stations Opened")+
  ggtitle('# Stations Opened in Colorado Each Year')
#

df %>% group_by(city) %>% summarize(n()) %>% View()

library(ggplot2)
df %>% ggplot(aes(access_code)) + geom_bar()
df %>% ggplot(aes(facility_type)) + geom_bar()


df %>% group_by(facility_type) %>% summarize(n=n()) %>% arrange(desc(n)) %>% View()

df %>% group_by(city) %>% summarize(n=n()) %>% arrange(desc(n)) %>% View()

library(leaflet)