import imaplib
import os
import email
import json
from email.header import decode_header
from datetime import datetime

# Your Gmail credentials
username = "stayvacasa@gmail.com"
app_password = os.environ["GOOGLE_APP_PASSWORD"]

# Connect to Gmail
mail = imaplib.IMAP4_SSL("imap.gmail.com")
mail.login(username, app_password)
mail.select("inbox")

# Search for all emails
status, messages = mail.search(None, "ALL")
email_ids = messages[0].split()

emails = []

# Helper function to decode text
def decode_mime_words(s):
    if not s:
        return ""
    decoded = decode_header(s)
    return ''.join(
        str(part.decode(enc if enc else "utf-8")) if isinstance(part, bytes) else part
        for part, enc in decoded
    )

# Helper function to extract body
def get_body(msg):
    if msg.is_multipart():
        for part in msg.walk():
            content_type = part.get_content_type()
            content_dispo = str(part.get("Content-Disposition"))
            if "attachment" in content_dispo:
                continue
            if content_type == "text/plain":
                return part.get_payload(decode=True).decode(errors="ignore")
        # fallback to html if no plain text found
        for part in msg.walk():
            if part.get_content_type() == "text/html":
                return part.get_payload(decode=True).decode(errors="ignore")
    else:
        return msg.get_payload(decode=True).decode(errors="ignore")

# Loop through all emails

# Add index for status tracking
i = 0

for email_id in email_ids:
    i += 1
    if i % 100 == 0:
        print(f"Processing email number {i}") 
    status, msg_data = mail.fetch(email_id, "(RFC822)")
    raw_email = msg_data[0][1]
    msg = email.message_from_bytes(raw_email)

    from_ = decode_mime_words(msg.get("From"))
    subject = decode_mime_words(msg.get("Subject"))
    date_str = msg.get("Date")

    try:
        date_obj = email.utils.parsedate_to_datetime(date_str)
        date = date_obj.strftime("%Y-%m-%d")
        time = date_obj.strftime("%H:%M:%S")
    except:
        date = ""
        time = ""

    body = get_body(msg)

    emails.append({
        "from": from_,
        "date": date,
        "time": time,
         #"email_id": email_id,
        "subject": subject,
        "body": body,
    })


# Write out the emails dictionary as a json file 
with open('data/emails.json', 'w') as fp:
    json.dump(emails, fp)


# Logout
#mail.logout()

# Print the result (optional)
#for e in emails:
#    print("\n--- Email ---")
#    for k, v in e.items():
#        print(f"{k}: {v[:100]}{'...' if len(v) > 100 else ''}")

# Result is in the `emails` list
