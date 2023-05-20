#--------------------------------------------------------
# Analysis of EV charging stations from NREL AFDC
#
# https://developer.nrel.gov/docs/transportation/alt-fuel-stations-v1/all/
#
# Andy Pickering
# andypicke@gmail.com
#
#--------------------------------------------------------

# https://developer.nrel.gov/api/alt-fuel-stations/v1.json?api_key=DEMO_KEY&fuel_type=E85,ELEC&state=CA&limit=2

library(httr)
library(jsonlite)
library(ggplot2)
library(dplyr)


# API key is stored in my .Renviron file
api_key <- Sys.getenv("AFDC_KEY")

# base url for AFDC alternative fuel stations API
target <- "https://developer.nrel.gov/api/alt-fuel-stations/v1"

# Return data for all electric stations in Colorado
api_path <-".json?api_key=DEMO_KEY&fuel_type=ELEC&state=CO&limit=all"

complete_api_path <- paste0(target,api_path,'&api_key=',api_key)

dat <- httr::GET(url=complete_api_path)

dat2 <- jsonlite::fromJSON(httr::content(dat,"text"))

print(paste(dat2$total_results,'Stations Found'))

df <- dat2$fuel_stations

# filter out non-EV related fields
df <- df %>% select(-starts_with("lng")) %>% 
  select(-starts_with("cng")) %>%
  select(-starts_with("lpg")) %>%
  select(-starts_with("hy")) %>% 
  select(-starts_with("ng")) %>% 
  select(-starts_with("e85")) 


# change date field to date type and add year opened variable
df$open_date <- lubridate::ymd(df$open_date)
df$open_year <- lubridate::year(df$open_date)


#
# Break down by status code status_code
#
# E	= Available
# P	= Planned
# T =	Temporarily Unavailable

df %>% group_by(status_code) %>% count() %>% View()
df %>% ggplot(aes(status_code)) + geom_bar()


#
# Look at how many stations opened each year
#


df_opened <- df %>% group_by(open_year) %>% summarise(nopened=n())# %>% View()
df_opened %>% ggplot(aes(open_year, nopened)) + 
  geom_col()+
  xlab("Year Opened")+
  ylab("# Stations Opened")+
  ggtitle('EV Stations Opened in Colorado Each Year')
#






#
# Break down by connector types, ev_connector_type,ev_charging_level
df %>% group_by(ev_charging_level) %>% count() %>% View()


# Network type
df %>% count(ev_network) %>% arrange(desc(n)) %>% View()

df %>%  count(ev_network) %>% 
  mutate(ev_network=as.factor(ev_network)) %>% 
  mutate(ev_network=forcats::fct_reorder(ev_network,n)) %>% 
  ggplot(aes(ev_network,n))+
  geom_col()+
  coord_flip()

#
# How many stations are in each city?
#
df %>% group_by(city) %>% summarize(n()) %>% View()

df %>% ggplot(aes(access_code)) + geom_bar()
df %>% ggplot(aes(facility_type)) + geom_bar()


df %>% group_by(facility_type) %>% summarize(n=n()) %>% arrange(desc(n)) %>% View()

df %>% group_by(city) %>% summarize(n=n()) %>% arrange(desc(n)) %>% View()


