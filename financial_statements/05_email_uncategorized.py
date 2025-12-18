'''This file emails unsorted transactions to Simon so he can look at them'''

# pylint: disable=import-error, invalid-name, too-many-arguments, too-many-positional-arguments

import os
import base64
import mimetypes
from email.message import EmailMessage

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

from dotenv import load_dotenv

import pandas as pd

load_dotenv()

# Same scope you already use
SCOPES = ["https://www.googleapis.com/auth/gmail.modify"]

# Load credentials from environment (GitHub secrets)
CLIENT_ID = os.environ["GOOGLE_OAUTH_CLIENT_ID"]
CLIENT_SECRET = os.environ["GOOGLE_OAUTH_CLIENT_SECRET"]
REFRESH_TOKEN = os.environ["GOOGLE_OAUTH_REFRESH_TOKEN"]

# Build credentials
creds = Credentials(
    None,
    refresh_token=REFRESH_TOKEN,
    token_uri="https://oauth2.googleapis.com/token",
    client_id=CLIENT_ID,
    client_secret=CLIENT_SECRET,
    scopes=SCOPES,
)

creds.refresh(Request())

# Build Gmail service
my_service = build("gmail", "v1", credentials=creds)


def create_message_with_attachment(
    sender: str,
    to: str,
    subject: str,
    body_text: str,
    attachment_path: str | None = None,
):
    """Create a Gmail API message with optional attachment."""
    message = EmailMessage()
    message["From"] = sender
    message["To"] = to
    message["Subject"] = subject
    message.set_content(body_text)

    if attachment_path:
        content_type, encoding = mimetypes.guess_type(attachment_path)
        if content_type is None or encoding is not None:
            content_type = "application/octet-stream"

        main_type, sub_type = content_type.split("/", 1)

        with open(attachment_path, "rb") as f:
            message.add_attachment(
                f.read(),
                maintype=main_type,
                subtype=sub_type,
                filename=os.path.basename(attachment_path),
            )

    encoded_message = base64.urlsafe_b64encode(message.as_bytes()).decode("utf-8")

    return {"raw": encoded_message}


def send_email(
    service,
    sender: str,
    to: str,
    subject: str,
    body_text: str,
    attachment_path: str | None = None,
):
    '''This function sends the email by calling the function from above internally'''

    message = create_message_with_attachment(
        sender, to, subject, body_text, attachment_path
    )

    sent = (
        service.users()
        .messages()
        .send(userId="me", body=message)
        .execute()
    )

    return sent


UNSORTEDS_PATH="data/unsorted_bank_transactions.csv"

# Read in the unsorted dataframe and count the number of rows
unsorted_transactions = pd.read_csv(UNSORTEDS_PATH)
row_count = len(unsorted_transactions)

# Send the email if there are any uncategorized transactions
if row_count > 0:

    response = send_email(
        service=my_service,
        sender="me",  # "me" uses the authenticated Gmail account
        to="simon1122@gmail.com",
        subject="Unsorted Bank Transactions",
        body_text="Hi Simon,\nHere are the latest uncategorized transactions.",
        attachment_path=UNSORTEDS_PATH,  # any file, or None
    )

    print(f"Email sent. Message ID: {response['id']}")
