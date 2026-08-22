source(file.path(Sys.getenv("SVI_ROOT", ".."), "code", "00_config.R"))
suppressPackageStartupMessages(library(data.table))
tabs <- c("B01001","B01003","B03002","B11012","B15002","B16005","B18101",
          "B23025","B25003","B25014","B25024","B25044","B25106","B26001","C17002")
for (t in tabs) {
  d <- fread(file.path(DIR_RAW, sprintf("%s_22.csv", t)), select=c("TBLID","GEOID","ORDER","TITLE"),
             showProgress=FALSE)
  d <- d[!is.na(ORDER)]
  lab <- unique(d[, .(ORDER, TITLE)])[order(ORDER)]
  cat("\n#####", t, " ntract=", uniqueN(d$GEOID), " nlines=", nrow(lab), "\n", sep="")
  print(lab, nrows=60, class=FALSE)
}
