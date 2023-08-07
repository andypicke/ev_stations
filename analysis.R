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


sc <- 300
if (sc !=200){
  print('Warning, possible error in API call')
  } else{
    print('Status code 200')
}

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
# Plot cumulative sum of stations opened over time
#
df_opened %>% ggplot(aes(open_year,cumsum(nopened)))+
  geom_line()+
  geom_point()+
  xlab("Year")+
  ylab("# Stations")+
  ggtitle("Cumulative sum of EV stations opened")





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
  coord_flip()+
  ylab("EV Network")+
  xlab("# stations")


# Owner type
df %>% count(owner_type_code) %>% arrange(desc(n)) %>% View()


# Facility type
df %>% count(facility_type) %>% arrange(desc(n)) %>% View()

#
df %>% count(restricted_access) %>% arrange(desc(n)) %>% View()



#
# How many stations are in each city?
#
df %>% group_by(city) %>% summarize(n()) %>% View()

df %>% ggplot(aes(access_code)) + geom_bar()
df %>% ggplot(aes(facility_type)) + geom_bar()


df %>% group_by(facility_type) %>% summarize(n=n()) %>% arrange(desc(n)) %>% View()

df %>% group_by(city) %>% summarize(n=n()) %>% arrange(desc(n)) %>% View()


#----------------------------


#<!-- ## Break down by connector types, ev_connector_type,ev_charging_level -->
  
#  <!-- ```{r } -->
  
#   <!-- #unique(unlist(df$ev_connector_types)) -->
#   
#   <!-- df4 <- df3 %>% rowwise() %>%  -->
#   
#   <!--   mutate(hasJ=if_else("J1772" %in% ev_connector_types,1,0)) %>%  -->
#   
#   <!--   mutate(hasJcomb=if_else("J1772COMBO" %in% ev_connector_types,1,0)) %>%  -->
#   
#   <!--   mutate(hasChad=if_else("CHADEMO" %in% ev_connector_types,1,0)) %>%  -->
#   
#   <!--   mutate(hasTesla=if_else("TESLA" %in% ev_connector_types,1,0)) %>%  -->
#   
#   <!--   mutate(hasNema520=if_else("NEMA520" %in% ev_connector_types,1,0)) %>%  -->
#   
#   <!--   mutate(hasNema515=if_else("NEMA515" %in% ev_connector_types,1,0)) %>%  -->
#   
#   <!--   mutate(hasNema1450=if_else("NEMA1450" %in% ev_connector_types,1,0)) -->
#   
#   <!--   View(df4) -->
#   
#   <!-- df4 %>% -->
#   
#   <!--   select_if(is.numeric) %>% -->
#   
#   <!--   map_dbl(sum)   -->
#   
#   <!-- tibble(connector_type=names(df5),n=df5) %>% View() -->
#   
#   <!-- ``` -->
#   
#   <!-- ```{r } -->
#   
#   <!-- #df %>% count(ev_network) %>% arrange(desc(n)) %>% View() -->
#   
#   <!-- df %>%  count(ev_network) %>%  -->
#   
#   <!--   mutate(ev_network=as.factor(ev_network)) %>%  -->
#   
#   <!--   mutate(ev_network=forcats::fct_reorder(ev_network,n)) %>%  -->
#   
#   <!--   ggplot(aes(ev_network,n))+ -->
#   
#   <!--   geom_col()+ -->
#   
#   <!--   coord_flip()+ -->
#   
#   <!--   xlab("EV Network")+ -->
#   
#   <!--   ylab("# stations") -->
#   
#   <!-- ``` -->
#   
#   ## Break down by city/county
#   
#   ```{r}
# 
# df %>% count(city) %>%
#   slice_max(order_by=n,n=15) %>%
#   mutate(city=forcats::fct_reorder(city,n)) %>%
#   ggplot(aes(city,n))+
#   geom_col()+
#   coord_flip()+
#   ggtitle("Number of EV Stations by City (Top 15)")+
#   xlab("City")+
#   ylab("Number of stations")
# 
# #  View()
# 
# ```
# 
# 
# 
# Cumulative sum of chargers added by level
# 
# ```{r}
# 
# ev_opened_level %>% ggplot()+
#   geom_line(aes(open_year,cumsum(n_DC)),col='black')+
#   geom_line(aes(open_year,cumsum(n_L2)),col='red')+
#   geom_line(aes(open_year,cumsum(n_L1)),col='green')
# 
# ```
# 
# ## Count \# individual plugs by level
# 
# ```{r }
# 
# n_lev1 <- sum(ev$ev_level1_evse_num,na.rm=TRUE)
# n_lev2 <- sum(ev$ev_level2_evse_num,na.rm=TRUE)
# n_dcfast <- sum(ev$ev_dc_fast_num, na.rm=TRUE)
# 
# plugs <- tibble(level=c('Level1','Level2','DC Fast'), n=c(n_lev1,n_lev2,n_dcfast))
# 
# plugs %>% ggplot(aes(level,n))+
#   geom_col()+
#   ggtitle("Total Number of Plugs By Charging Level")
# 
# ```
