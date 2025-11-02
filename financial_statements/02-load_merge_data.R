library(dotenv)
library(pdftools)

# Load credentials
load_dot_env()
BANK_STATEMENT_PASSWORD <- Sys.getenv("BANK_STATEMENT_PASSWORD")


# file_path
financial_data_folder <- "data/financial"

# Define file types based on names
airbnb_earnings <- list.files(financial_data_folder, pattern = ".*airbnb_earnings.pdf")
credit_card <- list.files(financial_data_folder, pattern = "信用.*")
bank_statements <- list.files(financial_data_folder, "國泰.*",
                              full.names = TRUE)


# Read in bank statement
bank_transactions  <- pdf_text(bank_statements,  upw=BANK_STATEMENT_PASSWORD)
