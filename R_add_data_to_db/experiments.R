source("helper_functions.R")

#### data preparation #### 

imp <- c14bazAAR::get_aDRAC()

imp %<>% c14bazAAR::calibrate(choices = "calprobdistr")

imp %<>% add_simple_cal()

imp %<>% c14bazAAR::finalize_country_name()

#### make connection to database ####
con <- DBI::dbConnect(
  RPostgres::Postgres(), 
  dbname = 'testdb', 
  host = '127.0.0.1', # i.e. 'ec2-54-83-201-96.compute-1.amazonaws.com'
  port = 5432, # or any other port specified by your DBA
  user = 'ultimate_postgres',
  password = 'nudelsalat'
)

#### helper functions ####
add_time_columns <- function(x, time = get_time()) { x %>% dplyr::mutate(created_at = time, updated_at = time) }
get_time <- function() { format(Sys.time(), "%Y-%m-%d %H:%M:%OS3") }

#### static (?) tables ####

# countries
country_names <- unique(countrycode::codelist$country.name.en) %>% na.omit()
countries <- tibble::tibble(
  id = 1:length(country_names),
  name = country_names
) %>% add_time_columns()

DBI::dbRemoveTable(con, "countries")
s <- "
create table countries(
  id integer NOT NULL PRIMARY KEY,
  name character(100),
  created_at timestamp NOT NULL,
  updated_at timestamp NOT NULL
)
" %>% gsub("\\n", "", .)
DBI::dbSendStatement(con, s)
DBI::dbWriteTable(con, "countries", countries, append = T)

#### helper functions ####

get_table <- function(x, con) { 
  DBI::dbReadTable(con, x) %>% tibble::as_tibble() 
}

exists_in_db <- function(new_value, old_vector) {
  exists <- FALSE
  if ( new_value %in% old_vector ) {
    exists <- TRUE
  }
  return(exists)
}

get_new_id <- function(id_vector) {
  if ( length(id_vector) > 0 ) {
    id <- max(id_vector) + 1
  } else {
    id <- 0
  }
  return(id)
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
  
  refcurref <- references_cur$short_ref
  refcurid <- references_cur$id
  references.ids <- c()
  for (i in 1:length(references.short_refs)) {
    nid <- get_id(references.short_refs[i], refcurref, refcurid)
    references.ids <- append(references.ids, nid)
    if (!is.na(nid)) {
      refcurid <- append(refcurid, nid)
      refcurref <- append(refcurref, references.short_refs[i])
    }
  }
  
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
      material_id = materials.id,
      species_id = NA,
      on_site_object_position_id = on_site_object_positions.id,
      site_phase_id = site_phases.id
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% arch_objects_cur$id)),
    append = T
  )

  # samples
  DBI::dbWriteTable(
    con, "samples", 
    tibble::tibble(
      id = samples.id,
      arch_object_id = arch_objects.id
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% samples_cur$id)),
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
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% c14_measurements_cur$id)),
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
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% measurements_cur$id)),
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
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% references_cur$id)),
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
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% site_phases_cur$id)),
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
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% periods_cur$id)),
    append = T
  )
  
  # periods_site_phases
  DBI::dbWriteTable(
    con, "periods_site_phases", 
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
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% typochronological_units_cur$id)),
    append = T
  )
  
  # site_phases_typochronological_units
  DBI::dbWriteTable(
    con, "site_phases_typochronological_units", 
    tibble::tibble(
      site_phase_id = site_phases.id,
      typochronological_unit_id = typochronological_units.id
    )  %>% 
      dplyr::filter(!is.na(site_phase_id) & !is.na(typochronological_unit_id)),
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
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% sites_cur$id)),
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
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% countries_cur$id)),
    append = T
  )
  
  # on_site_object_positions
  DBI::dbWriteTable(
    con, "on_site_object_positions", 
    tibble::tibble(
      id = on_site_object_positions.id,
      feature = on_site_object_positions.feature,
      coord_reference_system = NA,
      coord_X = NA,
      coord_Y = NA,
      coord_Z = NA,
      feature_type_id = NA
    ) %>% 
      add_time_columns() %>% 
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% on_site_object_positions_cur$id)),
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
      dplyr::filter(!is.na(id)) %>%
      dplyr::filter(!(id %in% materials_cur$id)),
    append = T
  )
  
}

DBI::dbDisconnect(con)

