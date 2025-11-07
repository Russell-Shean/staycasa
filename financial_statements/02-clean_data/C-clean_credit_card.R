library(lubridate)
library(dplyr)
library(stringr)
library(readr)
library(forcats)



# file_path
financial_data_folder <- "data/financial"


credit_card <- list.files(financial_data_folder, 
                          pattern = "信用.*",
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
           amount = as.numeric(str_remove_all(`新臺幣金額`, ",")) * -1,
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
  bind_rows() |>
  
  # create categories 
  mutate(category = case_when(
    str_detect(description, "電子化繳費稅麗冠有|北都數位有線電視股份有") ~ "Internet and TV",
    str_detect(description, "電子化繳費稅台灣電|電子化繳費稅北水自") ~ "Water and Electricity",
    
    str_detect(description, "多瓦娜家居") ~ "Maintenance/Repairs/Furniture",
    str_detect(description, "ＣＵＢＥＡｐｐ轉帳繳款") ~ "Credit Card Payments",
    str_detect(description, "信用卡年費|年費─註") ~ "Other Business Expenses",
    str_detect(description, "高鐵嘉義站|國外交易手續費 -PICAP|PEAK TRAMWAYS CO LTD|國外交易手續費 -PEAKT") ~ "Business Travel Expenses",
    str_detect(description,"ＥｌＭａｒｑｕｅｓ|瑪黑家居ＸＰ＆Ｔ柏林茶|燒番麥商行|ＯｉｅＴａｉｐｅｉ|放餐飲國際有限公司|場所ＰＬＡＣＥＥＥ|ｗｏｏｌｌｏｏｍｏｏｌ|艾風有限公司|ＢＡＮＣＯ世貿店|統一超商－朝天宮|PICA PICA") ~ "Business Meals",
    # HSR in Chiayi
    # restaurant
    # 7-11 in Yunlin
    # HongKong Train
    
    .default = NA
  ))




