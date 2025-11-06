# Load emails as a data frame and process
library(jsonlite)
library(dplyr)
library(stringr)
library(base64enc)
library(lubridate)

sample_data <- fromJSON("data/emails.json")

sample_data <- fromJSON("data/emails_from_api.json")

# add additional columns
sample_data2 <- sample_data |>
  
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
                       taipei_time = format(datetime_taipei, "%H:%M:%S"),
                    
                       
                       
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
                         
                       
                       
                       
                       
                       )


airbnb_emails <- sample_data2 |>
                 filter(sender_domain == "airbnb.com" 
                        
                        # We're just going to deal with this manually
                        #(sender_email == "simon1122@gmail.com" &date == "2025-11-04")
                        
                        )  |> 
  
                  # Clean body
                 mutate(body_cleaned = str_replace_all(body,
                                                       "\\n|\\r", 
                                                       "~~newline~~")) |>
  
                 mutate(body_cleaned = str_squish(body_cleaned)) |>
  
  
  
  
                  # Do a first round extraction of confirmation numbers
                  mutate(confirmation_number = str_extract(body, "(?<=/reservations/details/).*(?=\\?)")) |>
  
                  # extract the reservation number from cancelations
                  mutate(confirmation_number = ifelse(is.na(confirmation_number),
                                                      str_extract(subject, "(?<=已取消：預訂).*(?=（)"),
                                                      confirmation_number)) |>
  
                  # Get the reservation number from the forwarded airbnb emails
                  
  
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

                   airbnb_emails$context_parameter2 <- sapply(airbnb_emails$context_parameter, decoder)
                   
                   
                   
      # Print a warning about host modified reservations that aren't in the emails
      host_modified_reservations <- airbnb_emails |>
                                    filter(str_detect(subject, "你的預訂變更已接受"))
      
      
      for(confirmation_number  in host_modified_reservations$confirmation_number){
        
        warning(paste0("The following reservation number has changes that don't show up in any of the emails!\n",
                       confirmation_number))
      }
                   
                   
                  
         ##############################################
           airbnb_reservation_confirmations <- airbnb_emails|>
                     dplyr::filter(review == "no",
                                   reply == "no",
                                   super_host_invite == "no",
                                   reminder == "no",
                                   inquiry == "no",
                                   account_activity == "no",
                                   reservation_change_request == "no",
                                   payment_issues == "no",
                                   reservation_update == "no",
                                   miscellaneous == "no",
                                   context_parameter2 != "booking/v2_migration/reservation_host_pending",
                                   context_parameter2 != "reservation/inquiries/first_preapprove_reminder7",
                                   context_parameter2 != "claims/resolution_center/to_claimant_offer_money",
                                   context_parameter2 != "claims/resolution_center/to_claimant_accept_request"
                                   
                     )  
                   
                   airbnb_replies <- airbnb_emails |> 
                     filter(str_detect(subject, "RE:.*預訂"))
                   
                   
                   airbnb_cancelations <- airbnb_emails |> 
                     filter(str_detect(subject, "已取消：")) |>
                     mutate(guest_first_name = str_extract(body, "(?<=你的房客).*(?=必須取消)"))
                   
                   # Pull out the cancellation numbers
                   cancelation_numbers <- airbnb_cancelations |> 
                                          pull(confirmation_number) |> 
                                          unique()
                   
                   airbnb_reminders <- airbnb_emails |> 
                     filter(str_detect(subject, "提醒：.*快要入住了"))
                   
      ######################################################
                   
                   airbnb_reminders <- airbnb_reminders |>
                     
                     # extract confirmation numbers
                     mutate(confirmation_number = str_extract(body_cleaned, "(?<=reservations/details/).*?(?=\\?)")) |>
                     
                     
                     mutate(guest_first_name = str_extract(subject, "(?<=提醒：).*(?=快要)"))  |>
                     
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
                            checkout_date = str_squish(str_extract(reservation_dates, "(?<=週.).*(?=週)")),
                            checkin_day_of_week = str_extract(reservation_dates, "週."),
                            checkout_day_of_week = str_extract(reservation_dates, "週.(?=..午)"),
                            checkin_time = str_extract(reservation_times, "^.*(?= .午)"),
                            checkout_time = str_extract(reservation_times, "(?<= ).*$")) |>
                     
                     
                     # Convert checkin and checkout time to 24 hour clock
                     mutate(across(c(checkin_time, checkout_time),
                                   function(x)case_when(x=="下午4:00" ~ "16:00", 
                                                        x == "中午12:00" ~ "12:00",
                                                        x == "下午6:00" ~ "18:00",
                                                        x == "下午3:00" ~ "15:00",
                                                        x == "上午11:00" ~ "11:00",
                                                        .default = x))) |>
                     
                     
                     # convert checkin date to actual date format
                     mutate(checkin_date = ifelse(!str_detect(checkin_date, "年") & !is.na(checkin_date),
                                                  paste0(format(Sys.Date(), "%Y年"), checkin_date),
                                                  checkin_date),
                            checkout_date = ifelse(!str_detect(checkout_date, "年") & !is.na(checkout_date),
                                                   paste0(format(Sys.Date(), "%Y年"), checkout_date),
                                                   checkout_date),) |>
                     
                     mutate(across(c(checkin_date, checkout_date), ~ as.Date(.x, format= "%Y年%m月%d日"))) |>
                     
                     
                     # Guest info
                     mutate( #guest_name = str_extract(subject, "(?<=預訂已確認 -).*(?=於)"),
                       #guest_first_name = str_extract(body_cleaned, "(?<=已確認！).*(?=於)"),
                       guests_block = str_replace_all(str_extract(info_block1, "人數.*即將入住")," ", ""),
                       number_of_adults = as.numeric(str_extract(guests_block, "\\d+(?=名成人)")),
                       number_of_children = as.numeric(str_extract(guests_block, "\\d+(?=名兒童)"))) |>
                     
                     # convert na's to zeros for children
                     mutate(number_of_children = ifelse(!is.na(number_of_adults) & is.na(number_of_children),
                                                        0,
                                                        number_of_children)) |>
                     
                     mutate(number_of_guests = number_of_children + number_of_adults) |>
                     
                     mutate(room_number = case_when(room_id == "1396249388984584475" ~ as.character(1600),
                                                    room_id == "1378099322751033231" ~ as.character(513),
                                                    room_id == "1363706811577260499" ~ as.character(1615),
                                                    room_id == "1334778893973629207" ~ as.character(716),
                                                    room_id == "1325719145487941225" ~ as.character(1713),
                                                    room_id == "1316303449136573922" ~ as.character(515),
                                                    room_id == "1304380734749180095" ~ as.character(814),
                                                    
                                                    # NEW ROOM here!!
                                                    room_id == "1543487232480210468" ~ as.character(310)))
                   
                   
                   
                   
                   
                   
    ###############################################################
                   
                   
                   
              airbnb_reservation_confirmations2 <- airbnb_reservation_confirmations |>
                
                 # filter out cancelations
                 dplyr::filter(!(confirmation_number %in% cancelation_numbers)) |>
  
  
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
                        checkout_date = str_squish(str_extract(reservation_dates, "(?<=週.).*(?=週)")),
                        checkin_day_of_week = str_extract(reservation_dates, "週."),
                        checkout_day_of_week = str_extract(reservation_dates, "週.(?=..午)"),
                        checkin_time = str_extract(reservation_times, "^.*(?= .午)"),
                        checkout_time = str_extract(reservation_times, "(?<= ).*$")) |>
                     
                     
                     # Convert checkin and checkout time to 24 hour clock
                mutate(across(c(checkin_time, checkout_time),
                              function(x)case_when(x=="下午4:00" ~ "16:00", 
                                                   x == "中午12:00" ~ "12:00",
                                                   x == "下午6:00" ~ "18:00",
                                                   .default = x))) |>
                        
                        
                # convert checkin date to actual date format
                mutate(checkin_date = ifelse(!str_detect(checkin_date, "年") & !is.na(checkin_date),
                                             paste0(format(Sys.Date(), "%Y年"), checkin_date),
                                             checkin_date),
                       checkout_date = ifelse(!str_detect(checkout_date, "年") & !is.na(checkout_date),
                                             paste0(format(Sys.Date(), "%Y年"), checkout_date),
                                             checkout_date),) |>
                     
               mutate(across(c(checkin_date, checkout_date), ~ as.Date(.x, format= "%Y年%m月%d日"))) |>
                        
                        
                        # Guest info
                mutate( guest_name = str_extract(subject, "(?<=預訂已確認 -).*(?=於)"),
                        guest_first_name = str_extract(body_cleaned, "(?<=已確認！).*?(?=於)"),
                        guests_block = str_replace_all(str_extract(info_block1, "人數.*即將入住")," ", ""),
                        number_of_adults = as.numeric(str_extract(guests_block, "\\d+(?=名成人)")),
                        number_of_children = as.numeric(str_extract(guests_block, "\\d+(?=名兒童)"))) |>
                        
                        # convert na's to zeros for children
                        mutate(number_of_children = ifelse(!is.na(number_of_adults) & is.na(number_of_children),
                                                    0,
                                                    number_of_children)) |>
                        
                        mutate(number_of_guests = number_of_children + number_of_adults) |>
                     
                     
                        mutate(room_number = case_when(room_id == "1396249388984584475" ~ as.character(1600),
                                                       room_id == "1378099322751033231" ~ as.character(513),
                                                       room_id == "1363706811577260499" ~ as.character(1615),
                                                       room_id == "1334778893973629207" ~ as.character(716),
                                                       room_id == "1325719145487941225" ~ as.character(1713),
                                                       room_id == "1316303449136573922" ~ as.character(515),
                                                       room_id == "1304380734749180095" ~ as.character(814),
                                                       room_id == "1543487232480210468" ~ as.character(310)))

                   
                   # Add reminders that aren't currently in the data set
                   confirmation_numbers <- airbnb_reservation_confirmations2 |> 
                                  pull(confirmation_number)  |>
                                  unique()
                   
                   
                   airbnb_reminders2 <- airbnb_reminders |>
                                      filter(!(confirmation_number %in% confirmation_numbers)) |>
        
                   
                   # remove emails that are duplicates
                                      distinct(confirmation_number, .keep_all = TRUE) |>
                   
                   # remove cancellations from the reminders too!
                   dplyr::filter(!(confirmation_number %in% cancelation_numbers)) 
                   
                   
                   
                   airbnb_reservation_confirmations3 <- airbnb_reservation_confirmations2 |>
                                                        full_join(airbnb_reminders2)

  
                 

                   
 ####################################################333
                   
        #  Add change requests
                   
