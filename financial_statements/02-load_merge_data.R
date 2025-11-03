library(dotenv)
library(lubridate)
library(dplyr)
library(pdftools)
library(stringr)
library(readr)
library(forcats)

# Load credentials
load_dot_env()
BANK_STATEMENT_PASSWORD <- Sys.getenv("BANK_STATEMENT_PASSWORD")


# file_path
financial_data_folder <- "data/financial"

# Define file types based on names
airbnb_earnings <- list.files(financial_data_folder,
                              pattern = "^airbnb_.*",
                              full.names = TRUE)

credit_card <- list.files(financial_data_folder, 
                          pattern = "信用.*",
                          full.names = TRUE)

bank_statements <- list.files(financial_data_folder, 
                              "Bank Statement.*",
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
           amount = as.numeric(str_remove_all(`新臺幣金額`, ",")),
           account = "credit card") |> 
    filter(!is.na(transaction_date)) |>
    select(transaction_date,
           description = `交易說明`,
           amount,
           account)
  
  single_statement

}
  
  
  
credit_card_transactions <- lapply(credit_card, 
                                   load_single_cc_statement ) |> 
  bind_rows()



# Airbnb earnings
load_airbnb_payouts <- function(file_path){
  
  recipient <- file_path |>
               str_extract("(?<=airbnb_).*(?=\\.)")
  
  
  df <- file_path |>
        read.csv() |>
        mutate(recipient = recipient)
  
  
}

airbnb_payouts <- lapply(airbnb_earnings, load_airbnb_payouts) |>
                   bind_rows() |>
  
                   # fix dates
                   mutate(Date = mdy(Date),
                          Month = month.abb[month(Date)],
                          Year = year(Date),
                          month_year = paste0(Month, "_", Year)) |>
                  mutate(month_year = fct_relevel(month_year, 
                                                  paste0(month.abb,"_",
                                                         rep(2016:year(Sys.Date()), 
                                                             each=12)))) |>
  
                # attach room numbers
                  mutate(room_number = case_when(Listing == "Skyline Luxe Loft in Xinyi | Taipei 101 Views" ~ as.character(1600),
                                                 Listing == "The Creative Loft Xinyi | Walk to 101+Night Market" ~ as.character(513),
                                                 Listing == "Taipei 101 Executive Suite (Self-Check in)" ~ as.character(1615),
                                                 Listing == "Cozy City Hideaway Tpe 101 & Tonghua Mkt (LT Stay)" ~ as.character(716),
                                                 Listing == "Chic 2-Story Loft w/101 Views（Great for LT stay)" ~ as.character(1713),
                                                 Listing == "Modern Boutique Loft in Xinyi - Work, Live & Play" ~ as.character(515),
                                                 Listing == "101夜景之家 | 月租嚴選" ~ as.character(814),
                                                 Listing == "1543487232480210468" ~ as.character(310)))






airbnb_payouts |> 
  group_by(month_year, room_number) |>
  summarize(monthly_gross_earnings = sum(Gross.earnings, na.rm = TRUE)) |> 
  
  # Filter out 0 earnings listings (blank rows with NA as the room number)
  filter(monthly_gross_earnings > 0) |>
  write.csv("example_airbnb_data.csv", row.names = FALSE)






# Bank statement

bank_transactions <- lapply(bank_statements, 
                            function(x) read_csv(x, skip=4)) |> 
                    bind_rows() |>
   
  # Replace hyphens with NA for all character columns
  mutate(across(where(is.character), ~str_replace(., "−", NA_character_))) |>
  
  # fix dates
  mutate(date = as.Date(ymd_hm(交易日期)))









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





# combine all the datasets together
combined_transactions <- credit_card_transactions
