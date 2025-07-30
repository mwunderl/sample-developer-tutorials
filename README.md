# AWS Developer Tutorials

A collection of AWS CLI scripts and tutorials for common AWS service use cases, designed to help developers quickly get started with AWS services through the command line.

## Overview

This repository contains AWS CLI scripts and tutorials that demonstrate how to use AWS services through the command line interface. The scripts are designed to be interactive, handle errors, and clean up resources after use. The tutorials provide step-by-step guidance on how to use the scripts and understand the underlying AWS services.

These resources serve three main purposes:

1. **Running scripts**: Execute ready-made scripts to quickly set up and explore AWS services
2. **Reading tutorials**: Learn how AWS services work through detailed tutorials
3. **Generating new scripts**: Use Amazon Q Developer CLI to create new scripts for additional use cases

## Repository structure

- `/tuts`: Contains all tutorials and scripts, organized by use case
- `/instra`: Contains instructions for generating new tutorials and scripts

Each tutorial folder follows a naming convention of `XXX-service-usecase` where XXX is a three-digit number, and contains:

- A shell script (`.sh`) that implements the use case
- A tutorial (`.md`) that explains the use case and how to use the script
- Supporting files for documentation and reference

## Running scripts

To run an existing script:

1. Clone this repository or download the specific script you need
2. Make the script executable: `chmod +x script-name.sh`
3. Run the script: `./script-name.sh`

The scripts are interactive and will:
- Prompt for necessary inputs
- Create AWS resources
- Show the results of operations
- Track created resources
- Offer to clean up resources when done

## Reading tutorials

Each script comes with a detailed tutorial that explains:
- The AWS service and use case
- Prerequisites and setup
- Step-by-step walkthrough of the script's operations
- Explanation of key AWS CLI commands and parameters
- Best practices and considerations

To read a tutorial, open the corresponding markdown file in the same folder as the script.

## Generating new scripts

You can use Amazon Q Developer CLI to generate new scripts based on:

1. **Existing scripts**: Use an existing script as a template
2. **Documentation topics**: Generate a script from AWS documentation

### Using existing scripts as templates

```bash
# Example: Generate a script for IPAM setup using an existing script
q "Generate a script to set up IPAM for my VPC. Use the following script as an example: 009-vpc-ipam-gs.sh"
```

### Generating from documentation

```bash
# Example: Generate a script from AWS Payment Cryptography documentation
q "read the instructions in the ../../instra/tutorial-gen folder and follow them in order, using this topic: https://docs.aws.amazon.com/payment-cryptography/latest/userguide/getting-started.html when instructed to run the script in step 2b, it's ok to actually run the script and create resources. this is part of the process. when you generate the script, be careful to check required options and option names for each command."
```

## Prerequisites

- AWS CLI installed and configured with appropriate credentials
- Bash shell environment
- Appropriate AWS permissions for the services used in each script

## Contributing

We welcome contributions to expand the collection of tutorials and scripts. To contribute:

1. **Create a new folder** in the `/tuts` directory following the naming convention: `XXX-service-usecase`
2. **Follow the tutorial generation instructions** in the `/instra/tutorial-gen` folder
3. **Submit only the final tutorial and script files** after testing and validation

### Folder structure for new contributions

```
/tuts/XXX-service-usecase/
├── XXX-service-usecase-script.sh    # The executable script
├── XXX-service-usecase-tutorial.md      # The tutorial documentation
└── XXX-service-usecase-README.md          # Brief description of the use case
```

## Cleanup

All scripts include resource tracking and cleanup functionality. After provisioning and interacting with resources, the scripts provide a list of resources and ask if you want to clean them up. If a script encounters an issue, it attempts to clean up resources that it created before the error.

## License

This project is licensed under the MIT-0 License. See the LICENSE file for details.
