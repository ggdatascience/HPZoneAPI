#' Tests the supplied HPZone token against the token endpoint. Note that this does not check the type of access, only the functionality of the token.
#'
#' @return No return value.
#' @importFrom httr2 oauth_flow_client_credentials
#' @export
#'
#' @examples
#' HPZone_setup()
#' # This will print the results.
#' test_HPZone_token()
test_HPZone_token = function () {
  check_setup()

  if (!is.na(API_env$scope_standard)) {
    print("Testing the standard scope credentials...")
    token = httr2::oauth_flow_client_credentials(client=API_env$client)
    print(token)
  }

  if (!is.na(API_env$scope_extended)) {
    print("Testing the extended scope credentials...")
    token = httr2::oauth_flow_client_credentials(client=API_env$client)
    print(token)
  }

  if (is.na(API_env$scope_standard) && is.na(API_env$scope_extended)) {
    print("Neither scope was entered using HPZone_setup(). Terminating.")
  }
}
