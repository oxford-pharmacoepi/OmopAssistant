
#' Path to a store
#'
#' @param name Store name.
#'
#' @return String with the path to the store.
#' @export
#'
#' @examples
#' \donttest{
#' Sys.setenv("OMOP_DATA_FOLDER" = tempdir())
#' storePath()
#' }
#'
storePath <- function(name = "omop_assistant.duckdb") {
  # input check
  name <- dbName(name)

  # get model path
  path <- .storePath(name = name)

  # check if exits
  if (!file.exists(path)) {
    cli::cli_warn(c(x = "store does not exist: {.path {path}}"))
  }

  return(path)
}

#' Create a store
#'
#' @param embed A function that is called with a character vector and returns a
#' matrix of embeddings. Note this function will be serialised and then
#' deserialised in new R sessions, so it cannot reference to any objects in the
#' global or parent environments. Make sure to namespace all function calls with
#' ::. If additional R objects must be available in the function, you can
#' optionally supply a carrier::crate() with packaged data. It can also be NULL
#' for stores that don't need to embed their texts, for example, if only using
#' FTS algorithms such as ragnar_retrieve_bm25().
#' @param name Store name.
#' @param overwrite Whether to overwrite a preexisting store.
#'
#' @return String with the path to the store.
#' @export
#'
#' @examples
#' \donttest{
#' storeCreate(
#'   embed = \(x) ragnar::embed_ollama(x, model = "mxbai-embed-large"),
#'   name = "my_omop_assistant"
#' )
#'
#' chat <- ellmerChat(
#'   name = "my_omop_assistant",
#'   chat = ellmer::chat_google_gemini(),
#'   top_k = 10L
#' )
#'
#' chat$chat("How to create an acetaminophen cohort?")
#' }
#'
storeCreate <- function(embed,
                        name = "omop_assistant",
                        overwrite = FALSE) {
  # input check
  name <- dbName(name)
  omopgenerics::assertLogical(overwrite, length = 1)

  # get db directory
  dbdir <- .storePath(name = name)

  # check if exist
  if (file.exists(dbdir)) {
    if (overwrite) {
      duckdb::duckdb_shutdown(drv = duckdb::duckdb(dbdir = dbdir))
      unlink(dbdir, force = TRUE)
      unlink(paste0(dbdir, ".wal"), force = TRUE)
    } else {
      cli::cli_inform(c(i = "Using already created storage in: {.path {dbdir}}."))
      return(dbdir)
    }
  }

  # check embed
  if (missing(embed)) {
    cli::cli_abort(c(x = "Please provide a embed model to embed the documentation."))
  }

  # Create storage
  store <- ragnar::ragnar_store_create(
    location = dbdir,
    embed = embed,
    name = "omopverse"
  )

  # Reading online documentation
  chunks <- documentationChunks()

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

  return(dbdir)
}

#' Create an ellmer chat with the data of the omop trained model
#'
#' @param name Store name.
#' @param chat A chat object.
#' @param ... Arguments passed to `ragnar::ragnar_register_tool_retrieve()`
#'
#' @return The chat object with the trained store and prompt.
#' @export
#'
#' @examples
#' \donttest{
#' storeCreate(
#'   embed = \(x) ragnar::embed_ollama(x, model = "mxbai-embed-large"),
#'   name = "my_omop_assistant"
#' )
#'
#' chat <- ellmerChat(
#'   name = "my_omop_assistant",
#'   chat = ellmer::chat_google_gemini(),
#'   top_k = 10L
#' )
#'
#' chat$chat("How to create an acetaminophen cohort?")
#' }
#'
ellmerChat <- function(name = "omop_assistant",
                       chat = ellmer::chat_google_gemini(),
                       ...) {
  # check name
  name <- dbName(name = name)
  suppressMessages(dbdir <- .storePath(name = name))
  if (!file.exists(dbdir)) {
    cli::cli_abort(c(x = "{.pkg {name}} does not exist, please use {.code storeCreate()} to create it first."))
  }

  # set prompt
  cli::cli_inform(c(i = "Set system prompt."))
  chat$set_system_prompt(value = prompt())

  # add store
  cli::cli_inform(c(i = "Adding store to the chat."))
  store <- ragnar::ragnar_store_connect(location = dbdir)
  chat <- ragnar::ragnar_register_tool_retrieve(chat = chat, store = store, ...)

  return(chat)
}

dbName <- function(name, call = parent.frame()) {
  omopgenerics::assertCharacter(name, length = 1, call = call)
  if (!endsWith(x = name, suffix = ".duckdb")) {
    name <- paste0(name, ".duckdb")
  }
  return(name)
}
.storePath <- function(name) {
  file.path(getEnvPath(), name)
}
getEnvPath <- function() {
  # read path from environment
  path <- Sys.getenv(x = "OMOP_DATA_FOLDER", unset = "")

  # set temporal if not set
  if (identical(x = path, y = "")) {
    cli::cli_inform(c(i = "`OMOP_DATA_FOLDER` environment variable is not set, using temp directory."))
    path <- file.path(tempdir(), "OMOP_DATA_FOLDER")
    dir.create(path = path, showWarnings = FALSE)
  }

  return(path)
}
prompt <- function() {
  stringr::str_squish(
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
}
