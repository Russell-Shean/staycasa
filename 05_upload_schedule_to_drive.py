'''This script uploads the cleaning schedules and cleaning invoices to google drive'''

# pylint: disable=import-error, invalid-name, line-too-long

from utils import upload_file_to_drive, build_google_service, build_date_matrix


# Load date matrix---------------------------------------------------------
date_matrix = build_date_matrix()

# Create the string
NEXT_MONTH_FILENAME = f'data/daily_schedule_{date_matrix["next_month_first_date"]}_{date_matrix["next_month_last_date"]}.txt'

# Create the string
THIS_MONTH_FILENAME = f'data/daily_schedule_{date_matrix["this_month_first_day"]}_{date_matrix["this_month_last_day"]}.txt'



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
f'Automatically Generated Cleaning Schedule and Invoice - {date_matrix["current_month_year"]}',
'spreadsheet',
my_drive_service)
