'''This script sets up the webhook I used to get the line group id'''

import json
from flask import Flask, request


app = Flask(__name__)

@app.route("/webhook", methods=["POST"])
def webhook():
    body = request.get_json()
    print("📥 Received event:")
    print(json.dumps(body, indent=2))

    # Extract and log userId or groupId
    for event in body.get("events", []):
        source = event.get("source", {})
        user_id = source.get("userId")
        group_id = source.get("groupId")
        source_type = source.get("type")

        if source_type == "user" and user_id:
            print(f"👤 User ID: {user_id}")
        elif source_type == "group" and group_id:
            print(f"👥 Group ID: {group_id}")
        else:
            print("⚠️ Unknown source:", source)

    return "OK"


if __name__ == "__main__":
    app.run(port=5000)
