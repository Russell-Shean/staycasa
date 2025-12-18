'''This script uploads the cleaning schedules and cleaning invoices to google drive'''

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

# create a function to upload the file
def upload_file_to_drive(local_filename, drive_filename):
    '''This function uploads a text file as a google doc'''

    # See if the file already exists and delete it
    # If it does
    query = f"name='{drive_filename}'"

    current_files = drive_service.files().list(
    q=query,
    supportsAllDrives=True,
    includeItemsFromAllDrives=True,
    fields="files(id, name)"
    ).execute()


    for old_file in current_files.get("files", []):
        print(f"Deleting old file: {old_file['name']} ({old_file['id']})")
        drive_service.files().delete(fileId=file["id"]).execute()




    # Prepare file metadata for Google Doc conversion
    file_metadata = {

    "name": drive_filename,  # Desired name of Google Doc
    "mimeType": "application/vnd.google-apps.document"  # ⚠️ This tells Drive to convert it
    }

    # Upload the text file (must be plain text or compatible with conversion)
    media = MediaFileUpload(local_filename, mimetype="text/plain", resumable=True)

    # Upload and convert to Google Doc
    file = drive_service.files().create(
    body=file_metadata,
    media_body=media,
    fields="id, name, mimeType, webViewLink"

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

    print("✅ Uploaded as Google Doc:")
    print("📝 Name:", file["name"])
    print("📄 File ID:", file["id"])
    print("🔗 View it here:", file["webViewLink"])



    with open("data/drive_links.txt", "a", encoding="utf-8") as file:
      file.write(f"{drive_filename}: {file['webViewLink']}\n")




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




upload_file_to_drive(THIS_MONTH_FILENAME,
"Automatically Generated Daily Schedule - This Month")

upload_file_to_drive(NEXT_MONTH_FILENAME,
"Automatically Generated Daily Schedule - Next Month")

upload_excel_to_drive("data/this_months_payment_schedule.xlsx",
f'Automatically Generated Cleaning Schedule and Invoice - {current_month_year}')
