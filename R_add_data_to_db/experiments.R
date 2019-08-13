get_table <- function(x, con) { DBI::dbReadTable(con, x) %>% tibble::as_tibble() }
get_start_id <- function(x) { (x$id %>% max) + 1 }
add_time_columns <- function(x, time = get_time()) { x %>% dplyr::mutate(created_at = time, updated_at = time) }
get_time <- function() { format(Sys.time(), "%y-%d-%m %H:%M:%OS6") }

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

#### tables ####

# countries
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

imp_refs <- imp$shortref %>% 
  unique %>%
  gsub("\\:[^;]+(\\;|$)", ";", .) %>%
  gsub("\\;$", "", .) %>%
  strsplit(., ";") %>%
  unlist %>%
  trimws() %>%
  unique

references_add <- tibble::tibble(
  short_ref = imp_refs[!(imp_refs %in% references_cur$short_ref)]
) %>% add_time_columns()

DBI::dbWriteTable(con, "references", references_add, append = T)

# references_cur <- get_table("references", con)
# 
# measurements_references <- tibble::tibble(
#   reference_id = references_add$id,
#   measurement_id = references_add$name %>% pbapply::pblapply(function(x) {
#     grep(x, imp$shortref)
#   })
# ) %>% tidyr::unnest() %>%
#   add_time_columns(
#     get_time()
#   )

# labs
labs_cur <- get_table("labs", con)

# periods
periods_cur <- get_table("periods", con)

unique_periods <- unique(imp$period) %>% na.omit()

periods_add <- tibble::tibble(
  name = unique_periods[!(unique_periods %in% periods_cur$name)],
  approx_start_time = NA,
  approx_end_time = NA,
  parent_id = NA,
) %>% add_time_columns()

DBI::dbWriteTable(con, "periods", periods_add, append = T)

# typochronological_units
typochronological_units_cur <- get_table("typochronological_units", con)

unique_typochronological_units <- unique(imp$culture) %>% na.omit()

typochronological_units_add <- tibble::tibble(
  name = unique_typochronological_units[!(unique_typochronological_units %in% typochronological_units_cur$name)],
  approx_start_time = NA,
  approx_end_time = NA,
  parent_id = NA,
) %>% add_time_columns()

DBI::dbWriteTable(con, "typochronological_units", typochronological_units_add, append = T)

# on_site_object_positions
# on_site_object_positions_cur <- get_table("on_site_object_positions", con)
# 
# unique_features <- unique(imp$feature) %>% na.omit()
# 
# on_site_object_positions_add <- tibble::tibble(
#   feature = unique_features,
#   approx_start_time = NA,
#   approx_end_time = NA,
#   parent_id = NA,
# ) %>% add_time_columns()

# materials
materials_cur <- get_table("materials", con)

unique_materials <- unique(imp$material) %>% na.omit()

materials_add <- tibble::tibble(
  name = unique_materials[!(unique_materials %in% materials_cur$name)],
) %>% add_time_columns()

DBI::dbWriteTable(con, "materials", materials_add, append = T)

# sites
sites_cur <- get_table("sites", con)

unique_sites <- imp %>% dplyr::select(site, lat, lon) %>% 
  dplyr::group_by(site) %>%
  dplyr::summarise(
    lat = mean(lat),
    lon = mean(lon)
  ) %>%
  dplyr::filter(
    !(site %in% sites_cur$name),
  )

sites_add <- tibble::tibble(
  name = unique_sites$site,
  lat = unique_sites$lat,
  lng = unique_sites$lon,
  country_id = NA
) %>% add_time_columns()

DBI::dbWriteTable(con, "sites", sites_add, append = T)

# site_phases
site_phases_cur <- get_table("site_phases", con)
sites_cur <- get_table("sites", con)

unique_site_phases <- imp %>% dplyr::select(site) %>% unique %>%
  dplyr::filter(
    !(site %in% site_phases_cur$name),
  )

site_ids <- sapply(unique_site_phases$site, function(x) {
  sites_cur[x == sites_cur$name, ]$id
}) %>% unlist()

site_phases_add <- tibble::tibble(
  name = unique_site_phases$site,
  approx_start_time = NA,
  approx_end_time = NA,
  site_id = site_ids,
  site_type_id = NA,
) %>% add_time_columns()

DBI::dbWriteTable(con, "site_phases", site_phases_add, append = T)

# periods and site_phases
periods_cur <- get_table("periods", con)
site_phases_cur <- get_table("site_phases", con)
periods_site_phases_cur <- get_table("periods_site_phases", con)

pe_sp_names <- imp %>% dplyr::select(site, period) %>%
  dplyr::filter(
    !is.na(site) & !is.na(period)
  )

pe <- periods_cur %>% dplyr::select(id, name)
sp <- site_phases_cur %>% dplyr::select(id, name)

pe_sp_ids <- tibble::tibble(
  site_phase_id = sapply(pe_sp_names$site, function(x) { sp$id[x == sp$name] }),
  period_id = sapply(pe_sp_names$period, function(x) { pe$id[x == pe$name] })
)

periods_site_phases_new <- rbind(pe_sp_ids, periods_site_phases_cur) %>% unique

DBI::dbWriteTable(con, "periods_site_phases", periods_site_phases_new, append = T)
