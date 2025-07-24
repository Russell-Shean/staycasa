import os
import json
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

import json
from dotenv import load_dotenv


FOLDER_ID = os.environ.get("GOOGLE_DRIVE_FOLDER_ID")

load_dotenv()

json_str = os.environ["GOOGLE_CREDENTIALS_JSON2"]
#credentials = json.loads(json_str)


# Write secret to a file
with open("service_account.json", "w") as f:
    f.write(json_str)

# Load credentials
creds = service_account.Credentials.from_service_account_file(
                  "service_account.json",
                  scopes=[
                          "https://www.googleapis.com/auth/documents",
                          "https://www.googleapis.com/auth/drive"
                          ]
              )


# Authenticate

# Build service clients
docs_service = build("docs", "v1", credentials=creds)
drive_service = build("drive", "v3", credentials=creds)



file_metadata = {"name": "download.jpeg"}

media = MediaFileUpload("download.jpeg", mimetype="image/jpeg")
    # pylint: disable=maybe-no-member

file = (drive_service.files().create(body=file_metadata, media_body=media, fields="id").execute())

print(f'File ID: {file.get("id")}')










# Sanity test: Can the service account create a Drive file?
files = drive_service.files().list(
    q="mimeType='application/vnd.google-apps.document'",
    fields="files(id, name)",
    supportsAllDrives=True,
    includeItemsFromAllDrives=True
).execute()


files = drive_service.files().list(
    supportsAllDrives=True,
    includeItemsFromAllDrives=True,
    fields="files(id, name, mimeType)"
).execute()

for f in files.get("files", []):
    print(f"{f['name']} ({f['mimeType']})")


print(files)

for f in files["files"]:
    print("Deleting:", f["name"])
    #drive_service.files().delete(fileId=f["id"]).execute()





#file_metadata = {
 #   "name": "Test File",
  #  "mimeType": "application/vnd.google-apps.document",
   # "parents": [FOLDER_ID]  # create directly in the shared folder
#}

#file = drive_service.files().create(
#    body=file_metadata,
 #   fields="id").execute()


#print("File created in shared folder:", file["id"])




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
