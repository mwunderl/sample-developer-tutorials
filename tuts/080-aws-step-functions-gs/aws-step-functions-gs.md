# Getting started with AWS Step Functions using the AWS CLI

This tutorial guides you through creating and running your first AWS Step Functions state machine using the AWS Command Line Interface (AWS CLI). You'll learn how to create a simple workflow, execute it with different inputs, and integrate with Amazon Comprehend for sentiment analysis.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Basic understanding of JSON and state machines.
3. [Sufficient permissions](https://docs.aws.amazon.com/step-functions/latest/dg/security_iam_service-with-iam.html) to create and manage Step Functions resources in your AWS account.
4. Approximately 20-30 minutes to complete the tutorial.

To run the tutorial successfully, set up the AWS CLI to use an AWS Region that Amazon Comprehend is available in. For more information, see [Amazon Comprehend endpoints and quotas](https://docs.aws.amazon.com/general/latest/gr/comprehend.html).

**Cost information**: The resources created in this tutorial will incur minimal costs (less than $0.01) if you follow the cleanup instructions. Step Functions charges $0.025 per 1,000 state transitions for Standard workflows, and Amazon Comprehend charges $0.0001 per sentiment analysis request.

## Create an IAM role for Step Functions

First, you need to create an IAM role that allows Step Functions to execute. This role will be used by your state machine to access AWS services.

**Create a trust policy document**

Create a JSON file that defines the trust relationship for the Step Functions service:

```bash
cat > step-functions-trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
```

This trust policy allows the Step Functions service to assume this role.

**Create the IAM role**

Now, create the IAM role using the trust policy:

```bash
aws iam create-role \
  --role-name StepFunctionsHelloWorldRole \
  --assume-role-policy-document file://step-functions-trust-policy.json
```

The output will include details about the newly created role, including its ARN (Amazon Resource Name).

**Create a policy for Step Functions**

Create a policy that grants permissions for Step Functions operations:

```bash
cat > stepfunctions-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "states:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name StepFunctionsPolicy \
  --policy-document file://stepfunctions-policy.json
```

**Attach the policy to the role**

Attach the policy to the role you created:

```bash
POLICY_ARN=$(aws iam list-policies \
  --query "Policies[?PolicyName=='StepFunctionsPolicy'].Arn" \
  --output text)

aws iam attach-role-policy \
  --role-name StepFunctionsHelloWorldRole \
  --policy-arn $POLICY_ARN
```

This attaches the policy to the role, granting the necessary permissions.

## Create your first state machine

A state machine is a workflow defined using Amazon States Language (ASL), a JSON-based language. Let's create a simple "Hello World" state machine.

**Define the state machine**

Create a JSON file containing the state machine definition:

```bash
cat > hello-world.json << 'EOF'
{
  "Comment": "A Hello World example of the Amazon States Language using a Pass state",
  "StartAt": "SetVariables",
  "States": {
    "SetVariables": {
      "Type": "Pass",
      "Result": {
        "IsHelloWorldExample": true,
        "ExecutionWaitTimeInSeconds": 10
      },
      "Next": "IsHelloWorldExample"
    },
    "IsHelloWorldExample": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.IsHelloWorldExample",
          "BooleanEquals": true,
          "Next": "WaitState"
        }
      ],
      "Default": "FailState"
    },
    "WaitState": {
      "Type": "Wait",
      "SecondsPath": "$.ExecutionWaitTimeInSeconds",
      "Next": "ParallelProcessing"
    },
    "ParallelProcessing": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "Process1",
          "States": {
            "Process1": {
              "Type": "Pass",
              "Result": {
                "message": "Processing task 1"
              },
              "End": true
            }
          }
        },
        {
          "StartAt": "Process2",
          "States": {
            "Process2": {
              "Type": "Pass",
              "Result": {
                "message": "Processing task 2"
              },
              "End": true
            }
          }
        }
      ],
      "Next": "CheckpointState"
    },
    "CheckpointState": {
      "Type": "Pass",
      "Result": {
        "CheckpointMessage": "Workflow completed successfully!"
      },
      "Next": "SuccessState"
    },
    "SuccessState": {
      "Type": "Succeed"
    },
    "FailState": {
      "Type": "Fail",
      "Error": "NotHelloWorldExample",
      "Cause": "The IsHelloWorldExample value was false"
    }
  }
}
EOF
```

This state machine includes several state types:
- A **Pass state** that sets initial variables
- A **Choice state** that makes a decision based on input
- A **Wait state** that pauses execution
- A **Parallel state** that runs tasks concurrently
- **Succeed** and **Fail** states that end the execution

**Create the state machine**

Now, create the state machine using the AWS CLI:

```bash
ROLE_ARN=$(aws iam get-role \
  --role-name StepFunctionsHelloWorldRole \
  --query 'Role.Arn' \
  --output text)

aws stepfunctions create-state-machine \
  --name MyFirstStateMachine \
  --definition file://hello-world.json \
  --role-arn $ROLE_ARN \
  --type STANDARD
```

The output will include the ARN of your new state machine. Save this ARN for later use.

## Start your state machine execution

Now that you've created a state machine, let's run it.

**Start the execution**

Start an execution of your state machine:

```bash
STATE_MACHINE_ARN=$(aws stepfunctions list-state-machines \
  --query "stateMachines[?name=='MyFirstStateMachine'].stateMachineArn" \
  --output text)

aws stepfunctions start-execution \
  --state-machine-arn $STATE_MACHINE_ARN \
  --name hello001
```

The output will include the ARN of the execution and its start time.

**Check the execution status**

After waiting a few seconds for the execution to complete, check its status:

```bash
EXECUTION_ARN=$(aws stepfunctions list-executions \
  --state-machine-arn $STATE_MACHINE_ARN \
  --query "executions[?name=='hello001'].executionArn" \
  --output text)

aws stepfunctions describe-execution \
  --execution-arn $EXECUTION_ARN
```

The output will show details about the execution, including its status, input, and output. You should see that the execution has succeeded and the output contains the checkpoint message.

## Process external input

Let's modify the state machine to process external input instead of using hardcoded values.

**Update the state machine definition**

Create an updated state machine definition:

```bash
cat > updated-hello-world.json << 'EOF'
{
  "Comment": "A Hello World example of the Amazon States Language using a Pass state",
  "StartAt": "SetVariables",
  "States": {
    "SetVariables": {
      "Type": "Pass",
      "Parameters": {
        "IsHelloWorldExample.$": "$.hello_world",
        "ExecutionWaitTimeInSeconds.$": "$.wait"
      },
      "Next": "IsHelloWorldExample"
    },
    "IsHelloWorldExample": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.IsHelloWorldExample",
          "BooleanEquals": true,
          "Next": "WaitState"
        }
      ],
      "Default": "FailState"
    },
    "WaitState": {
      "Type": "Wait",
      "SecondsPath": "$.ExecutionWaitTimeInSeconds",
      "Next": "ParallelProcessing"
    },
    "ParallelProcessing": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "Process1",
          "States": {
            "Process1": {
              "Type": "Pass",
              "Result": {
                "message": "Processing task 1"
              },
              "End": true
            }
          }
        },
        {
          "StartAt": "Process2",
          "States": {
            "Process2": {
              "Type": "Pass",
              "Result": {
                "message": "Processing task 2"
              },
              "End": true
            }
          }
        }
      ],
      "Next": "CheckpointState"
    },
    "CheckpointState": {
      "Type": "Pass",
      "Result": {
        "CheckpointMessage": "Workflow completed successfully!"
      },
      "Next": "SuccessState"
    },
    "SuccessState": {
      "Type": "Succeed"
    },
    "FailState": {
      "Type": "Fail",
      "Error": "NotHelloWorldExample",
      "Cause": "The IsHelloWorldExample value was false"
    }
  }
}
EOF
```

The key difference in this updated definition is in the `SetVariables` state, which now uses the `Parameters` field with JSONPath references to pull values from the input.

**Update the state machine**

Update your state machine with the new definition:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn $STATE_MACHINE_ARN \
  --definition file://updated-hello-world.json \
  --role-arn $ROLE_ARN
```

**Run the state machine with input**

Create an input file:

```bash
cat > input.json << 'EOF'
{
  "wait": 5,
  "hello_world": true
}
EOF
```

Start an execution with this input:

```bash
aws stepfunctions start-execution \
  --state-machine-arn $STATE_MACHINE_ARN \
  --name hello002 \
  --input file://input.json
```

After waiting a few seconds, check the execution status:

```bash
EXECUTION2_ARN=$(aws stepfunctions list-executions \
  --state-machine-arn $STATE_MACHINE_ARN \
  --query "executions[?name=='hello002'].executionArn" \
  --output text)

aws stepfunctions describe-execution \
  --execution-arn $EXECUTION2_ARN
```

You'll see that the execution succeeded and used the input values you provided.

## Integrate Amazon Comprehend for sentiment analysis

Now, let's enhance our state machine by integrating with Amazon Comprehend to perform sentiment analysis on text input.

**Create a policy for Amazon Comprehend access**

First, create a policy that allows access to Amazon Comprehend:

```bash
cat > comprehend-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "comprehend:DetectSentiment"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name DetectSentimentPolicy \
  --policy-document file://comprehend-policy.json
```

**Attach the policy to the role**

Attach the Comprehend policy to your Step Functions role:

```bash
COMPREHEND_POLICY_ARN=$(aws iam list-policies \
  --query "Policies[?PolicyName=='DetectSentimentPolicy'].Arn" \
  --output text)

aws iam attach-role-policy \
  --role-name StepFunctionsHelloWorldRole \
  --policy-arn $COMPREHEND_POLICY_ARN
```

**Update the state machine with sentiment analysis**

Create an updated state machine definition that includes sentiment analysis:

```bash
cat > sentiment-hello-world.json << 'EOF'
{
  "Comment": "A Hello World example with sentiment analysis",
  "StartAt": "SetVariables",
  "States": {
    "SetVariables": {
      "Type": "Pass",
      "Parameters": {
        "IsHelloWorldExample.$": "$.hello_world",
        "ExecutionWaitTimeInSeconds.$": "$.wait",
        "FeedbackComment.$": "$.feedback_comment"
      },
      "Next": "IsHelloWorldExample"
    },
    "IsHelloWorldExample": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.IsHelloWorldExample",
          "BooleanEquals": true,
          "Next": "WaitState"
        }
      ],
      "Default": "DetectSentiment"
    },
    "WaitState": {
      "Type": "Wait",
      "SecondsPath": "$.ExecutionWaitTimeInSeconds",
      "Next": "ParallelProcessing"
    },
    "ParallelProcessing": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "Process1",
          "States": {
            "Process1": {
              "Type": "Pass",
              "Result": {
                "message": "Processing task 1"
              },
              "End": true
            }
          }
        },
        {
          "StartAt": "Process2",
          "States": {
            "Process2": {
              "Type": "Pass",
              "Result": {
                "message": "Processing task 2"
              },
              "End": true
            }
          }
        }
      ],
      "Next": "CheckpointState"
    },
    "CheckpointState": {
      "Type": "Pass",
      "Result": {
        "CheckpointMessage": "Workflow completed successfully!"
      },
      "Next": "SuccessState"
    },
    "DetectSentiment": {
      "Type": "Task",
      "Resource": "arn:aws:states:::aws-sdk:comprehend:detectSentiment",
      "Parameters": {
        "LanguageCode": "en",
        "Text.$": "$.FeedbackComment"
      },
      "Next": "SuccessState"
    },
    "SuccessState": {
      "Type": "Succeed"
    }
  }
}
EOF
```

This updated definition adds a new `DetectSentiment` task state that uses the Amazon Comprehend service to analyze the sentiment of text provided in the input.

**Update the state machine**

Update your state machine with the new definition:

```bash
aws stepfunctions update-state-machine \
  --state-machine-arn $STATE_MACHINE_ARN \
  --definition file://sentiment-hello-world.json \
  --role-arn $ROLE_ARN
