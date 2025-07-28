from datetime import date
import calendar

today = date.today()



# Current year and month
year = today.year
month = today.month
next_month = today.month + 1

# Calculate the month after the next
if month > 12:
    next_month = month - 12
    next_year += 1

else:
    next_year = year

# First and last day of that month
next_month_first_day = date(next_year, next_month, 1)
next_month_last_day = date(next_year, next_month, calendar.monthrange(next_year, next_month)[1])

# Create the string
next_month_filename = f"daily_schedule_{next_month_first_day}_{next_month_last_day}"
print(f'next month: {next_month_filename}')



# First and last day of the current month
this_month_first_day = date(year, month, 1)
this_month_last_day = date(year, month, calendar.monthrange(year, month)[1])

# Create the string
this_month_filename = f"daily_schedule_{this_month_first_day}_{this_month_last_day}"
print(f'this month: {this_month_filename}')