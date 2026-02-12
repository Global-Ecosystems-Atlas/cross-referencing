# Load the necessary libraries
library(tidyverse)
library(purrr)
library(glue)
library(googlesheets4)

# Define the folder where the CSV files are located
cw_folder <- "resources/03_cw_tables_GEA"

# Get a list of all CSV files in the folder (requires recursive search)
cw_files <- list.files(
  path = cw_folder, 
  pattern = "_GEA_crosswalk_table\\.csv$", 
  full.names = TRUE,
  recursive = TRUE
)

# Authenticate with the Google Service Account if available in the environment variables
gsa_json <- Sys.getenv("GOOGLE_SERVICE_ACCOUNT_JSON", unset = NA)

if (!is.na(gsa_json) && nchar(gsa_json) > 0) {
  temp_json <- tempfile(fileext = ".json")
  writeLines(gsa_json, temp_json)
  gs4_auth(path = temp_json)
}
# In dev, use: gs4_auth(email = TRUE)

# Read the sources database to get dataset type (raster or vector)
sources_database <- read_sheet(
  "https://docs.google.com/spreadsheets/d/1P-xus66mTxY-9-a8jZgzwh3KVlL2Yvh6HzJ8rbmT1bY", 
  sheet = "Data_Review_MASTER", 
  trim_ws = TRUE, 
  col_types = "c") |> 
  filter(QAQC_pass == TRUE)


# --- Define the required module import (Requirement 1) ---
js_module_import <- "var repository = require('users/murrnick/geo-atlas-prod:modules/central_repository');\n\n"


# Function to process each CSV file and generate the JavaScript dictionary
process_csv_file <- function(file_path) {
  # Read the CSV file
  df <- read_csv(file_path, show_col_types = FALSE)
  
  # --- Extract Metadata ---
  source_id <- df$Source_ID[1]
  data_id_code <- df$data_id_code[1]
  
  # *** CRITICAL UPDATE: Construct ee_asset_id path as a string literal (Requirement 2) ***
  # This string will be inserted directly into the JS object without quotes around the variable name.
  ee_asset_id_js_literal <- paste0("repository.data_catalogue.", data_id_code)
  
  # --- Extract Columns for JS Arrays ---
  band_layer_name <- df$band_layer_name
  in_class_field_name <- df$in_class_field_name
  in_class_value <- df$in_class_value
  pixel_value <- df$pixel_value # Using pixel_value as previously confirmed
  efg_names <- df$efg_name
  efg_codes <- df$efg_code
  
  # --- Extract dataset end year from the sources database ---
  matching_year_values <- sources_database$year_end[sources_database$Source_ID == source_id]
  non_na_years <- unique(na.omit(matching_year_values)) # Remove NA and count unique values
  
  if (length(non_na_years) == 1) {
    dataset_year <- non_na_years
  } else {
    dataset_year <- 'null'  # inconsistent years or no value
  }
  
  # --- Extract Raster/Vector type from the sources database ---
  matching_type_values <- sources_database$vector_raster[sources_database$Source_ID == source_id]
  non_na_types <- unique(na.omit(matching_type_values)) # Remove NA and count unique values
  
  if (length(non_na_types) == 1) {
    vector_raster <- paste0("'", non_na_types, "'")
  } else {
    vector_raster <- 'null'  # inconsistent types or no value
  }
  
  # Prepare in_class_value for JS: leave numeric values unquoted, quote character values
  in_class_value_js <- if (is.numeric(in_class_value)) {
    paste0(in_class_value, collapse = ", ")
  } else {
    paste0("'", in_class_value, "'", collapse = ", ")
  }
  
#  --- Generate the JavaScript dictionary content using glue ---
  js_content <- glue::glue(
    "//{data_id_code}\n",
    "var {data_id_code} = {{\n",
    "  source_id: {source_id},\n",
    "  data_id_code: '{data_id_code}',\n",
    "  dataset_year: {dataset_year},\n",
    "  vector_raster: {vector_raster},\n",
    "  ee_asset_id: {ee_asset_id_js_literal},\n",
    "  band_layer_name: [{paste0(\"'\", band_layer_name, \"'\", collapse = \", \")}],\n",
    "  in_class_field_name: [{paste0(\"'\", in_class_field_name, \"'\", collapse = \", \")}],\n",
    "  in_class_value: [{in_class_value_js}],\n",
    "  pixel_value: [{paste0(pixel_value, collapse = \", \")}],\n",
    "  efg_names: [{paste0(\"'\", efg_names, \"'\", collapse = \", \")}],\n",
    "  efg_codes: [{paste0(\"'\", efg_codes, \"'\", collapse = \", \")}]\n",
    "}};\n"
  )
  return(as.character(js_content))
}

# Process all CSV files and combine the JavaScript content
combined_js_content_snippets <- cw_files %>%
  map_chr(process_csv_file) %>%
  paste(collapse = "\n\n")

# Prepend the required module import line
final_js_output <- paste0(js_module_import, combined_js_content_snippets)


# Write the combined result to an output file
write(final_js_output, file = "resources/04_gee_dictionaries/combined_crosswalk_dictionaries.js")

