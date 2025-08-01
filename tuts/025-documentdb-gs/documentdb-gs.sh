#!/bin/bash

# Amazon DocumentDB Getting Started Script
# This script creates an Amazon DocumentDB cluster, connects to it, and demonstrates basic operations

# HIGH SEVERITY ISSUES FIXED:
# 1. Added explicit region handling to ensure consistent region usage throughout the script
# 2. Improved subnet selection logic to ensure subnets from different AZs are selected
# 3. Fixed subnet parsing to correctly extract subnet IDs
# 4. Improved status detection to be more robust with different JSON formatting

# Set up logging
LOG_FILE="docdb_script_v9.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting Amazon DocumentDB Getting Started Script"
echo "================================================="
echo "$(date)"
echo

# Get the current AWS region or use a default
# FIXED: HIGH SEVERITY - Added explicit region handling
AWS_REGION=$(aws configure get region 2>/dev/null)
if [ -z "$AWS_REGION" ]; then
    AWS_REGION="us-east-1"  # Default region if none is configured
    echo "No AWS region configured. Using default region: $AWS_REGION"
else
    echo "Using configured AWS region: $AWS_REGION"
fi
export AWS_REGION

# Error handling function
handle_error() {
    echo "ERROR: $1"
    echo "Attempting to clean up resources..."
    
    # Check if instance exists and delete it
    if [ -n "$DB_INSTANCE_ID" ]; then
        echo "Checking if DB instance exists: $DB_INSTANCE_ID"
        INSTANCE_EXISTS=$(aws docdb describe-db-instances --db-instance-identifier "$DB_INSTANCE_ID" --region "$AWS_REGION" 2>&1)
        echo "$INSTANCE_EXISTS"
        
        if ! echo "$INSTANCE_EXISTS" | grep -qi "DBInstanceNotFound"; then
            echo "Deleting DB instance: $DB_INSTANCE_ID"
            DELETE_INSTANCE_RESULT=$(aws docdb delete-db-instance --db-instance-identifier "$DB_INSTANCE_ID" --region "$AWS_REGION" 2>&1)
            echo "$DELETE_INSTANCE_RESULT"
            
            echo "Waiting for DB instance to be deleted..."
            while true; do
                INSTANCE_STATUS=$(aws docdb describe-db-instances --db-instance-identifier "$DB_INSTANCE_ID" --region "$AWS_REGION" 2>&1)
                echo "$INSTANCE_STATUS"
                
                if echo "$INSTANCE_STATUS" | grep -qi "DBInstanceNotFound"; then
                    echo "DB instance deleted"
                    break
                fi
                echo "DB instance still exists, waiting..."
                sleep 10
            done
        else
            echo "DB instance does not exist, skipping deletion"
        fi
    fi
    
    # Check if cluster exists and delete it
    if [ -n "$DB_CLUSTER_ID" ]; then
        echo "Checking if DB cluster exists: $DB_CLUSTER_ID"
        CLUSTER_EXISTS=$(aws docdb describe-db-clusters --db-cluster-identifier "$DB_CLUSTER_ID" --region "$AWS_REGION" 2>&1)
        echo "$CLUSTER_EXISTS"
        
        if ! echo "$CLUSTER_EXISTS" | grep -qi "DBClusterNotFound"; then
            echo "Deleting DB cluster: $DB_CLUSTER_ID"
            DELETE_CLUSTER_RESULT=$(aws docdb delete-db-cluster --db-cluster-identifier "$DB_CLUSTER_ID" --skip-final-snapshot --region "$AWS_REGION" 2>&1)
            echo "$DELETE_CLUSTER_RESULT"
        else
            echo "DB cluster does not exist, skipping deletion"
        fi
    fi
    
    # Delete DB subnet group if we created one
    if [ -n "$DB_SUBNET_GROUP" ]; then
        echo "Checking if DB subnet group exists: $DB_SUBNET_GROUP"
        SUBNET_GROUP_EXISTS=$(aws docdb describe-db-subnet-groups --db-subnet-group-name "$DB_SUBNET_GROUP" --region "$AWS_REGION" 2>&1)
        echo "$SUBNET_GROUP_EXISTS"
        
        if ! echo "$SUBNET_GROUP_EXISTS" | grep -qi "DBSubnetGroupNotFoundFault"; then
            echo "Deleting DB subnet group: $DB_SUBNET_GROUP"
            DELETE_SUBNET_GROUP_RESULT=$(aws docdb delete-db-subnet-group --db-subnet-group-name "$DB_SUBNET_GROUP" --region "$AWS_REGION" 2>&1)
            echo "$DELETE_SUBNET_GROUP_RESULT"
        else
            echo "DB subnet group does not exist, skipping deletion"
        fi
    fi
    
    # Delete the secret if we created one
    if [ -n "$SECRET_ARN" ]; then
        echo "Deleting secret: $SECRET_NAME"
        DELETE_SECRET_RESULT=$(aws secretsmanager delete-secret --secret-id "$SECRET_NAME" --force-delete-without-recovery --region "$AWS_REGION" 2>&1)
        echo "$DELETE_SECRET_RESULT"
    fi
    
    exit 1
}

