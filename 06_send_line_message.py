'''This script sends Simon a line message with the cleaning schedule for the next month'''

# pylint: disable=import-error

import os
from datetime import date
import calendar

import requests

from dotenv import load_dotenv
load_dotenv()


# Load file names ---------------------------------------------------------


today = date.today()



# Current year and month
year = today.year
month = today.month


# Calculate the month after the next
if month == 12:
    NEXT_MONTH = 1
    next_year = year + 1

else:
    NEXT_MONTH = today.month + 1
    next_year = year

# First and last day of that month
next_month_first_day = date(next_year, NEXT_MONTH, 1)
next_month_last_day = date(next_year, NEXT_MONTH, calendar.monthrange(next_year, NEXT_MONTH)[1])

# Create the string
next_month_filename = f"data/daily_schedule_{next_month_first_day}_{next_month_last_day}.txt"
print(f'next month: {next_month_filename}')



# First and last day of the current month
this_month_first_day = date(year, month, 1)
this_month_last_day = date(year, month, calendar.monthrange(year, month)[1])

# Create the string
this_month_filename = f"data/daily_schedule_{this_month_first_day}_{this_month_last_day}.txt"
print(f'this month: {this_month_filename}')


# Load line creds ------------------------------------------------------------------


# Load token from environment variable (or replace with string)
LINE_CHANNEL_ACCESS_TOKEN = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")  # or set directly as a string

# print(LINE_CHANNEL_ACCESS_TOKEN)
GROUP_ID = "C4c2944e52265752b5b36ca467d6bbbd6"  # actual group
# GROUP_ID = "Ufa81a6bd5dd4ed3282949516cc3dc200" # Russ

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
                "text": message_text[0:5000]
            }
        ]
    }

    response = requests.post(url, headers=headers, json=body)
    print("Status code:", response.status_code)
    print("Response:", response.text)


# Load the schedule so we can send it
with open(this_month_filename, 'r', encoding='utf-8') as file:
    this_month_schedule = file.read()


with open(next_month_filename, 'r', encoding='utf-8') as file:
    next_month_schedule = file.read()





# send messages
this_month_message = "Here's the monthly schedule for this month!\n" + this_month_schedule

next_month_message = "Here's the monthly schedule for next month!\n" + next_month_schedule

#send_line_message(GROUP_ID, "Here's the monthly schedule for this month!")
send_line_message(GROUP_ID, this_month_message)




#send_line_message(GROUP_ID, "Here's the monthly schedule for next month!")
send_line_message(GROUP_ID, next_month_message)


# load the links

links_message = ""
with open("data/drive_links.txt", "r", encoding="utf-8") as f:
    links_message += f.read()

send_line_message(GROUP_ID,links_message)
