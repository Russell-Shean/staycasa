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
                function(x)as.Date(x, format = "%Y年%m月%d日")))


if(any(is.na(airbnb_change_requests$change_type))){
  warning("NA change requests found. Please check the airbnb_change_requests dataframe to see what was requested")
}


airbnb_change_requests2 <- airbnb_change_requests |>
                           select(guest_first_name, 
                                  room_title,
                                  og_guest_number:requested_checkout_date)

airbnb_confirmed_changes <- airbnb_emails |> 
  filter(str_detect(subject, "預訂已更新")) |>
  # extract confirmation numbers
  mutate(confirmation_number = str_extract(body_cleaned, "(?<=reservations/details/).*?(?=\\?)"),
         guest_first_name = str_extract(body_cleaned, "(?<=您與).*(?=的預訂已經更新)"),
         room_title = str_extract(body, "Taipei 101 Executive Suite \\(Self-Check in\\)|The Creative Loft Xinyi | Walk to 101+Night Market|Panoramic Corner Loft in Xinyi | Taipei 101 Views|101夜景之家 \\| 月租嚴選|Cozy City Hideaway Tpe 101 & Tonghua Mkt \\(LT Stay\\)|Chic 2-Story Loft w/101 Views（Great for LT stay\\)")) 
  

airbnb_confirmed_changes2 <- airbnb_confirmed_changes |>
                             select(confirmation_number,
                                    guest_first_name, 
                                    room_title) |>
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


write.csv(airbnb_reservation_confirmations4, 
          file = "data/airbnb_reservation_confirmations.csv", 
          row.names = FALSE)  



