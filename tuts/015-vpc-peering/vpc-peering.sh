#!/bin/bash

# VPC Peering Connection Script - Version 4 (Fixed)
# This script establishes a VPC peering connection between two VPCs,
# creates subnets if needed, and configures the necessary route tables.
# It will use existing VPCs if available, or create new ones if needed.

# Initialize log file
LOG_FILE="vpc-peering-script-v4.log"
echo "Starting VPC Peering script at $(date)" > $LOG_FILE

# Function to log commands and their output
log_cmd() {
    echo "$(date): COMMAND: $1" >> $LOG_FILE
    eval "$1" 2>&1 | tee -a $LOG_FILE
    return ${PIPESTATUS[0]}
}

# Function to check for errors
check_error() {
    if [ $1 -ne 0 ]; then
        echo "ERROR: Command failed with exit code $1" | tee -a $LOG_FILE
        echo "See $LOG_FILE for details"
        cleanup_on_error
        exit $1
    fi
}

# Function to clean up resources on error
cleanup_on_error() {
    echo "Error encountered. Attempting to clean up resources..." | tee -a $LOG_FILE
    
    # List created resources
    echo "Resources created:" | tee -a $LOG_FILE
    for resource in "${CREATED_RESOURCES[@]}"; do
        echo "- $resource" | tee -a $LOG_FILE
    done
    
    # Clean up in reverse order
    for ((i=${#CLEANUP_COMMANDS[@]}-1; i>=0; i--)); do
        echo "Executing cleanup: ${CLEANUP_COMMANDS[$i]}" >> $LOG_FILE
        eval "${CLEANUP_COMMANDS[$i]}" 2>&1 >> $LOG_FILE
    done
}

# Array to store created resources and cleanup commands
declare -a CREATED_RESOURCES
declare -a CLEANUP_COMMANDS

echo "Setting up VPC peering connection..."

# Check for existing VPCs
echo "Checking for existing VPCs..."
EXISTING_VPCS=$(aws ec2 describe-vpcs --query 'Vpcs[?State==`available`].[VpcId,CidrBlock]' --output text 2>/dev/null)

if [ -z "$EXISTING_VPCS" ]; then
    echo "No existing VPCs found. Creating new VPCs..."
    CREATE_VPCS=true
else
    echo "Found existing VPCs:"
    echo "$EXISTING_VPCS"
    echo ""
    echo "Do you want to use existing VPCs (e) or create new ones (n)? [e/n]: "
    read -r VPC_CHOICE
    
    if [[ "${VPC_CHOICE,,}" == "e" ]]; then
        CREATE_VPCS=false
        # Get the first two available VPCs
        VPC1_INFO=$(echo "$EXISTING_VPCS" | head -n 1)
        VPC2_INFO=$(echo "$EXISTING_VPCS" | head -n 2 | tail -n 1)
        
        if [ -z "$VPC2_INFO" ]; then
            echo "Only one VPC found. Creating a second VPC..."
            VPC1_ID=$(echo $VPC1_INFO | awk '{print $1}')
            VPC1_CIDR=$(echo $VPC1_INFO | awk '{print $2}')
            CREATE_VPC2_ONLY=true
        else
            VPC1_ID=$(echo $VPC1_INFO | awk '{print $1}')
            VPC1_CIDR=$(echo $VPC1_INFO | awk '{print $2}')
            VPC2_ID=$(echo $VPC2_INFO | awk '{print $1}')
            VPC2_CIDR=$(echo $VPC2_INFO | awk '{print $2}')
            CREATE_VPC2_ONLY=false
        fi
    else
        CREATE_VPCS=true
    fi
fi

# Create VPCs if needed
if [ "$CREATE_VPCS" = true ]; then
    echo "Creating VPC1..."
    VPC1_ID=$(log_cmd "aws ec2 create-vpc --cidr-block 10.1.0.0/16 --tag-specifications \"ResourceType=vpc,Tags=[{Key=Name,Value=VPC1-Peering-Demo}]\" --query 'Vpc.VpcId' --output text")
    check_error $?
    VPC1_CIDR="10.1.0.0/16"
    CREATED_RESOURCES+=("VPC1: $VPC1_ID")
    CLEANUP_COMMANDS+=("aws ec2 delete-vpc --vpc-id $VPC1_ID")
    echo "VPC1 created with ID: $VPC1_ID"
    
    echo "Creating VPC2..."
    VPC2_ID=$(log_cmd "aws ec2 create-vpc --cidr-block 10.2.0.0/16 --tag-specifications \"ResourceType=vpc,Tags=[{Key=Name,Value=VPC2-Peering-Demo}]\" --query 'Vpc.VpcId' --output text")
    check_error $?
    VPC2_CIDR="10.2.0.0/16"
    CREATED_RESOURCES+=("VPC2: $VPC2_ID")
    CLEANUP_COMMANDS+=("aws ec2 delete-vpc --vpc-id $VPC2_ID")
    echo "VPC2 created with ID: $VPC2_ID"
    
    # Wait for VPCs to be available
    echo "Waiting for VPCs to be available..."
    log_cmd "aws ec2 wait vpc-available --vpc-ids $VPC1_ID $VPC2_ID"
    check_error $?
    
elif [ "$CREATE_VPC2_ONLY" = true ]; then
    echo "Creating VPC2..."
    VPC2_ID=$(log_cmd "aws ec2 create-vpc --cidr-block 10.2.0.0/16 --tag-specifications \"ResourceType=vpc,Tags=[{Key=Name,Value=VPC2-Peering-Demo}]\" --query 'Vpc.VpcId' --output text")
    check_error $?
    VPC2_CIDR="10.2.0.0/16"
    CREATED_RESOURCES+=("VPC2: $VPC2_ID")
    CLEANUP_COMMANDS+=("aws ec2 delete-vpc --vpc-id $VPC2_ID")
    echo "VPC2 created with ID: $VPC2_ID"
    
    # Wait for VPC2 to be available
    echo "Waiting for VPC2 to be available..."
    log_cmd "aws ec2 wait vpc-available --vpc-ids $VPC2_ID"
    check_error $?
fi

echo "Using the following VPCs:"
echo "VPC1: $VPC1_ID ($VPC1_CIDR)"
echo "VPC2: $VPC2_ID ($VPC2_CIDR)"

# Verify the VPCs exist and are available
echo "Verifying VPCs..."
log_cmd "aws ec2 describe-vpcs --vpc-ids $VPC1_ID $VPC2_ID --query 'Vpcs[*].[VpcId,State,CidrBlock]' --output table"
check_error $?

# Determine subnet CIDR blocks based on VPC CIDR blocks
VPC1_SUBNET_CIDR=$(echo $VPC1_CIDR | sed 's/0\.0\/16/1.0\/24/')
VPC2_SUBNET_CIDR=$(echo $VPC2_CIDR | sed 's/0\.0\/16/1.0\/24/')

# Create subnets in both VPCs
echo "Creating subnet in VPC1..."
SUBNET1_ID=$(log_cmd "aws ec2 create-subnet --vpc-id $VPC1_ID --cidr-block $VPC1_SUBNET_CIDR --tag-specifications \"ResourceType=subnet,Tags=[{Key=Name,Value=VPC1-Peering-Subnet}]\" --query 'Subnet.SubnetId' --output text")
check_error $?
CREATED_RESOURCES+=("Subnet in VPC1: $SUBNET1_ID")
CLEANUP_COMMANDS+=("aws ec2 delete-subnet --subnet-id $SUBNET1_ID")
echo "Subnet created in VPC1 with ID: $SUBNET1_ID (CIDR: $VPC1_SUBNET_CIDR)"

echo "Creating subnet in VPC2..."
SUBNET2_ID=$(log_cmd "aws ec2 create-subnet --vpc-id $VPC2_ID --cidr-block $VPC2_SUBNET_CIDR --tag-specifications \"ResourceType=subnet,Tags=[{Key=Name,Value=VPC2-Peering-Subnet}]\" --query 'Subnet.SubnetId' --output text")
check_error $?
CREATED_RESOURCES+=("Subnet in VPC2: $SUBNET2_ID")
CLEANUP_COMMANDS+=("aws ec2 delete-subnet --subnet-id $SUBNET2_ID")
echo "Subnet created in VPC2 with ID: $SUBNET2_ID (CIDR: $VPC2_SUBNET_CIDR)"

# Create a VPC peering connection
echo "Creating VPC peering connection..."
PEERING_ID=$(log_cmd "aws ec2 create-vpc-peering-connection --vpc-id $VPC1_ID --peer-vpc-id $VPC2_ID --tag-specifications \"ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=VPC1-VPC2-Peering}]\" --query 'VpcPeeringConnection.VpcPeeringConnectionId' --output text")
check_error $?
CREATED_RESOURCES+=("VPC Peering Connection: $PEERING_ID")
CLEANUP_COMMANDS+=("aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PEERING_ID")
echo "VPC Peering Connection created with ID: $PEERING_ID"

# Accept the VPC peering connection
echo "Accepting VPC peering connection..."
log_cmd "aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $PEERING_ID"
check_error $?
echo "VPC Peering Connection accepted"

# Wait for the peering connection to become active
echo "Waiting for peering connection to become active..."
log_cmd "aws ec2 wait vpc-peering-connection-exists --vpc-peering-connection-ids $PEERING_ID"
check_error $?

# Create a route table for VPC1
echo "Creating route table for VPC1..."
RTB1_ID=$(log_cmd "aws ec2 create-route-table --vpc-id $VPC1_ID --tag-specifications \"ResourceType=route-table,Tags=[{Key=Name,Value=VPC1-RouteTable}]\" --query 'RouteTable.RouteTableId' --output text")
check_error $?
CREATED_RESOURCES+=("Route Table for VPC1: $RTB1_ID")
CLEANUP_COMMANDS+=("aws ec2 delete-route-table --route-table-id $RTB1_ID")
echo "Route table created for VPC1 with ID: $RTB1_ID"

# Create a route from VPC1 to VPC2
echo "Creating route from VPC1 to VPC2..."
log_cmd "aws ec2 create-route --route-table-id $RTB1_ID --destination-cidr-block $VPC2_CIDR --vpc-peering-connection-id $PEERING_ID"
check_error $?
echo "Route created from VPC1 to VPC2"

# Associate the route table with the subnet in VPC1
echo "Associating route table with subnet in VPC1..."
RTB1_ASSOC_ID=$(log_cmd "aws ec2 associate-route-table --route-table-id $RTB1_ID --subnet-id $SUBNET1_ID --query 'AssociationId' --output text")
check_error $?
CREATED_RESOURCES+=("Route Table Association for VPC1: $RTB1_ASSOC_ID")
CLEANUP_COMMANDS+=("aws ec2 disassociate-route-table --association-id $RTB1_ASSOC_ID")
echo "Route table associated with subnet in VPC1"

# Create a route table for VPC2
echo "Creating route table for VPC2..."
RTB2_ID=$(log_cmd "aws ec2 create-route-table --vpc-id $VPC2_ID --tag-specifications \"ResourceType=route-table,Tags=[{Key=Name,Value=VPC2-RouteTable}]\" --query 'RouteTable.RouteTableId' --output text")
check_error $?
CREATED_RESOURCES+=("Route Table for VPC2: $RTB2_ID")
CLEANUP_COMMANDS+=("aws ec2 delete-route-table --route-table-id $RTB2_ID")
echo "Route table created for VPC2 with ID: $RTB2_ID"

# Create a route from VPC2 to VPC1
echo "Creating route from VPC2 to VPC1..."
log_cmd "aws ec2 create-route --route-table-id $RTB2_ID --destination-cidr-block $VPC1_CIDR --vpc-peering-connection-id $PEERING_ID"
check_error $?
echo "Route created from VPC2 to VPC1"

# Associate the route table with the subnet in VPC2
echo "Associating route table with subnet in VPC2..."
RTB2_ASSOC_ID=$(log_cmd "aws ec2 associate-route-table --route-table-id $RTB2_ID --subnet-id $SUBNET2_ID --query 'AssociationId' --output text")
check_error $?
CREATED_RESOURCES+=("Route Table Association for VPC2: $RTB2_ASSOC_ID")
CLEANUP_COMMANDS+=("aws ec2 disassociate-route-table --association-id $RTB2_ASSOC_ID")
echo "Route table associated with subnet in VPC2"

# Verify the VPC peering connection
echo "Verifying VPC peering connection..."
log_cmd "aws ec2 describe-vpc-peering-connections --vpc-peering-connection-ids $PEERING_ID --query 'VpcPeeringConnections[0].[VpcPeeringConnectionId,Status.Code,AccepterVpcInfo.VpcId,RequesterVpcInfo.VpcId]' --output table"
check_error $?
echo "VPC peering connection verified"

# Display summary of created resources
echo ""
echo "=============================================="
echo "SUMMARY OF CREATED RESOURCES"
echo "=============================================="
echo "VPC1 ID: $VPC1_ID"
echo "VPC1 CIDR: $VPC1_CIDR"
echo "Subnet1 ID: $SUBNET1_ID (CIDR: $VPC1_SUBNET_CIDR)"
echo "VPC2 ID: $VPC2_ID"
echo "VPC2 CIDR: $VPC2_CIDR"
echo "Subnet2 ID: $SUBNET2_ID (CIDR: $VPC2_SUBNET_CIDR)"
echo "Peering Connection ID: $PEERING_ID"
echo "Route Table 1 ID: $RTB1_ID"
echo "Route Table 1 Association ID: $RTB1_ASSOC_ID"
echo "Route Table 2 ID: $RTB2_ID"
echo "Route Table 2 Association ID: $RTB2_ASSOC_ID"
echo ""
echo "Created resources:"
for resource in "${CREATED_RESOURCES[@]}"; do
    echo "- $resource"
done
echo "=============================================="
echo ""

# Test connectivity (optional)
echo "=============================================="
echo "CONNECTIVITY TEST"
echo "=============================================="
echo "To test connectivity between VPCs, you would need to:"
echo "1. Launch EC2 instances in each subnet"
echo "2. Configure security groups to allow traffic"
echo "3. Test ping or other network connectivity"
echo ""

# Prompt for cleanup
echo ""
echo "=============================================="
echo "CLEANUP CONFIRMATION"
echo "=============================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE

if [[ "${CLEANUP_CHOICE,,}" == "y" ]]; then
    echo "Starting cleanup process..."
    
    # Clean up in reverse order
    echo "Disassociating route table from subnet in VPC2..."
    log_cmd "aws ec2 disassociate-route-table --association-id $RTB2_ASSOC_ID"
    
    echo "Disassociating route table from subnet in VPC1..."
    log_cmd "aws ec2 disassociate-route-table --association-id $RTB1_ASSOC_ID"
    
    echo "Deleting route table for VPC2..."
    log_cmd "aws ec2 delete-route-table --route-table-id $RTB2_ID"
    
    echo "Deleting route table for VPC1..."
    log_cmd "aws ec2 delete-route-table --route-table-id $RTB1_ID"
    
    echo "Deleting VPC peering connection..."
    log_cmd "aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PEERING_ID"
    
    echo "Deleting subnet in VPC2..."
    log_cmd "aws ec2 delete-subnet --subnet-id $SUBNET2_ID"
    
    echo "Deleting subnet in VPC1..."
    log_cmd "aws ec2 delete-subnet --subnet-id $SUBNET1_ID"
    
    # Delete VPCs if they were created by this script
    if [ "$CREATE_VPCS" = true ]; then
        echo "Deleting VPC2..."
        log_cmd "aws ec2 delete-vpc --vpc-id $VPC2_ID"
        
        echo "Deleting VPC1..."
        log_cmd "aws ec2 delete-vpc --vpc-id $VPC1_ID"
    elif [ "$CREATE_VPC2_ONLY" = true ]; then
        echo "Deleting VPC2..."
        log_cmd "aws ec2 delete-vpc --vpc-id $VPC2_ID"
    fi
    
    echo "Cleanup completed successfully."
else
    echo "Cleanup skipped. Resources will remain in your AWS account."
    echo ""
    echo "To manually clean up later, you can delete resources in this order:"
    echo "1. Route table associations"
    echo "2. Route tables"
    echo "3. VPC peering connection"
    echo "4. Subnets"
    if [ "$CREATE_VPCS" = true ] || [ "$CREATE_VPC2_ONLY" = true ]; then
        echo "5. VPCs (if created by this script)"
    fi
fi

echo "Script execution completed. See $LOG_FILE for detailed logs."