# Generate a random identifier suffix to avoid naming conflicts
RANDOM_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
DB_CLUSTER_ID="docdb-cluster-${RANDOM_SUFFIX}"
DB_INSTANCE_ID="docdb-instance-${RANDOM_SUFFIX}"
DB_SUBNET_GROUP="docdb-subnet-${RANDOM_SUFFIX}"
DB_USERNAME="adminuser"
SECRET_NAME="docdb-secret-${RANDOM_SUFFIX}"

echo "Using the following resource names:"
echo "- Cluster ID: $DB_CLUSTER_ID"
echo "- Instance ID: $DB_INSTANCE_ID"
echo "- Subnet Group: $DB_SUBNET_GROUP"
echo "- Secret Name: $SECRET_NAME"
echo "- AWS Region: $AWS_REGION"
echo

# Step 0: Create a secure password and store it in AWS Secrets Manager
echo "Step 0: Creating secure password in AWS Secrets Manager..."
# Generate a secure password
DB_PASSWORD=$(openssl rand -base64 16)

# Store the password in AWS Secrets Manager
echo "Creating secret in AWS Secrets Manager..."
SECRET_RESULT=$(aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "DocumentDB admin credentials for $DB_CLUSTER_ID" \
    --secret-string "{\"username\":\"$DB_USERNAME\",\"password\":\"$DB_PASSWORD\"}" \
    --region "$AWS_REGION" 2>&1)
echo "$SECRET_RESULT"

if echo "$SECRET_RESULT" | grep -qi "error"; then
    handle_error "Failed to create secret in AWS Secrets Manager"
fi

SECRET_ARN=$(echo "$SECRET_RESULT" | grep -o '"ARN": "[^"]*"' | cut -d'"' -f4)
echo "Secret created with ARN: $SECRET_ARN"

# Step 1: Get VPC and subnet information
echo "Step 1: Getting VPC and subnet information..."
DEFAULT_VPC_RESULT=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region "$AWS_REGION" 2>&1)
echo "$DEFAULT_VPC_RESULT"

