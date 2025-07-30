# create a script
based on the cli workflow doc 1-cli-workflow.md, generate a shell script that runs all of the included CLI commands. Use the AWS CLI --query operator and --text output flag as necessary to capture resource IDs, secrets, and other information from command output. keep the script as simple as possible. don't create redundant resources or use options that are not relevant to the use case. name this script 2-cli-script.sh. make it executable. 

## portability
to keep the script portable, avoid using the region option in commands. use random names for resources that require a unique name. if the script uses S3 buckets, generate a random 12 digit hex identifier for the bucket an prepend it with the API name of the service (all lowercase). use this as the bucket name.

don't use jq or other commands that are not available by default in linux systems. don't use the --cli-binary-format option as this is not available to AWS CLI v1 users. when you need to read a parameter value from a file, use the cat command in a subshell like this: $(cat config.json)

## security
apply security best practices to all API operations when possible. do not create resources that are publicly accessible. do not create security policies or network rules that have open permissions, such as resource identifiers with wildcards, or IP address ranges. use least privilege permissions at all times, or call out specifically that there is a requirement to use something less secure. note in comments when anything in the script can't be used in production environments due to security or scaling concerns.

do not every hardcode passwords or keys. If you need a database password, generate a new secure password and store it in AWS Secrets Manager. Retrieve the password from secrets manager when you need to use it to access resources. don't create IAM users. Assume that the user already has AWS credentials configured in their development environment. 

## cleanup
keep track of all resources that you create and ensure that all resources that you create are also cleaned up. before deleting any resources, pause the script and show a list of all of the resources that it created, so that the user can confirm. 

When prompting for user input (especially for cleanup confirmation):
1. Use separate `echo` statements with visual formatting (like separator lines) instead of `read -p`
2. Use a plain `read -r` command to capture input
3. Format the prompt to be clearly visible, for example:
```bash
echo ""
echo "==========================================="
echo "CLEANUP CONFIRMATION"
echo "==========================================="
echo "Do you want to clean up all created resources? (y/n): "
read -r CLEANUP_CHOICE
```
This ensures the prompt is properly displayed across different terminal environments.

## error handling
handle all errors within the script, and log all commands and outputs to a log file. when you capture the output of a command in a variable, check the output for errors and handle them before processing the output. use case insensitive pattern matching to get all varations of the word error. whether an error is caught or not, print the output of all commands. 

if the script encounters an error, print a list of all of the resources created prior to the error, and attempt to delete them in the reverse order of when you created them. when resources depend on one another, use wait commands to confirm that the first resource is ready before creating the second one, and the second one is deleted before deleting the first one.
