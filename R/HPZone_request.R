#' Performs a HPZone request with the given parameters.
#'
#' @param body A GraphQL query to send to the HPZone API.
#' @param scope The desired scope; either standard or extended.
#'
#' @return An object containing the requested data points. This can be in different forms, depending on the request.
#' @export
#' @importFrom httr2 request
#' @importFrom httr2 req_headers
#' @importFrom httr2 req_body_raw
#' @importFrom httr2 req_oauth_client_credentials
#' @importFrom httr2 req_perform
#' @importFrom jsonlite fromJSON
#'
#' @examples
HPZone_request_raw = function (body, scope=API_env$scope_standard) {
  if (!API_env$init_run) {
    stop("The package has not yet been initialized. Run HPZone_setup() first.")
  }

  if (scope == "standard") scope = API_env$scope_standard
  if (scope == "extended") scope = API_env$scope_extended

  req = httr2::request(API_env$data_url) |>
    httr2::req_headers(`content-type`="application/json",
                accept="application/json",
                scope=scope) |>
    httr2::req_body_raw(body) |>
    httr2::req_oauth_client_credentials(client=API_env$client) |>
    httr2::req_perform()

  return(jsonlite::fromJSON(httr2::resp_body_json(req)))
}

#' Performs a HPZone request with the given parameters.
#'
#' @param query A GraphQL query to send to the HPZone API.
#' @param scope The desired scope; either standard or extended.
#'
#' @return An object containing the requested data points. This can be in different forms, depending on the request, but is simplified as much as possible.
#' @export
#'
#' @examples
HPZone_request = function (query, scope=API_env$scope_standard) {
  if (!API_env$init_run) {
    stop("The package has not yet been initialized. Run HPZone_setup() first.")
  }

  if (scope == "standard") scope = API_env$scope_standard
  if (scope == "extended") scope = API_env$scope_extended

  data = HPZone_request_raw(paste0('{"query": "{', gsub('"', '\\\\"', query) , '}"}'))
  # eliminate unnecessary listing; the format is something weird like data$cases$items
  while (length(data) == 1 && is.list(data)) {
    data = data[[1]]
  }

  # TODO: error handling
  return(data)
}

#' Performs a HPZone request with the given parameters.
#'
#' @param query A GraphQL query to send to the HPZone API. Note that keywords 'skip' and 'take' cannot be present in the query; this function will add them.
#' @param n_max Maximum number of entries to request per call.
#' @param scope The desired scope; either standard or extended.
#'
#' @return A data frame containing all the responses gathered from the API. Only the items will be returned.
#' @export
#' @importFrom stringr str_locate
#' @importFrom stringr str_sub
#' @importFrom stringr str_detect
#' @importFrom stringr fixed
#'
#' @examples
HPZone_request_paginated = function (query, n_max=500, scope=API_env$scope_standard) {
  if (!API_env$init_run) {
    stop("The package has not yet been initialized. Run HPZone_setup() first.")
  }

  if (scope == "standard") scope = API_env$scope_standard
  if (scope == "extended") scope = API_env$scope_extended

  # find selector bracket, or lack thereof
  pos = stringr::str_locate(query, "(?<=[a-zA-Z]{1,10})(\\(|\\{)")
  query_char = stringr::str_sub(query, pos)
  if (query_char == "(") {
    # selector bracket; insert before other selectors
    selectors = stringr::str_sub(query, start=pos[,1]+1, end=stringr::str_locate(query, stringr::fixed(")"))[,1]-1)
    if (stringr::str_detect(selectors, "skip|take")) {
      stop("'skip' or 'take' were present in the query. This is not supported in this function. Please use HPZone_request() or HPZone_request_raw() instead.")
    }

    query = paste0(stringr::str_sub(query, end=pos[,1]), "[pageblock], ", stringr::str_sub(query, start=pos[,1]+1))
  } else if (query_char == "{") {
    # no selector bracket; insert
    query = paste0(stringr::str_sub(query, end=pos[,1]-1), "([pageblock])", stringr::str_sub(query, start=pos[,1]))
  } else {
    stop("No selector brackets nor opening curly brackets found. Make sure the query is properly formatted in GraphQL.")
  }

  # add totalCount to query, if not already present
  if (!stringr::str_detect(query, stringr::fixed("totalCount"))) {
    # this is pretty simple; it should be before the last curly bracket
    pos = stringr::str_locate_all(query, stringr::fixed("}")) |> unlist()
    pos = max(pos, na.rm=T)
    query = paste0(stringr::str_sub(query, end=pos-1), ", totalCount }")
  }

  n_retrieved = 0
  n_present = Inf
  data_total = data.frame()
  while (n_retrieved < n_present) {
    data = HPZone_request_raw(paste0('{"query": "{', gsub('"', '\\\\"', sub("[pageblock]", paste0("take: ", n_max, ", skip: ", n_retrieved), query, fixed=T)) , '}"}'))
    # eliminate unnecessary listing; the format is something weird like data$cases$items
    while (length(data) == 1 && is.list(data)) {
      data = data[[1]]
    }

    n_present = data$totalCount
    data_total = rbind(data_total, data$items)
    n_retrieved = n_retrieved + nrow(data$items)
  }

  # TODO: error handling
  return(data_total)
}
