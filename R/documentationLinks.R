
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
