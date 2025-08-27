import requests
import os
from datetime import date
import calendar
import json

from dotenv import load_dotenv
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
same_day_checkins_path = "data/same_day_checkins.json"

# Load line creds ------------------------------------------------------------------


# Load token from environment variable (or replace with string)
LINE_CHANNEL_ACCESS_TOKEN = os.getenv("LINE_CHANNEL_ACCESS_TOKEN")  # or set directly as a string

# cleaning group id 
group_id = "Cdfc4f0729f0b3f44c5b219b4928d3e24"


# define a function to send a line message

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


# Load the same day checkins file so we can send it
with open(same_day_checkins_path, "r", encoding="utf-8") as f:
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

