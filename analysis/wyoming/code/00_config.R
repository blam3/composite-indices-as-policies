## ---------------------------------------------------------------------------
## 00_config.R -- paths. Sourced by every other script.
## Set SVI_ROOT to the audit folder; everything else hangs off it.
## Override with:  export SVI_ROOT=/path/to/svi-wp1-audit
## ---------------------------------------------------------------------------
SVI_ROOT <- Sys.getenv("SVI_ROOT", unset = normalizePath(file.path(dirname(
  tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) "code/x")), ".."),
  mustWork = FALSE))
if (!dir.exists(SVI_ROOT)) SVI_ROOT <- normalizePath("..", mustWork = FALSE)

## The only state-specific lines. Porting to another state changes these two.
STATE_FIPS <- "56"
STATE_NAME <- "Wyoming"

DIR_RAW  <- file.path(SVI_ROOT, "data", "raw", "140")
DIR_WORK <- file.path(SVI_ROOT, "work")
DIR_OUT  <- file.path(SVI_ROOT, "outputs-rerun")
F_CDC    <- file.path(SVI_ROOT, "data", "raw", paste0(STATE_NAME, ".csv"))
VRT_FILE <- function(tbl) file.path(DIR_RAW, sprintf("%s_%s.csv", tbl, STATE_FIPS))
dir.create(DIR_WORK, showWarnings = FALSE, recursive = TRUE)
dir.create(DIR_OUT,  showWarnings = FALSE, recursive = TRUE)
stopifnot(dir.exists(DIR_RAW), file.exists(F_CDC))
