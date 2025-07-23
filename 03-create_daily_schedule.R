# Get July schedule


this_month <- timeperiodsR::this_month(part = "sequence") 
# this returns each date in this month
for(i in seq_along(this_month)){

  
  
  events_today = FALSE

  
   todays_checkouts <- airbnb_emails2 |> 
     filter(checkout_date == this_month[i])
   
   
   #print(nrow(todays_checkouts))
   
   if(nrow(todays_checkouts) > 0){
     events_today = TRUE
     print(this_month[i])
     for(t in 1:nrow(todays_checkouts)){
       
       # Print info about the checkout
       print(paste0("(",todays_checkouts[t,"room_number"], ")"))
       print(paste0("Check out: ", todays_checkouts[t,"guest_first_name"], " ",todays_checkouts[t, "checkout_time"]))
       
       # Find the next checkin for the room
       future_checkins <- airbnb_emails2 |> 
         filter(room_number == todays_checkouts[t,"room_number"],
                checkin_date > this_month[i]) |>
         arrange(checkin_date)
       
       print(paste0("Check in: ", future_checkins[1, "checkin_date"], " ", future_checkins[1, "guest_first_name"], " ", future_checkins[1, "checkin_time"]))
       
       print(paste0("Drop Keycard : (",todays_checkouts[t,"room_number"], ") ", future_checkins[1, "guest_first_name"], " 515"))
     }
   }
  
  
  
  
  
}               


