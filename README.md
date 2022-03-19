<!-- badges: start -->
<!-- badges: end -->

# signaculum

Caches favicons for [ambiorix](https://ambiorix.dev).

## Installation

``` r
# install.packages("remotes")
remotes::install_github("devOpifex/signaculum")
```

## Example

Serve the favicon with `signaculum`, pass it the path to your
`favicon.ico`.

``` r
library(signaculum)
library(ambiorix)

app <- Ambiorix$new()

app$get("/", \(req, res) {
  res$send("Hello")
})

# path to favicon
favicon <- system.file("favicon.ico", package = "signaculum")

# serve it with signaculum
app$get("/favicon.ico", signaculum(favicon))

app$start()
```
