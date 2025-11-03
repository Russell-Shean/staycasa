


combined_transactions <- combined_transactions |>
  mutate(category = case_when(str_detect(description, "電子化繳費稅北水自|電子化繳費稅台灣電|北都數位有線電視股份有|電子化繳費稅麗冠有") ~ "Utilities",
                              str_detect(description, "多瓦娜家居") ~ "Furniture",
                              str_detect(description, "ＣＵＢＥＡｐｐ轉帳繳款") ~ "Credit Card Payments",
                              str_detect(description, "信用卡年費|年費─註") ~ "Miscelaneos Business Expenses",
                              str_detect(description, "高鐵嘉義站|ＥｌＭａｒｑｕｅｓ|瑪黑家居ＸＰ＆Ｔ柏林茶|燒番麥商行|ＯｉｅＴａｉｐｅｉ|放餐飲國際有限公司|場所ＰＬＡＣＥＥＥ|ｗｏｏｌｌｏｏｍｏｏｌ|艾風有限公司|ＢＡＮＣＯ世貿店|統一超商－朝天宮|PICA PICA|國外交易手續費 -PICAP|PEAK TRAMWAYS CO LTD|國外交易手續費 -PEAKT") ~ "Unrelated Personal Expense",
                              # HSR in Chiayi
                              # restaurant
                              # 7-11 in Yunlin
                              # HongKong Train
                              
                              .default = NA
                              )) |> 
  write.csv("credit_card_category_guesses.csv", row.names = FALSE)




