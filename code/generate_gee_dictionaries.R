# Load the necessary libraries
library(tidyverse)
library(purrr)
library(glue)

# Define the folder where the CSV files are located
cw_folder <- "resources/03_cw_tables_GEA"

# Get a list of all CSV files in the folder (requires recursive search)
cw_files <- list.files(
  path = cw_folder, 
  pattern = "_GEA_crosswalk_table\\.csv$", 
  full.names = TRUE,
  recursive = TRUE
)

# --- Define the required module import (Requirement 1) ---
js_module_import <- "var repository = require('users/murrnick/geo-atlas-prod:modules/central_repository');\n\n"


# Function to process each CSV file and generate the JavaScript dictionary
process_csv_file <- function(file_path) {
  # Read the CSV file
  df <- read_csv(file_path, show_col_types = FALSE)
  
  # --- Extract Metadata ---
  data_id_code <- df$data_id_code[1]
  
  # *** CRITICAL UPDATE: Construct ee_asset_id path as a string literal (Requirement 2) ***
  # This string will be inserted directly into the JS object without quotes around the variable name.
  ee_asset_id_js_literal <- paste0("repository.assets.data_catalogue.", data_id_code)
  
  # --- Extract Columns for JS Arrays ---
  in_class_field_name <- df$in_class_field_name
  in_value <- df$in_class_value
  out_value <- df$pixel_value # Using pixel_value as previously confirmed
  efg_names <- df$efg_name
  efg_codes <- df$efg_code
  
#  --- Generate the JavaScript dictionary content using glue ---
  js_content <- glue::glue(
    "//{data_id_code}\n",
    "var {data_id_code} = {{\n",
    "  data_id_code: '{data_id_code}',\n",
    "  ee_asset_id: {ee_asset_id_js_literal},\n",
    "  in_class_field_name: [{paste0(\"'\", in_class_field_name, \"'\", collapse = \", \")}],\n",
    "  in_value: [{paste0(\"'\", in_value, \"'\", collapse = \", \")}],\n",
    "  out_class_value: [{paste0(out_value, collapse = \", \")}],\n",
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

