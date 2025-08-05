# AWS Developer Tutorials Inventory

This directory contains a collection of AWS CLI tutorials and scripts for various AWS services. Each tutorial demonstrates a specific use case and provides step-by-step guidance on using AWS services through the command line.

## Tutorial Inventory

| Tutorial ID | Service | Use Case | Description |
|-------------|---------|----------|-------------|
| 001 | Amazon Lightsail | Getting Started | Get started with Amazon Lightsail using the AWS CLI |
| 002 | Amazon VPC | Getting Started | Get started with Amazon VPC using the AWS CLI |
| 003 | Amazon S3 | Getting Started | Get started with Amazon S3 using the AWS CLI |
| 004 | AWS Cloud Map | Custom Attributes | Configure AWS Cloud Map with custom attributes |
| 005 | Amazon CloudFront | Getting Started | Set up and configure Amazon CloudFront distributions |
| 007 | Amazon Chime SDK | Routing Calls | Set up call routing with Amazon Chime SDK |
| 008 | Amazon VPC | Private Servers | Configure private servers in Amazon VPC |
| 009 | Amazon VPC | IPAM | Set up IP Address Manager (IPAM) for Amazon VPC |
| 010 | AWS Cloud Map | Service Discovery | Implement service discovery with AWS Cloud Map |
| 011 | AWS Batch | Fargate | Run batch jobs with AWS Batch and Fargate |
| 012 | AWS Transit Gateway | Getting Started | Set up and configure AWS Transit Gateway |
| 013 | Amazon EC2 | Basics | Basic operations for working with Amazon EC2 instances |
| 015 | Amazon VPC | Peering | Set up VPC peering connections between VPCs |
| 016 | Amazon OpenSearch Service | Getting Started | Get started with Amazon OpenSearch Service |
| 018 | Amazon ECS | EC2 | Get started with Amazon ECS using EC2 instances |
| 019 | AWS Lambda | Getting Started | Comprehensive introduction to AWS Lambda serverless functions |
| 020 | Amazon EBS | Getting Started Volumes | Create and manage Amazon EBS volumes with EC2 instances |
| 021 | AWS CloudFormation | Getting Started | Introduction to AWS CloudFormation infrastructure as code |
| 022 | Amazon EBS | Intermediate | Intermediate Amazon EBS concepts and operations |
| 024 | AWS Glue | Getting Started | Get started with AWS Glue using the AWS CLI |
| 025 | Amazon DocumentDB | Getting Started | Get started with Amazon DocumentDB MongoDB-compatible database |
| 027 | Amazon Connect | Getting Started | Get started with Amazon Connect using the AWS CLI |
| 028 | Amazon SageMaker | Feature Store | Use Amazon SageMaker Feature Store for ML features |
| 030 | AWS Marketplace | Buyer Getting Started | Get started as a buyer on AWS Marketplace |
| 031 | Amazon CloudWatch | Dynamic Dashboards | Create and manage dynamic dashboards in CloudWatch |
| 032 | Amazon CloudWatch | Streams | Work with Amazon CloudWatch log streams |
| 033 | Amazon SES | Getting Started | Get started with Amazon Simple Email Service |
| 034 | Amazon EKS | Getting Started | Comprehensive introduction to Amazon EKS |
| 035 | Amazon WorkSpaces | Personal | Set up and manage personal Amazon WorkSpaces |
| 036 | Amazon RDS | Getting Started | Get started with Amazon RDS managed databases |
| 037 | Amazon EMR | Getting Started | Get started with Amazon EMR for big data processing |
| 038 | Amazon Redshift | Serverless | Set up and use Amazon Redshift Serverless |
| 039 | Amazon Redshift | Provisioned | Set up Amazon Redshift provisioned clusters |
| 042 | Amazon Q Business | Anonymous Access | Configure anonymous access for Amazon Q Business |
| 043 | Amazon MQ | Getting Started | Comprehensive introduction to Amazon MQ message brokers |
| 044 | Amazon Managed Grafana | Getting Started | Introduction to Amazon Managed Grafana |
| 045 | AWS IAM Identity Center | Getting Started | Introduction to AWS IAM Identity Center (SSO) |
| 046 | AWS Systems Manager | Getting Started | Get started with AWS Systems Manager |
| 047 | AWS Network Firewall | Getting Started | Get started with AWS Network Firewall |
| 048 | Amazon SNS | Getting Started | Get started with Amazon Simple Notification Service |
| 049 | AWS End User Messaging | Getting Started | Get started with AWS End User Messaging |
| 051 | AWS Direct Connect | Getting Started | Introduction to AWS Direct Connect |
| 052 | AWS WAF | Getting Started | Introduction to AWS WAF (Web Application Firewall) |
| 053 | AWS Config | Getting Started | Introduction to AWS Config |
| 054 | Amazon Kinesis Video Streams | Getting Started | Get started with Amazon Kinesis Video Streams |
| 055 | Amazon VPC Lattice | Getting Started | Create and manage Amazon VPC Lattice service networks |
| 057 | Amazon MSK | Getting Started | Introduction to Amazon Managed Streaming for Apache Kafka |
| 058 | Elastic Load Balancing | Getting Started | Create and configure Application Load Balancers |
| 059 | Amazon DataZone | Getting Started | Introduction to Amazon DataZone |
| 061 | Amazon Athena | Getting Started | Get started with Amazon Athena |
| 062 | AWS Support | Getting Started | Get started with AWS Support |
| 063 | AWS IoT Core | Getting Started | Get started with AWS IoT Core |
| 064 | Amazon Neptune | Getting Started | Get started with Amazon Neptune |
| 065 | Amazon ElastiCache | Getting Started | Get started with Amazon ElastiCache |
| 066 | Amazon Cognito | Getting Started | Get started with Amazon Cognito |
| 067 | AWS Payment Cryptography | Getting Started | Get started with AWS Payment Cryptography |
| 069 | AWS Fault Injection Service | Getting Started | Use AWS Fault Injection Service for chaos engineering |
| 070 | Amazon DynamoDB | Getting Started | Get started with Amazon DynamoDB NoSQL database |
| 073 | AWS Secrets Manager | Getting Started | Introduction to AWS Secrets Manager |
| 074 | Amazon Textract | Getting Started | Get started with Amazon Textract document analysis |
| 075 | AWS Database Migration Service | Getting Started | Introduction to AWS Database Migration Service |
| 077 | AWS Account Management | Getting Started | Get started with AWS Account Management |
| 078 | Amazon ECR | Getting Started | Create and manage Docker container images with Amazon ECR |
| 079 | AWS IoT Device Defender | Getting Started | Introduction to AWS IoT Device Defender |
| 080 | AWS Step Functions | Getting Started | Create and run serverless workflows with AWS Step Functions |
| 081 | AWS Elemental MediaConnect | Getting Started | Introduction to AWS Elemental MediaConnect |
| 082 | Amazon Polly | Getting Started | Get started with Amazon Polly text-to-speech service |
| 085 | Amazon ECS | Service Connect | Set up service-to-service communication in Amazon ECS |
| 086 | Amazon ECS | Fargate Linux | Deploy containerized applications on Amazon ECS using Fargate |

