# Collect examples

read the input topic, which includes the identifier and "1-input-topic" in the filename. 

get the full list of API commands for the service, and general information about the service, by running aws <service-name> help. note that the service name might not match the service name used in the input tutorial. some service APIs are bundled together. For example, EC2 has APIs for autoscaling, VPC, and elastic block store, in addition to EC2 instance APIs. reference the documentation if you can't find the right service name.

## command inventory
save a list of the commands returned by the help command to a file named 1-commands.md.

## copy examples
read the AWS CLI examples for the service API actions from the AWS CLI source repository. check the user directory for the aws-cli repo. If it is there, copy the examples folder for the service into the working directory like this: cp -r ~/aws-cli/awscli/examples/<service-name>.  

## generate workflow
determine which CLI commands can be run to accomplish each of the steps in the tutorial. use the CLI examples and API names as a reference point. if there aren't examples the correspond to a step, determine which API needs to be used and refer to its API documentation to figure out what command you need to run.

create a CLI workflow document, cli-workflow.md as an example. each section in the workflow document lists API commands that correspond to a section in the input tutorial. there might not be a 1:1 relationship between actions that the user takes in the tutorial and CLI commands. figure out the intent of the tutorial step and determine which CLI commands are necessary to accomplish it. name this doc 1-cli-workflow.md.
