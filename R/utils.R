

decoder <- function(x){rawToChar(base64enc::base64decode(x))}



# df needs to be a 


filter_for_airbnb <- function(email_df) {
  
  
  airbnb_emails <- email_df |> 
  # extract info from the from column
  mutate(sender_name = str_squish(str_extract(from, "^.*(?=<)")),
         sender_email = str_extract(from, "(?<=\\<).*(?=\\>)"),
         sender_username = str_extract(from, "(?<=<).*(?=@)"),
         sender_domain = str_extract(from, "(?<=@).*(?=\\>)"),
         
         
         
         
         
         # Convert the date and time from UTC to Taiwan time
         # combine date + time string into a UTC datetime
         datetime_taipei = with_tz(dmy_hms(date), tz="Asia/Taipei"),
         
         # Convert the date to a date format
         date = as.Date(dmy_hms(date)),
         
         # extract new date and time in Taipei time
         taipei_date = as.Date(datetime_taipei),
         taipei_time = format(datetime_taipei, "%H:%M:%S")) |>
    
    
    # Filter for airbnb emails
    filter(sender_domain == "airbnb.com")
  
  
  airbnb_emails
    
  
  
}


# categorize emails types based on subject lines

categorize_airbnb <- function(airbnb_emails){
  
  categorized_airbnb <- airbnb_emails |> 
    
    mutate(   
      # determine if an email is a review
      review = ifelse(str_detect(subject, "評價"), 
                      "yes",
                      "no"),
      
      reply = ifelse(str_detect(subject, "回覆：|RE:") |
                       (str_detect(body, "Subject: RE: Reservation") &
                          sender_email == "simon1122@gmail.com"), 
                     "yes",
                     "no"),
      
      super_host_invite = ifelse(str_detect(subject, "認為你能成為優秀的搭檔"), 
                                 "yes",
                                 "no"),
      
      
      reminder = ifelse(str_detect(subject, "提醒：|溫馨提示"), 
                        "yes",
                        "no"),
      
      inquiry = 	ifelse(str_detect(subject, "住宿諮詢："), 
                        "yes",
                        "no"),
      
      reservation_confirmation = ifelse(str_detect(subject, "預訂已確認"), 
                                        "yes",
                                        "no"),
      
      reservation_cancelation = ifelse(str_detect(subject, "已取消："), 
                                       "yes",
                                       "no"),
      
      reservation_change = ifelse(str_detect(subject, "預訂已更新"), 
                                  "yes",
                                  "no"),
      
      reservation_change_request = ifelse(str_detect(subject, "想要更改預訂"), 
                                          "yes",
                                          "no"),
      
      reservation_update = ifelse(str_detect(subject, "預訂已更新"),
                                  "yes",
                                  "no"),
      
      
      
      
      account_activity = 	ifelse(str_detect(subject, "帳號活動：|Reset your password|請確認電子郵件地址|請確認電子郵件地址"), 
                                 "yes",
                                 "no"),
      
      payment_issues = ifelse(str_detect(subject, "付款問題|你已要求.*付款|要求你付款|已收到補償|提出的補償申請|確認搭檔收款|取消了收款提案|你已向.*支付賠償金"), 
                              "yes",
                              "no"),
      
      
      
      miscellaneous = 	ifelse(str_detect(subject, "感謝你接受.*的邀請|身分已通過驗證|Message sent off-schedule|Messages sent off-schedule|Scheduled message skipped|你身為搭檔所擁有的權限已變更|緊急通知：新增必要的出租資訊|是時候回覆Xu Jing YiIrene的住宿諮詢了|在6小時內回覆宜嫻的預訂詢問以維持您的高回覆率|有房客今天想入住|你的預訂變更已接受"), 
                              "yes",
                              "no")
      
      
    ) |>
    
    
    # Do some initial cleaning of the body
    # Clean body
    mutate(body_cleaned = str_replace_all(body,
                                          "\\n|\\r", 
                                          "~~newline~~")) |>
    
    mutate(body_cleaned = str_squish(body_cleaned)) |>
    
    mutate(         # euid = str_extract(body, "(?<=&euid=).*?(?=( |&))"),
      context_parameter = str_extract(body, "(?<=c\\=\\.pi80\\.pk).*?(?=\\&)"),
      room_id = str_extract(body, "(?<=www.airbnb.com.tw/rooms/).*?(?=\\?)")
    )
  
  
  categorized_airbnb$context_parameter2 <- sapply(categorized_airbnb$context_parameter, decoder)
  
  
  categorized_airbnb
  
  
  
}
