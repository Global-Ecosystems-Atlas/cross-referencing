# Cross-Referencing Pipeline

The cross-referencing pipeline does the following:

- Runs the script `code/generate_templates.qmd` to update the folder `resources/01-membership-matrix-templates` with any new or updated membership matrix templates based on the **Sources database**.

- Runs the script `code/generate_crosswalks.qmd` to update the folder `resources/03_cw_tables_GEA` with any new or updated crosswalk tables based on the completed membership matrices present in `resources/02-membership-matrix-complete`.

- Runs the script `code/generate_gee_dictionaries.R` to update the file `resources/04_gee_dictionaries/combined_crosswalk_dictionaries.js` with the membership matrices present in `resources/03_cw_tables_GEA`.

For the pipeline to run correctly, an environment secret named `GOOGLE_SERVICE_ACCOUNT_JSON` must be created for GitHub Actions. It must contain the JSON credentials that allow the Google Service Account to connect to the **Sources database** Google Sheet.