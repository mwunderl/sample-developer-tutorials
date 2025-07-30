# AWS Developer Tutorials Inventory

This directory contains a collection of AWS CLI tutorials and scripts for various AWS services. Each tutorial demonstrates a specific use case and provides step-by-step guidance on using AWS services through the command line.

## Tutorial Inventory

| Tutorial ID | Service | Use Case | Description |
|-------------|---------|----------|-------------|
| 001 | Amazon Lightsail | Getting Started | Create and manage a Lightsail instance |
| 002 | Amazon VPC | Getting Started | Set up a basic Virtual Private Cloud |
| 003 | Amazon S3 | Getting Started | Create buckets and manage objects in S3 |
| 004 | AWS Cloud Map | Custom Attributes | Configure Cloud Map with custom attributes |
| 005 | Amazon CloudFront | Getting Started | Set up a CloudFront distribution |
| 007 | Amazon Chime SDK | Routing Calls | Set up call routing with Chime SDK |
| 008 | Amazon VPC | Private Servers | Configure private servers in a VPC |
| 009 | Amazon VPC | IPAM | Set up IP Address Manager for VPC |
| 010 | AWS Cloud Map | Service Discovery | Implement service discovery with Cloud Map |
| 011 | AWS Batch | Fargate | Run batch jobs with AWS Fargate |
| 012 | AWS Transit Gateway | Getting Started | Set up and configure Transit Gateway |

## Using These Tutorials

Each tutorial folder contains:

1. A shell script (`.sh`) that implements the use case
2. A tutorial (`.md`) that explains the use case and how to use the script
3. Supporting files for documentation and reference

To use a tutorial:

1. Navigate to the specific tutorial folder
2. Read the tutorial markdown file for instructions
3. Make the script executable: `chmod +x XXX-service-usecase-2-cli-script.sh`
4. Run the script: `./XXX-service-usecase-2-cli-script.sh`

## Contributing

To contribute a new tutorial, please follow the instructions in the `/instra/tutorial-gen` folder.
