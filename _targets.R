# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
# library(tarchetypes) # Load other packages as needed. # nolint

# Set target options:
tar_option_set(
  packages = c("jsonlite", "tidyverse", "RSQLite",
               "DBI", "tidymodels", "forecast", 
               "modeltime", "timetk", "lubridate",
               "sf", "plotly"), # packages that your targets need to run
  format = "rds" # default storage format
  # Set other options as needed.
)


# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multiprocess")

# tar_make_future() configuration (okay to leave alone):
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to allow use_targets() to configure tar_make_future() options.

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# source("other_functions.R") # Source other scripts as needed. # nolint

# Replace the target list below with your own:
list(
  tar_target(file, "output/list_provinces.csv", format = "file"),
  tar_target(provinces, read_data(file)),
  tar_target(climate_data, get_all_df(provinces)),
  tar_target(database_data, store_data_db(climate_data)),
  tar_target(one_province_df, subset_data(climate_data)),
  tar_target(trend_plots, trend_plot(one_province_df)),
  tar_target(split_df, split_data(one_province_df)),
  tar_target(trend_split_plots, trend_split_plot(split_df)),
  tar_target(models, modeling(split_df)),
  tar_target(model_accuracy_df, get_accuracy_df(models, split_df)),
  tar_target(model_accuracy_tbl, get_accuracy_tbl(model_accuracy_df)),
  tar_target(trend_test_plot, get_test_viz(model_accuracy_df,
                                           split_df, one_province_df)),
  tar_target(forecasts, get_forecast(model_accuracy_df, one_province_df)),
  tar_target(zwe_map_df, get_map_data(climate_data)),
  tar_target(zwe_map, get_map(zwe_map_df))
)
