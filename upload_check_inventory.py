import csv
import argparse
from google.oauth2.service_account import Credentials
from googleapiclient.discovery import build
import smtplib
from email.message import EmailMessage
from slack_sdk import WebClient
from slack_sdk.errors import SlackApiError

# Function to fetch current data from the sheet
def fetch_current_sheet_data(service, spreadsheet_id, range_name):
    result = service.spreadsheets().values().get(
        spreadsheetId=spreadsheet_id, range=range_name).execute()
    return result.get('values', [])

def send_email_change_notification(changes):
    email_sender = 'your_email@example.com'
    email_password = 'your_password'
    email_receiver = 'receiver_email@example.com'

    subject = 'AWS Asset Inventory Alert'
    body = 'Changes detected in AWS Asset Inventory:\n\n' + changes

    em = EmailMessage()
    em['From'] = email_sender
    em['To'] = email_receiver
    em['Subject'] = subject
    em.set_content(body)

    with smtplib.SMTP_SSL('smtp.example.com', 465) as smtp:
        smtp.login(email_sender, email_password)
        smtp.send_message(em)

def send_slack_change_notification(changes, slack_token, channel_id):
    client = WebClient(token=slack_token)
    try:
        response = client.chat_postMessage(channel=channel_id, text=changes)
    except SlackApiError as e:
        print(f"Error sending message: {e.response['error']}")

def print_data_changes(current_data, new_data):
    changes = False
    change_details = "Asset Inventory Update Alert: "
    for current_row, new_row in zip(current_data, new_data):
        if current_row != new_row:
            changes = True
            identifier = current_row[0] if len(current_row) > 0 else "Unknown"
            for i, (current_cell, new_cell) in enumerate(zip(current_row, new_row)):
                if current_cell != new_cell:
                    change_message = f"Change in row with ID '{identifier}': Column {i+1} changed from '{current_cell}' to '{new_cell}'\n"
                    print(change_message)
                    change_details += change_message

    if changes:
        #send_email_change_notification(change_details)
        send_slack_change_notification(change_details, '[SLACK_TOKEN]', '[Channel-ID]')

    return changes

# Set up the credentials and API service
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = './credentials.json'
creds = Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPES)
service = build('sheets', 'v4', credentials=creds)

# Parse command-line arguments
parser = argparse.ArgumentParser(description='Upload CSV to Google Sheets')
parser.add_argument('spreadsheet_id', help='The ID of the spreadsheet')
parser.add_argument('csv_file', help='Path to the CSV file')
parser.add_argument('sheet_name', help='Name of the sheet')
parser.add_argument('sheet_id', type=int, help='ID of the sheet')
args = parser.parse_args()

# Read CSV file contents
with open(args.csv_file, 'r') as file:
    csv_content = csv.reader(file)
    new_data = list(csv_content)

# Fetch current data from the sheet
current_data = fetch_current_sheet_data(service, args.spreadsheet_id, args.sheet_name)

# Check for changes and print them
if print_data_changes(current_data, new_data):
    print("Changes detected in the data.")
else:
    print("No changes detected in the data.")

# Write data to sheet
body = {'values': new_data}
result = service.spreadsheets().values().update(
    spreadsheetId=args.spreadsheet_id, range=args.sheet_name,
    valueInputOption='USER_ENTERED', body=body).execute()

# Auto-resize columns
request_body = {
    "requests": [
        {
            "autoResizeDimensions": {
                "dimensions": {
                    "sheetId": args.sheet_id,
                    "dimension": "COLUMNS",
                    "startIndex": 0,
                    "endIndex": len(new_data[0])
                }
            }
        }
    ]
}

response = service.spreadsheets().batchUpdate(
    spreadsheetId=args.spreadsheet_id, body=request_body).execute()

print(f"{result.get('updatedCells')} cells updated.")

