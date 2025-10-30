#' Converts all relevant columns in the dataset to Date types.
#'
#' Based on the available fields, a date for statistics is automatically generated, using the following logic:
#' If cases: Date_of_onset > Datum_melding_aan_de_ggd > Case_creation_date.
#' If situations: Start_date > Situation_creation_date
#' If enquiries: Received_on > Date_closed
#'
#' @param data A dataset returned by the API.
#' @param search Column names to search for. Default: anything containing 'date' or 'datum'.
#' @param statdate Desired column name for the date for statistics field.
#'
#' @return An equivalent data.frame with Date types in the correct columns. Additionally, a column called 'Date_stat' is added, see Details.
#' @export
#' @importFrom stringr str_detect
#' @importFrom stringr regex
#' @importFrom lubridate ymd_hms
#' @importFrom dplyr coalesce
#'
#' @examples
#' \dontrun{
#' HPZone_request("cases", "basic", where=c("Case_creation_date", ">", "2025-01-01")) |>
#'   HPZone_convert_dates()
#' }
HPZone_convert_dates = function (data, search="dat(e|um)|Received_on", statdate="Date_stat") {
  dataset = data
  if (is.list(data) && "items" %in% names(data)) {
    dataset = data$items
  }

  cols = which(stringr::str_detect(colnames(dataset), stringr::regex(search, ignore_case=T)))
  for (col in cols) {
    dataset[[col]] = suppressWarnings(lubridate::ymd_hms(dataset[[col]]))
  }

  # calculate statistics date
  if (any(c("Case_creation_date", "Date_of_onset", "Datum_melding_aan_de_ggd") %in% colnames(dataset))) {
    # cases
    dataset[, statdate] = dplyr::coalesce(dataset$Date_of_onset, dataset$Datum_melding_aan_de_ggd, dataset$Case_creation_date)
  } else if (any(c("Start_date", "Situation_creation_date") %in% colnames(dataset))) {
    # situations
    dataset[, statdate] = dplyr::coalesce(dataset$Start_date, dataset$Situation_creation_date)
  }
  else if (any(c("Received_on", "Date_closed") %in% colnames(dataset))) {
    # enquiries
    dataset[, statdate] = dplyr::coalesce(dataset$Received_on, dataset$Date_closed)
  }

  return(dataset)
}
