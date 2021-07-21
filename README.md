# World's Tallest Freestanding Structures

Data on the world's tallest buildings was scraped from the Wikipedia page: [List of tallest freestanding structures](https://en.wikipedia.org/wiki/List_of_tallest_freestanding_structures), manipulated and visualized in three plots to gain practice in R with web scraping, string processing, tidying, and data visualization. The rvest package was used for scraping; the stringr and tidyverse packages were used for parsing and tidying; and ggplot2, maps, mapdata, ggrepel, and gganimate were used for visualization. Code that produces these plots can be found [here](https://github.com/corrigan-r/Tallest_Freestanding_Structures/blob/main/tallest_structures_code.R). An R markdown file which produces an html document with similar content to this readme can also be found [here](https://github.com/corrigan-r/Tallest_Freestanding_Structures/blob/main/tallest_structures.Rmd). The .Rmd file sources the .R code and assumes the code is located in the same folder as the .Rmd.

The retrieved data set includes all freestanding structures taller than 350 m across the world. Three plots were made to highlight some of the features of the data. 
 The first plot is a time animation that presents the locations of the structures on year of completion.

![alt text](https://github.com/corrigan-r/Tallest_Freestanding_Structures/blob/main/animation_plot.gif)

The second plot illustrates three distinct time-geographic trends: 1) prior to 1980, all structures in the data set were located in North America and Europe; 2) almost all structures completed in the 1980s were in Central Asia and Russia; and 3) from 1990 onward, construction of new structures was strongly dominated by countries in East Asian and the Middle East.
![alt text](https://github.com/corrigan-r/Tallest_Freestanding_Structures/blob/main/era_plot.png)
The final plot shows the number of structures taller than 350 m by country.
![alt text](https://github.com/corrigan-r/Tallest_Freestanding_Structures/blob/main/density_plot.png)