DEFAULT_VPC_ID=$(echo "$DEFAULT_VPC_RESULT" | grep -o '"VpcId": "[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$DEFAULT_VPC_ID" ] || [ "$DEFAULT_VPC_ID" == "None" ]; then
    echo "No default VPC found. You need to specify a VPC."
    handle_error "No default VPC found"
fi

echo "Using default VPC: $DEFAULT_VPC_ID"

# Get subnets in different AZs
# FIXED: Improved subnet selection to ensure different AZs
echo "Getting subnets from different Availability Zones..."
SUBNETS_RESULT=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" \
    --query "Subnets[*].[SubnetId,AvailabilityZone]" \
    --output text \
    --region "$AWS_REGION" 2>&1)
echo "$SUBNETS_RESULT"

# FIXED: Improved subnet parsing to correctly extract subnet IDs
# Parse the text output to get subnet IDs and their AZs
declare -A AZ_SUBNETS
while read -r SUBNET_ID AZ; do
    if [[ -n "$SUBNET_ID" && -n "$AZ" ]]; then
        AZ_SUBNETS["$AZ"]="$SUBNET_ID"
        echo "Found subnet $SUBNET_ID in AZ $AZ"
    fi
done <<< "$SUBNETS_RESULT"

# Check if we have subnets from at least 2 different AZs
if [ ${#AZ_SUBNETS[@]} -lt 2 ]; then
    echo "Need subnets in at least 2 different AZs, but only found ${#AZ_SUBNETS[@]} AZs."
    handle_error "Not enough AZs with subnets"
fi

# Select subnets from different AZs
SUBNET_IDS=()
for AZ in "${!AZ_SUBNETS[@]}"; do
    SUBNET_IDS+=("${AZ_SUBNETS[$AZ]}")
    echo "Selected subnet ${AZ_SUBNETS[$AZ]} from AZ $AZ"
    # We only need 2 subnets from different AZs for DocumentDB
    if [ ${#SUBNET_IDS[@]} -eq 2 ]; then
        break
    fi
done

echo "Selected ${#SUBNET_IDS[@]} subnets from different AZs for the DB subnet group"

# Step 2: Create a DB subnet group
echo "Step 2: Creating DB subnet group..."
SUBNET_IDS_PARAM=$(IFS=' ' ; echo "${SUBNET_IDS[*]}")
echo "Running command: aws docdb create-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP --db-subnet-group-description \"Subnet group for DocumentDB tutorial\" --subnet-ids $SUBNET_IDS_PARAM --region $AWS_REGION"

SUBNET_GROUP_RESULT=$(aws docdb create-db-subnet-group \
    --db-subnet-group-name "$DB_SUBNET_GROUP" \
    --db-subnet-group-description "Subnet group for DocumentDB tutorial" \
    --subnet-ids "${SUBNET_IDS[@]}" \
    --region "$AWS_REGION" 2>&1)
echo "$SUBNET_GROUP_RESULT"

if echo "$SUBNET_GROUP_RESULT" | grep -qi "error"; then
    echo "Subnet group creation failed with error:"
    echo "$SUBNET_GROUP_RESULT"
    handle_error "Failed to create DB subnet group"
fi

echo "DB subnet group created successfully."

# Step 3: Create a DocumentDB cluster
echo "Step 3: Creating DocumentDB cluster..."
echo "Running command: aws docdb create-db-cluster --db-cluster-identifier $DB_CLUSTER_ID --engine docdb --engine-version 5.0.0 --master-username $DB_USERNAME --master-user-password ******** --db-subnet-group-name $DB_SUBNET_GROUP --region $AWS_REGION"

CLUSTER_RESULT=$(aws docdb create-db-cluster \
    --db-cluster-identifier "$DB_CLUSTER_ID" \
    --engine docdb \
    --engine-version 5.0.0 \
    --master-username "$DB_USERNAME" \
    --master-user-password "$DB_PASSWORD" \
    --db-subnet-group-name "$DB_SUBNET_GROUP" \
    --region "$AWS_REGION" 2>&1)
echo "$CLUSTER_RESULT"

# Case-insensitive check for errors
if echo "$CLUSTER_RESULT" | grep -qi "error"; then
    echo "Cluster creation failed with error:"
    echo "$CLUSTER_RESULT"
    handle_error "Failed to create DB cluster"
fi

echo "Cluster creation initiated. Waiting for cluster to become available..."
TIMEOUT=600  # 10 minutes timeout
START_TIME=$(date +%s)
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED_TIME -gt $TIMEOUT ]; then
        handle_error "Timeout waiting for cluster to become available after $TIMEOUT seconds"
    fi
    
    CLUSTER_INFO=$(aws docdb describe-db-clusters \
        --db-cluster-identifier "$DB_CLUSTER_ID" \
        --query "DBClusters[0].Status" \
        --output text \
        --region "$AWS_REGION" 2>&1)
    echo "Cluster status (direct query): $CLUSTER_INFO"
    
    if [ "$CLUSTER_INFO" = "available" ]; then
        echo "Cluster is now available!"
        break
    fi
    
    sleep 10
done

# Step 4: Create a DocumentDB instance
echo "Step 4: Creating DocumentDB instance..."
echo "Running command: aws docdb create-db-instance --db-instance-identifier $DB_INSTANCE_ID --db-instance-class db.t3.medium --engine docdb --db-cluster-identifier $DB_CLUSTER_ID --region $AWS_REGION"

INSTANCE_RESULT=$(aws docdb create-db-instance \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --db-instance-class db.t3.medium \
    --engine docdb \
    --db-cluster-identifier "$DB_CLUSTER_ID" \
    --region "$AWS_REGION" 2>&1)
echo "$INSTANCE_RESULT"

if echo "$INSTANCE_RESULT" | grep -qi "error"; then
    echo "Instance creation failed with error:"
    echo "$INSTANCE_RESULT"
    handle_error "Failed to create DB instance"
fi

echo "Instance creation initiated. Waiting for instance to become available..."
TIMEOUT=900  # 15 minutes timeout
START_TIME=$(date +%s)
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED_TIME -gt $TIMEOUT ]; then
        handle_error "Timeout waiting for instance to become available after $TIMEOUT seconds"
    fi
    
    INSTANCE_INFO=$(aws docdb describe-db-instances \
        --db-instance-identifier "$DB_INSTANCE_ID" \
        --query "DBInstances[0].DBInstanceStatus" \
        --output text \
        --region "$AWS_REGION" 2>&1)
    echo "Instance status (direct query): $INSTANCE_INFO"
    
    if [ "$INSTANCE_INFO" = "available" ]; then
        echo "Instance is now available!"
        break
    fi
    
    sleep 10
done

# Step 5: Get cluster endpoint and security group information
echo "Step 5: Getting cluster connection information..."
CLUSTER_ENDPOINT=$(aws docdb describe-db-clusters \
    --db-cluster-identifier "$DB_CLUSTER_ID" \
    --query "DBClusters[0].Endpoint" \
    --output text \
    --region "$AWS_REGION" 2>&1)

if [ -z "$CLUSTER_ENDPOINT" ]; then
    handle_error "Failed to get cluster endpoint"
fi

SECURITY_GROUP_ID=$(aws docdb describe-db-clusters \
    --db-cluster-identifier "$DB_CLUSTER_ID" \
    --query "DBClusters[0].VpcSecurityGroups[0].VpcSecurityGroupId" \
    --output text \
    --region "$AWS_REGION" 2>&1)

if [ -z "$SECURITY_GROUP_ID" ]; then
    handle_error "Failed to get security group ID"
fi

echo "Cluster endpoint: $CLUSTER_ENDPOINT"
echo "Security group ID: $SECURITY_GROUP_ID"

# Step 6: Update security group to allow MongoDB connections
echo "Step 6: Updating security group to allow MongoDB connections..."
MY_IP_RESULT=$(curl -s https://checkip.amazonaws.com)
echo "IP address lookup result: $MY_IP_RESULT"
MY_IP=$(echo "$MY_IP_RESULT" | tr -d '[:space:]')

if [ -z "$MY_IP" ]; then
    handle_error "Failed to get current IP address"
fi

echo "Your current IP address: $MY_IP"
echo "Running command: aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 27017 --cidr ${MY_IP}/32 --region $AWS_REGION"

SG_RESULT=$(aws ec2 authorize-security-group-ingress \
    --group-id "$SECURITY_GROUP_ID" \
    --protocol tcp \
    --port 27017 \
    --cidr "${MY_IP}/32" \
    --region "$AWS_REGION" 2>&1)
echo "$SG_RESULT"

# Ignore if the rule already exists
if echo "$SG_RESULT" | grep -qi "error" && ! echo "$SG_RESULT" | grep -qi "already exists"; then
    echo "Security group update failed with error:"
    echo "$SG_RESULT"
    handle_error "Failed to update security group"
fi

# Step 7: Download CA certificate for TLS connections
echo "Step 7: Downloading CA certificate for TLS connections..."
mkdir -p ~/certs
WGET_RESULT=$(wget -v https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O ~/certs/global-bundle.pem 2>&1)
echo "$WGET_RESULT"

if [ ! -f ~/certs/global-bundle.pem ]; then
    handle_error "Failed to download CA certificate"
fi

echo "CA certificate downloaded to ~/certs/global-bundle.pem"

# Step 8: Retrieve password from Secrets Manager for connection
echo "Step 8: Retrieving password from Secrets Manager..."
SECRET_VALUE_RESULT=$(aws secretsmanager get-secret-value --secret-id "$SECRET_NAME" --region "$AWS_REGION" 2>&1)
echo "Secret retrieved (password redacted for security)"

if echo "$SECRET_VALUE_RESULT" | grep -qi "error"; then
    handle_error "Failed to retrieve secret from AWS Secrets Manager"
fi

# Extract password from secret (don't print it)
DB_PASSWORD_FROM_SECRET=$(echo "$SECRET_VALUE_RESULT" | grep -o '"password":"[^"]*"' | cut -d'"' -f4)

# Step 9: Display connection instructions
echo
echo "============================================================"
echo "Connection Information"
echo "============================================================"
echo "Your DocumentDB cluster is now ready to use!"
echo
echo "To connect using the MongoDB shell, run:"
echo "mongosh --tls --tlsCAFile ~/certs/global-bundle.pem \\"
echo "    --host $CLUSTER_ENDPOINT:27017 \\"
echo "    --username $DB_USERNAME \\"
echo "    --password <password-from-secrets-manager>"
echo
echo "To retrieve your password from Secrets Manager:"
echo "aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $AWS_REGION --query SecretString --output text | jq -r '.password'"
echo
echo "Once connected, you can run the following commands to test your cluster:"
echo
echo "# Insert a single document"
echo "db.collection.insertOne({\"hello\":\"DocumentDB\"})"
echo
echo "# Read the document"
echo "db.collection.findOne()"
echo
echo "# Insert multiple documents"
echo "db.profiles.insertMany(["
echo "  { _id: 1, name: 'Matt', status: 'active', level: 12, score: 202 },"
echo "  { _id: 2, name: 'Frank', status: 'inactive', level: 2, score: 9 },"
echo "  { _id: 3, name: 'Karen', status: 'active', level: 7, score: 87 },"
echo "  { _id: 4, name: 'Katie', status: 'active', level: 3, score: 27 }"
echo "])"
echo
echo "# Query all documents in a collection"
echo "db.profiles.find()"
echo
echo "# Query with a filter"
echo "db.profiles.find({name: \"Katie\"})"
echo
echo "# Find and modify a document"
echo "db.profiles.findAndModify({"
echo "  query: { name: \"Matt\", status: \"active\"},"
echo "  update: { \$inc: { score: 10 } }"
echo "})"
echo
echo "# Verify the modification"
echo "db.profiles.find({name: \"Matt\"})"
echo

# Step 10: Cleanup confirmation
echo
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Resources created:"
echo "- DB Cluster: $DB_CLUSTER_ID"
echo "- DB Instance: $DB_INSTANCE_ID"
echo "- DB Subnet Group: $DB_SUBNET_GROUP"
echo "- AWS Secrets Manager Secret: $SECRET_NAME"
echo "- Security Group Rule: TCP 27017 from ${MY_IP}/32 to $SECURITY_GROUP_ID"
echo
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "$CLEANUP_CHOICE" =~ ^[Yy]$ ]]; then
    echo "Starting cleanup process..."
    
    # Delete DB instance
    echo "Deleting DB instance: $DB_INSTANCE_ID"
    DELETE_INSTANCE_RESULT=$(aws docdb delete-db-instance --db-instance-identifier "$DB_INSTANCE_ID" --region "$AWS_REGION" 2>&1)
    echo "$DELETE_INSTANCE_RESULT"
    
    echo "Waiting for DB instance to be deleted..."
    TIMEOUT=600  # 10 minutes timeout
    START_TIME=$(date +%s)
    while true; do
        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
        
        if [ $ELAPSED_TIME -gt $TIMEOUT ]; then
            echo "Warning: Timeout waiting for instance to be deleted after $TIMEOUT seconds"
            break
        fi
        
        INSTANCE_INFO=$(aws docdb describe-db-instances --db-instance-identifier "$DB_INSTANCE_ID" --region "$AWS_REGION" 2>&1)
        
        if echo "$INSTANCE_INFO" | grep -qi "DBInstanceNotFound"; then
            echo "DB instance deleted"
            break
        fi
        
        INSTANCE_STATUS=$(aws docdb describe-db-instances \
            --db-instance-identifier "$DB_INSTANCE_ID" \
            --query "DBInstances[0].DBInstanceStatus" \
            --output text \
            --region "$AWS_REGION" 2>/dev/null)
        echo "Instance status: $INSTANCE_STATUS (elapsed time: $ELAPSED_TIME seconds)"
        sleep 10
    done
    
    # Delete DB cluster
    echo "Deleting DB cluster: $DB_CLUSTER_ID"
    DELETE_CLUSTER_RESULT=$(aws docdb delete-db-cluster --db-cluster-identifier "$DB_CLUSTER_ID" --skip-final-snapshot --region "$AWS_REGION" 2>&1)
    echo "$DELETE_CLUSTER_RESULT"
    
    # Wait for cluster to be deleted before deleting subnet group
    echo "Waiting for DB cluster to be deleted..."
    TIMEOUT=600  # 10 minutes timeout
    START_TIME=$(date +%s)
    while true; do
        CURRENT_TIME=$(date +%s)
        ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
        
        if [ $ELAPSED_TIME -gt $TIMEOUT ]; then
            echo "Warning: Timeout waiting for cluster to be deleted after $TIMEOUT seconds"
            break
        fi
        
        CLUSTER_INFO=$(aws docdb describe-db-clusters --db-cluster-identifier "$DB_CLUSTER_ID" --region "$AWS_REGION" 2>&1)
        
        if echo "$CLUSTER_INFO" | grep -qi "DBClusterNotFound"; then
            echo "DB cluster deleted"
            break
        fi
        
        CLUSTER_STATUS=$(aws docdb describe-db-clusters \
            --db-cluster-identifier "$DB_CLUSTER_ID" \
            --query "DBClusters[0].Status" \
            --output text \
            --region "$AWS_REGION" 2>/dev/null)
        echo "Cluster status: $CLUSTER_STATUS (elapsed time: $ELAPSED_TIME seconds)"
        sleep 10
    done
    
    # Delete DB subnet group
    echo "Deleting DB subnet group: $DB_SUBNET_GROUP"
    DELETE_SUBNET_GROUP_RESULT=$(aws docdb delete-db-subnet-group --db-subnet-group-name "$DB_SUBNET_GROUP" --region "$AWS_REGION" 2>&1)
    echo "$DELETE_SUBNET_GROUP_RESULT"
    
    # Delete the secret
    echo "Deleting secret: $SECRET_NAME"
    DELETE_SECRET_RESULT=$(aws secretsmanager delete-secret --secret-id "$SECRET_NAME" --force-delete-without-recovery --region "$AWS_REGION" 2>&1)
    echo "$DELETE_SECRET_RESULT"
    
    echo "Cleanup completed successfully!"
else
    echo "Cleanup skipped. Resources will continue to incur charges until deleted."
    echo "To delete resources later, run:"
    echo "aws docdb delete-db-instance --db-instance-identifier $DB_INSTANCE_ID --region $AWS_REGION"
    echo "aws docdb delete-db-cluster --db-cluster-identifier $DB_CLUSTER_ID --skip-final-snapshot --region $AWS_REGION"
    echo "aws docdb delete-db-subnet-group --db-subnet-group-name $DB_SUBNET_GROUP --region $AWS_REGION"
    echo "aws secretsmanager delete-secret --secret-id $SECRET_NAME --force-delete-without-recovery --region $AWS_REGION"
fi

echo
echo "Script completed at $(date)"
echo "Log file: $LOG_FILE"
