# #########################################
# R code extracts data for tall structures from Wikipedia 
# and creates plots to show some of the features of the data
# using ggplot2 and gganimate
# #########################################

library(tidyverse)
library(stringr)
library(rvest)
library(maps)
library(mapdata)
library(ggrepel)
library(gganimate)


# #########################################
# extract table info from wikipedia
# #########################################

h <- read_html("https://en.wikipedia.org/wiki/List_of_tallest_freestanding_structures") # read html code 

tab <- h %>% html_nodes("table") # select the table nodes

tall_structures <- tab[[3]] %>% html_table # table of tallest buildings is 3rd

names(tall_structures) <- str_replace_all(names(tall_structures), c("\\s" = ".")) # replace spaces with periods in column names


# #########################################
# convert coordinates to lat/lon in decimal
# #########################################

temp <- str_split(tall_structures$Coordinates, "/", simplify = TRUE)[,3] # after splitting by "/", 3rd column contains lat & lon in dec. form
coords <- as.data.frame((str_split(temp, ";", simplify = TRUE))) # ";" separates lat and lon
names(coords) <- c("Latitude", "Longitude")
tall_structures <- (bind_cols(tall_structures[,-c(4,11)], coords)) %>% 
  mutate(Latitude = as.numeric(Latitude), Longitude = as.numeric(Longitude)) %>% 
  rename(Height = "Pinnacle.height.(metres./.feet)") %>% 
  mutate(Height = parse_number(Height))


# ########################################
# create columns for time era & geographic region
# ########################################

tall_structures <- tall_structures %>% mutate(Era = case_when( # make column with 3 eras
  Year %in% c(1990:2020) ~ "1990 - 2020",
  Year %in% c(1980:1989) ~ "1980 - 1989",
  Year %in% c(1931:1979) ~ "1931 - 1979"))

tall_structures <- tall_structures %>% mutate(Region = case_when( # make column with geographic regions
  Country %in% c("Canada", "United States") ~ "North America",
  Country %in% c("Germany", "Romania", "Slovenia", "Spain", "Latvia", "Ukraine") ~ 
    "Europe",
  Country %in% c("China", "Japan", "Malaysia", "South Korea", "Sri Lanka", "Taiwan") ~ 
    "Asia",
  Country %in% c("Kazakhstan", "Uzbekistan") ~ "Central Asia",
  Country %in% c("Russia") ~ "North Asia",
  Country %in% c("Iran",  "Kuwait", "Saudi Arabia", "United Arab Emirates") ~
    "Middle East"))

save(tall_structures, file = "dat.RData") # save for use in .Rmd 


# ########################################
# plot maps with tall_structures data
# ########################################

world <- map_data("world") 

world$region[which(world$region=="USA")] <- "United States" # use same country name as scraped data

worldplot <- ggplot(world) + geom_polygon(aes(long, lat, group = group), 
  fill = "lightgrey", color = "white") + coord_fixed(xlim = c(-160, 165), 
  ylim = c(-50,75), ratio = 1.3) + theme_void()

anim <- worldplot + # create anim object for animation with frames based on Year
  geom_point(data = tall_structures, aes(Longitude, Latitude, size = Height), 
  color = "blue", alpha = 0.3) + labs(size = 'Height (m)') + 
  guides(size = guide_legend(reverse = T)) + 
  transition_manual(tall_structures$Year, cumulative = TRUE) + 
  ggtitle("{current_frame}") + 
  guides(color = guide_legend(override.aes = list(size = 11))) 
  
animation_plot <- animate(anim,  height = 500, width = 1000, res = 120, # animate the anim object
  renderer = gifski_renderer(), fps = 4)
  
# plot structures stratified by time era   
era_plot <- worldplot + geom_point(data = tall_structures, 
  aes(Longitude, Latitude, size = Height, color = Era), alpha = 0.5) + 
  labs(size = 'Height (m)') + guides(size = guide_legend(reverse = T)) + 
  guides(color = guide_legend(override.aes = list(size = 5))) 



# ##########################################
# plot heat map of countries by number of structures above 350 m
# ##########################################

# first create column for total number structures by country and join tall_structures dataframe with world map data
total_num_structures <- tall_structures %>% mutate(region = Country) %>% 
  group_by(region) %>% # count the structures per country
  summarize(total = n()) %>% mutate(info = paste(region, total, sep = " - "))

total_structures_map_dat <- total_num_structures %>% 
  inner_join(world, by = "region") # join with world data

region_labels_info <- total_structures_map_dat %>% group_by(region) %>% 
  summarize(info = first(info), long = mean(long), lat = mean(lat))

region_labels_info[which(region_labels_info$region == "United States"), 
  c("long", "lat")] <- # set Chicago as the location to label US (Alaska was throwing it off)
  tall_structures[first(which(tall_structures$City == "Chicago")), 
  c("Longitude", "Latitude")]

# now for the heat map plot
density_plot <- worldplot + geom_polygon(data = total_structures_map_dat, 
  aes(long, lat, group = group, fill = total),   color = "white") + 
  geom_text_repel(data = region_labels_info, aes(long, lat, label = info), 
  box.padding = .45) + 
  coord_fixed(xlim = c(-160, 165), ylim = c(-50,75), ratio = 1.3) +
  scale_fill_gradient(low = "papayawhip", high = "navajowhite3", trans = "log10", 
  name = "Structures \n above 350 m")
