
# book
book <- "https://oxford-pharmacoepi.github.io/Tidy-R-programming-with-OMOP/"

# packages
pkgs <- c(
  "CDMConnector", "omopgenerics", "CohortConstructor", "visOmopResults",
  "PhenotypeR", "OmopViewer", "DrugUtilisation", "IncidencePrevalence",
  "DrugExposureDiagnostics", "MeasurementDiagnostics", "PatientProfiles",
  "CohortCharacteristics", "OmopSketch", "CodelistGenerator",
  "CohortSurvival", "omock"
)

urls <- pkgs |>
  purrr::map(\(pkg) {
    con <- url(paste0("https://raw.githubusercontent.com/cran/", pkg, "/refs/heads/master/DESCRIPTION"))
    x <- read.dcf(con) |>
      dplyr::as_tibble() |>
      dplyr::pull("URL") |>
      stringr::str_split_1(pattern = ",\\s*") |>
      purrr::keep(\(x) stringr::str_detect(string = x, pattern = "\\.io"))
    close(con)
    return(x)
  }) |>
  purrr::flatten_chr()
urls <- c(book, urls) |>
  purrr::map(\(x) {
    cli::cli_inform(c("i" = "Finding links for {.url {x}}"))
    links <- ragnar::ragnar_find_links(x = x)
  }) |>
  purrr::flatten_chr() |>
  purrr::map(\(x) {
    tryCatch({
      cli::cli_inform(c("i" = "Reading markdown for {.url {x}}"))
      res <- ragnar::markdown_chunk(ragnar::read_as_markdown(x))
    }, error = function(e) {
      cli::cli_inform(c("x" = "Failed to read markdown"))
      NULL
    })
  }) |>
  purrr::compact()

store_location <- here::here("ollama.ragnar.duckdb")
file.remove(store_location)

store <- ragnar::ragnar_store_create(
  store_location,
  embed = \(x) ragnar::embed_ollama(x, model = "nomic-embed-text"),
  name = "omopverse"
)

urls |>
  purrr::map(\(x) ragnar::ragnar_store_insert(store = store, chunks = x))

ragnar_store_build_index(store)

store <- ragnar::ragnar_store_connect(location = here::here("ollama.ragnar.duckdb"))

#'  Register ellmer tool
#' You can register an ellmer tool to let the LLM retrieve chunks.
system_prompt <- stringr::str_squish(
  "
  You are an expert R programmer in the OMOP CDM. You are a good mentor giving
  concise and terse instructions.

  Before responding, retrieve relevant material from the knowledge store. Quote or
  paraphrase passages, clearly marking your own words versus the source. Provide a
  working link for every source cited, as well as any additional relevant links.
  Do not answer unless you have retrieved and cited a source.
  "
)
chat <- ellmer::chat_ollama(
  system_prompt = system_prompt,
  model = "llama3.1"
)

ragnar::ragnar_register_tool_retrieve(chat = chat, store = store, top_k = 10L)

res <- chat$chat("How can I create a cohort of acetaminophen users?")
