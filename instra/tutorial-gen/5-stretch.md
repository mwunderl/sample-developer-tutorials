# additional opportunities

Consider whether there are any opportunities missed by the tutorial. Document these in 5-stretch.md but don't modify the tutorial or script at this time.

## CloudFormation template

If there are resources listed as prerequisites, create a CloudFormation template that provisions these resources. Name the file prereqs.yaml and provide a short CLI script named prereqs.sh that deploys a CloudFormation stack with the template. This will simplify setting up a test environment for the tutorial, and we might choose to provide this template to readers as well.

If the tutorial creates resources, and then has users interact with those resources, then managing resources might not be the main focus of the tutorial. If the focus is the runtime or dataplane operations, and managing resources is secondary, create a second cloudformation template, resources.yaml, with accompanying script, that handles the resource management. We might choose to provide this as a shortcut for readers who prefer to manage resources with CloudFormation, the CDK, or another method.

## Permissions policies

Create a least-privilege permissions policy that only grants permission to call the API actions required for the tutorial. Use conditions where appropriate to restrict access to just the resources created when following the tutorial. We might choose to test tutorials and scripts using these permissions and publishing the policies as reference material.