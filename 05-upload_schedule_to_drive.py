from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

import os

from dotenv import load_dotenv

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
    scopes=["https://www.googleapis.com/auth/drive"],
)

# Refresh the access token
creds.refresh(Request())

drive_service = build("drive", "v3", credentials=creds)

# Prepare file metadata for Google Doc conversion
file_metadata = {
    "name": "Daily Schedule AUTOMATICALLY CREATED",  # Desired name of Google Doc
    "mimeType": "application/vnd.google-apps.document"  # ⚠️ This tells Drive to convert it
}

# Upload the text file (must be plain text or compatible with conversion)
media = MediaFileUpload("data/daily_schedule.txt", mimetype="text/plain", resumable=True)

# Upload and convert to Google Doc
file = drive_service.files().create(
    body=file_metadata,
    media_body=media,
    fields="id, name, mimeType, webViewLink"
).execute()




print("✅ Uploaded as Google Doc:")
print("📝 Name:", file["name"])
print("📄 File ID:", file["id"])
print("🔗 View it here:", file["webViewLink"])
