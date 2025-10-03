API_env = new.env(parent = emptyenv())

API_env$init_run = F
API_env$token_url = "https://connect.govconext.nl/oidc/token"
API_env$data_url = "https://api.hpzone.nl:8899/Edie"
API_env$scope_standard = "standard"
API_env$scope_extended = "extended"
API_env$client_id = NA
API_env$client_secret = NA


#' Initialisation function to define API credentials. This function must be called before anything else, as the details supplied in this call are required for use.
#' Note that client_id and client_secret should preferably not be supplied in this call, but rather stored using [HPZone_store_credentials()].
#'
#' @param client_id Client ID as supplied by InFact.
#' @param client_secret Client secret as supplied by InFact.
#' @param standard Name of the standard scope. Default: "standard"
#' @param extended Name of the extended scope. Default: "extended"
#' @param token_url Address of the token server.
#' @param data_url Address of the data server.
#'
#' @return No return value.
#' @importFrom httr2 oauth_client
#' @importFrom keyring key_list
#' @importFrom keyring key_get
#' @importFrom safer decrypt_string
#' @export
#'
#' @examples
#' # Not recommended:
#' HPZone_setup("id", "secret")
#'
#' # Recommended:
#' HPZone_store_credentials() # call once
#' HPZone_setup() # will automatically read stored credentials
HPZone_setup = function (client_id = NA, client_secret = NA, standard="standard", extended="extended",
                         token_url="https://connect.govconext.nl/oidc/token",
                         data_url="https://api.hpzone.nl:8899/Edie") {
  if (is.na(client_id) || is.na(client_secret)) {
    # check for stored credentials
    stored_keys = keyring::key_list()
    if (is.na(client_id) && "HPZone_client_id" %in% stored_keys$service) {
      client_id = keyring::key_get("HPZone_client_id") |> safer::decrypt_string(key="Kdj(327KWpX%")
    }

    if (is.na(client_secret) && "HPZone_client_secret" %in% stored_keys$service) {
      client_secret = keyring::key_get("HPZone_client_secret") |> safer::decrypt_string(key="Kdj(327KWpX%")
    }
  }

  if (is.na(client_id) || is.na(client_secret)) {
    stop("No client ID or secret supplied, and no previously stored credentials found. Use HPZone_store_credentials() if you want to store credentials.")
  }

  API_env$client_id = client_id
  API_env$client_secret = client_secret
  API_env$scope_standard = standard
  API_env$scope_extended = extended
  API_env$token_url = token_url
  API_env$data_url = data_url

  API_env$client = httr2::oauth_client(id=API_env$client_id, token_url=API_env$token_url, secret=API_env$client_secret, name="HPZone-API-R-package")

  API_env$init_run = T
}

#' Safely stores the HPZone API details, so you don't need to put them in your script. The default OS keyring backend is used through the keyring-package. Values are stored in an encrypted format to prevent harvesting by other applications.
#' Note that the actual values are not supplied as arguments, but requested using rstudioapi password prompts.
#'
#' @param client_id True / false: whether the client_id should be stored.
#' @param client_secret True / false: whether the client_secret should be stored.
#'
#' @return N/A
#' @export
#' @importFrom rstudioapi askForPassword
#' @importFrom keyring key_set_with_value
#' @importFrom safer encrypt_string
#'
#' @examples
#' # simply execute this line to store credentials
#' HPZone_store_credentials()
#' # after use, setup can be ran without arguments:
#' HPZone_setup()
HPZone_store_credentials = function (client_id = T, client_secret = T) {
  if (client_id) {
    secret_id = rstudioapi::askForPassword("Please enter the client_id")
    keyring::key_set_with_value("HPZone_client_id", password=safer::encrypt_string(secret_id, key="Kdj(327KWpX%"))
  }

  if (client_secret) {
    secret_secret = rstudioapi::askForPassword("Please enter the client_secret")
    keyring::key_set_with_value("HPZone_client_secret", password=safer::encrypt_string(secret_secret, key="Kdj(327KWpX%"))
  }
}


#' Checks if the setup function has been run, or can be run automatically. If so, HPZone_setup() is called. If not, an error is thrown.
#'
#' @return TRUE if setup has been run or can be run by this function.
#'
#' @examples
#' check_setup()
check_setup = function () {
  if (API_env$init_run) {
    return(T)
  }
  if (!API_env$init_run) {
    # check for stored credentials
    stored_keys = keyring::key_list()
    if ("HPZone_client_id" %in% stored_keys$service && "HPZone_client_secret" %in% stored_keys$service) {
      HPZone_setup()
      return(T)
    } else {
      stop("The package has not yet been initialized. Run HPZone_setup() first.")
    }
  }
}
