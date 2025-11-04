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


# load cleaning and keycard payment schedule
cleaning_and_keycard_payments <- read.csv("data/overall_payment_schedule.csv")


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
  bind_rows() |>
  
  # create categories 
  mutate(category = case_when(str_detect(description, "電子化繳費稅北水自|電子化繳費稅台灣電|北都數位有線電視股份有|電子化繳費稅麗冠有") ~ "Utilities",
                              str_detect(description, "多瓦娜家居") ~ "Maintenance/Repairs/Furniture",
                              str_detect(description, "ＣＵＢＥＡｐｐ轉帳繳款") ~ "Credit Card Payments",
                              str_detect(description, "信用卡年費|年費─註") ~ "Miscelaneos Business Expenses",
                              str_detect(description, "高鐵嘉義站|國外交易手續費 -PICAP|PEAK TRAMWAYS CO LTD|國外交易手續費 -PEAKT") ~ "Business Travel Expenses",
                              str_detect(description,"ＥｌＭａｒｑｕｅｓ|瑪黑家居ＸＰ＆Ｔ柏林茶|燒番麥商行|ＯｉｅＴａｉｐｅｉ|放餐飲國際有限公司|場所ＰＬＡＣＥＥＥ|ｗｏｏｌｌｏｏｍｏｏｌ|艾風有限公司|ＢＡＮＣＯ世貿店|統一超商－朝天宮|PICA PICA") ~ "Business Meals",
                              # HSR in Chiayi
                              # restaurant
                              # 7-11 in Yunlin
                              # HongKong Train
                              
                              .default = NA
  ))



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
                               
                               
                               str_detect(description, "\\(806\\)0000080221492500") ~ "Handyman 1",
                               
                               
                               


                              .default = NA
                               )) |>
  
  # And if we money was received, who sent it??
  mutate(sender = case_when(str_detect(description, "\\(013\\)0000270\\*\\*\\*032358") ~ "Tina",
                            str_detect(description, "\\(013\\)0000223\\*\\*\\*262045") ~ "李＊軒",
                            str_detect(description, "\\(808\\)0000015\\*\\*\\*209452") ~ "Andy",
                            .default = NA)) |> 
  
  # create categories 
  mutate(category = case_when(str_detect(description, "跨行費用") ~ "Bank Transfer fees",
                              
                              str_detect(description, "房租|Ｒｅｎｔ|租金|ｒｅｎｔ|押金") ~ "Rent",
                              str_detect(description, "８１４|\\(006\\)0001405765859712") & amount == -32560 ~ "Rent",
                              str_detect(description, "１７１３|\\(008\\)0000129200040033") & amount == -31500 ~ "Rent",
                              str_detect(description, "１６１５|\\(012\\)0000704168156410") & amount == -29560 ~ "Rent", 
                              str_detect(description, "７１６|\\(009\\)0053458666888700") & amount == -29000 ~ "Rent",
                              str_detect(description, "５１３|\\(009\\)0053458666888700") & amount == -27560 ~ "Rent",
                              
                              str_detect(description, "行銷") ~ "Marketing", 
                              
                              str_detect(description, "租倉儲空間|Ｓｔｏｒａｇｅ") ~ "Storage",
                              
                              str_detect(description, "報帳") ~ "Taxes",
                              
                              
                              
                              str_detect(description, "打掃|ｃｌｅａｎｉｎｇ|Ａｎｎ　ａｄｖａｎｃｅ") ~ "Cleaning",
                              str_detect(description, "佣金") ~ "Commision",
                              
                              str_detect(description, "ｄｉｓｔｒｉｂｕｔｉｏｎ|分紅|ｃａｓｈ　ｐａｙｏｕｔ|Ｃａｓｈ　Ｐａｙｏｕｔ|減資|ｃａｐ　ｒｅｄｕｃｔｉｏｎ|紅利分配")  ~ paste0("Dividend Distribution - ", recipient),
                              
                              

                              
                              # Assume that any payout of exactly 50000 going to Simon or Tina is also a dividend distribution
                              amount == -50000 &
                                str_detect(description, "\\(822\\)0000152540146385")  ~ "Dividend Distribution - Simon",
                              
                              
                              amount == -50000 &
                                str_detect(description, "\\(013\\)0000270506032358")  ~ "Dividend Distribution - Tina",
                              
                              

                              
                              
                              
                              str_detect(description, "五金雜貨|電視臂安裝|裝電視臂|熱水器|沙發床|ｈａｎｄｙｍａｎ|修理|修繕|檢修|拆濾水器|電子鎖|修水管|洗冷氣|墊款還款|ｓｈｏｗｅｒ　ｃｕｒｔａｉｎ|馬桶蓋") ~ "Maintenance/Repairs/Furniture",
                              str_detect(description,"ｌａｌａｍｏｖｅ|餐費") ~ "Business Meals",
                              str_detect(description, "網路|電費") ~ "Utilities",
                             
                             
                              
                              .default = NA
  )) 



unsorted_bank_transactions <- bank_transactions |>
                              filter(is.na(category))

annoymous_bank_transactions <- bank_transactions |> filter(is.na(recipient) & is.na(sender))





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
