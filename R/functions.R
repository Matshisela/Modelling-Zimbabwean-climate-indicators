## file name:
##
## description: Functions
## 
## author: Ntandoyenkosi
##
## date: 


# read_data ---------------------------------------------------------------

read_data <- function(file){
  read_csv(file, col_types = cols()) 
}


# location ----------------------------------------------------------------

get_location <- function(x){
  
  url <- glue::glue("https://nominatim.openstreetmap.org/search?q={x}&format=json")
  
  # Retrieve search results as JSON
  results <- jsonlite::fromJSON(url)
  
  # Extract latitude and longitude from first result
  lat <- results$lat[1]
  lon <- results$lon[1]
  
  # save as a tibble
  tibble(
    lat, lon
  ) 
  
}



# weather data ------------------------------------------------------------


get_data <- function(lat, lon){
  
  start = "1992-01-01"
  end = "2022-12-31"
  
  # Website where we getting the data from
  url = glue::glue("https://archive-api.open-meteo.com/v1/archive?latitude={lat}&longitude={lon}&start_date={start}&end_date={end}&daily=temperature_2m_max,temperature_2m_min,temperature_2m_mean,precipitation_sum,rain_sum,precipitation_hours&timezone=Africa%2FCairo")
  
  # Get the data from the JSON file
  response <- jsonlite::fromJSON(url) 
  
  # get the variables
  date <- response$daily$time
  max_temperature <- response$daily$temperature_2m_max
  mean_temperature <- response$daily$temperature_2m_mean
  min_temperature <- response$daily$temperature_2m_min
  precipitation_sum <- response$daily$precipitation_sum
  rain_sum <- response$daily$rain_sum
  precipitation_hours <- response$daily$precipitation_hours
  
  # Save as a tibble
  tibble(
    date, max_temperature, mean_temperature, min_temperature, precipitation_sum,
    rain_sum, precipitation_hours
  )
  
}




# climate data -------------------------------------------------------


get_all_df <- function(province){
  df <- province %>% 
    as_tibble() %>% 
    mutate(loc_stat = map(.x = provinces, 
                          .f = ~get_location(.x))) %>% 
    unnest(loc_stat) %>% 
    mutate(data = pmap(list(lat, lon), get_data)) %>% 
    unnest(data) %>% 
    mutate(date = as.Date(date)) %>% 
    mutate(day = wday(date, label = T),
           year = year(date),
           week = week(date))
  
  # Save data
  saveRDS(df, "output/climate_data.rds")
  
  tibble(df)
}
  
  

# store in a database -----------------------------------------------------

store_data_db <- function(data){
  # create a connection to the database
  con <- dbConnect(RSQLite::SQLite(), 
                   "output/climate_data.db")
  
  # create a table in the database and insert the data
  dbWriteTable(con, 
               "zimbabwe_table", 
               data, 
               overwrite = TRUE)
  
  
  # close the connection
  dbDisconnect(con)
}



# plot data ---------------------------------------------------------------

subset_data <- function(data){
  # Province
  prov <- "Bulawayo"
  
  # Variable
  var <- "mean_temperature"
  
  # Data
  subset_climate <- data %>% 
    filter(provinces  == prov) %>% 
    select(date, var)
  
}



trend_plot <- function(data){
  
  # Plot the data
  data %>% 
    mutate(date = as.Date(date)) %>% 
    plot_time_series(date, mean_temperature) 
}



# split_plan --------------------------------------------------------------

split_data <- function(data){
  split <- time_series_split(
    data,
    assess = "4 months",
    cumulative = TRUE
  )
}


trend_split_plot <- function(data){
  
  data %>% 
    tk_time_series_cv_plan() %>% 
    plot_time_series_cv_plan(date, mean_temperature)
  
  
  
}


# models ------------------------------------------------------------------


modeling <- function(data){
  
  ##Auto Arima
  
  model_arima <- arima_reg() %>% 
    set_engine("auto_arima") %>% 
    fit(mean_temperature ~ date, training(data))
  
  
  ## Prophet
  
  model_prophet <- prophet_reg() %>% 
    set_engine("prophet") %>% 
    fit(mean_temperature ~ date, training(data))
  
  ## GLMNET
  model_glmnet<- linear_reg(penalty = 0.01) %>% 
    set_engine("glmnet") %>% 
    fit(mean_temperature ~ wday(date, label = T)
        + month(date, label = T)
        + as.numeric(date), 
        training(data))
  
  # Table
  model_tbl <- modeltime_table(
    model_arima,
    model_prophet,
    model_glmnet
  )
  
  
}


get_accuracy_df <- function(model, data){
  
  # Accuracy
  calib_tbl <- model  %>% 
    modeltime_calibrate(testing(data))
  
}



get_accuracy_tbl <- function(data){
  
  data %>% 
    modeltime_accuracy()
}


get_test_viz <- function(data, split_data, one_province){
  
  data %>% 
    modeltime_forecast(
      new_data = testing(split_data),
      actual_data = one_province
    ) %>% 
    plot_modeltime_forecast()
}




# forecasting -------------------------------------------------------------

get_forecast <- function(data, one_province){
  
  future_forecast_tbl <- data %>% 
    modeltime_refit(one_province) %>% 
    modeltime_forecast(
      h = "4 months",
      actual_data = one_province
    )
  
  
  future_forecast_tbl %>% 
    plot_modeltime_forecast()
}



# maps --------------------------------------------------------------------


get_map_data <- function(data){
  # Select variable
  vars = "mean_temperature"
  
  # Select the date
  date_select = "2012-01-04"
  
  climate_data <- data %>%
    mutate(provinces = str_replace(provinces, "\\+", " ")) %>% 
    filter(date == date_select)  
  
  # Zim Shape file
  zim_sh <- st_read("data/zimbabwe_shape_files/ZWE_adm1.shp")
  
  # Combine the data and shape file
  zim_sh <- zim_sh %>%
    left_join(., climate_data, by = c("NAME_1" = "provinces"))
  
}


get_map <- function(data){
  
  
  # Select the palette
  palette = "YlGn"
  
  # Create the plot
  zim_map <- data %>%
    ggplot() +
    geom_sf(aes(fill = mean_temperature)) +
    scale_fill_distiller(palette = palette, trans = "reverse") +
    theme_void()
  
  # Plotly map
  plotly::ggplotly(zim_map)
  
}

