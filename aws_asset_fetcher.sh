#!/bin/bash

# Function to fetch EC2 instance details
fetch_ec2_details() {
    local output_file="$(date +'%d-%m-%y')_ec2_inventory.csv"
    echo "InstanceId,PublicIP,PrivateIP,KeyName,SecurityGroup,Ports" > "$output_file"

    local query='Reservations[*].Instances[*].[InstanceId, PublicIpAddress, PrivateIpAddress, KeyName, SecurityGroups[*].GroupId]'
    local instances=$(aws ec2 describe-instances --query "$query" --output json)

    if [ -z "$instances" ]; then
        echo "No instances found or unable to fetch instance details."
        return 1
    fi

    echo "$instances" | jq -c '.[][] | select(.[1] != null and .[4] != null)' | while read -r instance; do
        local instanceId=$(echo $instance | jq -r '.[0]')
        local publicIp=$(echo $instance | jq -r '.[1]')
        local privateIp=$(echo $instance | jq -r '.[2]')
        local keyName=$(echo $instance | jq -r '.[3]')
        local securityGroups=$(echo $instance | jq -r '.[4][]?')

        if [ -z "$securityGroups" ]; then
            echo "$instanceId,$publicIp,$privateIp,$keyName,NO_SECURITY_GROUP," >> "$output_file"
        else
            for sg in $securityGroups; do
                local ports=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[*].IpPermissions[*].FromPort' --output text)
                [ -z "$ports" ] && ports="NO_PORTS"
                echo "$instanceId,$publicIp,$privateIp,$keyName,$sg,$ports" >> "$output_file"
            done
        fi
    done

    echo "EC2 details written to $output_file"
    python3 upload_to_gsheets.py [SPREADSHEET_ID] [CSV_FILE_PATH] 'AWS EC2' [SHEET_ID]

}

# Function to fetch key pair details
fetch_keypair_details() {
    local output_file="$(date +'%d-%m-%y')_keypair_inventory.csv"
    echo "InstanceId,KeyName,InstanceType,State" > "$output_file"

    aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,KeyName,InstanceType,State.Name]' --output text | while read -r instanceId keyName instanceType state; do
        if [ "$keyName" != "None" ]; then
            echo "$instanceId,$keyName,$instanceType,$state" >> "$output_file"
        fi
    done

    echo "Keypair details written to $output_file"
    python3 upload_to_gsheets.py [SPREADSHEET_ID] [CSV_FILE_PATH] 'AWS Keypair' [SHEET_ID]
}

fetch_iam_details() {
    local output_file="$(date +'%d-%m-%y')_iam_inventory.csv"
    echo "UserName,UserId,UserCreationDate,AttachedPolicies" > "$output_file"

    local users=$(aws iam list-users --query 'Users[*].[UserName,UserId,CreateDate]' --output json)
    if [ -z "$users" ]; then
        echo "No IAM users found or unable to fetch user details."
        return 1
    fi

    echo "$users" | jq -c '.[]' | while read -r user; do
        local userName=$(echo $user | jq -r '.[0]')
        local userId=$(echo $user | jq -r '.[1]')
        local userCreationDate=$(echo $user | jq -r '.[2]')

        # Fetch attached policies for each user
        local policies=$(aws iam list-attached-user-policies --user-name "$userName" --query 'AttachedPolicies[*].PolicyName' --output text)
        [ -z "$policies" ] && policies="NO_POLICIES"

        echo "$userName,$userId,$userCreationDate,$policies" >> "$output_file"
    done

    echo "IAM details written to $output_file"
    python3 upload_to_gsheets.py [SPREADSHEET_ID] [CSV_FILE_PATH] 'AWS IAM' [SHEET_ID]

}

# Function to fetch S3 bucket details
fetch_s3_details() {
    local output_file="$(date +'%Y-%m-%d')_s3_inventory.csv"
    echo "BucketName,CreationDate,Region,Owner" > "$output_file"

    local buckets=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text)
    if [ -z "$buckets" ]; then
        echo "No S3 buckets found or unable to fetch bucket details."
        return 1
    fi

    for bucket in $buckets; do
        local creationDate=$(aws s3api get-bucket-creation-date --bucket "$bucket" --query 'CreationDate' --output text)
        local region=$(aws s3api get-bucket-location --bucket "$bucket" --query 'LocationConstraint' --output text)
        local owner=$(aws s3api get-bucket-acl --bucket "$bucket" --query 'Owner.DisplayName' --output text)

        [ -z "$region" ] && region="Global"  # For buckets in us-east-1 AWS returns null
        echo "$bucket,$creationDate,$region,$owner" >> "$output_file"
    done

    echo "S3 bucket details written to $output_file"
    python3 upload_to_gsheets.py [SPREADSHEET_ID] [CSV_FILE_PATH] 'AWS S3' [SHEET_ID]
}

# Main script execution
case "$1" in
    ec2)
        fetch_ec2_details
        ;;
    keypair)
        fetch_keypair_details
        ;;
    iam)
        fetch_iam_details
        ;;
    s3)
        fetch_s3_details
        ;;
    all)
        fetch_ec2_details
        fetch_keypair_details
        fetch_iam_details
        fetch_s3_details
        ;;
    *)
        echo "Invalid argument. Please use 'ec2', 'keypair', 'iam', or 's3'."
        exit 1
        ;;
esac

