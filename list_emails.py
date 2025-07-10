import os.path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from google.oauth2 import service_account


from googleapiclient.errors import HttpError





# Write secret to a file
with open("service_account.json", "w") as f:
    f.write(os.environ["GOOGLE_CREDENTIALS_JSON"])

# Load credentials
creds = service_account.Credentials.from_service_account_file(
                  "service_account.json",
                  scopes=["https://www.googleapis.com/auth/gmail.readonly"]
              )

service = build("gmail", "v1", credentials=creds)
results = service.users().labels().list(userId="stayvacasa@gmail.com").execute()
labels = results.get("labels", [])

if not labels:
    print("No labels found.")

print("Labels:")
for label in labels:
    print(label["name"])


