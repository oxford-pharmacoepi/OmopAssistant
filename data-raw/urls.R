
urls <- list(
  "omop_assistant" = "https://raw.githubusercontent.com/oxford-pharmacoepi/OmopAssistant/main/models/oa_omop_assistant.duckdb"
)

usethis::use_data(prompts, urls, overwrite = TRUE, internal = TRUE)
