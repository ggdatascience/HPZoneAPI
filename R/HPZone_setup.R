API_env = new.env(parent = emptyenv())

API_env$init_run = F
API_env$token_url = "https://login.ggdghor.nl/infactdev/oauth2/v1/token"
API_env$data_url = "http://85.90.69.239:8899/Edie"
API_env$scope_standard = "nog_standard"
API_env$scope_extended = "nog_extended"
API_env$client_id = NA
API_env$client_secret = NA


#' Initialisation function to define API credentials. This function must be called before anything else, as the details supplied in this call are required for use.
#'
#' @param client_id Client ID as supplied by InFact.
#' @param client_secret Client secret as supplied by InFact.
#' @param standard Name of the standard scope. Usually an abbreviation of the GGD name and "_standard", e.g. "rr_standard".
#' @param extended Name of the extended scope. Usually an abbreviation of the GGD name and "_extended", e.g. "nog_extended".
#' @param token_url Address of the token server.
#' @param data_url Address of the data server.
#'
#' @return
#' @importFrom httr2 oauth_client
#' @export
#'
#' @examples
HPZone_setup = function (client_id, client_secret, standard, extended,
                         token_url="https://login.ggdghor.nl/infactdev/oauth2/v1/token",
                         data_url="http://85.90.69.239:8899/Edie") {
  API_env$client_id = client_id
  API_env$client_secret = client_secret
  API_env$scope_standard = standard
  API_env$scope_extended = extended
  API_env$token_url = token_url
  API_env$data_url = data_url

  API_env$client = httr2::oauth_client(id=API_env$client_id, token_url=API_env$token_url, secret=API_env$client_secret, name="HPZone-API-R-package")

  API_env$init_run = T
}
