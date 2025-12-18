''' This script defines common python utility functions to be used across the project'''

import requests

from googleapiclient.http import MediaFileUpload


def upload_file_to_drive(local_filename, drive_filename, file_type, drive_service):
    """
    Uploads files to Google Drive and converts them to google file types.

    Args:
        local_filename (str): Path to the local Excel file to upload.
        drive_filename (str): Desired name of the file in Google Drive.
        file_type (str, optional): The type of google doc type to use. Options include: document, spreadsheet
    """

    if file_type not in ["document", "spreadsheet"]:
        raise ValueError("The file type must be 'document' or 'spreadsheet'")



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





def send_line_message(group_id, message_text):
    ''' This function sends a line message to a line group'''

    url = "https://api.line.me/v2/bot/message/push"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {LINE_CHANNEL_ACCESS_TOKEN}"
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