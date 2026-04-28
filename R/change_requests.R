

change_requests_extractor <- function(airbnb_emails) {


change_requests <- airbnb_emails |> 
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
         
         
  )  |>
  
  
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
    str_detect(room_title, "CityLink Suite Xinyi Downtown") ~ as.character(301),
    
    str_detect(room_title, "Luxe Modern Xinyi") ~ as.character("Renai Casa 2F-2"),
    str_detect(room_title, "Parkside Oasis") ~ as.character("Casa 2-3"),
    str_detect(room_title, "BLORGGGGGHHHHH") ~ as.character("BLORGH")))





change_requests2 <- change_requests |>
  select(guest_first_name, 
         datetime_taipei,
         room_number,
         og_guest_number:requested_checkout_date) |>
  arrange(guest_first_name, room_number, desc(datetime_taipei)) |>
  distinct(guest_first_name, room_number, .keep_all = TRUE) |>
  select(-datetime_taipei)


change_requests2


}
