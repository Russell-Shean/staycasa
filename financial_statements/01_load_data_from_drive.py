'''This file downloads financial data from our google drive account'''

# pylint: disable=import-error, line-too-long, invalid-name

import os
import sys
from pathlib import Path
import io

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build


from googleapiclient.http import MediaIoBaseDownload

sys.path.append(str(Path(__file__).resolve().parent.parent))

from utils import build_google_service


# Build a drive service  -----------------------------------------------------------------------
my_drive_service = build_google_service("drive")

def download_from_drive(drive_service, local_download_path):
    '''This function downloads a file from google drive'''

    # See if the file already exists and delete it
    # If it does
    query = "name='Airbnb Financial ' and mimeType='application/vnd.google-apps.folder' and trashed=false"

    results = drive_service.files().list(
    q=query,
    fields="files(id, name)"
    ).execute()

    print(results)


    folders = results.get("files", [])
    if not folders:
        print("No folder named 'Airbnb Financial' found on Drive.")
        return

    root_folder_id = folders[0]["id"]

    # Create local download root folder
    os.makedirs(local_download_path, exist_ok=True)

    def download_folder(folder_id, local_path):
        """Recursively download all contents of a Drive folder."""
        os.makedirs(local_path, exist_ok=True)

        # List all items in this folder
        query = f"'{folder_id}' in parents and trashed=false"
        items = drive_service.files().list(
            q=query,
            fields="files(id, name, mimeType)"
        ).execute().get("files", [])

        for item in items:
            file_id = item["id"]
            name = item["name"]

            if item["mimeType"] == "application/vnd.google-apps.folder":
                # Recurse into subfolder
                download_folder(file_id, os.path.join(local_path, name))
            else:
                # Download file
                request = drive_service.files().get_media(fileId=file_id)
                local_file_path = os.path.join(local_path, name)
                fh = io.FileIO(local_file_path, "wb")
                downloader = MediaIoBaseDownload(fh, request)

                done = False
                while not done:
                    status, done = downloader.next_chunk()
                    if status:
                        print(f"Downloading {name}: {int(status.progress() * 100)}%")
                print(f"Downloaded: {local_file_path}")

    # Start recursive download from the root folder
    download_folder(root_folder_id, local_download_path)



download_from_drive(drive_service=my_drive_service,
                    #root_folder_name="Airbnb Financial ",
                    local_download_path="data/financial")
