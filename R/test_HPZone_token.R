#' Tests the supplied HPZone token against the token endpoint. Note that this does not check the type of access, only the functionality of the token.
#'
#' @return No return value.
#' @importFrom httr2 oauth_flow_client_credentials
#' @export
#'
#' @examples
#' \dontrun{
#' HPZone_setup()
#' # This will print the results.
#' test_HPZone_token()
#' }
test_HPZone_token = function () {
  check_setup()

  returns = list()

  if (!is.na(API_env$scope_standard)) {
    message("Testing the standard scope credentials...")
    token = httr2::oauth_flow_client_credentials(client=API_env$client)
    returns = append(returns, list("standard"=token))
  }

  if (!is.na(API_env$scope_extended)) {
    message("Testing the extended scope credentials...")
    token = httr2::oauth_flow_client_credentials(client=API_env$client)
    returns = append(returns, list("extended"=token))
  }

  if (is.na(API_env$scope_standard) && is.na(API_env$scope_extended)) {
    return("Neither scope was entered using HPZone_setup(). Terminating.")
  }

  return(returns)
}
