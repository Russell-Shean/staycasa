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

# next 20 days
next_20_days <- seq.Date(from = today(),
                         length.out = 20, 
                         by = "day")  |>
  as.character()


#########################################################################3
# Define advanced keydrops


# create a keycard drops dataframe
# we should do this for the entire dataset not just the date series
# because there's a possibility that the checkout occurs in a different month
# than the checkin


# The keycard should be dropped off the same day as the checkout
# only if the checking occurs within the next three days
# otherwise the key should be dropped off the day of the checkin



min_date <- c(airbnb_emails2$checkin_date,
              airbnb_emails2$checkout_date) |> 
  unique() |>
  min() |>
  as.Date()

max_date <- c(airbnb_emails2$checkin_date,
              airbnb_emails2$checkout_date) |> 
  unique() |>
  max() |>
  as.Date()


complete_date_range <- seq.Date(from = min_date,
                                to = max_date, 
                                by = "day") |>
  as.character()




# create a dataframe to determine if the keydrop needs to be done
# a day before checkin
# the default is no, which we'll modify further down
keydrops <- data.frame(date = as.Date(complete_date_range), 
                       advanced_key_drop = FALSE, 
                       confirmation_number = NA)





for(day in complete_date_range){
  
  #print(day)
  
  todays_checkouts <- airbnb_emails2 |> 
    dplyr::filter(checkout_date == day)
  
  todays_checkins <- airbnb_emails2 |> 
    dplyr::filter(checkin_date == day)
  
  if(nrow(todays_checkouts) > 0){
    
    for(t in 1:nrow(todays_checkouts)){
      
      
      # Find the next checkin for the room
      future_checkins <- airbnb_emails2 |> 
        dplyr::filter(room_number == todays_checkouts[t,"room_number"],
                      checkin_date >= day) |>
        dplyr::arrange(checkin_date)
      
      
    }
    
    
    # The keycard should be dropped off the same day as the checkout
    # only if the checking occurs within the next three days
    # otherwise the key should be dropped off the day of the checkin
    
    
    # check to make sure there are entries in the dataframes
    if(nrow(future_checkins) > 0 & 
       nrow(todays_checkouts) > 0){
      
      if(as.Date(future_checkins[1,"checkin_date"]) - as.Date(todays_checkouts[t,"checkout_date"]) > 3){
        
        
        
        keydrops <- keydrops |>
          mutate(advanced_key_drop = if_else(date == as.Date(future_checkins[1,"checkin_date"]) - 1,
                                             TRUE,
                                             advanced_key_drop),
                 
                 confirmation_number = if_else(date == as.Date(future_checkins[1,"checkin_date"]) - 1,
                                               future_checkins[1,"confirmation_number"],
                                               confirmation_number)
          )
        
        
      } 
      
    }
  }
  
  
}


# merge data about the checkin onto keydrops dataframe

keydrops <- keydrops |>
  
  # filter out NA values
  filter(!is.na(confirmation_number)) |>
  
  
  left_join(airbnb_emails2, by = join_by("confirmation_number" == "confirmation_number"))










###########################################################################


