#' Performs a HPZone request with the given parameters.
#'
#' Note that there are several helper functions that make the use of the API a lot simpler; specifically [HPZone_request()], [HPZone_request_paginated()].
#' This should only be used as a last resort; if manual GraphQL queries are required, [HPZone_request_query()] is highly advised instead.
#'
#' @param body A GraphQL query to send to the HPZone API, including all necessary bracketing and JSON-elements.
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
#' @importFrom magrittr "%>%"
#'
#' @seealso [HPZone_request()], [HPZone_request_paginated()], [HPZone_request_query()]
#'
#' @examples
#' # Note the difference between the raw and convenience functions.
#' # These lines are equal:
#' \dontrun{
#' HPZone_request("cases", c("Case_creation_date", "Case_number"),
#'                where=c("Case_creation_date", ">=", "2025-01-01"))
#' HPZone_request_query(paste0('cases(where: { ',
#'                       'Case_creation_date: { gte: "2025-01-01" }',
#'                       '})',
#'                       '{ items { Case_creation_date, Case_number } }')
#'                     )
#' HPZone_request_raw(paste0('{"query": "{ cases(where: {',
#'                             'Case_creation_date: { gte: \\"2025-01-01\\" }',
#'                           '})',
#'                           '{ items { Case_creation_date, Case_number } }',
#'                           '}"}'))
#' }
HPZone_request_raw = function (body, scope=API_env$scope_standard) {
  check_setup()

  if (scope == "standard") scope = API_env$scope_standard
  if (scope == "extended") scope = API_env$scope_extended

  req = httr2::request(API_env$data_url) %>%
    httr2::req_headers(`content-type`="application/json",
                accept="application/json",
                scope=scope) %>%
    httr2::req_body_raw(body) %>%
    httr2::req_oauth_client_credentials(client=API_env$client) %>%
    httr2::req_perform()

  return(jsonlite::fromJSON(httr2::resp_body_json(req)))
}

#' Performs a HPZone request with the given parameters.
#'
#' This function is a convenience wrapper around [HPZone_request_raw()], to facilitate easier coding.
#' This function integrates [sprintf()] to allow for easier query design, quotes are automatically escaped, and the the result is unlisted to allow for easier access.
#' See the example for differences with [HPZone_request_raw()]. Note that results are *not* automatically paginated; use [HPZone_request_paginated()] for that.
#'
#' @param query A GraphQL query to send to the HPZone API. Note that only the actual query is required. (See the examples.)
#' @param ... Parameters to be passed to [sprintf()]. If empty, the body is not passed through [sprintf()].
#' @param scope The desired scope; either standard or extended.
#'
#' @return An object containing the requested data points. This can be in different forms, depending on the request, but is simplified as much as possible.
#' @export
#' @seealso [HPZone_request()], [HPZone_request_paginated()], [HPZone_convert_dates()]
#'
#' @examples
#' # Note the difference between the raw and convenience functions.
#' # These lines are equal:
#' \dontrun{
#' HPZone_request("cases", c("Case_creation_date", "Case_number"),
#'                where=c("Case_creation_date", ">=", "2025-01-01"))
#' HPZone_request_query(paste0('cases(where: {',
#'                               'Case_creation_date: { gte: "2025-01-01" }',
#'                             '}) {',
#'                               'items { Case_creation_date, Case_number }',
#'                              '}'))
#' HPZone_request_raw(paste0('{"query": "{ cases(where: {',
#'                             'Case_creation_date: { gte: \\"2025-01-01\\" }',
#'                           '}) {',
#'                             'items { Case_creation_date, Case_number }',
#'                           '} }"}'))
#' }
HPZone_request_query = function (query, ..., scope=API_env$scope_standard) {
  check_setup()

  if (scope == "standard") scope = API_env$scope_standard
  if (scope == "extended") scope = API_env$scope_extended

  if (...length() > 0) {
    query = sprintf(query, ...)
  }

  data = HPZone_request_raw(paste0('{"query": "{', gsub('"', '\\\\"', query) , '}"}'), scope=scope)
  # eliminate unnecessary listing; the format is something weird like data$cases$items
  while (length(data) == 1 && is.list(data)) {
    data = data[[1]]
  }

  # TODO: error handling
  return(data)
}

