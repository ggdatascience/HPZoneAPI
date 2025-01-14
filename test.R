load_all()

client_id <- "6304452313324575947"
client_secret <- "WPPoITmAdhYaj8EqyYk5sqXYJagHIU5e"
scope_standard <- 'nog_standard' # pas aan naar jouw ggd
scope_extended <- 'nog_extended' # pas aan naar jouw ggd

HPZone_setup(client_id, client_secret, scope_standard, scope_extended)

test_HPZone_token()


# verwacht: standard
HPZone_necessary_scope(c("Diagnosis", "Case_number", "Entered_by"))
# verwacht: extended
HPZone_necessary_scope(c("Diagnosis", "Case_number", "Entered_by", "Family_name"))