generate_schedule <- function(day_series, file_name=NULL){
  
 # day_series <- next_month

  if(is.null(file_name)){
  file_name <- paste0("data/daily_schedule_",
                      min(day_series),
                      "_",
                      max(day_series),
                      ".txt")
  }
  
  # Make sure we're starting with a blank file
  write("", file = file_name)
  
  
  # this returns each date in this month
  for(day in day_series){
    
    #print(day)
    #day <- "2025-12-25"

    todays_checkouts <- airbnb_emails2 |> 
      dplyr::filter(checkout_date == day)
    
    todays_checkins <- airbnb_emails2 |> 
      dplyr::filter(checkin_date == day)
    
    
    #print(nrow(todays_checkouts))
    
    write(as.character(format(as.Date(day), "%m-%d")),
          file = file_name , append = TRUE
    )
    
    if(nrow(todays_checkouts) > 0){
      events_today = TRUE
      
      for(t in 1:nrow(todays_checkouts)){
        
        
        # Find the next checkin for the room
        future_checkins <- airbnb_emails2 |> 
          dplyr::filter(room_number == todays_checkouts[t,"room_number"],
                        checkin_date >= day) |>
          dplyr::arrange(checkin_date)
        
        
        # Determine when the unit should be cleaned
        clean_time <- ifelse(future_checkins[1, "checkin_date"] == day &
                               # If there are no future checkins, just print clean
                               # anytime
                               nrow(future_checkins) > 0,
                             " Clean immediately",
                             " Clean anytime of day")
        
        # Print info about the checkout
        write(paste0("(",todays_checkouts[t,"room_number"], ")"),
              file = file_name, append = TRUE)
        
        write(paste0("Check out: ", 
                     todays_checkouts[t,"guest_first_name.x"], 
                     " ",todays_checkouts[t, "checkout_time"],
                     clean_time),
              file = file_name, append = TRUE)
        

        # Print info about checkins
        # if there are no future checkins, don't print anything
        
        if(nrow(future_checkins) > 0){
        write(paste0("Check in: ",
                     future_checkins[1, "checkin_date"], 
                     " ", future_checkins[1, "guest_first_name.x"], 
                     "(", future_checkins[1, "number_of_guests"], 
                     ") ", future_checkins[1, "checkin_time"]),
              file = file_name, append = TRUE)
          
        }
        
        # Print about key card drops
        
        # The keycard should be dropped off the same day as the checkout
        # only if the checking occurs within the next three days
        # otherwise the key should be dropped off the day of the checkin
        
        
        if((as.Date(future_checkins[1,"checkin_date"]) - as.Date(todays_checkouts[t,"checkout_date"]) > 3)|nrow(future_checkins) < 1){
        

          keydrop_on_checkout <- FALSE
          
          
        } else {
          
          
          keydrop_on_checkout <- TRUE
          
          
          write(paste0("Drop Keycard : (",
                       future_checkins[1, "room_number"],
                       ") ", 
                       future_checkins[1, "guest_first_name.x"],
                       " 515"),
                file = file_name, append = TRUE)
          
          
          
        }
        

        
        
        # remove the future checkin from today's checkins so that we don't
        # double print
        todays_checkins <- todays_checkins |>
                           dplyr::filter((!guest_first_name.x == future_checkins[1, "guest_first_name.x"] &
                                         checkin_time  == future_checkins[1, "checkin_time"])) 
        
        if(t == nrow(todays_checkouts)){
          
          write("\n",
                file = file_name, append = TRUE)
          
        }
      }
    } else {


      write("\n",
            file = file_name, append = TRUE)
    }
    
    # Write out checkins for listings where there's not a checkout  date listed
    
    if(nrow(todays_checkins) > 0){
    
    for(u in 1:nrow(todays_checkins)){
      
      # Print info about the checkin
      write(paste0("(",todays_checkins[u,"room_number"], ")"),
            file = file_name, append = TRUE)
      
      write(paste0("Check in: ", 
                   todays_checkins[u,"guest_first_name.x"], 
                   "(", todays_checkins[1, "number_of_guests"], 
                   ") ",
                   " ",todays_checkins[u, "checkin_time"]),
            file = file_name, append = TRUE)
      
      
      if(u == nrow(todays_checkins)){
        
        write("\n",
              file = file_name, append = TRUE)
        
      }
    }
    }
    
    
    # check to see if there are advanced keydrops that need to be recorded for the day
    if(day %in% keydrops$date.x){
      
      
      todays_keydrops <- keydrops |>
        filter(date.x == day)
      
      
      for(z in 1:nrow(todays_keydrops)){
        
        write(paste0("DAY BEFORE KEY DROPS:\nDrop Keycard : (",
                     todays_keydrops[z, "room_number"],
                     ") ", 
                     todays_keydrops[z, "guest_first_name.x"],
                     " 515\n"),
              file = file_name, append = TRUE)
        
        
        
        
      }
      
      

      
      
    }

    
  }   #破哦  
  
  #print(keydrops)
}

generate_schedule(this_month)
generate_schedule(next_month)
generate_schedule(next_20_days, "data/daily_schedule_next_20.txt")


