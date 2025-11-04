airbnb_payouts |> 
  filter(!is.na(room_number)) |> 
  group_by(room_number, month_year) |> 
  summarize(monthly_gross = sum(Gross.earnings, na.rm = TRUE),
            monthly_occupancy_tax = sum(Occupancy.taxes, na.rm = TRUE),
            monthly_service_fee = sum(Service.fee, na.rm = TRUE)) |>
  mutate(net_earnings = monthly_gross - monthly_occupancy_tax - monthly_service_fee) |>
   View()


# Add month year to bank

# Filter out dividend 

# Rent
# cleaning fee
# everything else expense

# filter out 4
網銀外存 218087121432 −

# filter out anything over 30000


# month years as columns

revenue (exclude 1600 and 515 )
row for each unit 

COGS (sum of rent + cleaning + utilities (water and electricty) + (internet and tv) )
seperate rows

expenses (everything else)
Gross margin as number = revenue - COGS
Gross margin % = (revenue - COGS) / revenue * 100

operating_expense = expense / revenue
net income = gross_margin - operating_expense


# new page
