'''This script sends Simon a line message with the cleaning schedule for the next month'''

# pylint: disable=import-error, invalid-name, line-too-long

import os

from dotenv import load_dotenv

from utils import send_line_message

load_dotenv()


# Load line creds ------------------------------------------------------------------


# Load token from environment variable (or replace with string)
LINE_CHANNEL_ACCESS_TOKEN = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")

# print(LINE_CHANNEL_ACCESS_TOKEN)
GROUP_ID = "C4c2944e52265752b5b36ca467d6bbbd6"  # actual group
# GROUP_ID = "Ufa81a6bd5dd4ed3282949516cc3dc200" # Russ

# Load the schedule so we can send it
with open("data/daily_schedule_next_20.txt", 'r', encoding='utf-8') as file:
    next_20_schedule = file.read()


# send messages
next_20_message = "Here's the monthly schedule for the next 20 days!\n" + next_20_schedule

#send_line_message(GROUP_ID, "Here's the monthly schedule for this month!")
send_line_message(GROUP_ID, next_20_message, LINE_CHANNEL_ACCESS_TOKEN)


# load the links
links_message = ""
with open("data/drive_links.txt", "r", encoding="utf-8") as f:
    links_message += f.read()

send_line_message(GROUP_ID, links_message, LINE_CHANNEL_ACCESS_TOKEN)