#' Performs a HPZone request with the given parameters.
#'
#' Convenience wrapper around [HPZone_request_query()]. This function automatically pulls the available number of records, rather than only the first 500.
#' Note that the current maximum for batching is 500 rows, so increasing n_max is not recommended.
#' This function is mainly intended for use when the query builder in [HPZone_request()] is insufficient. Usage of [HPZone_request()] is considerably easier otherwise.
#'
#' @param query A GraphQL query to send to the HPZone API. Note that keywords 'skip' and 'take' cannot be present in the query; this function will add them.
#' @param ... Parameters to be passed to sprintf(). If empty, the body is not passed through sprintf().
#' @param n_max Maximum number of entries to request per call.
#' @param scope The desired scope; either standard or extended.
#'
#' @return A data frame containing all the responses gathered from the API. Only the items will be returned.
#' @export
#' @importFrom stringr str_locate
#' @importFrom stringr str_sub
#' @importFrom stringr str_detect
#' @importFrom stringr fixed
#' @importFrom dplyr coalesce
#'
#' @seealso [HPZone_request()], [HPZone_convert_dates()]
#'
#' @examples
#' \dontrun{
#' # Note the single quotes to facilitate double quote encapsulation for arguments.
#' HPZone_request_paginated(
#'   paste0('cases(where: {',
#'       'Case_creation_date: { gte: "2025-01-01" }',
#'     '}) {',
#'       'items { Case_creation_date, Case_number }',
#'      '}'))
#' # Or equal, making use of the sprintf integration:
#' startdate = "2025-01-01"
#' fields = c("Case_creation_date", "Case_number")
#' HPZone_request_paginated(
#'   'cases(where: { Case_creation_date: { gte: "%s" } }) { items { %s } }',
#'    startdate, stringr::str_c(fields, collapse=", ")
#' )
#' }
HPZone_request_paginated = function (query, ..., n_max=500, scope=API_env$scope_standard) {
  check_setup()

  if (scope == "standard") scope = API_env$scope_standard
  if (scope == "extended") scope = API_env$scope_extended

  # find selector bracket, or lack thereof
  pos = stringr::str_locate(query, "(?<=[a-zA-Z]{1,10})(\\(|\\{)")
  query_char = stringr::str_sub(query, pos)
  if (query_char == "(") {
    # selector bracket; insert before other selectors
    selectors = stringr::str_sub(query, start=pos[,1]+1, end=stringr::str_locate(query, stringr::fixed(")"))[,1]-1)
    if (stringr::str_detect(selectors, "skip|take")) {
      stop("'skip' or 'take' were present in the query. This is not supported in this function. Please use HPZone_request_query() or HPZone_request_raw() instead.")
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
    pos = unlist(stringr::str_locate_all(query, stringr::fixed("}")))
    pos = max(pos, na.rm=T)
    query = paste0(stringr::str_sub(query, end=pos-1), ", totalCount }")
  }

  if (...length() > 0) {
    query = sprintf(query, ...)
  }

  n_retrieved = 0
  n_present = Inf
  data_total = data.frame()
  while (n_retrieved < n_present) {
    data = HPZone_request_raw(paste0('{"query": "{', gsub('"', '\\\\"', sub("[pageblock]", paste0("take: ", n_max, ", skip: ", n_retrieved), query, fixed=T)) , '}"}'), scope=scope)
    # eliminate unnecessary listing; the format is something weird like data$cases$items
    while (length(data) == 1 && is.list(data)) {
      data = data[[1]]
    }

    n_present = data$totalCount
    data_total = rbind(data_total, data$items)
    n_retrieved = n_retrieved + dplyr::coalesce(nrow(data$items), 0)
  }

  # TODO: error handling
  return(data_total)
}

#' Performs a HPZone request with the given parameters.
#'
#' This function does most of the querybuilding for you, which allows for easier calling.
#' There are several shorthands for field selection, the request is automatically paginated, and the necessary scope is automatically detected from the desired fields.
#' Note that the take and skip elements are, by design, not present. If these are necessary, use [HPZone_request_query()] instead.
#'
#' @param endpoint The requested endpoint. Can be "cases", "situations", "enquiries", "contacts", or "actions". Case mismatch or spelling mismatch is automatically corrected with HPZone_make_valid().
#' @param fields A vector containing the required fields. Spelling is automatically corrected. Alternatively, the keywords "all" (all available fields), "basic" (usual fields for surveillance), "standard" (only fields in the standard scope), or "none"/"id" (only HPZone ID and date) can be used. "basic" and "standard" can be combined: c("basic", "Longitude", "Latitude")
#' @param where Either a vector containing pairs of 3 arguments, a literal query string, or a list outlining the selection criteria. See details.
#' @param order A vector of field=order pairs, e.g. c("Case_creation_date"="ASC"). If no order is supplied, ASC is assumed.
#' @param verbose Whether or not to display the calculated query and scope; useful for debugging query issues.
#'
#' @return An object containing the requested data points. This can be in different forms, depending on the request, but is simplified as much as possible.
#' @export
#' @importFrom stats setNames
#'
#' @seealso  [HPZone_request_paginated()], [HPZone_request_query()], [HPZone_make_valid()], [HPZone_convert_dates()]
#'
#' @details
#' The where clause can be specified in several formats. These can be:
#' * A literal string containing GraphQL. E.g. "Status: \{ eq: \"Open\" \}"
#' * A vector of strings containing three pairs: field, comparator, value. E.g. c("Status", "=", "Open"). Any usual R-style comparators are allowed and automatically translated, GraphQL comparators are left as-is.
#' * A list detailing the structure of the query, containing name-value pairs of keyword-selectors. This allows for complex and/or-structures, see the bottom example.
#'
#' @examples
#' \dontrun{
#' # These statements are equal:
#' HPZone_request("cases", "all",
#'                where=c("Case_creation_date", ">", "2025-10-01"))
#' HPZone_request("cases", "all",
#'                where=c("Case_creation_date", "gt", "2025-10-01"))
#'
#' # Selects cases after 2025-09-01, ordered by infection and then descending date.
#' HPZone_request("cases", "all",
#'                where=c("Case_creation_date", ">", "2025-09-01"),
#'                order=c("Infection", "Case_creation_date"="desc"))
#'
#' # Selects all cases which were registered after 2025-01-01 AND where Infection equals Leptospirosis.
#' HPZone_request("cases", "all",
#'                where=list("and"=c("Case_creation_date", "gte", "2025-01-01",
#'                                   "Infection", "=", "Leptospirosis")))
#' # Note that the default is AND, so this statement is equal:
#' HPZone_request("cases", "all",
#'                where=c("Case_creation_date", "gte", "2025-01-01",
#'                        "Infection", "=", "Leptospirosis"))
#'
#' # All cases after 2025-01-01 with either Leptospirosis or Malaria as infection.
#' # Note the nested list; adding a c() without a list() will warp the structure
#' # of the list and break everything.
#' HPZone_request("cases", "all",
#'                where=list(
#'                 "and"=list(c("Case_creation_date", "gte", "2025-01-01"),
#'                            list("or"=c("Infection", "=", "Leptospirosis",
#'                                        "Infection", "==", "Malaria"))
#'                           )))
#' }
HPZone_request = function (endpoint, fields, where=NA, order=NA, verbose=F) {
  check_setup()

  # valid endpoint?
  if (length(endpoint) != 1) {
    stop("Only one endpoint can be supplied per request.")
  }
  endpoint = HPZone_make_valid(endpoints=endpoint)

  if (length(fields) == 1 && fields == "all") {
    fields = HPZone_fields$field[tolower(HPZone_fields$endpoint) == endpoint]
  } else if (any(fields == "basics") || any(fields == "basic")) {
    # basic subset for each endpoint
    fields = fields[!(fields == "basics" | fields == "basic")]
    fields = c(fields, HPZone_fields$field[tolower(HPZone_fields$endpoint) == endpoint & HPZone_fields$in_basic])
  } else if (any(fields == "standard")) {
    # basic subset for each endpoint
    fields = fields[!(fields == "standard")]
    fields = c(fields, HPZone_fields$field[tolower(HPZone_fields$endpoint) == endpoint & HPZone_fields$scope_standard])
  } else if (length(fields) == 1 && (fields == "id" || fields == "none")) {
    # only request IDs
    if (endpoint == "cases")
      fields = c("Case_number", "Case_creation_date")
    else if (endpoint == "situations")
      fields = c("Situation_number", "Situation_creation_date")
    else if (endpoint == "enquiries")
      fields = c("Enquiry_number", "Received_on")
    else if (endpoint == "actions")
      fields = c("Number", "Date_created")
    else if (endpoint == "contacts")
      fields = c("Contact_number", "Contact_creation_date")
  }
  if (length(fields) == 1) {
    fields = trimws(unlist(strsplit(fields, ",")))
  }
  fields = HPZone_make_valid(endpoint, fields)

  # determine scope
  scope = HPZone_necessary_scope(fields, endpoint)

  # the query is in this format:
  # [endpoint](where?, order?, take?, skip?) { items { [fields] }, totalCount? }
  # e.g. cases(where: { Case_creation_date: { gte: "2020-01-01" } }) { items { Gp, Family_name } }
  # take and skip are not supported in this function, as HPZone_request_paginated() will cycle through those
  selectors = c()
  if ((is.vector(where) && any(!is.na(where))) || !is.na(where)) {
    # where can be in several formats, and with several shorthands
    # this function allows:
    # - a literal string, e.g. "Infection: { eq: "Hepatitis B" }"
    # - a list of selectors, with the name as the logic operator and then a list of three logic elements;
    #   e.g.: list("and"=c("Infection", "==", "Hepatitis B", "Status", "==", "Open"))
    # - R-like syntax: where = "field comparator value", e.g. where = "Infection == "
    # list of selectors
    if (is.list(where) || is.vector(where)) {
      where = parse_query_list(endpoint, where)
    } else if (length(where) == 1 && is.character(where)) {
      if (is.null(names(where))) {
        # literal string, do nothing
      } else {
        # convert syntax
        where = parse_query_list(endpoint, where)
      }
    } else {
      stop("Unknown format for the where clause supplied. Consult the documentation.")
    }

    selectors = c(selectors, paste0("where: { ", where, " }"))
  }
  if ((is.vector(order) && any(!is.na(order))) || !is.na(order)) {
    if (is.null(names(order))) {
      # assume ASC
      order = stats::setNames(rep("ASC", length(order)), order)
    }
    if (any(names(order) == "")) {
      # some values are unnamed; flip name-value pair around
      indexes = names(order) == ""
      values = order[indexes]
      order[indexes] = rep("ASC", sum(indexes))
      names(order)[indexes] = values
    }

    names(order) = HPZone_make_valid(endpoint, fields=names(order))
    order = trimws(toupper(order))

    order_graphql = paste0("{ ", names(order), ": ", unname(order), " }")

    selectors = c(selectors, paste0("order: [", stringr::str_c(order_graphql, collapse=", "), "]"))
  }

  if (length(selectors) > 0) {
    query = paste0(endpoint, "(", stringr::str_c(selectors, collapse=", "), ") { items { ", stringr::str_c(fields, collapse=", "), " } }")
  } else {
    query = paste0(endpoint, " { items { ", stringr::str_c(fields, collapse=", "), " } }")
  }

  if (verbose) message("Executing the following query with scope ", scope, ": ", query)
  data = HPZone_request_paginated(query, scope=scope)

  return(data)
}

graphql_dictionary = c("="="eq", "=="="eq", "!="="neq", ">"="gt", ">="="gte", "<"="lt", "<="="lte", "%in%"="in",
                       "|"="or", "||"="or", "&"="and", "&&"="and")
convert_graphql = function (keyword) {
  keyword = tolower(trimws(keyword))
  if (keyword %in% names(graphql_dictionary)) {
    keyword = graphql_dictionary[keyword]
  }
  return(keyword)
}

parse_query_list = function (endpoint, where) {
  if (is.list(where)) {
    where_elements = c()
    for (i in 1:length(where)) {
      logic = names(where)[i]
      if (is.null(logic) || is.na(logic)) {
        logic = "and"
      } else {
        logic = tolower(logic)
      }

      elements = where[[i]]
      if (is.list(elements)) {
        graphql_elements = c()
        for (j in 1:length(elements)) {
          graphql_elements = c(graphql_elements, parse_query_list(endpoint, elements[j]))
        }
      } else if (is.character(elements) && length(elements) == 3) {
        graphql_elements = parse_query_list(endpoint, elements)
      } else if (is.character(elements) && length(elements) %% 3 == 0) {
        graphql_elements = c()
        for (j in seq(1, length(elements), 3)) {
          graphql_elements = c(graphql_elements, parse_query_list(endpoint, elements[j:(j+2)]))
        }
      } else {
        stop("Query elements should be in multiples of 3; c(\"fieldname\", \"==\", \"value\")")
      }

      if (logic != "" && length(graphql_elements) > 1) {
        graphql = paste0(logic, ": [", stringr::str_c(paste0("{ ", graphql_elements, " }"), collapse=", "), "]")
      } else {
        graphql = stringr::str_c(graphql_elements, collapse=", ")
      }

      where_elements = c(where_elements, graphql)
    }
    return(stringr::str_c(where_elements, collapse=", "))
  } else if (is.character(where) && length(where) == 3) {
    return(paste0(HPZone_make_valid(endpoint, where[1]), ": { ", convert_graphql(where[2]), ": \"", where[3], "\" }"))
  }
  else if (is.character(where) && length(where) %% 3 == 0) {
    return(parse_query_list(endpoint, list("and"=where)))
  }
}
