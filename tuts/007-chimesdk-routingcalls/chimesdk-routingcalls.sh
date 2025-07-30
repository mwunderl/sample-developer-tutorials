#!/bin/bash

# Script for setting up Amazon Chime SDK PSTN Audio call routing with AWS Lambda
# This script demonstrates how to create resources for routing calls to AWS Lambda functions
# Version 5: Improved phone number search and provisioning with error handling

# Set up logging
LOG_FILE="chime-sdk-setup.log"
echo "Starting setup at $(date)" > $LOG_FILE

# Function to log commands and their output
log_cmd() {
  echo "Running: $1" | tee -a $LOG_FILE
  eval "$1" 2>&1 | tee -a $LOG_FILE
  return ${PIPESTATUS[0]}
}

# Function to handle errors
handle_error() {
  echo "Error occurred at line $1" | tee -a $LOG_FILE
  echo "Resources created:" | tee -a $LOG_FILE
  for resource in "${CREATED_RESOURCES[@]}"; do
    echo "- $resource" | tee -a $LOG_FILE
  done
  echo "Attempting cleanup..." | tee -a $LOG_FILE
  cleanup
  exit 1
}

# Function to clean up resources
cleanup() {
  # Reverse the array to delete resources in reverse order of creation
  for ((i=${#CLEANUP_COMMANDS[@]}-1; i>=0; i--)); do
    # Skip empty commands
    if [ -n "${CLEANUP_COMMANDS[$i]}" ]; then
      log_cmd "${CLEANUP_COMMANDS[$i]}"
      # Add a small delay between cleanup commands to avoid rate limiting
      sleep 2
    fi
  done
}

# Set up error handling
trap 'handle_error $LINENO' ERR
CREATED_RESOURCES=()
CLEANUP_COMMANDS=()

# Set default region if not specified
DEFAULT_REGION="us-east-1"
REGION=${AWS_REGION:-$DEFAULT_REGION}

# Generate random identifier for resource names
RANDOM_ID=$(openssl rand -hex 4)
LAMBDA_FUNCTION_NAME="ChimeSDKCallHandler-${RANDOM_ID}"
BACKUP_LAMBDA_NAME="ChimeSDKBackupHandler-${RANDOM_ID}"
PRIMARY_SIP_APP_NAME="PrimaryCallHandler-${RANDOM_ID}"
BACKUP_SIP_APP_NAME="BackupCallHandler-${RANDOM_ID}"
PRIMARY_SIP_RULE_NAME="PrimaryCallRule-${RANDOM_ID}"
VOICE_CONNECTOR_RULE_NAME="VoiceConnectorRule-${RANDOM_ID}"

echo "=== Amazon Chime SDK PSTN Audio Call Routing Setup ==="
echo "This script will create the following resources:"
echo "- Lambda functions for call handling"
echo "- SIP Media Applications"
echo "- SIP Rules for call routing"
echo ""
echo "Random identifier for this run: ${RANDOM_ID}"
echo "Log file: ${LOG_FILE}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "AWS CLI is not installed. Please install it first." | tee -a $LOG_FILE
  exit 1
fi

# Check if user is logged in to AWS
if ! aws sts get-caller-identity &> /dev/null; then
  echo "Not logged in to AWS. Please configure AWS CLI first." | tee -a $LOG_FILE
  exit 1
fi

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Using AWS Account ID: ${ACCOUNT_ID}" | tee -a $LOG_FILE

# Search for available toll-free phone numbers
echo "Searching for available toll-free phone numbers..." | tee -a $LOG_FILE
log_cmd "aws chime-sdk-voice search-available-phone-numbers --phone-number-type TollFree --country US --toll-free-prefix 844 --max-results 5 --region ${REGION}"

# List existing phone numbers in the account
echo "Checking existing phone numbers in the account..." | tee -a $LOG_FILE
log_cmd "aws chime-sdk-voice list-phone-numbers --region ${REGION}"

# Get an unassigned phone number from the account inventory
PHONE_NUMBER=$(aws chime-sdk-voice list-phone-numbers --region ${REGION} --query "PhoneNumbers[?Status=='Unassigned'].E164PhoneNumber | [0]" --output text)

if [ -z "$PHONE_NUMBER" ] || [ "$PHONE_NUMBER" == "None" ]; then
  echo "No unassigned phone numbers found in your account. Searching for available toll-free numbers..." | tee -a $LOG_FILE
  
  # Search for available toll-free phone numbers
  AVAILABLE_PHONE_NUMBER=$(aws chime-sdk-voice search-available-phone-numbers --phone-number-type TollFree --country US --toll-free-prefix 844 --max-results 1 --region ${REGION} --query "E164PhoneNumbers[0]" --output text)
  
  if [ -z "$AVAILABLE_PHONE_NUMBER" ] || [ "$AVAILABLE_PHONE_NUMBER" == "None" ]; then
    echo "No available phone numbers found. Please try a different toll-free prefix or area code." | tee -a $LOG_FILE
    exit 1
  fi
  
  echo "Found available phone number: ${AVAILABLE_PHONE_NUMBER}" | tee -a $LOG_FILE
  echo "To order this phone number, you would use:" | tee -a $LOG_FILE
  echo "aws chime-sdk-voice create-phone-number-order --product-type SipMediaApplicationDialIn --e164-phone-numbers ${AVAILABLE_PHONE_NUMBER} --region ${REGION}" | tee -a $LOG_FILE
  echo "For this tutorial, we need an existing phone number in your inventory." | tee -a $LOG_FILE
  exit 1
else
  echo "Using unassigned phone number from your account: ${PHONE_NUMBER}" | tee -a $LOG_FILE
fi

# Create a simple Lambda function for call handling
echo "Creating Lambda execution role..." | tee -a $LOG_FILE

# Create a temporary policy document
cat > /tmp/lambda-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the IAM role for Lambda
ROLE_NAME="ChimeSDKLambdaRole-${RANDOM_ID}"
log_cmd "aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file:///tmp/lambda-trust-policy.json"
ROLE_ARN=$(aws iam get-role --role-name ${ROLE_NAME} --query Role.Arn --output text)
CREATED_RESOURCES+=("IAM Role: ${ROLE_NAME}")
CLEANUP_COMMANDS+=("aws iam delete-role --role-name ${ROLE_NAME}")

# Attach basic Lambda execution policy
log_cmd "aws iam attach-role-policy --role-name ${ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
CLEANUP_COMMANDS+=("aws iam detach-role-policy --role-name ${ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole")

# Wait for role to propagate
echo "Waiting for IAM role to propagate..." | tee -a $LOG_FILE
sleep 10

# Create a simple Lambda function for call handling
echo "Creating Lambda function code..." | tee -a $LOG_FILE
mkdir -p /tmp/lambda
cat > /tmp/lambda/index.js << EOF
exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));
  
  // Simple call handling logic
  const response = {
    SchemaVersion: '1.0',
    Actions: [
      {
        Type: 'Speak',
        Parameters: {
          Engine: 'neural',
          Text: 'Hello! This is a test call from Amazon Chime SDK PSTN Audio.',
          VoiceId: 'Joanna'
        }
      },
      {
        Type: 'Hangup',
        Parameters: {
          SipResponseCode: '200'
        }
      }
    ]
  };
  
  return response;
};
EOF