```

**Run the state machine with sentiment analysis**

Create an input file with a feedback comment:

```bash
cat > sentiment-input.json << 'EOF'
{
  "hello_world": false,
  "wait": 5,
  "feedback_comment": "This getting started with Step Functions workshop is a challenge!"
}
EOF
```

Start an execution with this input:

```bash
aws stepfunctions start-execution \
  --state-machine-arn $STATE_MACHINE_ARN \
  --name hello003 \
  --input file://sentiment-input.json
```

After waiting a few seconds, check the execution status:

```bash
EXECUTION3_ARN=$(aws stepfunctions list-executions \
  --state-machine-arn $STATE_MACHINE_ARN \
  --query "executions[?name=='hello003'].executionArn" \
  --output text)

aws stepfunctions describe-execution \
  --execution-arn $EXECUTION3_ARN
```

The output will show the sentiment analysis results, including the detected sentiment (POSITIVE, NEGATIVE, NEUTRAL, or MIXED) and confidence scores.

## Clean up resources

When you're finished with this tutorial, clean up the resources to avoid incurring additional charges.

**Delete the state machine**

Delete the state machine you created:

```bash
aws stepfunctions delete-state-machine \
  --state-machine-arn $STATE_MACHINE_ARN
```

**Detach policies from the role**

Detach the policies from the IAM role:

```bash
aws iam detach-role-policy \
  --role-name StepFunctionsHelloWorldRole \
  --policy-arn $COMPREHEND_POLICY_ARN

