# Get July schedule
library(dplyr)

airbnb_emails2 <- read.csv( file = "data/airbnb_reservations.csv")  

this_month <- timeperiodsR::this_month(part = "sequence") 
# this returns each date in this month
for(i in seq_along(this_month)){

  
  
  events_today = FALSE

  
   todays_checkouts <- airbnb_emails2 |> 
     dplyr::filter(checkout_date == this_month[i])
   
   
   #print(nrow(todays_checkouts))
   
   write(as.character(this_month[i]),
         file = "data/daily_schedule.txt", append = TRUE)
   
   if(nrow(todays_checkouts) > 0){
     events_today = TRUE

     for(t in 1:nrow(todays_checkouts)){
       
       # Print info about the checkout
       write(paste0("(",todays_checkouts[t,"room_number"], ")"),
             file = "data/daily_schedule.txt", append = TRUE)
       
       write(paste0("Check out: ", 
                    todays_checkouts[t,"guest_first_name"], 
                    " ",todays_checkouts[t, "checkout_time"]),
             file = "data/daily_schedule.txt", append = TRUE)
       
       # Find the next checkin for the room
       future_checkins <- airbnb_emails2 |> 
         dplyr::filter(room_number == todays_checkouts[t,"room_number"],
                checkin_date > this_month[i]) |>
         dplyr::arrange(checkin_date)
       
       write(paste0("Check in: ",
                    future_checkins[1, "checkin_date"], 
                    " ", future_checkins[1, "guest_first_name"], 
                    " ", future_checkins[1, "checkin_time"]),
             file = "data/daily_schedule.txt", append = TRUE)
       
       write(paste0("Drop Keycard : (",
                    todays_checkouts[t,"room_number"],
                    ") ", 
                    future_checkins[1, "guest_first_name"], " 515"),
             file = "data/daily_schedule.txt", append = TRUE)
       
       if(t == nrow(todays_checkouts)){
         
         write("\n",
               file = "data/daily_schedule.txt", append = TRUE)
         
       }
     }
   } else {
     
     
     write("\n",
           file = "data/daily_schedule.txt", append = TRUE)
   }
  
  
  
  
  
}               


