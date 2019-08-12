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

time <- format(Sys.time(), "%y-%d-%m %H:%M:%OS6")

#### static tables ####

# countries
countries_cur <- DBI::dbReadTable(con, "countries") %>% tibble::as_tibble()

country_names <- unique(countrycode::codelist$iso.name.en) %>% na.omit()
countries <- tibble::tibble(
  id = 1:length(country_names),
  name = unique(countrycode::codelist$iso.name.en) %>% na.omit(),
  created_at = time,
  updated_at = time
)
DBI::dbWriteTable(con, "countries", countries, overwrite = T)

#### tables ####

c14_measurements_cur <- DBI::dbReadTable(con, "c14_measurements") %>% tibble::as_tibble()

c14_measurements_add <- tibble::tibble(
  bp = imp$c14age,
  std = imp$c14std,
  cal_bp = simple_cal$bp,
  cal_std = simple_cal$std,
  delta_c13 = imp$c13val,
  delta_c13_std = NA_real_,
  method = NA_character_,
  created_at = time,
  updated_at = time
)



feature_types_cur <- DBI::dbReadTable(con, "feature_types") %>% tibble::as_tibble()

feature_types



con <- DBI::dbConnect(RSQLite::SQLite(), dbname = "agora/xronos.rails/db/development.sqlite3")



DBI::dbListTables(con)
DBI::dbListFields(con, "species")
DBI::dbReadTable(con, "species")




DBI::dbAppendTable(
  con, "species", 
  tibble::tibble(
    id = 6,
    name = "Husten",
    created_at = time,
    updated_at = time
  )
)

DBI::dbDisconnect(con)
