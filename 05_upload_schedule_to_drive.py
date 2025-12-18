'''This script uploads the cleaning schedules and cleaning invoices to google drive'''

# pylint: disable=import-error, invalid-name

import os

from datetime import date
from datetime import datetime

import calendar

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build




from dotenv import load_dotenv

from utils import upload_file_to_drive, build_google_service


# Load file names ---------------------------------------------------------


today = date.today()

# Get current date
now = datetime.now()

# Format as "Month Year"
current_month_year = now.strftime("%B %Y")



# Current year and month
year = today.year
month = today.month


# Calculate the month after the next
if month == 12:
    NEXT_MONTH = 1
    next_year = year + 1

else:
    NEXT_MONTH = today.month + 1
    next_year = year

# First and last day of that month
NEXT_MONTH_FIRST_DAY = date(next_year, NEXT_MONTH, 1)
NEXT_MONTH_LAST_DAY = date(next_year, NEXT_MONTH, calendar.monthrange(next_year, NEXT_MONTH)[1])

# Create the string
NEXT_MONTH_FILENAME = f"data/daily_schedule_{NEXT_MONTH_FIRST_DAY}_{NEXT_MONTH_LAST_DAY}.txt"
print(f'next month: {NEXT_MONTH_FILENAME}')



# First and last day of the current month
this_month_first_day = date(year, month, 1)
this_month_last_day = date(year, month, calendar.monthrange(year, month)[1])

# Create the string
THIS_MONTH_FILENAME = f"data/daily_schedule_{this_month_first_day}_{this_month_last_day}.txt"
print(f'this month: {THIS_MONTH_FILENAME}')


# links to drive files
# Step 1: Create/overwrite the file to make it blank
with open("data/drive_links.txt", "w", encoding="utf-8") as file:
    pass


# load google creds -----------------------------------------------------------------------
my_drive_service = build_google_service("drive")


upload_file_to_drive(THIS_MONTH_FILENAME,
"Automatically Generated Daily Schedule - This Month",
'document',
my_drive_service)

upload_file_to_drive(NEXT_MONTH_FILENAME,
"Automatically Generated Daily Schedule - Next Month",
'document',
my_drive_service)

upload_file_to_drive("data/this_months_payment_schedule.xlsx",
f'Automatically Generated Cleaning Schedule and Invoice - {current_month_year}',
'spreadsheet',
my_drive_service)
