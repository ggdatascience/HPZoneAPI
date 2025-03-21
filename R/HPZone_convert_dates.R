#' Converts all relevant columns in the dataset to Date types.
#'
#' @param data A dataset returned by the API.
#' @param search Column names to search for. Default: anything containing 'date' or 'datum'.
#'
#' @return An equivalent data.frame with Date types in the correct columns.
#' @export
#' @importFrom stringr str_detect
#' @importFrom stringr regex
#' @importFrom lubridate ymd_hms
#'
#' @examples
HPZone_convert_dates = function (data, search="dat(e|um)") {
  dataset = data
  if (is.list(data) && "items" %in% names(data)) {
    dataset = data$items
  }

  cols = which(colnames(dataset) |> stringr::str_detect(stringr::regex(search, ignore_case=T)))
  for (col in cols) {
    dataset[[col]] = lubridate::ymd_hms(dataset[[col]])
  }

  return(dataset)

  # TODO: error handling
}
