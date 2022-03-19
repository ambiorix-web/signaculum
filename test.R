devtools::load_all()
library(ambiorix)

app <- Ambiorix$new()

app$get("/", \(req, res) {
  res$send("Hello")
})

favicon <- system.file("favicon.ico", package = "signaculum")
app$get("/favicon.ico", signaculum(favicon))

app$start()
