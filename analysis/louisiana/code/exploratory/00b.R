source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages(library(data.table))
for (t in c("B25106","B26001","B27001","C17002")) {
  d <- fread(file.path(DIR_RAW, sprintf("%s_22.csv", t)), select=c("GEOID","ORDER","TITLE"), showProgress=FALSE)
  d <- d[!is.na(ORDER)]
  lab <- unique(d[, .(ORDER, TITLE)])[order(ORDER)]
  cat("\n#####", t, " ntract=", uniqueN(d$GEOID), "\n", sep="")
  print(lab, nrows=50, class=FALSE)
}
