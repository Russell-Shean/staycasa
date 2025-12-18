'''This file uploads the processed financial transactions back to google drive'''

# pylint: disable=import-error, invalid-name

import os
from datetime import date
from datetime import datetime
import calendar


from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

from utils import upload_file_to_drive, build_drive_service



# Load file names ---------------------------------------------------------


today = date.today()

# Get current date
now = datetime.now()

# Format as "Month Year"
current_month_year = now.strftime("%B %Y")



# Current year and month
year = today.year
month = today.month
next_month = today.month + 1

# Calculate the month after the next
if month == 12:
    next_month = 1
    next_year = year + 1

else:
    next_month = today.month + 1
    next_year = year

# First and last day of that month
next_month_first_day = date(next_year, next_month, 1)
next_month_last_day = date(next_year, next_month, calendar.monthrange(next_year, next_month)[1])




# First and last day of the current month
this_month_first_day = date(year, month, 1)
this_month_last_day = date(year, month, calendar.monthrange(year, month)[1])


# links to drive files
# Step 1: Create/overwrite the file to make it blank
with open("data/financial_drive_links.txt", "w", encoding="utf-8") as drive_links_file:
    pass


# Build a drive service  -----------------------------------------------------------------------

my_drive_service = build_drive_service("drive")


# upload files
# ---------------------------------------

upload_file_to_drive("data/financial_report_format1.csv",
                      f'Financial Report Format 1 - {current_month_year}',
'spreadsheet',
my_drive_service)

upload_file_to_drive("data/financial_report_format2.csv",
                      f'Financial Report Format 2 - {current_month_year}',
'spreadsheet',
my_drive_service)

upload_file_to_drive("data/unsorted_bank_transactions.csv",
                      f'Unsorted Bank Transactions - {current_month_year}',
'spreadsheet',
my_drive_service)

upload_file_to_drive("data/all_transactions.csv",
                      f'All Transactions - {current_month_year}',
'spreadsheet',
my_drive_service)
