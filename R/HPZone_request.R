#' Performs a HPZone request with the given parameters.
#'
#' @param body A GraphQL query to send to the HPZone API.
#' @param scope The desired scope; either standard or extended. This can be the fully qualified term, or keywords 'standard' or 'extended'.
#'
#' @return
#' @export
#' @importFrom httr2 request
#' @importFrom httr2 req_headers
#' @importFrom httr2 req_body_raw
#' @importFrom httr2 req_oauth_client_credentials
#' @importFrom httr2 req_perform
#' @importFrom jsonlite fromJSON
#'
#' @examples
HPZone_request = function (body, scope=API_env$scope_standard) {
  if (!API_env$init_run) {
    stop("The package has not yet been initialized. Run HPZone_setup() first.")
  }

  if (scope == 'standard') scope = API_env$scope_standard
  if (scope == 'extended') scope = API_env$scope_extended

  req = httr2::request(API_env$data_url) %>%
    httr2::req_headers(`content-type`="application/json",
                accept="application/json",
                scope=scope) %>%
    httr2::req_body_raw(body) %>%
    httr2::req_oauth_client_credentials(client=API_env$client, scope=scope) %>%
    httr2::req_perform()

  return(jsonlite::fromJSON(resp_body_json(test)))
}
