'''This script uploads the cleaning schedules and cleaning invoices to google drive'''

# pylint: disable=import-error, invalid-name, line-too-long

from utils import upload_file_to_drive, build_google_service, build_date_matrix


# Load date matrix---------------------------------------------------------
date_matrix = build_date_matrix()

# Create the string
NEXT_MONTH_FILENAME = f'data/daily_schedule_{date_matrix["next_month_first_day"]}_{date_matrix["next_month_last_day"]}.txt'

# Create the string
THIS_MONTH_FILENAME = f'data/daily_schedule_{date_matrix["this_month_first_day"]}_{date_matrix["this_month_last_day"]}.txt'






# load google creds -----------------------------------------------------------------------
my_drive_service = build_google_service("drive")


this_month_link = upload_file_to_drive(local_filename = THIS_MONTH_FILENAME,
                                       drive_filename = "Automatically Generated Daily Schedule - This Month",
                                       file_type = 'document',
                                       drive_service = my_drive_service,
                                       folder_id = "1Xs4GpS31nAVnvrv2Ds-KeI63nu3_Z3UW" #"Cleaning Schedules and Invoices"
                                       )

next_month_link = upload_file_to_drive(local_filename = NEXT_MONTH_FILENAME,
                                       drive_filename = "Automatically Generated Daily Schedule - Next Month",
                                       file_type = 'document',
                                       drive_service = my_drive_service,
                                       folder_id = "1Xs4GpS31nAVnvrv2Ds-KeI63nu3_Z3UW" #"Cleaning Schedules and Invoices"
                                       )

invoice_link = upload_file_to_drive(local_filename = "data/this_months_payment_schedule.xlsx",
                                    drive_filename = f'Automatically Generated Cleaning Schedule and Invoice - {date_matrix["current_month_year"]}',
                                    file_type = 'spreadsheet',
                                    drive_service = my_drive_service,
                                    folder_id = "1Xs4GpS31nAVnvrv2Ds-KeI63nu3_Z3UW" #"Cleaning Schedules and Invoices"
                                    )

# links to drive files
# Step 1: Create/overwrite the file to make it blank
with open("data/drive_links.txt", "w", encoding="utf-8") as file:
    file.write(f"This Month's cleaning schedule: {this_month_link}\n")
    file.write(f"This Month's cleaning schedule: {next_month_link}\n")
    file.write(f"Invoice link: {invoice_link}")
