library(lubridate)
library(dplyr)
library(stringr)
library(readr)
library(forcats)



# file_path
financial_data_folder <- "data/financial"
credit_card_statements_folder <- paste0(financial_data_folder, "/Airbnb Credit Card Statement")

credit_card <- list.files(credit_card_statements_folder,
                          full.names = TRUE)




# load credit card transactions
load_single_cc_statement <- function(file_path){
  
  
  # extract statement year and month
  statement_date <- file_path |> 
    read_csv(locale = locale(encoding = "UTF-8"),
             show_col_types = FALSE) |>
    colnames() 
  
  statement_year <- statement_date |> 
    str_extract("^\\d{4}") 
  
  
  statement_month <- statement_date |> 
    str_extract("(?<=/).*(?=信用卡對帳單)")
  
  
  single_statement <- file_path |>
    read_csv(skip = 23) |>
    
    # Attach the year and the month to the dataset
    mutate(statement_year = as.numeric(statement_year),
           statement_month = as.numeric(statement_month),
           transaction_month = as.numeric(str_extract(消費日, "^\\d+")))  |>
    
    # change the transaction year to go backwards if the transaction month is larger
    # than the statement month
    mutate(transaction_year = ifelse(transaction_month > statement_month,
                                     statement_year - 1,
                                     statement_year)) |> 
    
    mutate(transaction_date = ymd(paste0(transaction_year, "/",消費日)),
           amount = as.numeric(str_remove_all(`新臺幣金額`, ",")) * -1,
           account = "credit card") |> 
    filter(!is.na(transaction_date)) |>
    select(transaction_date,
           transaction_year,
           transaction_month,
           statement_year,
           statement_month,
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
    str_detect(description, "電子化繳費稅台灣電|電子化繳費稅北水自|電子化繳費稅新台北") ~ "Water and Electricity",
    str_detect(description, "電子化繳費稅遠傳電") ~ "Ann Phone Bill",
    
    str_detect(description, "多瓦娜家居|ＩＫＥＡ|宜得利|樂購蝦皮|宇拓創新股份有限|富邦ｍｏｍｏ|富邦ＭＯＭＯ|ＭＯＭＯ－ＥＣ３Ｄ|SHEIN.COM|國外交易手續費 -SHEIN|班尼斯國際家具名床|志高旗艦") ~ "Maintenance/Repairs/Furniture",
    
    str_detect(description, "藍新") ~ "Storage",
    
    
    str_detect(description, "ＣＵＢＥＡｐｐ轉帳繳款") ~ "Credit Card Payments",
    str_detect(description, "信用卡年費|年費─註") ~ "Other Business Expenses",
    str_detect(description, "高鐵嘉義站|國外交易手續費 -PICAP|PEAK TRAMWAYS CO LTD|國外交易手續費 -PEAKT") ~ "Business Travel Expenses",
    str_detect(description,"ＥｌＭａｒｑｕｅｓ|ＫＩＴＥＣＯＦＦＥＥ|ＳａｋｅＭｏｍｏ|全聯|瑪黑家居ＸＰ＆Ｔ柏林茶|燒番麥商行|ＯｉｅＴａｉｐｅｉ|放餐飲國際有限公司|場所ＰＬＡＣＥＥＥ|ｗｏｏｌｌｏｏｍｏｏｌ|艾風有限公司|ＢＡＮＣＯ世貿店|統一超商－朝天宮|PICA PICA|ＫＦＣ|ＫＵＲＥ８") ~ "Business Meals",
    # HSR in Chiayi
    # restaurant
    # 7-11 in Yunlin
    # HongKong Train
    
    .default = NA
  )) |>
  
  # Make sure there aren't duplicates...
  distinct() |>
  
  # filter out phone payments to Ann
  filter(category != "Ann Phone Bill")




