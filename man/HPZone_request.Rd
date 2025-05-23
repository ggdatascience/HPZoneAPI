% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/HPZone_request.R
\name{HPZone_request}
\alias{HPZone_request}
\title{Performs a HPZone request with the given parameters.}
\usage{
HPZone_request(query, scope = API_env$scope_standard)
}
\arguments{
\item{query}{A GraphQL query to send to the HPZone API.}

\item{scope}{The desired scope; either standard or extended.}
}
\value{
An object containing the requested data points. This can be in different forms, depending on the request, but is simplified as much as possible.
}
\description{
Performs a HPZone request with the given parameters.
}
