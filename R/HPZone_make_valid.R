globalVariables("HPZone_fields")

#' Takes a list of fields or endpoints and corrects them. This allows for short hand usage without having to check the documentation, e.g. 'Date of onset' instead of 'Date_of_onset'
#'
#' @param endpoints A list of desired endpoints.
#' @param fields A list of desired fields.
#'
#' @return A list of properly formatted fields or endpoints.
#' @importFrom stringr str_to_lower
#' @importFrom stringr str_c
#' @export
#'
#' @examples
#' HPZone_make_valid("case") # should return "cases"
#' HPZone_make_valid(fields="case_creation") # should return "Case_creation_date"
#' HPZone_make_valid("case", fields=c("Family name", "Gp")) # should return c("Family_name", "Gp")
HPZone_make_valid = function (endpoints=NULL, fields=NULL) {
  if (!is.null(fields)) {
    possible_fields = HPZone_fields$field
    possible_fields_hr = HPZone_fields$field_hr
    if (!is.null(endpoints)) {
      endpoints = HPZone_make_valid(endpoints)
      possible_fields = HPZone_fields$field[stringr::str_to_lower(HPZone_fields$endpoint) %in% endpoints]
      possible_fields_hr = HPZone_fields$field_hr[stringr::str_to_lower(HPZone_fields$endpoint) %in% endpoints]
    }
    fields_valid = unlist(lapply(fields, \(x) {
      index = grep(x, possible_fields, ignore.case=T)
      if (length(index) == 0) {
        index = grep(x, possible_fields_hr, ignore.case=T)
        if (length(index) == 0) {
          stop("Invalid field supplied: ", x)
        }
        if (length(index) > 1) {
          # if one field matches exactly, minus case sensitivity, that's the one we want
          # otherwise: error
          if (stringr::str_to_lower(x) %in% stringr::str_to_lower(possible_fields_hr[index]) &&
              sum(stringr::str_to_lower(x) == stringr::str_to_lower(possible_fields_hr[index])) == 1) {
            return(index[stringr::str_to_lower(x) == stringr::str_to_lower(possible_fields_hr[index])])
          }
          stop("Multiple fields match the supplied description (", x, "): ", stringr::str_c(possible_fields[index], collapse=", "))
        }
      }
      if (length(index) > 1) {
        # if one field matches exactly, minus case sensitivity, that's the one we want
        # otherwise: error
        if (stringr::str_to_lower(x) %in% stringr::str_to_lower(possible_fields[index]) &&
            sum(stringr::str_to_lower(x) %in% stringr::str_to_lower(possible_fields[index])) == 1) {
          return(index[stringr::str_to_lower(x) == stringr::str_to_lower(possible_fields[index])])
        }
        stop("Multiple fields match the supplied description (", x, "): ", stringr::str_c(possible_fields[index], collapse=", "))
      }
      return(index)
    }))
    return(possible_fields[fields_valid])
  } else if (!is.null(endpoints)) {
    possible_endpoints = str_to_lower(unique(HPZone_fields$endpoint))
    endpoints_valid = unlist(lapply(endpoints, \(x) {
      index = grep(x, possible_endpoints, ignore.case=T)
      if (length(index) != 1) stop("Invalid endpoint supplied: ", x)
      return(index)
    }))
    return(possible_endpoints[endpoints_valid])
  }
}