# Create a backup Lambda function with slightly different response
cat > /tmp/lambda/backup-index.js << EOF
exports.handler = async (event) => {
  console.log('Received event in backup handler:', JSON.stringify(event, null, 2));
  
  // Simple call handling logic for backup
  const response = {
    SchemaVersion: '1.0',
    Actions: [
      {
        Type: 'Speak',
        Parameters: {
          Engine: 'neural',
          Text: 'Hello! This is the backup handler for Amazon Chime SDK PSTN Audio.',
          VoiceId: 'Matthew'
        }
      },
      {
        Type: 'Hangup',
        Parameters: {
          SipResponseCode: '200'
        }
      }
    ]
  };
  
  return response;
};
EOF

# Zip the Lambda functions
cd /tmp/lambda
zip -r function.zip index.js > /dev/null
zip -r backup-function.zip backup-index.js > /dev/null
cd - > /dev/null

# Create the primary Lambda function
echo "Creating primary Lambda function: ${LAMBDA_FUNCTION_NAME}..." | tee -a $LOG_FILE
log_cmd "aws lambda create-function --function-name ${LAMBDA_FUNCTION_NAME} --runtime nodejs18.x --role ${ROLE_ARN} --handler index.handler --zip-file fileb:///tmp/lambda/function.zip --region ${REGION}"
CREATED_RESOURCES+=("Lambda Function: ${LAMBDA_FUNCTION_NAME}")
CLEANUP_COMMANDS+=("aws lambda delete-function --function-name ${LAMBDA_FUNCTION_NAME} --region ${REGION}")