#########################################################
  
  
                   
                   airbnb_change_requests <- airbnb_emails |> 
                     filter(str_detect(subject, "想要更改預訂")) |>
                     # extract confirmation numbers
                     mutate(confirmation_number = str_extract(body_cleaned, "(?<=reservations/details/).*?(?=\\?)")) |>
                     mutate(guest_first_name = str_extract(body, ".*(?=想要更改預訂)"),
                            room_title = str_squish(str_extract(body, "(?<=·).*")),
                            changes_info_block = str_extract(body_cleaned, "(?<=原來的).*(?=如果您接受)") #,
                            # change_type = ifelse(str_detect(changes_info_block, "日期"),
                            #                     "dates",
                            #                    ifelse(str_detect(changes_info_block, "房客"),
                            #                         "guests",
                            #                       NA))
                            
                            
                     ) |>
                     
                     
                     # remove all the new lines stuff from the changes info block
                     mutate(changes_info_block = str_remove_all(changes_info_block, "~~newline~~"),
                            og_dates = str_extract(changes_info_block, "(?<=日期).*(?=申請的日期)"),
                            requested_dates = str_extract(changes_info_block, "(?<=申請的日期).*?(?=原來的房客|$)"),
                            og_guest_number = as.numeric(str_extract(changes_info_block, "(?<=房客).*(?=人申請的房客)")),
                            requested_guest_number = as.numeric(str_extract(changes_info_block, "(?<=申請的房客).*(?=人)")),
                            
                            og_checkin_date = str_squish(str_extract(og_dates,".*(?=-)")),
                            requested_checkin_date = str_squish(str_extract(requested_dates, ".*(?=-)")),
                            
                            og_checkout_date = str_squish(str_extract(og_dates,"(?<=-).*" )),
                            requested_checkout_date = str_squish(str_extract(requested_dates, "(?<=-).*" ))
                            
                     ) |>
                     
                     mutate(across(c(og_checkin_date, 
                                     og_checkout_date, 
                                     requested_checkin_date, 
                                     requested_checkout_date), 
                                   function(x)as.Date(x, format = "%Y年%m月%d日")))  |>
                     
                     # get the room number
                     mutate(room_number = case_when(
                       str_detect(room_title, "Skyline Luxe Loft in Xinyi|Panoramic Corner Loft in Xinyi") ~ as.character(1600),
                       str_detect(room_title, "The Creative Loft Xinyi") ~ as.character(513),
                       str_detect(room_title, "Taipei 101 Executive Suite") ~ as.character(1615),
                       str_detect(room_title, "Cozy City Hideaway Tpe 101") ~ as.character(716),
                       str_detect(room_title, "Chic 2-Story Loft w/101 Views") ~ as.character(1713),
                       str_detect(room_title, "Modern Boutique Loft in Xinyi") ~ as.character(515),
                       str_detect(room_title, "101夜景之家") ~ as.character(814),
                       
                       # NEW ROOM here!!
                       str_detect(room_title, "CityLink Suite Xinyi Downtown") ~ as.character(310)))
                   
                   
                   if(any(is.na(airbnb_change_requests$change_type))){
                     warning("NA change requests found. Please check the airbnb_change_requests dataframe to see what was requested")
                   }
                   
                   
                   airbnb_change_requests2 <- airbnb_change_requests |>
                     select(guest_first_name, 
                            room_number,
                            og_guest_number:requested_checkout_date)
                   
                   airbnb_confirmed_changes <- airbnb_emails |> 
                     filter(str_detect(subject, "預訂已更新")) |>
                     # extract confirmation numbers
                     mutate(confirmation_number = str_extract(body_cleaned, "(?<=reservations/details/).*?(?=\\?)"),
                            guest_first_name = str_extract(body_cleaned, "(?<=您與).*(?=的預訂已經更新)"),
                            
                            # Add new room here
                            room_title = str_extract(body, "Taipei 101 Executive Suite \\(Self-Check in\\)|The Creative Loft Xinyi | Walk to 101+Night Market|Panoramic Corner Loft in Xinyi | Taipei 101 Views|101夜景之家 \\| 月租嚴選|Cozy City Hideaway Tpe 101 & Tonghua Mkt \\(LT Stay\\)|Chic 2-Story Loft w/101 Views（Great for LT stay\\)|CityLink Suite Xinyi Downtown|Modern Boutique Loft in Xinyi - Work, Live & Play|Skyline Luxe Loft in Xinyi | Taipei 101 Views")) |>
                    
                     # get the room number
                     mutate(room_number = case_when(
                            str_detect(room_title, "Skyline Luxe Loft in Xinyi|Panoramic Corner Loft in Xinyi") ~ as.character(1600),
                            str_detect(room_title, "The Creative Loft Xinyi") ~ as.character(513),
                            str_detect(room_title, "Taipei 101 Executive Suite") ~ as.character(1615),
                            str_detect(room_title, "Cozy City Hideaway Tpe 101") ~ as.character(716),
                            str_detect(room_title, "Chic 2-Story Loft w/101 Views") ~ as.character(1713),
                            str_detect(room_title, "Modern Boutique Loft in Xinyi") ~ as.character(515),
                            str_detect(room_title, "101夜景之家") ~ as.character(814),
                            
                            # NEW ROOM here!!
                            str_detect(room_title, "CityLink Suite Xinyi Downtown") ~ as.character(310)))
                   
                   
                   airbnb_confirmed_changes2 <- airbnb_confirmed_changes |>
                     select(confirmation_number,
                            guest_first_name, 
                            room_number) |>
                     left_join(airbnb_change_requests2)
                   
                   
                   
                   
                   airbnb_reservation_confirmations4 <- airbnb_reservation_confirmations3 |>
                     left_join(airbnb_confirmed_changes2, 
                               by = join_by("confirmation_number" == "confirmation_number")) |>
                     mutate(checkin_date = if_else(is.na(requested_checkin_date),
                                                   checkin_date,
                                                   requested_checkin_date),
                            checkout_date = if_else(is.na(requested_checkout_date),
                                                    checkout_date,
                                                    requested_checkout_date),
                            number_of_guests = if_else(is.na(requested_guest_number),
                                                       number_of_guests,
                                                       requested_guest_number))
                   
                   
                   
                   # Make manual changes that don't show up in any of the emails
                   airbnb_reservation_confirmations4 <- airbnb_reservation_confirmations4 |>
                                                        mutate(checkout_date = if_else(confirmation_number == "HMQMWRA9PB",
                                                                                       as.Date("2025-06-28"),
                                                                                       checkout_date)) |>
                     
                     mutate(checkout_date = if_else(confirmation_number == "HM5CRZWWZZ",
                                                    as.Date("2025-08-04"),
                                                    checkout_date)) |> 
                     
                     
                     mutate(checkout_date = if_else(confirmation_number == "HMYN3YCAQ2",
                                                    as.Date("2025-10-11"),
                                                    checkout_date)) |>
                     
                     # rename room_numbers
                     rename(room_number = room_number.x)
                   
                   
                   
                   # Manually create a dataframe for the three reservations that weren't included
            #       manual_reservations <- data.frame(
                     
             #        checkin_date = c(),
              #       checkout_date = c(),
              #       confirmation_number = c(),
              #       room_number = c()
              #       guest_first_name.x = c(),
              #       number_of_guests = c(),
              #       checkin_time = c(),
              #       checkout_time = c()
              #       date = c()
                       
              #     )
                   
                   
                   write.csv(airbnb_reservation_confirmations4, 
                             file = "data/airbnb_reservation_confirmations.csv", 
                             row.names = FALSE)  
                   
                   
                   
                   
                 
                  
   
