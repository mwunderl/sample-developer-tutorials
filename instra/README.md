# Instructions

You can use the instructions in this folder to generate new scripts and tutorials for the AWS CLI based on existing content. The instructions use existing AWS Documentation and CLI examples to generate working scripts for the AWS CLI, even if there isn't a specific example for your use case.

Choose a use case or scenario for one or more services. Find an existing documentation topic for the use case. The content doesn't need to reference the AWS CLI directly, but it helps if you have CLI examples in the AWS CLI GitHub repository.

## Prerequisites

To generate tutorials, you need the following tools.

- The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
- The [Q CLI](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/command-line.html)
- The [AWS Docs MCP server](https://awslabs.github.io/mcp/servers/aws-documentation-mcp-server/)
- The [AWS CLI GitHub repository](https://github.com/aws/aws-cli/tree/develop/awscli)

The AWS CLI repo has examples for AWS CLI commands. The instructions direct Q to find these in the repo in your user directory. If you clone the repo somewhere else, indicate this in the prompt.

## Create a folder

Create a new folder in the [tuts](../tuts) directory for your use case, following the naming convention.

   ```
   001-lightsail-gs
   002-vpc-gs
   ```

Use the next available number after the highest number in use. Indicate the service name or names and the use case in the folder name. You can use `gs` for getting started use cases.

## Prompt

Open Q chat in the new folder. Pass the URL to an existing topic with some additional instructions

> read the instructions in the ../../instra/tutorial-gen folder and follow them in order, using this topic: https://docs.aws.amazon.com/payment-cryptography/latest/userguide/getting-started.html when instructed to run the script in step 2b, it's ok to actually run the script and create resources. this is part of the process. when you generate the script, be careful to check required options and option names for each command."

Q tends to not run the script unless you specify this in the prompt. Q processes the instructions in order to generate a script, test it, simplify it, and generate and revise a tutorial. The process can take 20-40 minutes depending on the available documentation and examples. 

## Pull requests

The tool generates a lot of artifacts including intermediate script revisions that generate errors. Submit a pull request with only the final revision of the script and tutorial. Rename these after the use case follow this convention.
torial. Rename these after the use case follow this convention.

```
├── 001-lightsail-gs
│   ├── README.md
│   ├── lightsail-gs.md
│   └── lightsail-gs.sh
```

## Testing

All new scripts and tutorials need to be tested by the author. Attach a log from a successful test run to the pull request.
