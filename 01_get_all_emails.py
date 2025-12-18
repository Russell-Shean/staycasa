'''This script retrieves all emails from the stayvacasa gmail account'''

# pylint: disable=import-error, invalid-name

import os
import base64
import json
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build


from dotenv import load_dotenv

from utils import build_google_service


# Path to checkpoint file
CHECKPOINT_FILE = "data/last_message_id.txt"

# PAth to save out data
EMAILS_PATH = "data/emails_from_api.json"

my_service = build_google_service("gmail")


def get_message_body(msg_payload):
    """Extract plain text or HTML body."""
    parts = msg_payload.get("parts", [])
    if not parts:
        data = msg_payload.get("body", {}).get("data")
        return base64.urlsafe_b64decode(data).decode("utf-8", errors="ignore") if data else ""
    for part in parts:
        mime_type = part.get("mimeType")
        data = part.get("body", {}).get("data")
        if mime_type == "text/plain" and data:
            return base64.urlsafe_b64decode(data).decode("utf-8", errors="ignore")
    for part in parts:
        mime_type = part.get("mimeType")
        data = part.get("body", {}).get("data")
        if mime_type == "text/html" and data:
            return base64.urlsafe_b64decode(data).decode("utf-8", errors="ignore")
    return ""

# Load last processed message ID (if exists)
last_message_id = None
if os.path.exists(CHECKPOINT_FILE):
    with open(CHECKPOINT_FILE, "r", encoding="utf-8") as f:
        last_message_id = f.read().strip()

emails = []
all_new_ids = []
page_token = None
stop_fetching = False

# Page through Gmail messages
while True:

    print(f'Now on page: {page_token}')

    results = my_service.users().messages().list(
        userId="me",
        maxResults=500,
        pageToken=page_token,
    ).execute()

    messages = results.get("messages", [])
    if not messages:
        break

    for msg in messages:
        msg_id = msg["id"]

        # Stop when we reach the last processed ID
        if last_message_id and msg_id == last_message_id:
            stop_fetching = True
            break

        # Download message details
        message = my_service.users().messages().get(userId="me", id=msg_id, format="full").execute()
        payload = message.get("payload", {})
        headers = payload.get("headers", [])
        header_map = {h["name"]: h["value"] for h in headers}

        from_ = header_map.get("From", "")
        subject = header_map.get("Subject", "")
        date = header_map.get("Date", "")
        body = get_message_body(payload)

        emails.append({
            "id": msg_id,
            "from": from_,
            "subject": subject,
            "date": date,
            "body": body,
        })

        all_new_ids.append(msg_id)

    if stop_fetching:
        break

    page_token = results.get("nextPageToken")
    if not page_token:
        break

# Tell le gen how many new emails we fetched
print(f"Fetched {len(emails)} new emails")


# Save emails JSON
os.makedirs("data", exist_ok=True)

if os.path.exists(EMAILS_PATH):
    with open(EMAILS_PATH, "r", encoding="utf-8") as file:
        old_emails = json.load(file)
        emails.extend(old_emails)


with open(EMAILS_PATH, "w", encoding="utf-8") as f:
    json.dump(emails, f, indent=2)

# Save newest message ID as checkpoint
if all_new_ids:
    newest_id = all_new_ids[0]  # Gmail returns newest first
    with open(CHECKPOINT_FILE, "w", encoding="utf-8") as f:
        f.write(newest_id)

print(f"Fetched {len(emails)} total emails")
