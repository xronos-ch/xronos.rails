#### data preparation #### 

imp <- c14bazAAR::get_aDRAC()

imp %<>% c14bazAAR::calibrate(choices = "calprobdistr")

simple_cal_list <- pbapply::pblapply(imp$calprobdistr, function(x) {
  if (nrow(x) == 0) {
    return(data.frame(bp = NA, std = NA))
  }
  middle <- which.min(abs(cumsum(x$density) - 0.5))
  res_sum <- 0
  i <- 1
  while (res_sum < 0.95) {
    start <- middle - i
    stop <- middle + i
    if (start <= 0) {
      start <- 1
    }
    if (stop > nrow(x)) {
      stop <- nrow(x)
    }
    res_sum <- sum(x$density[start:stop], na.rm = T)  
    i <- i + 1
  }
  return(data.frame(bp = x$calage[middle], std = i))
})

simple_cal <- do.call(rbind, simple_cal_list)

#### make connection to database ####
con <- DBI::dbConnect(RSQLite::SQLite(), dbname = "agora/xronos.rails/db/development.sqlite3")

#### static tables ####

# countries
#countries_cur <- DBI::dbReadTable(con, "countries") %>% tibble::as_tibble()
country_names <- unique(countrycode::codelist$iso.name.en) %>% na.omit()
countries <- tibble::tibble(
  id = 1:length(country_names),
  name = unique(countrycode::codelist$iso.name.en) %>% na.omit(),
  created_at = time,
  updated_at = time
)

DBI::dbRemoveTable(con, "countries")
s <- "
create table countries(
  id PRIMARY KEY NOT NULL,
  name,
  created_at NOT NULL,
  updated_at NOT NULL
)
" %>% gsub("\\n", "", .)
DBI::dbSendStatement(con, s)
DBI::dbWriteTable(con, "countries", countries, append = T)

#### tables ####

get_table <- function(x, con) { DBI::dbReadTable(con, x) %>% tibble::as_tibble() }
get_start_id <- function(x) { (x$id %>% max) + 1 }
add_time_columns <- function(x, time) { x %>% dplyr::mutate(created_at = time, updated_at = time) }
get_time <- function() { format(Sys.time(), "%y-%d-%m %H:%M:%OS6") }

# c14_measurements
c14_measurements_cur <- DBI::dbReadTable(con, "c14_measurements") %>% tibble::as_tibble()

start_id <- (c14_measurements_cur$id %>% max) + 1

c14_measurements_add <- tibble::tibble(
  id = seq(start_id, start_id + nrow(imp) - 1),
  bp = imp$c14age,
  std = imp$c14std,
  cal_bp = simple_cal$bp,
  cal_std = simple_cal$std,
  delta_c13 = imp$c13val,
  delta_c13_std = NA_real_,
  method = NA_character_
) %>%
  add_time_columns(
    get_time()
  )

DBI::dbWriteTable(con, "c14_measurements", c14_measurements_add, append = T)

# references
references_cur <- get_table("references", con)
start_id <- get_start_id(references_cur)

imp_refs <- imp$shortref %>% unique %>%
  gsub("\\:[^;]+(\\;|$)", ";", .) %>%
  gsub("\\;$", "", .) %>%
  strsplit(., ";") %>%
  unlist %>%
  trimws()

references_add <- tibble::tibble(
  id = seq(start_id, start_id + length(imp_refs) - 1),
  name = imp_refs
) %>%
  add_time_columns(
    get_time()
  )

measurements_references <- tibble::tibble(
  reference_id = references_add$id,
  measurement_id = references_add$name %>% pbapply::pblapply(function(x) {
    grep(x, imp$shortref)
  })
) %>% tidyr::unnest()

