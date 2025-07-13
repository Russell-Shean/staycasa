# Load emails as a data frame and process
library(jsonlite)
library(dplyr)
library(stringr)
library(base64enc)

sample_data <- fromJSON("/home/russ/Documents/python_projects/staycasa-automation/emails.json")

# add additional columns
sample_data2 <- sample_data |>
  
                       # extract info from the from column
                mutate(sender_name = str_squish(str_extract(from, "^.*(?=<)")),
                       sender_email = str_extract(from, "(?<=\\<).*(?=\\>)"),
                       sender_username = str_extract(from, "(?<=<).*(?=@)"),
                       sender_domain = str_extract(from, "(?<=@).*(?=\\>)"),
                       
                       
                       # Convert the date to a date format
                       date = as.Date(date),
                       
                       
                       # determine if an email is a review
                       review = ifelse(str_detect(subject, "評價"), 
                                       "yes",
                                       "no"),
                       
                       reply = ifelse(str_detect(subject, "回覆：|RE:"), 
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
                         
                         
                         
                       
                      account_activity = 	ifelse(str_detect(subject, "帳號活動：|Reset your password|請確認電子郵件地址|請確認電子郵件地址"), 
                                         "yes",
                                         "no"),
                      
                      payment_issues = ifelse(str_detect(subject, "付款問題|你已要求.*付款|要求你付款|已收到補償|提出的補償申請|確認搭檔收款|取消了收款提案"), 
                                               "yes",
                                               "no"),
                       
                      
                       
                       miscellaneous = 	ifelse(str_detect(subject, "感謝你接受.*的邀請|身分已通過驗證|Message sent off-schedule|Messages sent off-schedule|Scheduled message skipped|你身為搭檔所擁有的權限已變更|緊急通知：新增必要的出租資訊|是時候回覆Xu Jing YiIrene的住宿諮詢了|在6小時內回覆宜嫻的預訂詢問以維持您的高回覆率|有房客今天想入住"), 
                                         "yes",
                                         "no")
                         
                       
                       
                       
                       
                       )


airbnb_emails <- sample_data2 |>
                 filter(sender_domain == "airbnb.com")


airbnb_reservations <- airbnb_emails |>
                      dplyr::filter(review == "no",
                             reply == "no",
                             super_host_invite == "no",
                             reminder == "no",
                             inquiry == "no",
                             account_activity == "no",
                             reservation_change_request == "no",
                             payment_issues == "no",
                             miscellaneous == "no"
                             )  


airbnb_emails2 <- airbnb_reservations |> 
  
                  # Do a first round extraction of confirmation numbers
                  mutate(confirmation_number = str_extract(body, "(?<=/reservations/details/).*(?=\\?)")) |>
  
                  # extract the reservation number from cancelations
                  mutate(confirmation_number = ifelse(is.na(confirmation_number),
                                                      str_extract(subject, "(?<=已取消：預訂).*(?=（)"),
                                                      confirmation_number)) |>
  
                  mutate(confirmation_number = str_squish(confirmation_number)) |>
  
                 # Extract the thread id field
                 # (This allows us to link messages to the right reservation)
                 mutate(thread_id = str_extract(body, "(?<=/hosting/thread/).*(?=\\?)")) |>
  
                 # Thread type  
                 mutate(thread_type = str_extract(body, "(?<=thread_type\\=).*?(?=\\&)")) |>
  
                 # room id
                mutate(room_id = str_extract(body, "(?<=www.airbnb.com.tw/rooms/).*?(?=\\?)")) |>
                
                 # Context parameter
                   
                     # From Chat gpt:
  
                    #b. c=.pi80.pkaG9tZXNfbWVzc2FnaW5nL25ld19tZXNzYWdl
                     #This is likely a tracking or internal context parameter.
                     # .pi80.pkaG9tZXNfbWVzc2FnaW5nL25ld19tZXNzYWdl appears to be base64-encoded.
                     # When decoded: homes_messaging/new_message
                    # So this likely helps Airbnb identify the source or action related to messaging.
                   
                   # extract from URL
                   mutate(context_parameter = str_extract(body, "(?<=c\\=\\.pi80\\.pk).*?(?=\\&)")) 

                  
                  # Use base R because something dumb is happening with decoding plus dplyr
                  decoder <- function(x){rawToChar(base64enc::base64decode(x))}

                   airbnb_emails2$context_parameter2 <- sapply(airbnb_emails2$context_parameter, decoder)
                   
                   
                   airbnb_emails2 <- airbnb_emails2 |>
  
       
  
  
                    

  
                 # clean the body field
                 mutate(body_cleaned = str_replace_all(body, "\\n|\\r", "~~newline~~")) |>
                 
                 mutate(body_cleaned = str_squish(body_cleaned)) |>
  
  
                 # extract two blocks of information
                 mutate(info_block1 = str_extract(body_cleaned, "入住 退房.*即將入住租客的更多詳情")) |>
                 mutate(info_block1 = str_replace_all(info_block1, "~~newline~~", "")) |>
  
                 mutate(info_block2 = str_extract(body_cleaned, "確認碼.*出租收入會在房客入住")) |>
                 mutate(info_block2 = str_replace_all(info_block2, "~~newline~~", "")) |>
  
                 # Extract the checkin and checkout dates
                 mutate(reservation_dates = str_squish(str_extract(info_block1, "(?<=退房).*(?=人數)"))) |>
                 mutate(reservation_times = str_squish(str_extract(info_block1, "(?<=週.).*(?=人數)"))) |> 
                 mutate(reservation_times = str_squish(str_extract(reservation_times, "(?<=週.).*"))) |> 
  
                 mutate(checkin_date = str_extract(reservation_dates, "^.*?(?=週)"),
                        checkout_date = str_extract(reservation_dates, "(?<=週.).*(?=週)"),
                        checkin_day_of_week = str_extract(reservation_dates, "週."),
                        checkout_day_of_week = str_extract(reservation_dates, "週.(?=..午)"),
                        checkin_time = str_extract(reservation_times, "^.*(?= .午)"),
                        checkout_time = str_extract(reservation_times, "(?<= ).*$"),
                        
                        
                        # Guest info
                        guest_name = str_extract(subject, "(?<=預訂已確認 -).*(?=於)"),
                        guests_block = str_replace_all(str_extract(info_block1, "人數.*即將入住")," ", ""),
                        number_of_adults = as.numeric(str_extract(guests_block, "\\d+(?=名成人)")),
                        number_of_children = as.numeric(str_extract(guests_block, "\\d+(?=名兒童)"))) |>
                        
                        # convert na's to zeros for children
                        mutate(number_of_children = ifelse(!is.na(number_of_adults) & is.na(number_of_children),
                                                    0,
                                                    number_of_children)) |>
                        
                        mutate(number_of_guests = number_of_children + number_of_adults)

  
                 

  
  
  
  
                 
                  
   
