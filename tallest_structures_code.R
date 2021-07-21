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
tall <- tab[[3]] %>% html_table # table of tallest buildings is 3rd
names(tall) <- str_replace_all(names(tall), c("\\s" = ".")) # replace spaces with periods in column names


# #########################################
# convert coordinates to lat/lon in decimal
# #########################################
temp <- str_split(tall$Coordinates, "/", simplify = TRUE)[,3] # after splitting by "/", 3rd column contains lat & lon in dec. form
coords <- as.data.frame((str_split(temp, ";", simplify = TRUE))) # ";" separates lat and lon
names(coords) <- c("Latitude", "Longitude")
tall <- (bind_cols(tall[,-c(4,11)], coords)) %>% 
  mutate(Latitude = as.numeric(Latitude), Longitude = as.numeric(Longitude)) %>% 
  rename(Height = "Pinnacle.height.(metres./.feet)") %>% mutate(Height = parse_number(Height))

# ########################################
# create column for time era
# ########################################
tall <- tall %>% mutate(Era = case_when( # make column with 3 eras
  Year %in% c(1990:2020) ~ "1990 - 2020",
  Year %in% c(1980:1989) ~ "1980 - 1989",
  Year %in% c(1931:1979) ~ "1931 - 1979"))

# ########################################
# create column for geographic region
# ########################################
tall <- tall %>% mutate(Region = case_when( # make column with geographic regions
  Country %in% c("Canada", "United States") ~ "North America",
  Country %in% c("Germany", "Romania", "Slovenia", "Spain", "Latvia", "Ukraine") ~ "Europe",
  Country %in% c("China", "Japan", "Malaysia", "South Korea", "Sri Lanka", "Taiwan") ~ "Asia",
  Country %in% c("Kazakhstan", "Uzbekistan") ~ "Central Asia",
  Country %in% c("Russia") ~ "North Asia",
  Country %in% c("Iran",  "Kuwait", "Saudi Arabia", "United Arab Emirates") ~ "Middle East"))


save("tall", file = "dat.RData")


# ########################################
# plot maps with tall data
# ########################################
world <- map_data("world") 

world$region[which(world$region=="USA")] <- "United States" # use same country name as scraped data

worldplot <- ggplot(world) + geom_polygon(aes(long, lat, group = group), 
  fill = "lightgrey", color = "white") + coord_fixed(xlim = c(-160, 165), 
  ylim = c(-50,75), ratio = 1.3) + theme_void()

anim <- worldplot + # animate worldplot
  geom_point(data = tall, aes(Longitude, Latitude, size = Height), 
  color = "blue", alpha = 0.3) + labs(size = 'Height (m)') + 
  guides(size = guide_legend(reverse = T)) + 
  transition_manual(tall$Year, cumulative = TRUE) + ggtitle("{current_frame}") + 
  guides(color = guide_legend(override.aes = list(size = 11))) 
  
animation_plot <- animate(anim,  height = 500, width = 1000, res = 120, 
  renderer = gifski_renderer(), fps = 4)

anim_save(filename = "animation_plot.gif", animation = last_animation())#, height = 5, width = 10, dpi = 600)
  
# plot structures stratified by time era   
era_plot <- worldplot + geom_point(data = tall, aes(Longitude, Latitude, size = Height, 
  color = Era), alpha = 0.5) + labs(size = 'Height (m)') + 
  guides(size = guide_legend(reverse = T)) + 
  guides(color = guide_legend(override.aes = list(size = 5))) 

ggsave("era_plot.png", height = 5, width = 10, device = "png", dpi = 600)

# ######################################################
# plot heat map of countries by number of structures above 350 m
# ######################################################
# first create column for total number structures by country and join tall dataframe with world map data
total_num_structures <- tall %>% mutate(region = Country) %>% group_by(region) %>% # count the structures per country
  summarize(total = n()) %>% mutate(info = paste(region, total, sep = " - "))

total_structures_map_dat <- total_num_structures %>% inner_join(world, by = "region") # join with world data

region_labels_info <- total_structures_map_dat %>% group_by(region) %>% 
  summarize(info = first(info), long = mean(long), lat = mean(lat))

region_labels_info[which(region_labels_info$region == "United States"), c("long", "lat")] <- # set Chicago as the location to label US (Alaska was throwing it off)
  tall[first(which(tall$City == "Chicago")), c("Longitude", "Latitude")]

# now for the heat map plot
density_plot <- worldplot + geom_polygon(data = total_structures_map_dat, aes(long, lat, group = group, fill = total), color = "white") + 
  geom_text_repel(data = region_labels_info, aes(long, lat, label = info), box.padding = .45) + 
  coord_fixed(xlim = c(-160, 165), ylim = c(-50,75), ratio = 1.3) +
  scale_fill_gradient(low = "papayawhip", high = "navajowhite3", trans = "log10", name = "Structures \n above 350 m")

density_plot

ggsave("era_plot.png", height = 5, width = 10, device = "png", dpi = 600)