library(lubridate)
library(dplyr)
library(stringr)
library(readr)
library(forcats)



# file_path
financial_data_folder <- "data/financial"

# Define file types based on names
airbnb_earnings <- list.files(financial_data_folder,
                              pattern = "^airbnb_.*",
                              full.names = TRUE)





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


# Select a version of airbnb payouts for later use
airbnb_payouts2 <- airbnb_payouts |> 
  filter(!is.na(room_number)) |> 
  
  # filter out Tina's rooms
  filter(!room_number %in% c("1600", "515")) |>
  group_by(#room_number, 
    month_year) |> 
  summarize(monthly_gross = sum(Gross.earnings, na.rm = TRUE),
            monthly_occupancy_tax = sum(Occupancy.taxes, na.rm = TRUE),
            monthly_service_fee = sum(Service.fee, na.rm = TRUE)) |>
  mutate(net_earnings = monthly_gross - monthly_occupancy_tax - monthly_service_fee) 