## Using These Tutorials

Each tutorial folder contains:

1. A shell script (`.sh`) that implements the use case
2. A tutorial (`.md`) that explains the use case and how to use the script
3. Supporting files for documentation and reference

To use a tutorial:

1. Navigate to the specific tutorial folder
2. Read the tutorial markdown file for instructions
3. Make the script executable: `chmod +x script-name.sh`
4. Run the script: `./script-name.sh`

## Tutorial Categories

The tutorials are organized by AWS service categories:

**Compute & Containers**
- EC2 (013), Lambda (019), Batch (011), EKS (034), ECS (018, 085, 086), Lightsail (001)

**Storage & Databases**
- S3 (003), EBS (020, 022), RDS (036), DynamoDB (070), DocumentDB (025), Neptune (064), ElastiCache (065), Redshift (038, 039)

**Networking & Content Delivery**
- VPC (002, 008, 009, 015), CloudFront (005), Transit Gateway (012), Direct Connect (051), VPC Lattice (055), Network Firewall (047), Elastic Load Balancing (058)

**Analytics & Big Data**
- EMR (037), Glue (024), Athena (061), Kinesis Video Streams (054), MSK (057), DataZone (059)

**Machine Learning & AI**
- SageMaker (028), Textract (074), Polly (082)

**Security & Identity**
- IAM Identity Center (045), Secrets Manager (073), Config (053), WAF (052), Payment Cryptography (067), Cognito (066)

**Monitoring & Management**
- CloudWatch (031, 032), Systems Manager (046), CloudFormation (021), Support (062), Account Management (077)

**Application Integration**
- SNS (048), SES (033), MQ (043), Cloud Map (004, 010), Step Functions (080)

**IoT & Edge**
- IoT Core (063), IoT Device Defender (079)

**Media & Communications**
- Chime SDK (007), Connect (027), Elemental MediaConnect (081)

**Developer Tools & Services**
- Q Business (042), End User Messaging (049), Marketplace (030), ECR (078)

**Other Services**
- WorkSpaces (035), Managed Grafana (044), Fault Injection Service (069), Database Migration Service (075), OpenSearch Service (016)

## Contributing

To create a new tutorial, see [instra/README.md](../instra/README.md).
