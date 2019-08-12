con <- DBI::dbConnect(RSQLite::SQLite(), dbname = "agora/xronos.rails/db/development.sqlite3")

DBI::dbListTables(con)

DBI::dbListFields(con, "species")
DBI::dbReadTable(con, "species")

time <- format(Sys.time(), "%y-%d-%m %H:%M:%OS6")

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
