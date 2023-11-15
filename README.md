# AWSInventorySync

## Introduction

AWSInventorySync is a pragmatic and efficient tool designed for security professionals and IT managers. Its core function is to streamline the management and monitoring of AWS assets periodically and reporting the changes in assets (like new added S3 bucket, new opened EC2 ports, new added IAM permissions) over communication channels. 

The tool focuses on key AWS resources: EC2 instances, Keypairs, IAM users, and S3 buckets. It automates the data extraction process from AWS, uploads this data to Google Sheets for easy access and analysis, and provides timely alerts on changes via Slack and email.

## Why AWSInventorySync?

In the rapidly evolving cloud environment, keeping track of assets is not just a matter of organization, but a critical component of security and compliance. AWSInventorySync addresses several key needs:

- **Asset Visibility**: Provides a clear and updated view of AWS resources, crucial for managing large and complex cloud environments.
- **Change Management**: Quickly identifies and communicates changes, helping to spot unauthorized modifications or compliance issues.
- **Time Efficiency**: Automates routine tasks, freeing up valuable time for your team to focus on more strategic initiatives.
- **Risk Mitigation**: Prompt alerts on changes enable faster response to potential security threats.

## How AWSInventorySync Works

### Data Extraction

- **AWS Connection**: The tool connects to your AWS account and gathers detailed information about specified AWS services.
- **Data Structuring**: It organizes this data into CSV files, one for each service (EC2, IAM, S3, Keypairs), making it easy to understand and analyze.

### Data Upload and Monitoring

- **Google Sheets Integration**: The extracted data is uploaded to a Google Spreadsheet using the Google Sheets API. This step provides a centralized and accessible platform for viewing AWS asset information.
- **Change Detection**: AWSInventorySync compares the latest data with the previously stored data in the spreadsheet. This comparison is crucial for identifying any new, removed, or altered assets.

<img width="1186" alt="example asset inventory" src="https://github.com/foreseon/AWSInventorySync/assets/25774631/f23274a4-6d22-4620-bf12-cf9b60964316">

### Alerts and Notifications

- **Slack Integration**: If the tool detects any changes, it sends an alert to a designated Slack channel. This feature ensures that your team is immediately aware of any modifications.
- **Email Notifications**: In addition to Slack, the tool can also send email notifications about detected changes, providing an additional layer of alerting.

<img width="824" alt="example slack alert" src="https://github.com/foreseon/AWSInventorySync/assets/25774631/085f8e4c-a3bf-46d9-9443-6c9c25fb0815">

# Installation and Configuration Guide

## Prerequisites

- Access to an AWS account with necessary permissions.
- A Google Cloud account with access to Google Sheets API.
- A Slack workspace with permissions to create and manage apps.
- Python 3 installed on your system.
- AWS CLI installed and configured on your system.
- `jq` command-line JSON processor.

## Step 1: Setting Up AWS API Access

1. **Create an IAM User**: Log into your AWS Management Console, navigate to IAM, and create a new user with programmatic access.
2. **Assign Permissions**: Attach policies that grant access to EC2, IAM, and S3 services.
3. **Store Credentials**: Note down the `Access key ID` and `Secret access key`.

## Step 2: Configuring Google Sheets API

1. **Create a Project in Google Cloud Console**: Go to the Google Cloud Console, create a new project, and enable the Google Sheets API for it.
2. **Create Credentials**: In the API & Services > Credentials section, create credentials for a service account. Download the JSON file containing the credentials.
3. **Share Your Spreadsheet**: Share your target Google Spreadsheet with the email address found in the downloaded JSON file.

## Step 3: Setting Up Slack Bot API

1. **Create a Slack App**: Go to the Slack API website, create a new app, and assign it to your workspace.
2. **Add Permissions**: In the OAuth & Permissions section, add necessary scopes (like `chat:write`).
3. **Install App to Workspace**: Install the app to your workspace to get the OAuth Access Token.
4. **Note the Channel ID**: Identify the Slack channel ID where notifications will be sent.

## Step 4: Configuring the Scripts

1. **Clone or Download the Scripts**: Obtain the AWSInventorySync scripts.
2. **Update AWS Script**: In the bash script, replace the placeholder for the spreadsheet ID and sheet ID with your actual Google Sheets details.
3. **Update Python Script**: In the Python script, replace the `SERVICE_ACCOUNT_FILE` path with the path to your downloaded Google credentials JSON file.

## Step 5: Installing Dependencies

1. **Install Python Libraries**: Run `pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client slack_sdk`.
2. **Install jq**: Ensure `jq` is installed on your system for JSON processing.

## Step 6: Updating Credentials and Tokens

1. **AWS Credentials**: Configure AWS CLI with the credentials of the IAM user created in Step 1.
2. **Google API Credentials**: Place the downloaded JSON file in the same directory as your Python script or update the script with its path.
3. **Slack Token**: Update the Python script with your Slack OAuth Access Token and channel ID.

## Step 7: Running the Tool

1. **Execute Bash Script**: Run the bash script with the desired parameters (ec2, keypair, iam, s3, or all).
2. **Run Python Script**: Execute the Python script to upload data to Google Sheets and check for changes.

## Step 8: Scheduling Regular Updates

1. **Cron Job (Optional)**: Set up a cron job to run the bash and Python scripts at regular intervals for automated updates.

# How to use

## Bash Script

In the provided Bash script, you need to edit the following areas to configure it for your environment:

1. **Google Sheets API Integration:**
   - In each function (`fetch_ec2_details`, `fetch_keypair_details`, `fetch_iam_details`, `fetch_s3_details`), there is a line that calls `python3 upload_to_gsheets.py`. You need to replace `[SPREADSHEET_ID]`, `[CSV_FILE_PATH]`, and `[SHEET_ID]` with your actual Google Sheets ID, the path to the CSV file you want to upload, and the ID of the specific sheet within your Google Spreadsheet, respectively.
   - Example: `python3 upload_to_gsheets.py '1aBcD2eFgHiJkL3mNoP4qRsTuV5wXyZ' './ec2_inventory.csv' 'AWS EC2' 1234567890`

2. **Execution Parameters:**
   - The script uses command-line arguments (`ec2`, `keypair`, `iam`, `s3`, `all`) to determine which AWS resource details to fetch. Ensure these parameters align with your intended use.

3. **Region-Specific Adjustments:**
   - In the `fetch_s3_details` function, buckets in `us-east-1` are treated as having a "Global" region. Adjust this part if your handling of AWS regions is different.

## Python Script
In the provided Python script, you need to edit the following hardcoded parts:

1. **Email Configuration:**
   - `email_sender`: Replace `'your_email@example.com'` with your actual email address used for sending notifications.
   - `email_password`: Replace `'your_password'` with the password for the email sender account.
   - `email_receiver`: Replace `'receiver_email@example.com'` with the email address where you want to send notifications.
   - `smtp.example.com`: Replace with the SMTP server address for your email provider.

2. **Slack Configuration:**
   - `[slack-token]`: Replace with your actual Slack bot token.
   - `[channel-id]`: Replace with the Slack channel ID where you want to send notifications.

3. **Google Sheets API Credentials:**
   - Ensure that `./credentials.json` correctly points to your Google service account credentials file. If the file is located elsewhere or named differently, update the path accordingly.


