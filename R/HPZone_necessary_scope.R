#' Determines the necessary scope for a given list of fields.
#'
#' @param fields List of desired fields from a query.
#' @param endpoint The required endpoint.
#' @param resolve_fieldnames Whether or not to parse the supplied fields and convert them to valid HPZone field names. (By calling [HPZone_make_valid])
#'
#' @return The required scope as expected by the HPZone API, i.e. "standard" or "extended".
#' @export
#'
#' @examples
#' # these variables do not required an extended scope; desired response = standard
#' HPZone_necessary_scope(c("Diagnosis", "Case_number", "Entered_by"))
#' # Family_name requires the extended scope; desired response = extended
#' HPZone_necessary_scope(c("Diagnosis", "Case_number", "Family_name"))
HPZone_necessary_scope = function (fields, endpoint="Cases", resolve_fieldnames=TRUE) {
  if (is.na(endpoint) || is.null(endpoint)) {
    stop("No valid endpoint supplied.")
  }

  if (any(is.na(fields)) || any(is.null(fields))) {
    stop("No valid fields supplied.")
  }

  if (!endpoint %in% HPZone_fields$endpoint) {
    # case mismatch?
    endpoints = unique(HPZone_fields$endpoint)
    if (stringr::str_to_lower(endpoint) %in% stringr::str_to_lower(endpoints)) {
      endpoint = endpoints[stringr::str_to_lower(endpoint) == stringr::str_to_lower(endpoints)]
    } else {
      stop("Invalid endpoint supplied: ", endpoint)
    }
  }

  if (resolve_fieldnames) {
    fields = HPZone_make_valid(fields=fields)
  }

  required_scope = "standard"
  if (!all(HPZone_fields$scope_standard[which(HPZone_fields$field %in% fields & HPZone_fields$endpoint == endpoint)])) {
    required_scope = "extended"
  }

  return(required_scope)
}
