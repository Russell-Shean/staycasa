# reservations
reservation_extractor <- function(airbnb_emails) {



reservations <- airbnb_emails|>
                
  dplyr::filter(context_parameter2 %in% c("booking/host/ReservationHostConfirmationTemplate", 
                                          #"booking/cancellation/guest_to_host/ReservationCanceledByGuestToHostTemplate", 
                                          "booking/v2_migration/reservation_host_confirmation")) |>
                  
                  
                  
      # add new fields
        mutate(confirmation_number = str_squish(str_extract(body, "(?<=/reservations/details/).*(?=\\?)"))) |>
  
  
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
                               paste0(format(taipei_date, "%Y年"), checkin_date),
                               checkin_date),
         checkout_date = ifelse(!str_detect(checkout_date, "年") & !is.na(checkout_date),
                                paste0(format(taipei_date, "%Y年"), checkout_date),
                                checkout_date)) |>
  
  mutate(across(c(checkin_date, checkout_date), ~ as.Date(.x, format= "%Y年%m月%d日"))) |>
  
  # Catch checkin dates where the year is in a different year than the email
  # ie. an email on dec 30 2025 about a checkin on jan 03 2026 
  
  mutate(checkin_date = if_else(checkin_date < taipei_date,
                               checkin_date + years(1),
                               checkin_date),
         checkout_date = if_else(checkout_date < taipei_date,
                                checkout_date + years(1),
                                checkout_date)) |> 
  
  
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
                                 room_id == "1543487232480210468" ~ as.character(301),
                                 room_id == "1558409237712768132" ~ as.character("Renai Casa 2F-2"),
                                 room_id == "1556499339485122464" ~ as.character("Casa 2-3"),
                                 room_id == "1626777461460533309" ~ as.character("5F-3"),
                                 room_id == "1662216486099283423" ~ as.character("Tina1")))

  

reservations 
  
}
