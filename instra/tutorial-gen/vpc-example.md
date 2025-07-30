# VPC Architecture Model Example

This document provides a reference architecture for a standard VPC deployment using AWS CLI commands.

## Architecture Overview

This model creates a VPC with the following components:
- VPC with CIDR block 10.0.0.0/16
- 2 public subnets (10.0.0.0/24, 10.0.1.0/24) across 2 AZs
- 2 private subnets (10.0.2.0/24, 10.0.3.0/24) across 2 AZs
- Internet Gateway for public internet access
- Single NAT Gateway in the first public subnet for private subnet internet access
- Route tables for public and private subnets
- Security groups for common use cases

## CLI Commands for VPC Creation

The following commands demonstrate how to create a VPC using shell variables to capture and reuse resource IDs. Each section builds on the previous one, so execute commands in the order shown.

```bash
#!/bin/bash
# Set your region or use the default configured region
REGION=$(aws configure get region)
# Add environment identifier to resource names
ENV_PREFIX="dev"

# Create VPC and capture the VPC ID
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${ENV_PREFIX}-tutorial-vpc}]" \
  --query 'Vpc.VpcId' \
  --output text)

# Get availability zones for the region
AZ1="${REGION}a"
AZ2="${REGION}b"

# Create public subnet in AZ1
PUBLIC_SUBNET1_ID=$(aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block 10.0.0.0/24 \
  --availability-zone ${AZ1} \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${ENV_PREFIX}-public-subnet-1}]" \
  --query 'Subnet.SubnetId' \
  --output text)

# Create public subnet in AZ2
PUBLIC_SUBNET2_ID=$(aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ${AZ2} \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${ENV_PREFIX}-public-subnet-2}]" \
  --query 'Subnet.SubnetId' \
  --output text)

# Create private subnet in AZ1
PRIVATE_SUBNET1_ID=$(aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block 10.0.2.0/24 \
  --availability-zone ${AZ1} \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${ENV_PREFIX}-private-subnet-1}]" \
  --query 'Subnet.SubnetId' \
  --output text)

# Create private subnet in AZ2
PRIVATE_SUBNET2_ID=$(aws ec2 create-subnet \
  --vpc-id ${VPC_ID} \
  --cidr-block 10.0.3.0/24 \
  --availability-zone ${AZ2} \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${ENV_PREFIX}-private-subnet-2}]" \
  --query 'Subnet.SubnetId' \
  --output text)

# Create and attach Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${ENV_PREFIX}-tutorial-igw}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)

aws ec2 attach-internet-gateway \
  --internet-gateway-id ${IGW_ID} \
  --vpc-id ${VPC_ID}

# Create NAT Gateway (Single NAT for Dev/Test)
EIP_ALLOC_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --query 'AllocationId' \
  --output text)

NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id ${PUBLIC_SUBNET1_ID} \
  --allocation-id ${EIP_ALLOC_ID} \
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${ENV_PREFIX}-nat-gateway}]" \
  --query 'NatGateway.NatGatewayId' \
  --output text)

# Wait for NAT Gateway to become available
aws ec2 wait nat-gateway-available --nat-gateway-ids ${NAT_GW_ID}

# Create and configure route tables
PUBLIC_RTB_ID=$(aws ec2 create-route-table \
  --vpc-id ${VPC_ID} \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${ENV_PREFIX}-public-rtb}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

# Add route to Internet Gateway
aws ec2 create-route \
  --route-table-id ${PUBLIC_RTB_ID} \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id ${IGW_ID}

# Associate public subnets with public route table
PUBLIC_SUBNET1_ASSOC_ID=$(aws ec2 associate-route-table \
  --route-table-id ${PUBLIC_RTB_ID} \
  --subnet-id ${PUBLIC_SUBNET1_ID} \
  --query 'AssociationId' \
  --output text)

PUBLIC_SUBNET2_ASSOC_ID=$(aws ec2 associate-route-table \
  --route-table-id ${PUBLIC_RTB_ID} \
  --subnet-id ${PUBLIC_SUBNET2_ID} \
  --query 'AssociationId' \
  --output text)

# Create private route table
PRIVATE_RTB_ID=$(aws ec2 create-route-table \
  --vpc-id ${VPC_ID} \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${ENV_PREFIX}-private-rtb}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

# Add route to NAT Gateway
aws ec2 create-route \
  --route-table-id ${PRIVATE_RTB_ID} \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id ${NAT_GW_ID}

# Associate private subnets with private route table
PRIVATE_SUBNET1_ASSOC_ID=$(aws ec2 associate-route-table \
  --route-table-id ${PRIVATE_RTB_ID} \
  --subnet-id ${PRIVATE_SUBNET1_ID} \
  --query 'AssociationId' \
  --output text)

PRIVATE_SUBNET2_ASSOC_ID=$(aws ec2 associate-route-table \
  --route-table-id ${PRIVATE_RTB_ID} \
  --subnet-id ${PRIVATE_SUBNET2_ID} \
  --query 'AssociationId' \
  --output text)

# Enable DNS support and hostnames
aws ec2 modify-vpc-attribute \
  --vpc-id ${VPC_ID} \
  --enable-dns-support

aws ec2 modify-vpc-attribute \
  --vpc-id ${VPC_ID} \
  --enable-dns-hostnames

# Create security groups
WEB_SG_ID=$(aws ec2 create-security-group \
  --group-name ${ENV_PREFIX}-web-sg \
  --description "Security group for web servers" \
  --vpc-id ${VPC_ID} \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${ENV_PREFIX}-web-sg}]" \
  --query 'GroupId' \
  --output text)

# Add HTTP and HTTPS rules to web security group
aws ec2 authorize-security-group-ingress \
  --group-id ${WEB_SG_ID} \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id ${WEB_SG_ID} \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Create application server security group
APP_SG_ID=$(aws ec2 create-security-group \
  --group-name ${ENV_PREFIX}-app-sg \
  --description "Security group for application servers" \
  --vpc-id ${VPC_ID} \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${ENV_PREFIX}-app-sg}]" \
  --query 'GroupId' \
  --output text)

# Add rule to allow traffic from web security group
aws ec2 authorize-security-group-ingress \
  --group-id ${APP_SG_ID} \
  --protocol tcp \
  --port 8080 \
  --source-group ${WEB_SG_ID}

# Create database server security group
DB_SG_ID=$(aws ec2 create-security-group \
  --group-name ${ENV_PREFIX}-db-sg \
  --description "Security group for database servers" \
  --vpc-id ${VPC_ID} \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${ENV_PREFIX}-db-sg}]" \
  --query 'GroupId' \
  --output text)

# Add rule to allow traffic from application security group
aws ec2 authorize-security-group-ingress \
  --group-id ${DB_SG_ID} \
  --protocol tcp \
  --port 3306 \
  --source-group ${APP_SG_ID}
```

