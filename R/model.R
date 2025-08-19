
#' Path to a store
#'
#' @param name Store name.
#'
#' @return Path to the model.
#' @export
#'
#' @examples
#' library(OmopAssistant)
#'
#' Sys.setenv("OMOP_DATA_FOLDER" = tempdir())
#' pathModel(name = NULL)
#'
pathModel <- function(name = NULL) {
  if (is.null(name)) {
    return(getEnvPath())
  }

  # get path
  path <- modelName(name = name) |>
    fullName() |>
    modelPath()

  # check exists
  if (!file.exists(path)) {
    cli::cli_abort(c(x = "Model {.pkg {name}} does not exist."))
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
#' @param chunks a character vector or a dataframe with a text column, and
#' optionally, a pre-computed `embedding` matrix column. If `embedding` is not
#' present, then `store@embed()` is used. `chunks` can also be a character
#' vector.
#' @param name Store name.
#' @param overwrite Whether to overwrite a preexisting store.
#' @param ... Passed to `ragnar::ragnar_store_create()`.
#'
#' @return Path to the trained model.
#' @export
#'
trainModel <- function(embed,
                       chunks,
                       name,
                       overwrite = FALSE,
                       ...) {
  # input check
  name <- modelName(name = name)
  omopgenerics::assertLogical(overwrite, length = 1)

  dbdir <- overwriteModel(name = name, overwrite = overwrite)

  # check embed
  if (missing(embed)) {
    cli::cli_abort(c(x = "Please provide a embed model to embed the documentation."))
  }

  # check chunks
  if (missing(chunks)) {
    cli::cli_abort(c(x = "Please provide chunks to embed in the model."))
  }

  # Create storage
  store <- ragnar::ragnar_store_create(
    location = dbdir,
    embed = embed,
    name = name,
    ...
  )

  if (inherits(chunks, "ragnar::MarkdownDocumentChunks")) {
    chunks <- list(chunks)
  }

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

#' Download a preexisting model
#'
#' @param name Name of the model to download. See options using `avialableModels()`.
#' @param overwrite Whether to overwrite a preexisting model.
#'
#' @return Path to the downloaded model.
#' @export
#'
#' @examples
#' \donttest{
#' library(OmopAssistant)
#'
#' Sys.setenv("OMOP_DATA_FOLDER" = tempdir())
#'
#' downloadedModels()
#' downloadModel(name = "omop_assistant")
#' downloadedModels()
#' }
#'
downloadModel <- function(name = "omop_assistant",
                          overwrite = FALSE) {
  # input check
  name <- modelName(name = name)
  omopgenerics::assertLogical(overwrite, length = 1)
  omopgenerics::assertChoice(x = name, choices = names(urls))

  dbdir <- overwriteModel(name = name, overwrite = overwrite)
  con <- duckdb::dbConnect(drv = duckdb::duckdb(dbdir = dbdir))
  duckdb::dbDisconnect(conn = con)

  utils::download.file(url = urls[[name]], destfile = dbdir)

  invisible(dbdir)
}

#' Title
#'
#' @return Available models.
#' @export
#'
#' @examples
#' library(OmopAssistant)
#'
#' avialableModels()
#'
avialableModels <- function() {
  names(urls)
}

#' Title
#'
#' @return Models that have been downloaded.
#' @export
#'
#' @examples
#' \donttest{
#' library(OmopAssistant)
#'
#' path <- file.path(tempdir(), "OMOP_DATA_FOLDER")
#' dir.create(path = path)
#' Sys.setenv("OMOP_DATA_FOLDER" = path)
#'
#' downloadedModels()
#' downloadModel(name = "omop_assistant")
#' downloadedModels()
#' }
#'
downloadedModels <- function() {
  # find paths
  x <- list.files(path = getEnvPath())
  x <- x[startsWith(x = x, prefix = "oa_")]
  x <- x[endsWith(x = x, suffix = ".duckdb")]

  # extract names
  stringr::str_match(string = x, pattern = "^oa_(.*)\\.duckdb$")[,2]
}

modelName <- function(name, call = parent.frame()) {
  omopgenerics::assertCharacter(name, length = 1, call = call)
  name |>
    stringr::str_remove(pattern = "\\.duckdb$") |>
    stringr::str_remove(pattern = "^oa_")
}
fullName <- function(name) {
  paste0("oa_", name, ".duckdb")
}
modelPath <- function(name) {
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
    Sys.setenv("OMOP_DATA_FOLDER" = path)
  }

  return(path)
}
overwriteModel <- function(name, overwrite, call = parent.frame()) {
  dbdir <- modelPath(name = fullName(name = name))
  if (file.exists(dbdir)) {
    if (overwrite) {
      duckdb::duckdb_shutdown(drv = duckdb::duckdb(dbdir = dbdir))
      unlink(dbdir, force = TRUE)
      unlink(paste0(dbdir, ".wal"), force = TRUE)
    } else {
      cli::cli_abort(message = c(x = "Model {.pkg {name}} already exists and `overwrite = FALSE`."), call = call)
    }
  }
  return(dbdir)
}