# Get the Lambda function ARN
LAMBDA_ARN=$(aws lambda get-function --function-name ${LAMBDA_FUNCTION_NAME} --query Configuration.FunctionArn --output text --region ${REGION})
echo "Primary Lambda ARN: ${LAMBDA_ARN}" | tee -a $LOG_FILE

# Add Lambda permission for Chime SDK
echo "Adding Lambda permission for Chime SDK..." | tee -a $LOG_FILE
log_cmd "aws lambda add-permission --function-name ${LAMBDA_FUNCTION_NAME} --statement-id ChimeSDK --action lambda:InvokeFunction --principal voiceconnector.chime.amazonaws.com --region ${REGION}"

# Create the backup Lambda function in the same region
echo "Creating backup Lambda function: ${BACKUP_LAMBDA_NAME}..." | tee -a $LOG_FILE
log_cmd "aws lambda create-function --function-name ${BACKUP_LAMBDA_NAME} --runtime nodejs18.x --role ${ROLE_ARN} --handler backup-index.handler --zip-file fileb:///tmp/lambda/backup-function.zip --region ${REGION}"
CREATED_RESOURCES+=("Lambda Function: ${BACKUP_LAMBDA_NAME}")
CLEANUP_COMMANDS+=("aws lambda delete-function --function-name ${BACKUP_LAMBDA_NAME} --region ${REGION}")

# Get the backup Lambda function ARN
BACKUP_LAMBDA_ARN=$(aws lambda get-function --function-name ${BACKUP_LAMBDA_NAME} --query Configuration.FunctionArn --output text --region ${REGION})
echo "Backup Lambda ARN: ${BACKUP_LAMBDA_ARN}" | tee -a $LOG_FILE

# Add Lambda permission for Chime SDK to backup function
echo "Adding Lambda permission for Chime SDK to backup function..." | tee -a $LOG_FILE
log_cmd "aws lambda add-permission --function-name ${BACKUP_LAMBDA_NAME} --statement-id ChimeSDK --action lambda:InvokeFunction --principal voiceconnector.chime.amazonaws.com --region ${REGION}"

# Create primary SIP Media Application
echo "Creating primary SIP Media Application..." | tee -a $LOG_FILE
log_cmd "aws chime-sdk-voice create-sip-media-application --aws-region ${REGION} --name \"${PRIMARY_SIP_APP_NAME}\" --endpoints '[{\"LambdaArn\":\"${LAMBDA_ARN}\"}]' --region ${REGION}"

# Wait a moment for the SIP media application to be fully created
sleep 5

# Get the SIP media application ID with error checking
PRIMARY_SIP_APP_ID=$(aws chime-sdk-voice list-sip-media-applications --region ${REGION} --query "SipMediaApplications[?Name=='${PRIMARY_SIP_APP_NAME}'].SipMediaApplicationId" --output text)
if [ -z "$PRIMARY_SIP_APP_ID" ]; then
  echo "Error: Failed to get primary SIP media application ID" | tee -a $LOG_FILE
  handle_error $LINENO
fi

