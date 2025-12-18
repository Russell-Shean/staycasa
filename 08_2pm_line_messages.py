'''This script sends a line message alerting Simon to same day checkins if present'''

# pylint: disable=import-error

import os
from datetime import date
import json

import requests

from dotenv import load_dotenv

from utils import send_line_message

load_dotenv()

# Get today's date
today = date.today()



sameday_checkins = [{"checkin_date":"2025-08-27",
                     "sameday_checkins":True,
                     "checkins":[

                       {"checkin_date":"2025-08-27",
                     "checkin_time":"4pm",
                     "room_number":513,
                     "number_of_guests":2,
                     "guest_first_name":"Russ"},

                     {"checkin_date":"2025-08-27",
                     "checkin_time":"4pm",
                     "room_number":716,
                     "number_of_guests":4,
                     "guest_first_name":"John"}


                     ]},

                     {
                     "checkin_date":"2025-08-27",
                     "sameday_checkins":False,
                     "checkins":[]

                     }



                     ]

# Define path to same_day_checkins file
SAME_DAY_CHECKINS_PATH = "data/same_day_checkins.json"

# Load line creds ------------------------------------------------------------------


# Load token from environment variable (or replace with string)
LINE_CHANNEL_ACCESS_TOKEN = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")  # or set directly as a string

# cleaning group id
#group_id = "Cdfc4f0729f0b3f44c5b219b4928d3e24"
GROUP_ID = "C4c2944e52265752b5b36ca467d6bbbd6"  # actual group



# Load the same day checkins file so we can send it
with open(SAME_DAY_CHECKINS_PATH, "r", encoding="utf-8") as f:
    sameday_checkins = json.load(f)

# check to see if there are any same day checkins today
for days in sameday_checkins:

  # look for today's date
  if days["checkin_date"] == str(today):

    # Then check to see if there are same day checkin today
    if len(days["checkins"]) > 0:

      line_message = "TODAY THERE ARE SAME DAY CHECKINS\n"

      for todays_checkins in days["checkins"]:
        line_message += f'({todays_checkins["room_number"]})\n{todays_checkins["guest_first_name"]} ({todays_checkins["number_of_guests"]}) {todays_checkins["checkin_time"]}\n'



      # send a line message only if there's a checkin today
      send_line_message(GROUP_ID, line_message)
