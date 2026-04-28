# Load emails as a data frame and process
library(jsonlite)
library(dplyr)
library(stringr)
library(base64enc)
library(lubridate)

# Load functions
for(file in list.files("R", full.names = TRUE)){
  source(file)
}


# Load emails, filter for only airbnb, and assign categories
airbnb_emails <- fromJSON("data/emails_from_api.json") |> 
                 filter_for_airbnb()  |>
                 categorize_airbnb()

# find confirmations and extract data
reservation_confirmations <- airbnb_emails|>
                             reservation_extractor() |>
        
                             # filter out cancelled reservations
                             filter(!(confirmation_number %in% get_cancellation_numbers(airbnb_emails)))
      

# Find reminders and extract data
reminders <- airbnb_emails |>
             reminder_extractor() 

# Add reminders that aren't currently in the reservations dataset
# to the reservations dataset
confirmation_numbers <- reservation_confirmations |> 
                        pull(confirmation_number)  |>
                        unique()

                   
reminders2 <- reminders |>
  
              # remove reminders for reservations where there's already a confirmed
              # Reservation. This may be a bad idea because I'm adding them back later to catch 
              # reservations that changed
              filter(!(confirmation_number %in% confirmation_numbers)) |>
                   
              # remove cancellations from the reminders too!
              filter(!(confirmation_number %in% get_cancellation_numbers(airbnb_emails)))  |>
  
  
              # arrange the reminders by date so we can choose the latest message for
              # each reservation
              arrange(desc(datetime_taipei)) |>
    
              # remove emails that are duplicates
              distinct(confirmation_number, .keep_all = TRUE) 
                   
                   
                   
reservation_confirmations2 <- reservation_confirmations |>
                                     full_join(reminders2)
                   

# Find change requests
change_requests <- airbnb_emails |> 
                   change_requests_extractor()



# find confirmed changes
confirmed_changes <- airbnb_emails |> 
                     confirmed_changes_extractor()
                   
confirmed_changes2 <- confirmed_changes |>
                             select(confirmation_number,
                                    guest_first_name, 
                                    date,
                                    room_number) |>
                             left_join(change_requests) |>
                             group_by(confirmation_number) |>
                             slice_max(order_by = date,
                                       n = 1, 
                                       with_ties = FALSE) |>
                             ungroup() |>
                             select(-date)


                   
reservation_confirmations3 <- reservation_confirmations2 |>
                     left_join(confirmed_changes2, 
                               by = join_by(confirmation_number,
                                            guest_first_name,
                                            room_number
                                            )) |>
                     mutate(checkin_date = if_else(is.na(requested_checkin_date),
                                                   checkin_date,
                                                   requested_checkin_date),
                            checkout_date = if_else(is.na(requested_checkout_date),
                                                    checkout_date,
                                                    requested_checkout_date),
                            number_of_guests = if_else(is.na(requested_guest_number),
                                                       number_of_guests,
                                                       requested_guest_number))

                   
# Add an additional check for things that got missed with all 
# the things above, but probably got caught in the reminders
unique_reminders <- reminders |> 
                    select(date,
                           confirmation_number,
                           room_id,
                           guest_first_name,
                           checkin_date,
                           checkout_date,
                           checkin_time,
                           checkout_time,
                           number_of_adults,
                           number_of_children,
                           number_of_guests,
                           room_number) |>
                     arrange(confirmation_number, desc(date)) |>
                     distinct(confirmation_number, .keep_all = TRUE)
                   
reminders_to_update <- unique_reminders |>
                     inner_join(
                       reservation_confirmations3 |> select(confirmation_number, date_initial = date),
                       by = "confirmation_number"
                     ) |>
                     filter(date > date_initial) |>
                     select(-date_initial) 
                   

reservation_confirmations4 <- rows_update(
                     reservation_confirmations3,
                     reminders_to_update,
                     by = "confirmation_number"
                   )


reservation_confirmations5 <- reservation_confirmations4 |>
                         # filter out things from DAAN casa
                         dplyr::filter(!room_number %in% c("5F-3"))
                   
write.csv(reservation_confirmations4, 
                             file = "data/airbnb_reservation_confirmations.csv", 
                             row.names = FALSE)  
                   