'''This script is how I got refresh tokens in the first place'''

# pylint: disable=import-error, line-too-long

from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = ['https://www.googleapis.com/auth/drive',
 'https://www.googleapis.com/auth/gmail.modify']

flow = InstalledAppFlow.from_client_secrets_file(
    '/home/russ/Downloads/client_secret_949319258142-r63ks0avjf218a6n13p558gn704h5k2v.apps.googleusercontent.com.json',
SCOPES)

creds = flow.run_local_server(port=0,
access_type="offline",
prompt="consent")  # This opens a browser for you to log in

print("Refresh token:", creds.refresh_token)
