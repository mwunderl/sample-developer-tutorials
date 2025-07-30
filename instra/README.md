# AWS Developer Tutorials - Instructions

This directory contains instructions and resources for generating new AWS CLI tutorials and scripts.

## Overview

The instructions in this directory guide you through the process of creating high-quality AWS CLI tutorials and scripts using Amazon Q Developer CLI. These instructions are designed to help you:

1. Collect information about AWS services and use cases
2. Generate working AWS CLI scripts
3. Create comprehensive tutorials that explain the scripts
4. Validate and improve both scripts and tutorials

## Directory Structure

- `/tutorial-gen`: Step-by-step instructions for generating tutorials and scripts

## Tutorial Generation Process

The tutorial generation process is divided into several steps, each with its own instruction file in the `/tutorial-gen` directory:

1. **Information Collection**
   - Collect documentation topics
   - Gather example CLI commands

2. **Script Creation**
   - Generate an initial script
   - Test and run the script
   - Validate script functionality
   - Simplify and improve the script

3. **Tutorial Creation**
   - Draft a tutorial based on the script
   - Validate tutorial content

4. **Finalization**
   - Address feedback
   - Make final improvements

## Using These Instructions

To generate a new tutorial:

1. Start with the file `0-general-instructions.md` in the `/tutorial-gen` directory
2. Follow the numbered instruction files in sequence
3. Use Amazon Q Developer CLI to assist with each step
4. Place the final tutorial and script in a new folder in the `/tuts` directory

## Example Usage with Amazon Q Developer CLI

```bash
q "read the instructions in the ../../instra/tutorial-gen folder and follow them in order, using this topic: https://docs.aws.amazon.com/payment-cryptography/latest/userguide/getting-started.html when instructed to run the script in step 2b, it's ok to actually run the script and create resources. this is part of the process. when you generate the script, be careful to check required options and option names for each command."
```

This command instructs Amazon Q Developer CLI to:
1. Read the tutorial generation instructions
2. Follow them in order
3. Use the AWS Payment Cryptography getting started guide as the source material
4. Generate and test a script for this service

## Contributing

If you have suggestions for improving the tutorial generation process, please submit them as pull requests or issues in the repository.
