library(lubridate)
library(dplyr)
library(stringr)
library(readr)
library(forcats)




# load cleaning and keycard payment schedule
cleaning_and_keycard_payments <- read.csv("data/overall_payment_schedule.csv")



# combine all the datasets together
combined_transactions <- bank_transactions |> 
                         bind_rows(credit_card_transactions) |> 
                      
                        # create a category 2 to match report requirements
                        mutate(category2 = case_when(
                          
                          category %in% c("Rent") ~ "Rent",
                          category %in% c("Cleaning") ~ "Cleaning",
                          
                          category %in% c("Water and Electricity") ~ "Water and Electricity",
                          category %in% c("Internet and TV") ~ "Internet and TV",
                          
                          category %in% c("Other Business Expenses", 
                                          "Business Meals",
                                          "Bank Transfer fees",
                                          "Maintenance/Repairs/Furniture",
                                          "Storage",
                                          "Taxes",
                                          "Marketing",
                                          "Business Travel Expenses" ) ~ "Other Business Expenses",
                          
                          category %in% c("Interest") ~ "Revenue",
                          
                          category %in% c("Capital Reduction",
                                          "Dividend Distribution - Marty",
                                          "Dividend Distribution - Simon",
                                          "Dividend Distribution - Tina",
                                          "Dividend Distribution - Andy",
                                          "Credit Card Payments"          ) ~ "Unneeded categories",
                          
                          
                          .default = NA
                                                     
                                                     
                                                     ))
