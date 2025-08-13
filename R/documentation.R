
#' List the documentation links to train the OmopAssistant model
#'
#' @return Named character vector with documentation links.
#' @export
#'
#' @examples
#' documentationLinks()
#'
documentationLinks <- function() {
  c(
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
  )
}

#' Read documentation chunks
#'
#' @return List of chunks of the OMOP documentation.
#' @export
#'
#' @examples
#' \donttest{
#' documentationChunks()
#' }
#'
documentationChunks <- function() {
  # get information links
  links <- documentationLinks()

  # get related links
  links <- links |>
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
        expr = ragnar::markdown_chunk(ragnar::read_as_markdown(link)),
        error = function(e) {
          cli::cli_inform(c("x" = "Failed to read markdown in {.url {link}}"))
          NULL
        })
    }) |>
    purrr::compact()

  return(chunks)
}
