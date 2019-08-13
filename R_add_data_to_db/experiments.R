get_table <- function(x, con) { DBI::dbReadTable(con, x) %>% tibble::as_tibble() }
get_start_id <- function(x) { (x$id %>% max) + 1 }

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

imp %<>% dplyr::mutate(
  cal_bp = simple_cal$bp,
  cal_std = simple_cal$std
) 

imp %<>% c14bazAAR::finalize_country_name()

#### make connection to database ####
con <- DBI::dbConnect(RSQLite::SQLite(), dbname = "agora/xronos.rails/db/development.sqlite3")

#### tables ####

# countries
country_names <- unique(countrycode::codelist$country.name.en) %>% na.omit()
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

# typochronological units and site_phases
typochronological_units_cur <- get_table("typochronological_units", con)
site_phases_cur <- get_table("site_phases", con)
typochronological_units_site_phases_cur <- get_table("site_phases_typochronological_units", con)

ty_sp_names <- imp %>% dplyr::select(site, culture) %>%
  dplyr::filter(
    !is.na(site) & !is.na(culture)
  )

ty <- typochronological_units_cur %>% dplyr::select(id, name)
sp <- site_phases_cur %>% dplyr::select(id, name)

ty_sp_ids <- tibble::tibble(
  site_phase_id = sapply(ty_sp_names$site, function(x) { sp$id[x == sp$name] }),
  typochronological_unit_id = sapply(ty_sp_names$culture, function(x) { ty$id[x == ty$name] })
)

typochronological_units_site_phases_new <- rbind(ty_sp_ids, typochronological_units_site_phases_cur) %>% unique

DBI::dbWriteTable(con, "site_phases_typochronological_units", typochronological_units_site_phases_new, append = T)

# measurements
measurements_cur <- get_table("measurements", con)

measurements_add <- tibble::tibble(
  labnr = imp$labnr,
  sample_id = NA,
  lab_id = NA,
  c14_measurement_id = NA
) %>% add_time_columns()

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

##############################
#### alternative approach ####
##############################

exists_in_db <- function(new_value, old_vector) {
  exists <- FALSE
  if ( new_value %in% old_vector ) {
    exists <- TRUE
  }
  return(exists)
}

get_id <- function(new_value, old_vector, id_vector) {
  if ( is.na(new_value) ) {
    id <- NA
  } else if ( exists_in_db(new_value, old_vector) ) {
    id <- id_vector[new_value == old_vector][1]
  } else {
    id <- get_new_id(id_vector)
  }
  return(id)
}

get_new_id <- function(id_vector) {
  if ( length(id_vector) > 0 ) {
    id <- max(id_vector) + 1
  } else {
    id <- 0
  }
  return(id)
}

add_time_columns <- function(x, time = get_time()) { x %>% dplyr::mutate(created_at = time, updated_at = time) }
get_time <- function() { format(Sys.time(), "%y-%d-%m %H:%M:%OS6") }

