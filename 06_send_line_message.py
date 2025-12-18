'''This script sends Simon a line message with the cleaning schedule for the next month'''

# pylint: disable=import-error, invalid-name, line-too-long

import os

from dotenv import load_dotenv

from utils import send_line_message, build_date_matrix

load_dotenv()


# Load date matrix---------------------------------------------------------
date_matrix = build_date_matrix()

# Create the string
NEXT_MONTH_FILENAME = f'data/daily_schedule_{date_matrix["next_month_first_date"]}_{date_matrix["next_month_last_date"]}.txt'


# Create the string
THIS_MONTH_FILENAME = f'data/daily_schedule_{date_matrix["this_month_first_day"]}_{date_matrix["this_month_last_day"]}.txt'


# Load line creds ------------------------------------------------------------------


# Load token from environment variable (or replace with string)
LINE_CHANNEL_ACCESS_TOKEN = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")  # or set directly as a string

# print(LINE_CHANNEL_ACCESS_TOKEN)
GROUP_ID = "C4c2944e52265752b5b36ca467d6bbbd6"  # actual group
# GROUP_ID = "Ufa81a6bd5dd4ed3282949516cc3dc200" # Russ

# Load the schedule so we can send it
with open(THIS_MONTH_FILENAME, 'r', encoding='utf-8') as file:
    this_month_schedule = file.read()


with open(NEXT_MONTH_FILENAME, 'r', encoding='utf-8') as file:
    next_month_schedule = file.read()





# send messages
this_month_message = "Here's the monthly schedule for this month!\n" + this_month_schedule

next_month_message = "Here's the monthly schedule for next month!\n" + next_month_schedule

#send_line_message(GROUP_ID, "Here's the monthly schedule for this month!")
send_line_message(GROUP_ID, this_month_message, LINE_CHANNEL_ACCESS_TOKEN)




#send_line_message(GROUP_ID, "Here's the monthly schedule for next month!")
send_line_message(GROUP_ID, next_month_message, LINE_CHANNEL_ACCESS_TOKEN)


# load the links

links_message = ""
with open("data/drive_links.txt", "r", encoding="utf-8") as f:
    links_message += f.read()

send_line_message(GROUP_ID, links_message, LINE_CHANNEL_ACCESS_TOKEN)
