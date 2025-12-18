'''This file uploads the processed financial transactions back to google drive'''

# pylint: disable=import-error

import os
from datetime import date
from datetime import datetime
import calendar


from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload



from dotenv import load_dotenv

load_dotenv()

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
open("data/financial_drive_links.txt", "w", encoding="utf-8").close()


# load google creds -----------------------------------------------------------------------


# Load from environment variables
client_id = os.environ["GOOGLE_OAUTH_CLIENT_ID"]
client_secret = os.environ["GOOGLE_OAUTH_CLIENT_SECRET"]
refresh_token = os.environ["GOOGLE_OAUTH_REFRESH_TOKEN"]

creds = Credentials(
    token=None,
    refresh_token=refresh_token,
    token_uri="https://oauth2.googleapis.com/token",
    client_id=client_id,
    client_secret=client_secret,
    scopes=["https://www.googleapis.com/auth/drive"],
)

# Refresh the access token
creds.refresh(Request())

drive_service = build("drive", "v3", credentials=creds)



# Function for excel docs
def upload_excel_to_drive(local_filename,drive_filename):
    """
    Uploads an Excel (.xlsx) file to Google Drive and converts it to a Google Sheet.

    Args:
        local_filename (str): Path to the local Excel file to upload.
        drive_filename (str): Desired name of the file in Google Drive.
        folder_id (str, optional): If provided, the file will be placed in this folder.
    """

    # 1️⃣ Check if a file with the same name already exists and delete it
    # See if the file already exists and delete it
    # If it does
    query = f"name='{drive_filename}'"

    current_files = drive_service.files().list(
    q=query,
    supportsAllDrives=True,
    includeItemsFromAllDrives=True,
    fields="files(id, name)"
    ).execute()


    for f in current_files.get("files", []):
        print(f"Deleting old file: {f['name']} ({f['id']})")
        drive_service.files().delete(fileId=f["id"]).execute()


    # 2️⃣ Prepare metadata
    file_metadata = {
        "name": drive_filename,
        "mimeType": "application/vnd.google-apps.spreadsheet"


    }


    media = MediaFileUpload(
        local_filename,
        mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        resumable=True
    )


    # 3️⃣ Upload & convert to Google Sheet
    file = drive_service.files().create(
        body=file_metadata,
        media_body=media,
        fields="id, name, mimeType, webViewLink",
        supportsAllDrives=True
    ).execute()

    # give anyone with a link viewing permissions
    permission = {
            "type": "anyone",  # Anyone on the internet
            "role": "reader"   # Can also be "reader" or "commenter"
        }

    drive_service.permissions().create(
            fileId=file["id"],
            body=permission
        ).execute()

    print("🌍 Sharing enabled: Anyone with link can edit")

    print("✅ Uploaded as Google Sheet:")
    print("📝 Name:", file["name"])
    print("📄 File ID:", file["id"])
    print("🔗 View it here:", file["webViewLink"])





# upload files
# ---------------------------------------

upload_excel_to_drive("data/financial_report_format1.csv",
                      f'Financial Report Format 1 - {current_month_year}')
upload_excel_to_drive("data/financial_report_format2.csv",
                      f'Financial Report Format 2 - {current_month_year}')
upload_excel_to_drive("data/unsorted_bank_transactions.csv",
                      f'Unsorted Bank Transactions - {current_month_year}')
upload_excel_to_drive("data/all_transactions.csv",
                      f'All Transactions - {current_month_year}')