## Resource Cleanup

The following commands demonstrate how to clean up all resources created by the VPC setup. Resources must be deleted in the correct order due to dependencies.

```bash
#!/bin/bash
# This script assumes you have the resource IDs from the creation script
# If running separately, you'll need to set these variables manually

# Delete security groups (must be done in reverse dependency order)
aws ec2 delete-security-group --group-id ${DB_SG_ID}
aws ec2 delete-security-group --group-id ${APP_SG_ID}
aws ec2 delete-security-group --group-id ${WEB_SG_ID}

# Delete route table associations
aws ec2 disassociate-route-table --association-id ${PUBLIC_SUBNET1_ASSOC_ID}
aws ec2 disassociate-route-table --association-id ${PUBLIC_SUBNET2_ASSOC_ID}
aws ec2 disassociate-route-table --association-id ${PRIVATE_SUBNET1_ASSOC_ID}
aws ec2 disassociate-route-table --association-id ${PRIVATE_SUBNET2_ASSOC_ID}

# Delete route tables
aws ec2 delete-route-table --route-table-id ${PRIVATE_RTB_ID}
aws ec2 delete-route-table --route-table-id ${PUBLIC_RTB_ID}

# Delete NAT Gateway (this can take a few minutes)
aws ec2 delete-nat-gateway --nat-gateway-id ${NAT_GW_ID}

# Wait for NAT Gateway to be deleted
aws ec2 wait nat-gateway-deleted --nat-gateway-ids ${NAT_GW_ID}

# Release Elastic IP
aws ec2 release-address --allocation-id ${EIP_ALLOC_ID}

# Detach and delete Internet Gateway
aws ec2 detach-internet-gateway --internet-gateway-id ${IGW_ID} --vpc-id ${VPC_ID}
aws ec2 delete-internet-gateway --internet-gateway-id ${IGW_ID}

# Delete subnets
aws ec2 delete-subnet --subnet-id ${PUBLIC_SUBNET1_ID}
aws ec2 delete-subnet --subnet-id ${PUBLIC_SUBNET2_ID}
aws ec2 delete-subnet --subnet-id ${PRIVATE_SUBNET1_ID}
aws ec2 delete-subnet --subnet-id ${PRIVATE_SUBNET2_ID}

# Delete VPC
aws ec2 delete-vpc --vpc-id ${VPC_ID}
```

