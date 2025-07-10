import os
import json
import datetime
from google.oauth2 import service_account
from googleapiclient.discovery import build


# Write secret to a file
with open("service_account.json", "w") as f:
    f.write(os.environ["GOOGLE_CREDENTIALS_JSON"])

# Load credentials
creds = service_account.Credentials.from_service_account_file(
                  "service_account.json",
                  scopes=["https://www.googleapis.com/auth/calendar.readonly"]
              )

service = build("calendar", "v3", credentials=creds)
now = datetime.datetime.utcnow().isoformat() + "Z"

events_result = service.events().list(
              calendarId="primary", timeMin=now,
              maxResults=10, singleEvents=True,
              orderBy="startTime"
            ).execute()

events = events_result.get("items", [])
    if not events:
        print("No upcoming events found.")

for event in events:
    start = event["start"].get("dateTime", event["start"].get("date"))
    print(start, event["summary"])
