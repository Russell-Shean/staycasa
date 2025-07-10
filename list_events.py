from gcsa.google_calendar import GoogleCalendar

calendar = GoogleCalendar('stayvacasa@gmail.com', credentials_path='.credentials/client_secret_2_949319258142-bgqtf88a7k7m03kb1tvtrdhe0ukph07j.apps.googleusercontent.com.json')
for event in calendar:
    print(event)