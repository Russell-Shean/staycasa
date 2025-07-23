import os
import json
from google.oauth2 import service_account
from googleapiclient.discovery import build


# Write secret to a file
with open("service_account.json", "w") as f:
    f.write(os.environ["GOOGLE_CREDENTIALS_JSON"])

# Load credentials
creds = service_account.Credentials.from_service_account_file(
                  "service_account.json",
                  scopes=[
                          "https://www.googleapis.com/auth/documents",
                          "https://www.googleapis.com/auth/drive"
                          ]
              )



# Authenticate
credentials = service_account.Credentials.from_service_account_info(
    credentials_info, scopes=SCOPES
)

# Build service clients
docs_service = build("docs", "v1", credentials=credentials)
drive_service = build("drive", "v3", credentials=credentials)

# Title and content of the doc
DOCUMENT_TITLE = "GitHub Actions Created Doc"
DOCUMENT_CONTENT = [
    {
        "insertText": {
            "location": {
                "index": 1,
            },
            "text": "Hello from GitHub Actions!\nThis document was created automatically.\n"
        }
    }
]

# Create the doc
doc = docs_service.documents().create(body={"title": DOCUMENT_TITLE}).execute()
document_id = doc["documentId"]

# Insert text
docs_service.documents().batchUpdate(
    documentId=document_id,
    body={"requests": DOCUMENT_CONTENT}
).execute()

print(f"Created document with ID: {document_id}")

# Move the file to a specific folder
FOLDER_ID = os.environ.get("GOOGLE_DRIVE_FOLDER_ID")
if FOLDER_ID:
    # First, get the current parents
    file = drive_service.files().get(fileId=document_id, fields="parents").execute()
    previous_parents = ",".join(file.get("parents", []))

    # Move file
    drive_service.files().update(
        fileId=document_id,
        addParents=FOLDER_ID,
        removeParents=previous_parents,
        fields="id, parents"
    ).execute()

    print(f"Moved document to folder: {FOLDER_ID}")