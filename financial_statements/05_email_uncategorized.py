'''This file emails unsorted transactions to Simon so he can look at them'''

# pylint: disable=import-error, invalid-name, too-many-arguments, too-many-positional-arguments
# pylint: disable=wrong-import-position
import os

import sys
from pathlib import Path

import base64
import mimetypes
from email.message import EmailMessage

import pandas as pd

sys.path.append(str(Path(__file__).resolve().parent.parent))

from utils import build_google_service

my_service = build_google_service("gmail")


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


ATTACHMENTS = ["data/unsorted_bank_transactions.csv", "data/transactions_by_category.xlsx"]

# Read in the unsorted dataframe and count the number of rows
unsorted_transactions = pd.read_csv(ATTACHMENTS)
row_count = len(unsorted_transactions)

# Send the email if there are any uncategorized transactions
if row_count > 0:

    response = send_email(
        service=my_service,
        sender="me",  # "me" uses the authenticated Gmail account
        to="simon1122@gmail.com",
        subject="Unsorted Bank Transactions",
        body_text="Hi Simon,\nHere's the latest version of the financial report and the unsorted transactions.",
        attachment_path=ATTACHMENTS,  # any file, or None
    )

    print(f"Email sent. Message ID: {response['id']}")
