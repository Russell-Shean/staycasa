library(lubridate)
library(dplyr)
library(stringr)
library(readr)
library(forcats)



# file_path
financial_data_folder <- "data/financial"

# Find bank statements in the data folder
bank_statements <- list.files(financial_data_folder, 
                              "Bank Statement.*",
                              full.names = TRUE)



bank_transactions <- lapply(bank_statements, 
                            function(x) read_csv(x, skip=4)) |> 
  bind_rows() |>
  
  
  
  mutate(
    # fix dates
    transaction_date = as.Date(ymd_hm(交易日期)),
    
    # create an amount column
    amount = case_when(提出 != "−" ~ as.numeric(str_remove_all(提出, ",")) * -1,
                       存入 != "−" ~ as.numeric(str_remove_all(存入, ","))),
    
    # Create a combined description field
    description = paste(說明, 備註, 交易資訊),
    
    # create account column
    account = "Cathay"
  ) |>
  
  # Replace hyphens with NA for all character columns
  #mutate(across(where(is.character), ~str_replace(., "−", NA_character_))) |>
  
  # select columns we want to keep
  select(transaction_date, 
         description,
         amount, 
         account
  ) |>
  
  # Remove rows where date is NA
  filter(!is.na(transaction_date)) |>
  
  
  # Create recipient column
  mutate(recipient = case_when(str_detect(description, "\\(822\\)0000241540091956") ~ "Simon",
                               str_detect(description, "\\(013\\)0000270506032358") ~ "Tina",
                               str_detect(description, "\\(822\\)0000152540146385") ~ "Andy",
                               str_detect(description, "\\(009\\)0053459500036600") ~ "Marty",
                               str_detect(description, "\\(822\\)0000215540116773") ~ "Russ",
                               str_detect(description, "\\(013\\)0000011506192732") ~ "劉＊志",
                               str_detect(description, "\\(013\\)0000222506144844") ~ "陳＊君",
                               str_detect(description, "\\(013\\)0000043558186748") ~ "王＊凱",
                               
                               str_detect(description, "\\(013\\)0000218506051130") ~ "黃＊真",
                               str_detect(description, "\\(013\\)0000699515257750") ~ "張＊凱",
                               
                               
                               
                               
                               
                               
                               
                               str_detect(description, "\\(008\\)0000129200040033") ~ "1713 Landlord",
                               str_detect(description, "\\(012\\)0000704168156410") ~ "1615 Landlord",
                               str_detect(description, "\\(822\\)0000241540091956") ~ "513 Landlord",
                               str_detect(description, "\\(009\\)0053458666888700") ~ "716 Landlord",
                               str_detect(description, "\\(006\\)0001405765859712") ~ "814 Landlord",
                               str_detect(description, "\\(007\\)0000010668132820") ~ "301 Landlord",
                               str_detect(description, "\\(007\\)0000014610067030") ~ "Storage Landlord",
                               
                               str_detect(description, "\\(700\\)0000013131001632") ~ "Cleaner 1",
                               str_detect(description, "\\(822\\)0000190530056476") ~ "Cleaner 2",
                               str_detect(description, "\\(007\\)0000018150301741") ~ "Cleaner 3",
                               str_detect(description, "\\(700\\)0001213890257738") ~ "Cleaner 4",
                               str_detect(description, "\\(008\\)0000130200094501") ~ "Cleaner 5",
                               
                               
                               str_detect(description, "\\(806\\)0000080221492500") ~ "Handyman 1",
                               
                               
                               
                               
                               
                               .default = NA
  )) |>
  
  # And if we money was received, who sent it??
  mutate(sender = case_when(str_detect(description, "\\(013\\)0000270\\*\\*\\*032358") ~ "Tina",
                            str_detect(description, "\\(822\\)0000241\\*\\*\\*091956") ~ "Simon",
                            str_detect(description, "\\(013\\)0000223\\*\\*\\*262045") ~ "李＊軒",
                            str_detect(description, "\\(808\\)0000015\\*\\*\\*209452") ~ "Andy",
                            str_detect(description, "\\(009\\)0053459\\*\\*\\*036600") ~ "Marty",
                            .default = NA)) |> 
  
  
  
  # create categories 
  mutate(category = case_when(str_detect(description, "跨行費用|費用沖正") ~ "Bank Transfer fees",
                              
                              (str_detect(description, "房租|Ｒｅｎｔ|租金|ｒｅｎｔ") & 
                              #replace_na(sender != "Andy", FALSE) & 
                              !str_detect(description, "押金")) ~ "Rent",
                              
                              str_detect(description, "８１４|\\(006\\)0001405765859712") & amount == -32560 ~ "Rent",
                              str_detect(description, "１７１３|\\(008\\)0000129200040033") & amount == -31500 ~ "Rent",
                              str_detect(description, "１６１５|\\(012\\)0000704168156410") & amount == -29560 ~ "Rent", 
                              str_detect(description, "７１６|\\(009\\)0053458666888700") & amount == -29000 ~ "Rent",
                              str_detect(description, "５１３|\\(009\\)0053458666888700") & amount == -27560 ~ "Rent",
                              str_detect(recipient, "Landlord") & amount > -40000 ~ "Rent",
                              
                              # Deposit
                              str_detect(description, "押金") ~ "Deposit",
                              
                              str_detect(description, "行銷") ~ "Marketing", 
                              
                              str_detect(description, "租倉儲空間|Ｓｔｏｒａｇｅ") ~ "Storage",
                              
                              str_detect(description, "報帳") ~ "Taxes",
                              
                              
                              
                              str_detect(description, "打掃|ｃｌｅａｎｉｎｇ|Ａｎｎ　ａｄｖａｎｃｅ") ~ "Cleaning",
                              str_detect(recipient, "Cleaner") ~ "Cleaning", 
                              # str_detect(description, "佣金") ~ "Commision",
                              
                              str_detect(description, "佣金|傭金|ｄｉｓｔｒｉｂｕｔｉｏｎ|分紅|ｃａｓｈ　ｐａｙｏｕｔ|Ｃａｓｈ　Ｐａｙｏｕｔ|減資|ｃａｐ　ｒｅｄｕｃｔｉｏｎ|紅利分配")  ~ paste0("Dividend Distribution - ", recipient),
                              
                              
                              
                              
                              # Assume that any payout of exactly 50000 going to Simon or Tina is also a dividend distribution
                              amount == -50000 &
                                str_detect(description, "\\(822\\)0000152540146385")  ~ "Dividend Distribution - Simon",
                              
                              
                              amount == -50000 &
                                str_detect(description, "\\(013\\)0000270506032358")  ~ "Dividend Distribution - Tina",
                              
                              
                              
                              # Interest
                              str_detect(description, "存款息") ~ "Interest",
                              
                              # REvenue
                              str_detect(description, "現金 彭文|２天住宿費用") ~ "Revenue",
                              
                              amount < 0 & recipient == "Marty" ~ "Revenue",
                              
                              !(sender %in% c("Simon", "Tina", "Andy")) & amount > 0 ~ "Revenue",
                              
                              
                              
                              
                              
                              
                              
                              str_detect(description, "五金雜貨|電視臂安裝|裝電視臂|熱水器|沙發床|ｈａｎｄｙｍａｎ|修理|修繕|檢修|拆濾水器|電子鎖|修水管|洗冷氣|墊款還款|ｓｈｏｗｅｒ　ｃｕｒｔａｉｎ|馬桶蓋") ~ "Maintenance/Repairs/Furniture",
                              recipient %in% c("Handyman 1") ~ "Maintenance/Repairs/Furniture",
                              str_detect(description,"ｌａｌａｍｏｖｅ|餐費") ~ "Business Meals",
                              str_detect(description, "網路") ~ "Internet and TV",
                              str_detect(description, "電費") ~ "Water and Electricity",
                              
                              
                              # Reimbursements
                              str_detect(description, "ｒｅｉｍｂｕｒｓｅ|Ｒｅｉｍｂｕｒｓｅ|Ｒｅｉｍｂｕｒ|Ｒｅｉｎｂｕｒ") ~ "Reimbursement",
                              
                              # Any time we're sending money to Simon, it's a remibursement
                              recipient %in% c("Simon", "Tina", "Andy") & amount < 0 ~ "Reimbursement",
                             
                    
                              
                              # Other expenses
                              str_detect(description, "ｅｘｐｅｎｓｅ|自行提款|跨行提款|客服的錢|Ｍａｒｔｙ　代客") ~ "Other Business Expenses",
                              
                              # Payments to Russ and other people
                              recipient %in% c("Russ", "陳＊君", "張＊凱") ~ "Other Business Expenses",
                              
                              # Credit card payments
                              str_detect(description, "信用卡款") ~ "Credit Card Payments",
                              
                              
                              
                              
                              .default = NA
  )) |>
  
  
  mutate(category = case_when( 
    
    # Assume all remaining charges over 40K are capital distribution
    amount >= 40000 & is.na(category) ~ "Capital Injection",
    
    # Cash advance
    sender == "Simon" & 
      amount > 0 & 
      amount < 30000 & 
      is.na(category)~ "Cash Advance Payback",
    
    # remaining expenses
    str_detect(description, "\\(822\\)0000186540138330|\\(007\\)0000010668151280|電子轉出 Ｗ１１０ \\(812\\)0020551000093942|\\(700\\)0003117411608267") ~ "Other Business Expenses",
    
    .default = category
    
  )) |> 
  
  # Filter out unneeded things 
  
  #whatever this is
  filter(!str_detect(description, "網銀外存 218087121432 −")) |> 
  
  # reversed bank errors
  filter(!str_detect(description, "錯誤更正 ｊｕｎｅ　ｓａｌａｒｙ \\(700\\)0001213890257738|電子轉出 ｊｕｎｅ　ｓａｌａｒｙ \\(700\\)0001213890257738"))



unsorted_bank_transactions <- bank_transactions |>
  filter(is.na(category))


# Write out unsorted transactions for simon
unsorted_bank_transactions |> write.csv("unsorted_bank_transactions.csv", row.names = FALSE)

annoymous_bank_transactions <- bank_transactions |> 
  filter(is.na(recipient) & is.na(sender))