aws iam detach-role-policy \
  --role-name StepFunctionsHelloWorldRole \
  --policy-arn $POLICY_ARN
```

**Delete the policies**

Delete the policies you created:

```bash
aws iam delete-policy \
  --policy-arn $COMPREHEND_POLICY_ARN

aws iam delete-policy \
  --policy-arn $POLICY_ARN
```

**Delete the role**

Finally, delete the IAM role:

```bash
aws iam delete-role \
  --role-name StepFunctionsHelloWorldRole
```

**Remove temporary files**

Remove the temporary files created during this tutorial:

```bash
rm -f hello-world.json updated-hello-world.json sentiment-hello-world.json step-functions-trust-policy.json comprehend-policy.json stepfunctions-policy.json input.json sentiment-input.json
```
## Going to production

This tutorial demonstrates basic Step Functions functionality for learning purposes. For production environments, consider these additional best practices:

### Security best practices

1. **Least privilege permissions**: The IAM policies in this tutorial use broad permissions. In production, scope permissions to specific resources and actions.

2. **Encryption**: Configure KMS encryption for your state machine data:
   ```bash
   aws stepfunctions create-state-machine --encryption-configuration type=AWS_OWNED_KEY
   ```

3. **Resource tagging**: Add tags to your resources for better organization and access control:
   ```bash
   aws stepfunctions create-state-machine --tags Key=Environment,Value=Production
   ```

### Architecture best practices

1. **Error handling**: Add Retry and Catch states to handle failures gracefully:
   ```json
   "DetectSentiment": {
     "Type": "Task",
     "Resource": "arn:aws:states:::aws-sdk:comprehend:detectSentiment",
     "Retry": [
       {
         "ErrorEquals": ["States.TaskFailed"],
         "IntervalSeconds": 2,
         "MaxAttempts": 3,
         "BackoffRate": 2
       }
     ],
     "Catch": [
       {
         "ErrorEquals": ["States.ALL"],
         "Next": "ErrorHandler"
       }
     ],
     "Next": "SuccessState"
   }
   ```

2. **Logging and monitoring**: Configure CloudWatch Logs and X-Ray tracing for observability.

3. **Workflow type selection**: Choose between Standard and Express workflows based on your performance and cost requirements.

For more information on production best practices, see:
- [AWS Step Functions Best Practices](https://docs.aws.amazon.com/step-functions/latest/dg/sfn-best-practices.html)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [Security Best Practices for AWS Step Functions](https://docs.aws.amazon.com/step-functions/latest/dg/security-best-practices.html)

## Next steps

Now that you've learned the basics of AWS Step Functions, explore these additional topics:

1. [Creating workflows with AWS Step Functions](https://docs.aws.amazon.com/step-functions/latest/dg/creating-workflows.html) - Learn more about creating complex workflows.
2. [AWS Step Functions service integrations](https://docs.aws.amazon.com/step-functions/latest/dg/connect-to-resource.html) - Discover how to integrate with other AWS services.
3. [Error handling in Step Functions](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-error-handling.html) - Learn about error handling strategies.
4. [Step Functions Express Workflows](https://docs.aws.amazon.com/step-functions/latest/dg/concepts-standard-vs-express.html) - Explore high-volume, event-processing workloads.
5. [Step Functions data processing patterns](https://docs.aws.amazon.com/step-functions/latest/dg/service-integration-patterns-data-processing.html) - Learn about common data processing patterns.
