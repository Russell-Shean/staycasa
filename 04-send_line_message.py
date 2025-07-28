import requests
import os

from dotenv import load_dotenv
load_dotenv()


# Load token from environment variable (or replace with string)
LINE_CHANNEL_ACCESS_TOKEN = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")  # or set directly as a string

print(LINE_CHANNEL_ACCESS_TOKEN)
# GROUP_ID = "C4c2944e52265752b5b36ca467d6bbbd6"  # actual group
GROUP_ID = "Ufa81a6bd5dd4ed3282949516cc3dc200" # Russ

def send_line_message(group_id, message_text):
    url = "https://api.line.me/v2/bot/message/push"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {LINE_CHANNEL_ACCESS_TOKEN}"
    }
    body = {
        "to": group_id,
        "messages": [
            {
                "type": "text",
                "text": message_text
            }
        ]
    }

    response = requests.post(url, headers=headers, json=body)
    print("Status code:", response.status_code)
    print("Response:", response.text)


# Load the schedule so we can send it
with open('data/daily_schedule.txt', 'r', encoding='utf-8') as file:
    daily_schedule = file.read()

# Example usage
send_line_message(GROUP_ID, "Here's the monthly schedule for this month!")
send_line_message(GROUP_ID, daily_schedule)
