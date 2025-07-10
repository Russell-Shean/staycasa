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
                  scopes=["https://www.googleapis.com/auth/calendar",
                          "https://www.googleapis.com/auth/calendar.calendarlist",
                          "https://www.googleapis.com/auth/calendar.calendarlist.readonly",
                          "https://www.googleapis.com/auth/calendar.readonly",
                          ]
              )

service = build("calendar", "v3", credentials=creds)
now = datetime.datetime.utcnow().isoformat() + "Z"


#############################3

service = build("calendar", "v3", credentials=creds)

# Call the Calendar API
now = datetime.datetime.now(tz=datetime.timezone.utc).isoformat()
print("Getting the upcoming 10 events")
events_result = (
        service.events()
        .list(
            calendarId="stayvacasa@gmail.com",
            timeMin=now,
            maxResults=10,
            singleEvents=True,
            orderBy="startTime",
        )
        .execute()
    )

events = events_result.get("items", [])

if not events:
    print("No upcoming events found.")

    # Prints the start and name of the next 10 events
for event in events:
    start = event["start"].get("dateTime", event["start"].get("date"))
    print(start, event["summary"])


#########------------------------------------------------------------------------------

# Build service
service = build("calendar", "v3", credentials=creds)


# ------------------------------------------------------

# List all calendars the service account has access to
calendar_list = service.calendarList().list().execute()

items = calendar_list.get("items", [])

print("Available calendars:")
for calendar in items:
    print(f"- {calendar.get('summary')} (ID: {calendar.get('id')})")

# --------------------------------------

events_result = service.events().list(
              calendarId="jd8mtvlnvnrion079ir6gbbq8vcntdca@import.calendar.google.com",
              maxResults=10, singleEvents=True,
              orderBy="startTime"
            ).execute()

events = events_result.get("items", [])

if not events:
    print("No upcoming events found.")

for event in events:
    start = event["start"].get("dateTime", event["start"].get("date"))
    print(start, event["summary"])
