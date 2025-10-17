usethis::use_import_from("readxl", "read_xlsx")

#' List of available fields in the API
#' @keywords external
HPZone_fields = readxl::read_xlsx("data-raw/graphql_fields.xlsx")
colnames(HPZone_fields) = c("endpoint", "field_hr", "field", "scope_standard", "scope_extended", "in_basic", "note")
HPZone_fields$scope_standard = HPZone_fields$scope_standard == "Yes"
HPZone_fields$scope_extended = HPZone_fields$scope_extended == "Yes"
HPZone_fields$in_basic = HPZone_fields$in_basic == "Yes"
HPZone_fields$in_basic[is.na(HPZone_fields$in_basic)] = F
# for some reason, lots of NAs at the end of the table
HPZone_fields = HPZone_fields[!is.na(HPZone_fields$endpoint),]

usethis::use_data(HPZone_fields, overwrite = TRUE)
