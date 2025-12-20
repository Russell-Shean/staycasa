library(lubridate)
library(dplyr)
library(stringr)
library(readr)
library(forcats)
library(tidyr)




# load cleaning and keycard payment schedule
cleaning_and_keycard_payments <- read.csv("data/overall_payment_schedule.csv")



# combine all the datasets together
combined_transactions <- bank_transactions |> 
  bind_rows(credit_card_transactions) |>
  
  # add a month year
  # fix dates
  mutate( Month = month.abb[month(transaction_date)],
         Year = year(transaction_date),
         month_year = paste0(Month, "_", Year)) |>
  
  mutate(month_year = fct_relevel(month_year, 
                                  paste0(month.abb,"_",
                                         rep(2016:year(Sys.Date()), 
                                             each=12)))) |>
  
  
  # create a category 2 to match report requirements
  mutate(category2 = case_when(
    
    category %in% c("Rent") ~ "Rent",
    category %in% c("Revenue") ~ "Revenue",
    category %in% c("Cleaning") ~ "Cleaning",
    
    category %in% c("Water and Electricity") ~ "Water and Electricity",
    category %in% c("Internet and TV") ~ "Internet and TV",
    
    category %in% c("Bank Transfer fees",
                    "Maintenance/Repairs/Furniture",
                    "Storage", 
                    "Reimbursement",
                    "Service Fee"
                    ) ~ "Other Business Expenses - COGS",
    
    category %in% c(#"Deposit",
                    "Business Meals",
                    
                    # We're counting account interest as a business expense
                    # Because it esentially offsets the business expense of 
                    # bank transfer fees
                    "Interest",
                    "Taxes",
                    "Marketing",
                    "Business Travel Expenses" ) ~ "Other Business Expenses - Operating Expenses",
    
    category %in% c("Deposit") ~ "Deposit",
    
    category %in% c("Other Business Expenses", "Cash Advance Payback") & amount <= -15000 ~ "Other Business Expenses - Operating Expenses",
    category %in% c("Other Business Expenses", "Cash Advance Payback") & amount > -15000 ~ "Other Business Expenses - COGS",
    
    
    #category %in% c() ~ "Revenue",
    
    category %in% c("Credit Card Payments"          ) ~ "Unneeded categories",
    
    
#category %in% c("Capital Reduction") ~ "Capital Reduction",
    category %in% c("Capital Injection") ~ "Capital Injection",
    category %in% c("Dividend Distribution - Marty",
                    "Dividend Distribution - Simon",
                    "Dividend Distribution - Tina",
                    "Dividend Distribution - Andy") ~ "Dividend Distribution",
    
    
    .default = NA
    
    
  )) 




unsorted_bank_transactions <- combined_transactions |>
  filter(is.na(category))

#annoymous_bank_transactions <- bank_transactions |> 
#  filter(is.na(recipient) & is.na(sender))



#calculate a monthly summary of costs
financial_report <- combined_transactions |> 
  filter(!category2 %in% c("Unneeded categories", "Deposit")) |>
  group_by(category2, month_year) |>
  summarise(total_value = sum(amount)) |>
  ungroup() |>
  pivot_wider(values_from = total_value,
              names_from = category2) |> 
  
  # Make sure negative numbers are now positive
  mutate(across(where(is.numeric), function(x) x * -1)) |>
  
  # Join on the payouts data
  #right_join(airbnb_payouts2) |>
  
  # Replace NA's with zeros
  mutate(across(where(is.numeric), function(x) replace_na(x, 0))) |>
  
  # Add random bank transfers to net_earnings
  mutate(Revenue = - Revenue) |>
  
  # Calculate new columns
  mutate(COGS = Rent + Cleaning + `Water and Electricity` + `Internet and TV` + `Other Business Expenses - COGS`, 
         `Gross Margin` = Revenue - COGS,
         `Gross margin %` = (Revenue - COGS) / Revenue * 100,
         `Operating Expenses` = `Other Business Expenses - Operating Expenses` / Revenue,
         `Net Income` = `Gross Margin` - `Operating Expenses`) |>
  
  # Fix Nan and inf number caused by dividing by zero when monthly revenue is zero

  mutate(
    across(
      c(`Gross margin %`, `Operating Expenses`),
      ~ dplyr::na_if(., NaN) %>%
        replace(is.infinite(.), NA)
    )
  ) |> 
  
  select(`Month and Year` = month_year,
         COGS,
         Rent, 
         Cleaning, 
         `Water and Electricity`,
         `Internet and TV`,
         `Other Business Expenses - COGS`,
         `Other Business Expenses - Operating Expenses`,
         #`NA`,
         `Gross Margin`,
         `Gross margin %`,
         `Operating Expenses`,
         Revenue,
         `Capital Injection`,
#`Capital Reduction`,
         `Dividend Distribution`
         ) |> 
         arrange(`Month and Year`) 





financial_report_format2 <- financial_report %>%
  pivot_longer(-`Month and Year`, names_to = "variable", values_to = "value") %>%
  mutate(across(where(is.numeric), ~ format(round(.x), scientific = FALSE))) |>
  pivot_wider(names_from = `Month and Year`, values_from = value) 


write.csv(financial_report, "data/financial_report_format1.csv", row.names = FALSE)
write.csv(financial_report_format2, "data/financial_report_format2.csv", row.names = FALSE)

write.csv(unsorted_bank_transactions, "data/unsorted_bank_transactions.csv", row.names = FALSE)
write.csv(combined_transactions, "data/all_transactions.csv", row.names = FALSE)




       