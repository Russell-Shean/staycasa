# check for same day checkins
library(jsonlite)
library(purrr)

sameday_checkins <- airbnb_emails2 |> 
 
  filter(checkin_date == taipei_date| checkin_date == taipei_date) 

# save the sameday_checkins as a json file

# Build JSON-ready list grouped by date

# Helper: convert "16:00" -> "4pm"
format_time <- function(x) {
  t <- strptime(x, "%H:%M")
  format(t, "%I%p") %>% tolower() %>% sub("^0", "", .)
}

# Build JSON-ready list grouped by date
final_list <- sameday_checkins %>%
  group_by(checkin_date) %>%
  group_map(~ {
    # Add checkin_date back to each row
    .x <- .x %>%
      mutate(
        checkin_time = sapply(checkin_time, format_time),
        guest_first_name = guest_first_name.x,
        checkin_date = .y$checkin_date
      ) %>%
      select(checkin_date, checkin_time, room_number, number_of_guests, guest_first_name)
    
    # Convert each row to a named list
    checkins <- lapply(seq_len(nrow(.x)), function(i) as.list(.x[i, ]))
    
    list(
      checkin_date = .y$checkin_date,
      sameday_checkins = nrow(.x) > 0,
      checkins = checkins
    )
  })

# Write to JSON file
write_json(final_list, "data/same_day_checkins.json", pretty = TRUE, auto_unbox = TRUE)