## Alternative Configuration Format

The same VPC architecture can be represented in JSON format:

```json
{
  "vpc": {
    "name": "dev-tutorial-vpc",
    "region": "us-east-1",
    "cidr_block": "10.0.0.0/16"
  },
  "internet_gateway": {
    "type": "ingress"
  },
  "nat_gateways": {
    "nat-az1": {
      "subnet": "public-az1",
      "eips": ["nat-az1-eip1"]
    }
  },
  "subnets": [
    {
      "name": "public-az1",
      "az_id": 1,
      "ipv4": {"size": "/24"},
      "route_table": "public"
    },
    {
      "name": "private-az1",
      "az_id": 1,
      "ipv4": {"size": "/24"},
      "route_table": "private"
    },
    {
      "name": "public-az2",
      "az_id": 2,
      "ipv4": {"size": "/24"},
      "route_table": "public"
    },
    {
      "name": "private-az2",
      "az_id": 2,
      "ipv4": {"size": "/24"},
      "route_table": "private"
    }
  ],
  "route_tables": {
    "public": {
      "routes": [
        {"dst": "0.0.0.0/0", "next_hop": "@igw"}
      ]
    },
    "private": {
      "routes": [
        {"dst": "0.0.0.0/0", "next_hop": "@nat-az1"}
      ]
    }
  }
}
```

## Security Considerations
- This architecture isolates resources that don't need direct internet access in private subnets
- NAT Gateway provides outbound internet access for private resources
- Security groups should be configured with least privilege access
- Network ACLs can provide an additional layer of security
- Consider using VPC Flow Logs to monitor network traffic

## Cost Considerations
- NAT Gateways incur hourly charges and data processing fees
- Using a single NAT Gateway reduces costs but introduces a single point of failure
- Elastic IPs attached to NAT Gateways are free, but unattached Elastic IPs incur charges
- VPC Flow Logs will incur additional charges if enabled

## High Availability Considerations
- This architecture uses multiple AZs for redundancy
- For production environments, consider using a NAT Gateway in each AZ
- Critical resources should be deployed across multiple AZs
- For production workloads, consider deploying resources in at least three AZs

## Scalability Considerations
- The CIDR block allocation allows for future expansion
- Consider using Transit Gateway for connecting multiple VPCs if your architecture grows
- For large-scale deployments, implement a consistent CIDR allocation strategy across all VPCs
