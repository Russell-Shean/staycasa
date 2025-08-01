library(openxlsx)
library(dplyr)

# create payment schedule for cleanings
cleaning_payment_schedule <- airbnb_emails2 |>
                    mutate(cleaning_payment = 1000
                           ) |>
                    tidyr::pivot_wider(names_from = room_number,
                                       values_from = cleaning_payment) |>

                    select(checkout_date,
                          # guest_first_name.x,
                           #confirmation_number,
                           `814`,
                           `1713`,
                           `716`,
                           `1615`,
                           `513`,
                           `515`,
                           `1600`) |>
  group_by(checkout_date) |>
  summarise(across(everything(), ~sum(.x, na.rm = TRUE)), .groups = "drop") |>
  mutate(checkout_date = as.Date(checkout_date))



  
  # calculate the total payment for all the rooms 
cleaning_payment_schedule <- cleaning_payment_schedule|>
  mutate(cleaning_daily_total = rowSums(select(cleaning_payment_schedule,
                                               -checkout_date)))





keydrop_payment_schedule <- airbnb_emails2 |>
  mutate(keydrop_payment = 100) |>
  tidyr::pivot_wider(
    names_from = room_number,
    values_from = keydrop_payment
  ) |>
  left_join(
    keydrops |> select(confirmation_number, date.x),
    by = "confirmation_number"
  ) |>
  mutate(
    keydrop_date = if_else(
      !is.na(date.x),
      date.x,
      as.Date(checkout_date)
    )
  ) |>
  
  select(keydrop_date,
         # guest_first_name.x,
         #confirmation_number,
         `814`,
         `1713`,
         `716`,
         `1615`,
         `513`,
         `515`,
         `1600`) |>
  group_by(keydrop_date) |>
  summarise(across(everything(), ~sum(.x, na.rm = TRUE)), .groups = "drop")


  




# list the keydrops for the day
keydrop_room_numbers <- apply(keydrop_payment_schedule[,-1], 1, function(x) {
  paste(names(x)[x != 0], collapse = ", ")
})

keydrops_per_day <- data.frame(
  keydrop_date = keydrop_payment_schedule$keydrop_date,
  keycard_drop_rooms = paste0("Keydrops today: ",keydrop_room_numbers),
  stringsAsFactors = FALSE
)


# calculate the total payment for all the rooms 


keydrop_payment_schedule <- keydrop_payment_schedule |>
  mutate(keycards_daily_total = rowSums(select(keydrop_payment_schedule, 
                                               -keydrop_date))) 


keydrop_payment_schedule <- keydrop_payment_schedule |> 
                            left_join(keydrops_per_day) |>
                            select(keydrop_date, 
                                   keycards_daily_total,
                                   keycard_drop_rooms)




# merge the keycards data onto the cleaning schedule
overall_payments <- cleaning_payment_schedule |> 
                    full_join(keydrop_payment_schedule, 
                              by = join_by("checkout_date" == "keydrop_date"))



this_months_payments <- data.frame(date = as.Date(this_month)) |>
                        left_join(overall_payments,
                                  by = join_by( "date" == "checkout_date")) |>
                        mutate(across(`716`:keycards_daily_total, ~tidyr::replace_na(., 0))) |>
                        
                        # remove the daily totals column
                        select(-cleaning_daily_total) 



#last_months_payments <- data.frame(date = seq.Date(from = as.Date("2025-07-01"),
 #                                                  to = as.Date("2025-07-31"),
  #                                                 by = "days")) |>
  #left_join(overall_payments,
   #         by = join_by( "date" == "checkout_date")) |>
  #mutate(across(`716`:keycards_daily_total, ~tidyr::replace_na(., 0))) |>
  
  # remove the daily totals column
  #select(-cleaning_daily_total) 




create_invoice_spreadsheet <- function(df, filename){

# Create workbook
wb <- createWorkbook()
addWorksheet(wb, "Sheet1")


# default font style

# Create a base Arial style
default_style <- createStyle(fontName = "Arial",
)

# Apply Arial font to the entire table (header + data)
addStyle(
  wb,
  sheet = "Sheet1",
  style = default_style,
  rows = 1:(nrow(df) + 1),   # header row + data rows
  cols = 1:ncol(df),
  gridExpand = TRUE
)

# Write dataframe starting at row 1, col 1
writeData(wb, "Sheet1", df, startRow = 1, startCol = 1)

# Determine where the total row should go
total_row <- nrow(df) + 2  # leave one blank row after the table

# Write "total" in first cell of total row
writeData(wb, "Sheet1", "Total", startRow = total_row, startCol = 1)

# Merge the next 5 cells (columns B–E in this case)
mergeCells(wb, "Sheet1", cols = 2:6, rows = total_row)

# Merge the next two cells for Tina's properties
mergeCells(wb, "Sheet1", cols = 7:8, rows = total_row)

# Add formulas in the merged cells
writeFormula(
  wb, "Sheet1", 
  x = sprintf("SUM(B2:F%d)", nrow(df) + 1), 
  startCol = 2, startRow = total_row
)


# Add formulas in the merged cells
writeFormula(
  wb, "Sheet1", 
  x = sprintf("SUM(G2:H%d)", nrow(df) + 1), 
  startCol = 7, startRow = total_row
)

# calculate the keycard totals
writeFormula(
  wb, "Sheet1", 
  x = sprintf("SUM(I2:I%d)", nrow(df) + 1), 
  startCol = 9, startRow = total_row
)


# Style the totals row
totals_row_style <- createStyle(
  fontColour = "#FF0000",      
  fontSize = 14,               # bigger font size
  halign = "center",           # horizontal align center
  valign = "center",           # vertical align center
  border = "TopBottomLeftRight",
  borderColour = "black"
)

addStyle(
  wb, "Sheet1",
  style = totals_row_style,
  rows = total_row,
  cols = 1:9,
  gridExpand = TRUE
)

# style the header row
header_style <- createStyle(
  fontName = "Arial",
  fontColour = "black",      # black text for contrast
  fgFill = "#FFFF00",        # bright yellow background
  textDecoration = "bold",   # bold font
  halign = "center",
  valign = "center"
)


addStyle(
  wb,
  sheet = "Sheet1",
  style = header_style,
  rows = 1,
  cols = 1:ncol(df),
  gridExpand = TRUE
)





# manually adjust a few column widths

setColWidths(wb, "Sheet1", cols = 9, widths = 22)
setColWidths(wb, "Sheet1", cols = 10, widths = 24)

# Save workbook
saveWorkbook(wb, filename, overwrite = TRUE)

}


create_invoice_spreadsheet(this_months_payments, 
                           "data/this_months_payment_schedule.xlsx")



#create_invoice_spreadsheet(last_months_payments, 
   #                        "Cleaning Schedule and Invoice - July 2025.xlsx")
