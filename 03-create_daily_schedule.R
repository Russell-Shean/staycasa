# Get July schedule
library(dplyr)
library(lubridate)

airbnb_emails2 <- read.csv( file = "data/airbnb_reservation_confirmations.csv")  


month_start <- floor_date(today(), unit = "month")  # First day of the month
next_month_start <- ceiling_date(today(), unit = "month")   # first day of next month

this_month <-  seq.Date(from = month_start, 
                        to = next_month_start - days(1), 
                        by = "day") |>
  as.character()

next_month <-  seq.Date(from = next_month_start,
                        to = ceiling_date(next_month_start , 
                                          unit = "month")- days(1), 
                        by = "day") |>
  as.character()


generate_schedule <- function(day_series){
  
  
  
  file_name <- paste0("data/daily_schedule_",
                      min(day_series),
                      "_",
                      max(day_series),
                      ".txt")
  
  
  # this returns each date in this month
  for(day in day_series){
    

    todays_checkouts <- airbnb_emails2 |> 
      dplyr::filter(checkout_date == day)
    
    
    #print(nrow(todays_checkouts))
    
    write(as.character(format(as.Date(day), "%m-%d")),
          file = file_name , append = TRUE
    )
    
    if(nrow(todays_checkouts) > 0){
      events_today = TRUE
      
      for(t in 1:nrow(todays_checkouts)){
        
        # Print info about the checkout
        write(paste0("(",todays_checkouts[t,"room_number"], ")"),
              file = file_name, append = TRUE)
        
        write(paste0("Check out: ", 
                     todays_checkouts[t,"guest_first_name"], 
                     " ",todays_checkouts[t, "checkout_time"]),
              file = file_name, append = TRUE)
        
        # Find the next checkin for the room
        future_checkins <- airbnb_emails2 |> 
          dplyr::filter(room_number == todays_checkouts[t,"room_number"],
                        checkin_date >= day) |>
          dplyr::arrange(checkin_date)
        
        write(paste0("Check in: ",
                     future_checkins[1, "checkin_date"], 
                     " ", future_checkins[1, "guest_first_name"], 
                     " ", future_checkins[1, "checkin_time"]),
              file = file_name, append = TRUE)
        
        write(paste0("Drop Keycard : (",
                     todays_checkouts[t,"room_number"],
                     ") ", 
                     future_checkins[1, "guest_first_name"], " 515"),
              file = file_name, append = TRUE)
        
        if(t == nrow(todays_checkouts)){
          
          write("\n",
                file = file_name, append = TRUE)
          
        }
      }
    } else {

      write("\n",
            file = file_name, append = TRUE)
    }
  }               
}

generate_schedule(this_month)
generate_schedule(next_month)


