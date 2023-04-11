## file name:
##
## description: Zim Climate functions
## 
## author: Ntandoyenkosi
##
## date: 




# packages ----------------------------------------------------------------

library(targets)
library(tidyverse)
#use_targets()

# List of provinces -------------------------------------------------------

list_provinces <- c("Bulawayo", "Harare", "Manicaland", "Mashonaland+Central",
                    "Mashonaland+East", "Mashonaland+West", "Masvingo",
                    "Matabeleland+North", "Matabeleland+South", "Midlands") %>% 
  as_tibble() %>% 
  rename(provinces = value)

write_csv(list_provinces, "output/list_provinces.csv")




# Inspect pipeline --------------------------------------------------------

tar_manifest(fields = all_of("command"))


# Visualization -----------------------------------------------------------

tar_visnetwork()


# Run pipeline ------------------------------------------------------------

tar_make()


# Output ------------------------------------------------------------------

tar_read(climate_data)
tar_read(trend_plots)
tar_read(trend_split_plots)
tar_read(model_accuracy_tbl)
tar_read(trend_test_plot)
tar_read(forecasts)
tar_read(zwe_map)

