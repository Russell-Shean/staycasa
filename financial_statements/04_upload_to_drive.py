'''This file uploads the processed financial transactions back to google drive'''

# pylint: disable=import-error, invalid-name, wrong-import-position

import sys
from pathlib import Path



sys.path.append(str(Path(__file__).resolve().parent.parent))

from utils import upload_file_to_drive, build_google_service, build_date_matrix


# Load date matrix---------------------------------------------------------
date_matrix = build_date_matrix()



# links to drive files
# Step 1: Create/overwrite the file to make it blank
with open("data/financial_drive_links.txt", "w", encoding="utf-8") as drive_links_file:
    pass


# Build a drive service  -----------------------------------------------------------------------

my_drive_service = build_google_service("drive")


# upload files
# ---------------------------------------

#upload_file_to_drive("data/financial_report_format1.csv",
 #                     f'Financial Report Format 1 - {date_matrix["current_month_year"]}',
#'spreadsheet',
#my_drive_service)

link1 = upload_file_to_drive("data/transactions_by_category.xlsx",
                      f'Financial Report - {date_matrix["current_month_year"]}',
'spreadsheet',
my_drive_service)

link2 = upload_file_to_drive("data/unsorted_bank_transactions.csv",
                      f'Unsorted Bank Transactions - {date_matrix["current_month_year"]}',
'spreadsheet',
my_drive_service)


# write links
with open("data/financial_drive_links.txt", "w", encoding="utf-8") as drive_links_file:
    drive_links_file.write("Financial Report: " + link1 + "\n")
    drive_links_file.write("Unsorted transactions: " + link2)