for (i in 1:nrow(imp)) {
  cur <- imp[i,]

  #### preparing variables ####
  
  # arch_objects
  arch_objects_cur <- get_table("arch_objects", con)
  arch_objects.id <- get_new_id(arch_objects_cur$id)

  # samples
  samples_cur <- get_table("samples", con)
  samples.id <- get_new_id(samples_cur$id)
  
  # measurements
  measurements_cur <- get_table("measurements", con)
  measurements.labnr <- cur$labnr
  if (is.na(measurements.labnr) | exists_in_db(measurements.labnr, measurements_cur$labnr)) {
    next
  }
  measurements.id <- get_id(measurements.labnr, measurements_cur$labnr, measurements_cur$id)

  # c14_measurements
  c14_measurements_cur <- get_table("c14_measurements", con)
  c14_measurements.bp <- cur$c14age
  c14_measurements.std <- cur$c14std
  c14_measurements.cal_bp <- cur$cal_bp
  c14_measurements.cal_std <- cur$cal_std
  c14_measurements.delta_c13 <- cur$c13val
  c14_measurements.id <- get_new_id(c14_measurements_cur$id)
  
  # references
  references_cur <- get_table("references", con)
  references.short_refs <- cur$shortref %>% 
    gsub("\\:[^;]+(\\;|$)", ";", .) %>%
    gsub("\\;$", "", .) %>%
    strsplit(., ";") %>%
    unlist %>%
    trimws()
  references.ids <- sapply(
    references.short_ref, 
    function(x, y, z) {
      get_id(x, y, z)
    },
    y = references_cur$short_ref,
    z = references_cur$id
  )
  
  # site_phases
  site_phases_cur <- get_table("site_phases", con)
  site_phases.name <- cur$site
  site_phases.id <- get_id(site_phases.name, site_phases_cur$name, site_phases_cur$id)
  
  # periods
  periods_cur <- get_table("periods", con)
  periods.name <- cur$period
  periods.id <- get_id(periods.name, periods_cur$name, periods_cur$id)
  
  # typochronological units
  typochronological_units_cur <- get_table("typochronological_units", con)  
  typochronological_units.name <- cur$culture
  typochronological_units.id <- get_id(typochronological_units.name, typochronological_units_cur$name, typochronological_units_cur$id)
  
  # sites
  sites_cur <- get_table("sites", con)
  sites.name <- cur$site
  sites.lat <- cur$lat
  sites.lng <- cur$lon
  sites.id <- get_id(sites.name, sites_cur$name, sites_cur$id)

  # countries
  countries_cur <- get_table("countries", con)
  countries.name <- cur$country_final
  countries.id <- get_id(countries.name, countries_cur$name, countries_cur$id)
  
  # on_site_object_positions
  on_site_object_positions_cur <- get_table("on_site_object_positions", con)
  on_site_object_positions.feature <- cur$feature
  on_site_object_positions.id <- get_new_id(on_site_object_positions_cur$id)
  
  # materials
  materials_cur <- get_table("materials", con)
  materials.name <- cur$material
  materials.id <- get_id(materials.name, materials_cur$name, materials_cur$id)

  #### writing tables ####
  
  # arch_objects
  DBI::dbWriteTable(
    con, "arch_objects", 
    tibble::tibble(
      id = arch_objects.id,
      materials_id = materials.id,
      species_id = NA,
      on_site_object_positions_id = on_site_object_positions.id,
      site_phase_id = site_phases.id
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )

  # samples
  DBI::dbWriteTable(
    con, "samples", 
    tibble::tibble(
      id = samples.id,
      arch_objects_id = arch_objects.id
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
  # measurements
  DBI::dbWriteTable(
    con, "measurements", 
    tibble::tibble(
      id = measurements.id,
      labnr = measurements.labnr,
      sample_id = samples.id,
      lab_id = NA,
      c14_measurement_id = c14_measurements.id
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
  # c14_measurements
  DBI::dbWriteTable(
    con, "c14_measurements", 
    tibble::tibble(
      id = c14_measurements.id,
      bp = c14_measurements.bp,
      std = c14_measurements.std,
      cal_bp = c14_measurements.cal_bp,
      cal_std = c14_measurements.cal_std,
      delta_c13 = c14_measurements.delta_c13,
      delta_c13_std = NA,
      method = NA
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )

  # references
  DBI::dbWriteTable(
    con, "references", 
    tibble::tibble(
      id = references.ids,
      short_ref = references.short_refs,
      bibtex = NA
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
  # measurements_references
  DBI::dbWriteTable(
    con, "measurements_references", 
    tibble::tibble(
      measurement_id = measurements.id,
      reference_id = references.ids
    ) %>% 
      dplyr::filter(!is.na(measurement_id) & !is.na(reference_id)),
    append = T
  )
  
  # site_phases
  DBI::dbWriteTable(
    con, "site_phases", 
    tibble::tibble(
      id = site_phases.id,
      name = site_phases.name,
      approx_start_time = NA,
      approx_end_time = NA,
      site_id = sites.id,
      site_type_id = NA
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
  # periods
  DBI::dbWriteTable(
    con, "periods", 
    tibble::tibble(
      id = periods.id,
      name = periods.name,
      approx_start_time = NA,
      approx_end_time = NA,
      parent_id = NA 
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
  # periods_site_phases
  DBI::dbWriteTable(
    con, "measurements_references", 
    tibble::tibble(
      site_phase_id = site_phases.id,
      period_id = periods.id
    ) %>% 
      dplyr::filter(!is.na(site_phase_id) & !is.na(period_id)),
    append = T
  )
  
  # typochronological_units
  DBI::dbWriteTable(
    con, "typochronological_units", 
    tibble::tibble(
      id = typochronological_units.id,
      name = typochronological_units.name,
      approx_start_time = NA,
      approx_end_time = NA,
      parent_id = NA 
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
  # site_phases_typochronological_units
  DBI::dbWriteTable(
    con, "site_phases_typochronological_units", 
    tibble::tibble(
      site_phase_id = site_phases.id,
      period_id = typochronological_units.id
    )  %>% 
      dplyr::filter(!is.na(site_phases.id) & !is.na(period_id)),
    append = T
  )
  
  # sites
  DBI::dbWriteTable(
    con, "sites", 
    tibble::tibble(
      id = sites.id,
      name = sites.name,
      lat = sites.lat,
      lng = sites.lng,
      country_id = countries.id
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
  # countries
  DBI::dbWriteTable(
    con, "countries", 
    tibble::tibble(
      id = countries.id,
      name = countries.name
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
  # on_site_object_positions
  DBI::dbWriteTable(
    con, "on_site_object_positions", 
    tibble::tibble(
      id = on_site_object_positions.id,
      feature = on_site_object_positions.feature,
      coord_reference_sytem = NA,
      coord_X = NA,
      coord_Y = NA,
      coord_Z = NA,
      feature_type_id = NA
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
  # materials
  DBI::dbWriteTable(
    con, "materials", 
    tibble::tibble(
      id = materials.id,
      name = materials.name
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)),
    append = T
  )
  
}