CREATED_RESOURCES+=("SIP Media Application: ${PRIMARY_SIP_APP_NAME} (${PRIMARY_SIP_APP_ID})")
CLEANUP_COMMANDS+=("aws chime-sdk-voice delete-sip-media-application --sip-media-application-id ${PRIMARY_SIP_APP_ID} --region ${REGION}")

echo "Primary SIP Media Application ID: ${PRIMARY_SIP_APP_ID}" | tee -a $LOG_FILE

# Create backup SIP Media Application in the same region
echo "Creating backup SIP Media Application..." | tee -a $LOG_FILE
log_cmd "aws chime-sdk-voice create-sip-media-application --aws-region ${REGION} --name \"${BACKUP_SIP_APP_NAME}\" --endpoints '[{\"LambdaArn\":\"${BACKUP_LAMBDA_ARN}\"}]' --region ${REGION}"

# Wait a moment for the SIP media application to be fully created
sleep 5

# Get the backup SIP media application ID with error checking
BACKUP_SIP_APP_ID=$(aws chime-sdk-voice list-sip-media-applications --region ${REGION} --query "SipMediaApplications[?Name=='${BACKUP_SIP_APP_NAME}'].SipMediaApplicationId" --output text)
if [ -z "$BACKUP_SIP_APP_ID" ]; then
  echo "Error: Failed to get backup SIP media application ID" | tee -a $LOG_FILE
  handle_error $LINENO
fi

CREATED_RESOURCES+=("SIP Media Application: ${BACKUP_SIP_APP_NAME} (${BACKUP_SIP_APP_ID})")
CLEANUP_COMMANDS+=("aws chime-sdk-voice delete-sip-media-application --sip-media-application-id ${BACKUP_SIP_APP_ID} --region ${REGION}")

echo "Backup SIP Media Application ID: ${BACKUP_SIP_APP_ID}" | tee -a $LOG_FILE

# Create a SIP rule with phone number trigger for primary application
echo "" | tee -a $LOG_FILE
echo "=== Creating SIP Rule with Phone Number ===" | tee -a $LOG_FILE
echo "Creating SIP rule with phone number trigger..." | tee -a $LOG_FILE

echo "Using phone number: ${PHONE_NUMBER}" | tee -a $LOG_FILE

# Create SIP rule with phone number trigger for primary application only
log_cmd "aws chime-sdk-voice create-sip-rule --name \"${PRIMARY_SIP_RULE_NAME}\" --trigger-type ToPhoneNumber --trigger-value \"${PHONE_NUMBER}\" --target-applications '[{\"SipMediaApplicationId\":\"${PRIMARY_SIP_APP_ID}\",\"Priority\":1}]' --region ${REGION}"

# Wait for SIP rule to be created
sleep 5

# Get the SIP rule ID with error checking
PRIMARY_SIP_RULE_ID=$(aws chime-sdk-voice list-sip-rules --region ${REGION} --query "SipRules[?Name=='${PRIMARY_SIP_RULE_NAME}'].SipRuleId" --output text)
if [ -z "$PRIMARY_SIP_RULE_ID" ]; then
  echo "Error: Failed to get primary SIP rule ID" | tee -a $LOG_FILE
  handle_error $LINENO
fi

CREATED_RESOURCES+=("SIP Rule: ${PRIMARY_SIP_RULE_NAME} (${PRIMARY_SIP_RULE_ID})")
CLEANUP_COMMANDS+=("aws chime-sdk-voice delete-sip-rule --sip-rule-id ${PRIMARY_SIP_RULE_ID} --region ${REGION}")

echo "SIP Rule ID: ${PRIMARY_SIP_RULE_ID}" | tee -a $LOG_FILE

