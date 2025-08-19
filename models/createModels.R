
# omop_assistant ----
name <- "omop_assistant"

prompt <- stringr::str_squish(
  "
  You are an expert R programmer and epidemiologist working with OMOP CDM data.
  Use concise, accurate R examples using OMOPverse packages (e.g. CDMConnector,
  CohortConstructor).

  Before answering:
  - Retrieve relevant documents from the knowledge store.
  - Quote or paraphrase the material retrieved, clearly separating source vs your own explanation.
  - Include direct links to cited content (e.g. .io documentation pages).
  - If no relevant information is found, say 'No information available.'

  Only answer if source material is retrieved.
  "
)

dbdir <- here::here("models", paste0("oa_", name, ".duckdb"))
unlink(dbdir, force = TRUE)
unlink(paste0(dbdir, ".wal"), force = TRUE)

store <- ragnar::ragnar_store_create(
  location = dbdir,
  embed = \(x) ragnar::embed_ollama(x, model = "mxbai-embed-large"),
  name = name
)

# Reading online documentation
links <- c(
  "tidy book" = "https://oxford-pharmacoepi.github.io/Tidy-R-programming-with-OMOP/",
  "CDMConnector" = "https://darwin-eu.github.io/CDMConnector/",
  "omopgenerics" = "https://darwin-eu.github.io/omopgenerics/",
  "CohortConstructor" = "https://ohdsi.github.io/CohortConstructor/",
  "visOmopResults" = "https://darwin-eu.github.io/visOmopResults/",
  "PhenotypeR" = "https://ohdsi.github.io/PhenotypeR/",
  "OmopViewer" = "https://ohdsi.github.io/OmopViewer/",
  "DrugUtilisation" = "https://darwin-eu.github.io/DrugUtilisation/",
  "IncidencePrevalence" = "https://darwin-eu.github.io/IncidencePrevalence/",
  "DrugExposureDiagnostics" = "https://darwin-eu.github.io/DrugExposureDiagnostics/",
  "MeasurementDiagnostics" = "https://ohdsi.github.io/MeasurementDiagnostics/",
  "PatientProfiles" = "https://darwin-eu.github.io/PatientProfiles/",
  "CohortCharacteristics" = "https://darwin-eu.github.io/CohortCharacteristics/",
  "OmopSketch" = "https://OHDSI.github.io/OmopSketch/",
  "CodelistGenerator" = "https://darwin-eu.github.io/CodelistGenerator/",
  # to change darwin-eu-dev to darwin-eu
  "CohortSurvival" = "https://darwin-eu-dev.github.io/CohortSurvival/",
  "omock" = "https://ohdsi.github.io/omock/"
) |>
  purrr::map(ragnar::ragnar_find_links) |>
  purrr::flatten_chr()

# remove uninformative links
links <- links[stringr::str_detect(
  string = links,
  pattern = "CONTRIBUTING\\.html$|LICENSE\\.html$",
  negate = TRUE
)]

# read chunks
chunks <- links |>
  purrr::map(\(link) {
    tryCatch(
      expr = {
        cli::cli_inform(c("i" = "Reading information from {.url {link}}"))
        ragnar::markdown_chunk(ragnar::read_as_markdown(link))
      },
      error = function(e) {
        cli::cli_inform(c("x" = "Failed to read markdown in {.url {link}}"))
        NULL
      })
  }) |>
  purrr::compact()

# Embeding information
cli::cli_inform(c(i = "Embeding retrieved information."))
cli::cli_progress_bar("Embeding", total = length(chunks), type = "tasks")
for (k in seq_along(chunks)) {
  ragnar::ragnar_store_insert(store = store, chunks = chunks[[k]])
  cli::cli_progress_update()
}
cli::cli_progress_done()

# build store index
ragnar::ragnar_store_build_index(store = store)

con <- duckdb::dbConnect(drv = duckdb::duckdb(dbdir = dbdir))
DBI::dbWriteTable(conn = con, name = "oa_prompt", value = dplyr::tibble(prompt = prompt))
DBI::dbDisconnect(conn = con)
