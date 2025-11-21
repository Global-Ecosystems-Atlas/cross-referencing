# Load the necessary libraries
library(tidyverse)
library(purrr)
library(glue) # Ensure glue is loaded for path concatenation if needed

# Define the folder where the CSV files are located
# NOTE: This should point to the output of your first workflow (03_cw_tables_GEA)
cw_folder <- "resources/03_cw_tables_GEA"

# Get a list of all CSV files in the folder (requires recursive search)
# We use list.files with full.names and recursive to find files inside subdirectories
cw_files <- list.files(
  path = cw_folder, 
  pattern = "_GEA_crosswalk_table\\.csv$", 
  full.names = TRUE,
  recursive = TRUE
)

# Function to process each CSV file and generate the JavaScript dictionary
process_csv_file <- function(file_path) {
  # Read the CSV file
  df <- read_csv(file_path, show_col_types = FALSE)
  
  # --- Extract Metadata ---
  # These values are often the same for all rows in a single crosswalk table.
  data_id_code <- df$data_id_code[1]
  band_layer_name <- df$band_layer_name[1]
  
  # Generate the Earth Engine Asset ID
  # NOTE: The path provided in your sample JS is hardcoded ('projects/UQ_intertidal/gee-geo-atlas/open-datasets/jcu/')
  # You may need to verify this base path is correct for your use case.
  ee_asset_id <- paste0("projects/UQ_intertidal/gee-geo-atlas/open-datasets/jcu/", band_layer_name)
  
  # --- Extract Columns for JS Arrays ---
  # Generate the relevant fields row-wise.
  in_class_field_name <- df$in_class_field_name
  in_value <- df$in_class_value
  
  # *** CRITICAL UPDATE: Use pixel_value for the out_class_value array ***
  out_value <- df$pixel_value
  
  efg_names <- df$efg_name
  efg_codes <- df$efg_code
  
  # --- Generate the JavaScript dictionary content ---
  # The use of paste0(..., collapse = ", ") converts the R vector into a JS array string
  js_content <- glue::glue(
    "//{data_id_code}\n",
    "var {data_id_code} = {{\n",
    "  data_id_code: '{data_id_code}',\n",
    "  ee_asset_id: '{ee_asset_id}',\n",
    "  in_class_field_name: [{paste0(\"'\", in_class_field_name, \"'\", collapse = \", \")}],\n",
    "  in_value: [{paste0(in_value, collapse = \", \")}],\n",
    "  out_class_value: [{paste0(out_value, collapse = \", \")}],\n",
    "  efg_names: [{paste0(\"'\", efg_names, \"'\", collapse = \", \")}],\n",
    "  efg_codes: [{paste0(\"'\", efg_codes, \"'\", collapse = \", \")}]\n",
    "}};
"
  )
  
  return(as.character(js_content))
}

# Process all CSV files and combine the JavaScript content
# Using map_chr and paste(collapse) combines all generated snippets into one string
combined_js_content <- cw_files %>%
  map_chr(process_csv_file) %>%
  paste(collapse = "\n\n")

# Write the combined result to an output file
# It is often better to use a .js extension for direct use/syntax highlighting
# I'll keep the .md extension as requested, but recommend .js
write(combined_js_content, file = "resources/04_gee_snippets/combined_crosswalk_dictionaries.txt")

message("Successfully generated combined JavaScript dictionaries and saved to combined_crosswalk_dictionaries.md")