# Information about creating a SIP rule with Request URI hostname trigger
echo "" | tee -a $LOG_FILE
echo "=== Creating SIP Rule with Request URI Hostname ===" | tee -a $LOG_FILE
echo "To create a SIP rule with a Request URI hostname trigger, you would use:" | tee -a $LOG_FILE
echo "aws chime-sdk-voice create-sip-rule \\" | tee -a $LOG_FILE
echo "  --name \"HostnameRule\" \\" | tee -a $LOG_FILE
echo "  --trigger-type RequestUriHostname \\" | tee -a $LOG_FILE
echo "  --trigger-value \"example.voiceconnector.chime.aws\" \\" | tee -a $LOG_FILE
echo "  --target-applications '[{\"SipMediaApplicationId\":\"${PRIMARY_SIP_APP_ID}\",\"Priority\":1}]' \\" | tee -a $LOG_FILE
echo "  --region ${REGION}" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Note: You need to have Voice Connectors in your account to use this trigger type" | tee -a $LOG_FILE

# Create outbound call example
echo "" | tee -a $LOG_FILE
echo "=== Creating Outbound Call Example ===" | tee -a $LOG_FILE
echo "Creating an example outbound call..." | tee -a $LOG_FILE

# Use the phone number we purchased for the from-phone-number
FROM_PHONE_NUMBER="${PHONE_NUMBER}"
TO_PHONE_NUMBER="+12065550102"  # This is a placeholder destination number

echo "This command would create an outbound call from ${FROM_PHONE_NUMBER} to ${TO_PHONE_NUMBER}:" | tee -a $LOG_FILE
echo "aws chime-sdk-voice create-sip-media-application-call \\" | tee -a $LOG_FILE
echo "  --from-phone-number \"${FROM_PHONE_NUMBER}\" \\" | tee -a $LOG_FILE
echo "  --to-phone-number \"${TO_PHONE_NUMBER}\" \\" | tee -a $LOG_FILE
echo "  --sip-media-application-id ${PRIMARY_SIP_APP_ID} \\" | tee -a $LOG_FILE
echo "  --region ${REGION}" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Note: To make actual calls, the destination number must be valid" | tee -a $LOG_FILE

# Display information about triggering Lambda during an active call
echo "" | tee -a $LOG_FILE
echo "=== Triggering Lambda During an Active Call ===" | tee -a $LOG_FILE
echo "To trigger Lambda during an active call, you would use:" | tee -a $LOG_FILE
echo "aws chime-sdk-voice update-sip-media-application-call \\" | tee -a $LOG_FILE
echo "  --sip-media-application-id ${PRIMARY_SIP_APP_ID} \\" | tee -a $LOG_FILE
echo "  --transaction-id <transaction-id> \\" | tee -a $LOG_FILE
echo "  --arguments '{\"action\":\"custom-action\"}' \\" | tee -a $LOG_FILE
echo "  --region ${REGION}" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
echo "Note: You need an active call with a valid transaction ID" | tee -a $LOG_FILE

# Summary of created resources
echo "" | tee -a $LOG_FILE
echo "=== Resources Created ===" | tee -a $LOG_FILE
for resource in "${CREATED_RESOURCES[@]}"; do
  echo "- $resource" | tee -a $LOG_FILE
done

# Ask user if they want to clean up resources
echo "" | tee -a $LOG_FILE
echo "Do you want to clean up all created resources? (y/n)" | tee -a $LOG_FILE
read -r CLEANUP_RESPONSE

if [[ $CLEANUP_RESPONSE =~ ^[Yy]$ ]]; then
  echo "Cleaning up resources..." | tee -a $LOG_FILE
  cleanup
  echo "Cleanup completed." | tee -a $LOG_FILE
else
  echo "Resources will not be cleaned up. You can manually delete them later." | tee -a $LOG_FILE
  echo "To clean up resources, run the following commands:" | tee -a $LOG_FILE
  for ((i=${#CLEANUP_COMMANDS[@]}-1; i>=0; i--)); do
    echo "${CLEANUP_COMMANDS[$i]}" | tee -a $LOG_FILE
  done
fi

echo "" | tee -a $LOG_FILE
echo "Setup completed at $(date)" | tee -a $LOG_FILE
echo "Log file: ${LOG_FILE}" | tee -a $LOG_FILE
