

confirmed_changes_extractor <- function(airbnb_emails) {


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
    str_detect(room_title, "CityLink Suite Xinyi Downtown") ~ as.character(301),
    
    str_detect(room_title, "Luxe Modern Xinyi") ~ as.character("Renai Casa 2F-2"),
    str_detect(room_title, "Parkside Oasis") ~ as.character("Casa 2-3"))) |>
  
  # Break ties for multiple change requests in a row
  # based on when the email was received
  arrange(guest_first_name, room_number, desc(datetime_taipei)) |>
  distinct(confirmation_number, .keep_all = TRUE)


airbnb_confirmed_changes

}
