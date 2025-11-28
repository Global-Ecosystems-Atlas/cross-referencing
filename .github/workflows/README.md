# Cross-Referencing Pipeline

The cross-referencing pipeline does the following:

- Runs the script `code/generate_crosswalks.qmd` to update the folder `resources/01-membership-matrix-templates` with any new or updated membership matrix templates based on the **Sources database**.

- Runs the script `code/generate_templates.qmd` to update the folder `resources/03_cw_tables_GEA` with any new or updated crosswalk tables based on the completed membership matrices present in `resources/02-membership-matrix-complete`.