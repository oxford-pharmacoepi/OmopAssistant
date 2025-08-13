
trainModel <- function(embed, overwrite = FALSE) {
  # input check
  omopgenerics::assertLogical(overwrite, length = 1)

  # get model path
  modelPath <- file.path(getEnvPath(), "omop_assistant.duckdb")

  # check if exist
  if (file.exists(modelPath)) {
    if (overwrite) {

    } else {
      return()
    }
  }

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
