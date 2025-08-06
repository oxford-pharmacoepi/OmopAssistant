
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

content <- pkgs |>
  # find URL in descciption
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
  purrr::flatten_chr() |>
  append(book) |>
  # find sublinks
  purrr::map(\(x) {
    cli::cli_inform(c("i" = "Finding links for {.url {x}}"))
    links <- ragnar::ragnar_find_links(x = x)
  }) |>
  purrr::flatten_chr() |>
  # read chuncks
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
  embed = \(x) ragnar::embed_ollama(x, model = "mxbai-embed-large"),
  name = "omopverse"
)

purrr::map(content, \(x) ragnar::ragnar_store_insert(store = store, chunks = x))

ragnar::ragnar_store_build_index(store = store)

store <- ragnar::ragnar_store_connect(location = here::here("ollama.ragnar.duckdb"))

#'  Register ellmer tool
#' You can register an ellmer tool to let the LLM retrieve chunks.
system_prompt <- stringr::str_squish(
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
chat <- ellmer::chat_google_gemini(system_prompt = system_prompt)

ragnar::ragnar_register_tool_retrieve(chat = chat, store = store, top_k = 10L)

chat$chat("How can I create a cohort of acetaminophen users?")
