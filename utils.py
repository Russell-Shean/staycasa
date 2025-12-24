''' This script defines common python utility functions to be used across the project'''

# pylint: disable=import-error

import os

from datetime import date
from datetime import datetime

import calendar

import requests

from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request

from dotenv import load_dotenv


def build_google_service(service_type):
    '''This function builds a drive service for later use manipulating drive
     files and sending emails

    This loads secrets from .env or github secrets and then builds
    authentication and the service based on the provided scopes

    Possible types are gmail and drive (for now)
    '''

    my_scopes = []
    service_version = ""

    if service_type == "gmail":
        my_scopes = ["https://www.googleapis.com/auth/gmail.modify"]
        service_version = "v1"

    elif service_type == "drive":
        my_scopes = ["https://www.googleapis.com/auth/drive"]
        service_version = "v3"

    # Load secrets
    load_dotenv()

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
    scopes=my_scopes,
    )

    # Refresh the access token
    creds.refresh(Request())

    drive_service = build(service_type, service_version, credentials=creds)

    return drive_service



def upload_file_to_drive(local_filename, drive_filename, file_type, drive_service):
    """
    Uploads files to Google Drive and converts them to google file types.

    Args:
        local_filename (str): Path to the local Excel file to upload.
        drive_filename (str): Desired name of the file in Google Drive.
        file_type (str, optional): The type of google doc type to use.
        Options include: document, spreadsheet
    """

    if file_type not in ["document", "spreadsheet"]:
        raise ValueError("The file type must be 'document' or 'spreadsheet'")


    file_mime_type = ""



    if file_type == "spreadsheet":
        file_mime_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    elif file_type == "document":
        file_mime_type = "text/plain"



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
        "mimeType": f"application/vnd.google-apps.{file_type}"
    }


    media = MediaFileUpload(
        local_filename,
        mimetype=file_mime_type,
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

    print(f"✅ Uploaded as Google {file_type}:")
    print("📝 Name:", file["name"])
    print("📄 File ID:", file["id"])
    print("🔗 View it here:", file["webViewLink"])

    return file["webViewLink"]





def send_line_message(group_id, message_text, channel_access_token):
    ''' This function sends a line message to a line group'''

    url = "https://api.line.me/v2/bot/message/push"

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {channel_access_token}"
    }


    body = {
        "to": group_id,
        "messages": [
            {
                "type": "text",
                "text": message_text[0:5000]
            }
        ]
    }

    response = requests.post(url, headers=headers, json=body)
    print("Status code:", response.status_code)
    print("Response:", response.text)


def build_date_matrix():
    '''This function returns information about the current and next month.
       For use constructing file paths
    '''
    date_matrix = {}
    date_matrix["today"] = date.today()

    # Get current date
    date_matrix["now"] = datetime.now()

    # Format as "Month Year"
    date_matrix["current_month_year"] = date_matrix["now"].strftime("%B %Y")

    # Current year and month
    date_matrix["year"] = date_matrix["today"].year
    date_matrix["month"] = date_matrix["today"].month
    date_matrix["next_month"] = date_matrix["today"].month + 1

    # Calculate the month after the next
    if date_matrix["month"] == 12:
        date_matrix["next_month"] = 1
        date_matrix["next_year"] = date_matrix["year"] + 1

    else:
        date_matrix["next_month"] = date_matrix["today"].month + 1
        date_matrix["next_year"] = date_matrix["year"]

    # First and last day of that month
    date_matrix["next_month_first_day"] = date(date_matrix["next_year"],
                                               date_matrix["next_month"],
                                               1)

    date_matrix["next_month_last_day"] = date(date_matrix["next_year"],
                                              date_matrix["next_month"],
                                              calendar.monthrange(date_matrix["next_year"],
                                               date_matrix["next_month"])[1])

    # First and last day of the current month
    date_matrix["this_month_first_day"] = date(date_matrix["year"],
                                               date_matrix["month"], 1)

    date_matrix["this_month_last_day"] = date(date_matrix["year"],
                                               date_matrix["month"],
                                               calendar.monthrange(date_matrix["year"],
                                                date_matrix["month"])[1])


    return date_matrix
