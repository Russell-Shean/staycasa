# staycasa-automation
A collection of processes for automating Air Bnb procedures

## Summary
This script does the following things:    
1. Pulls checkin and checkout times from the Air Bnb calandar
2. Creates a cleaning schedule spreadsheet and stores it in google drive
3. Messages a line group with the cleaning schedule and cleaning reminders

## Notes
1. Air Bnb is annoying and doesn't provide free (or any) API access. Possible workarounds include:    
    a. Selenium: this would get all the available data, but it would run the risk of getting the account blocked by Air Bnb
    b. Use a channel manager software: This would give access to the functionality of the API. IT's not clear what underlying access the channel manager provide to the API and there software may be just as limited as Air BNB. None of the appear to be free either
    c. Sync calandars using ical. This is free and easy to do. The disadvantage is that it only provides limited data about the booking and doesn't allow us to automate other things like updating listings and prices. 

### Setting up ical
https://www.airbnb.com/help/article/99    

I manually set up the links between google calandar and each airbnb listing. Now that they're linked, the reservations should link automatically. The google calandar events only list dates and reservations numbers, but those can be linked to a csv file of transations that can be manually downloaded from Airbnb. 

## Google API
Most of the aumation will be implemented using the google API and python. Here are some links to documentation:

https://github.com/googleapis/google-api-python-client
https://developers.google.com/workspace/calendar/api/quickstart/python

Service principals access
https://cloud.google.com/iam/docs/granting-changing-revoking-access





### Steps

1. enable google calandar API service
     A. create a service principal
     B. Create a key for the service principal
     B. enable Cloud Resource Manager API. 
     C. Install Google cloud CLI https://cloud.google.com/sdk/docs/install 
     D. Authenticate to google cloud using gcloud init 
     E. Create a workpool (see this https://github.com/google-github-actions/auth)
2. Enable google drive API service
