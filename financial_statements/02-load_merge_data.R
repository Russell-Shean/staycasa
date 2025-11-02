library(dotenv)
library(pdftools)
library(stringr)
library(readr)

# Load credentials
load_dot_env()
BANK_STATEMENT_PASSWORD <- Sys.getenv("BANK_STATEMENT_PASSWORD")


# file_path
financial_data_folder <- "data/financial"

# Define file types based on names
airbnb_earnings <- list.files(financial_data_folder,
                              pattern = ".*airbnb_earnings.pdf",
                              full.names = TRUE)

credit_card <- list.files(financial_data_folder, 
                          pattern = "信用.*",
                          full.names = TRUE)

bank_statements <- list.files(financial_data_folder, 
                              "國泰.*",
                              full.names = TRUE)


# load credit card transactions
load_single_cc_statement <- function(file_path){
  

  # extract year
  statement_year <- file_path |> 
    read_csv() |>
    colnames() |> 
    str_extract("^\\d{4}")
  
  single_statement <- file_path |>
    read_csv(skip = 23) |>
    mutate(transaction_date = ymd(paste0(statement_year, "/",消費日)),
           account = "credit card") |> 
    filter(!is.na(transaction_date)) |>
    select(transaction_date,
           description = `交易說明`,
           amount = `新臺幣金額`,
           account)
  
  single_statement

}
  
  
  
credit_card_transactions <- lapply(credit_card, 
                                   load_single_cc_statement ) |> 
  bind_rows()



# Airbnb earnings
airbnb_earnings[1] |>
  pdf_text()





# Read in bank statement as individual pages
bank_pages_df <- data.frame(text = pdf_text(bank_statements,
                          upw = BANK_STATEMENT_PASSWORD)) #|> 
                 #mutate(text = str_remove_all(text, "\n"))


bank_transactions_text <- pdf_text(bank_statements,
         upw = BANK_STATEMENT_PASSWORD) |>
  
          # collapse into single text because we don't care about pages 
         paste(collapse = "~~newpage~~") |>
  
         #replace \n with something else
         str_replace_all("\n","~~newline~~" ) |>
         
         # extract individual lines
         str_extract_all("~~newline~~\\d+.*?(?=~~newline~~\\d+|\\d+~~newline~~$)") |>
  
         # unlist into a vector
         unlist() |>
  
         # Remove extra stuff
         str_remove_all("~~newline~~") |>
        # str_squish() |> 
         str_remove_all("\\d+~~newpage~~.*")
         
         

bank_transactions  <- data.frame(text = bank_transactions_text) |>
  
                      # extract columns from text
                      mutate(transaction_date = as.Date(str_extract(text, 
                                                            "\\d{4}/\\d{2}/\\d{2}")),
                             
                             transaction_type = str_extract(text,
                                                            "電子轉出|網銀轉帳|跨行費用|跨行轉入|自行提款|存款息|跨行提款|ＡＴＭ存|現金|網銀外存|錯誤更正|費用沖正"))

