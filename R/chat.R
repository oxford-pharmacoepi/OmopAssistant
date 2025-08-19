
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
  name <- modelName(name = name)

  dbdir <- modelPath(name = fullName(name = name))
  if (!file.exists(dbdir)) {
    cli::cli_abort(c(x = "{.pkg {name}} does not exist, please use {.code downloadModel()} or {.code trainModel()} to create the model first."))
  }

  # set prompt
  cli::cli_inform(c(i = "Setting system prompt."))
  con <- duckdb::dbConnect(drv = duckdb::duckdb(dbdir = dbdir))
  if ("oa_prompt" %in% duckdb::dbListTables(conn = con)) {
    prompt <- dplyr::collect(dplyr::tbl(con, "oa_prompt"))
    chat$set_system_prompt(value = prompt)
  }
  duckdb::dbDisconnect(conn = con)

  # add store
  cli::cli_inform(c(i = "Adding model store to the chat."))
  store <- ragnar::ragnar_store_connect(location = dbdir)
  chat <- ragnar::ragnar_register_tool_retrieve(chat = chat, store = store, ...)

  return(chat)
}
