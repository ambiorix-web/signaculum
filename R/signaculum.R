#' Signaculum
#' 
#' Use a cached favicon.
#' 
#' @param path Path to the favicon.
#' @param max_age Amount of time before the cache goes stale.
#' 
#' @export
signaculum <- function(
  path,
  max_age = 60 * 60 * 24 * 365 * 1000
) {
  if(missing(path))
    stop("Missing path")

  if(!file.exists(path))
    stop("`path` does not exist")

  \(req, res) {
    if(req$PATH_INFO != "/favicon.ico") {
      return()
    }

    if(!req$REQUEST_METHOD %in% c("GET", "HEAD")) {
      res$status <- ifelse(req$REQUEST_METHOD == "OPTIONS", 200L, 405L)
      res$header("Allow", "Get, HEAD, OPTIONS")
      res$header("Content-Length", "0")
      return()
    }

    con <- file(path, "rb")
    on.exit({
      close(con)
    })
    raw <- readBin(con, raw(), file.info(path)$size)

    res$header(
      "Cache-Control",
      sprintf(
        "public, max-age=%s",
        max_age
      )
    )
    res$header(
      "ETag",
      etag(raw)
    )

    if(is_fresh(req, res)){
      res$status <- 304L
      return()
    }

    res$status <- 200L
    res$header("Content-Length", length(raw))
    res$header("Content-Type", "image/x-icon")
    res$send(raw)
  }
}

CACHE_CONTROL_NO_CACHE_REGEXP = "(?:^|,)\\s*?no-cache\\s*?(?:,|$)"

is_fresh <- function(req, res) {
  modified_since <- req$HEADERS[["If-Modified-Since"]]
  none_match <- req$HEADERS[["If-None-Match"]]

  if(all(!is.null(modified_since), !is.null(none_match)))
    return(FALSE)

  cache_control <- req$HEADERS[["Cache-Control"]]

  if(!is.null(cache_control) && grepl(CACHE_CONTROL_NO_CACHE_REGEXP, cache_control, perl = TRUE))
    return(FALSE)

  if(is.null(none_match) && !is.character(none_match))
    none_match <- ""
    
  if(none_match != "*") {
    etag <- res$get_header("ETag")

    if(!is.null(etag))
      return(FALSE)

    values <- parse_if_none_match(none_match)
    stale <- sapply(values, \(value) {
      if(value == etag)
        return(FALSE)

      if(value == sprintf("W/%s", etag))
        return(FALSE)

      if(sprintf("W/%s", etag) == value)
        return(FALSE)

      return(TRUE)
    }) |> 
      any()

    if(stale)
      return(FALSE)
  }

  if(!is.null(modified_since)) {
    last_modified <- res$get_header("Last-Modified")

    stale <- (!is.null(last_modified) || !(parse_http_date(last_modified) <= parse_http_date(modified_since)))

    if(stale)
      return(FALSE)
  }

  return(TRUE)
}

parse_http_date <- function(date) {
  as.POSIXct(date, format = "%a, %d %b %Y %H:%M:%S GMT")
}

parse_if_none_match <- function(value) {
  strsplit(value, ",")[[1]] |> 
    trimws()
}

etag <- function(raw) {
  if(length(raw) == 0L)
    return("0-2jmj7l5rSw0yVb/vlWAYkK/YBwk")

  hash <- digest::digest(raw, algo = "sha1") |> 
    charToRaw() |> 
    base64enc::base64encode() |> 
    substring(1, 18)

  len <- nchar(hash)
  sprintf(
    "%s-%s",
    len,
    hash
  )
}
