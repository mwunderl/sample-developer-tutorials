# Creating and managing Amazon EBS volumes using the AWS CLI

This tutorial guides you through the process of creating and managing Amazon Elastic Block Store (EBS) volumes using the AWS Command Line Interface (AWS CLI). You'll learn how to create volumes, check their status, attach them to EC2 instances, and clean up resources when you're done.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. Permissions to create and manage EBS volumes and EC2 instances in your AWS account. At minimum, you need the following permissions: `ec2:CreateVolume`, `ec2:DescribeVolumes`, `ec2:AttachVolume`, `ec2:DetachVolume`, and `ec2:DeleteVolume`.
4. At least one running EC2 instance if you want to attach your volume (optional - the script provided with this tutorial can create a test instance for you if needed).

**Time to complete:** Approximately 30 minutes

**Cost:** The resources created in this tutorial will incur charges while they exist. The approximate costs for running the resources for one hour in the US East (N. Virginia) region are:
- Standard gp3 volume (10 GiB): $0.01/hour
- EC2 t2.micro instance (if created): $0.0116/hour

To avoid ongoing charges, follow the cleanup instructions at the end of the tutorial. For more information about pricing, see [Amazon EBS pricing](https://aws.amazon.com/ebs/pricing/) and [Amazon EC2 pricing](https://aws.amazon.com/ec2/pricing/).

## Automated script option

If you prefer to automate the steps in this tutorial, you can use the provided script. The script creates an EBS volume, optionally creates an EC2 instance if you don't have one available, attaches the volume to the instance, and provides cleanup options.

To run the script:

```bash
./ebs-gs-volumes.sh
```

The script will guide you through the process with interactive prompts. For a more hands-on experience, continue with the manual steps below.

## Create an EBS volume

Amazon EBS provides block-level storage volumes that you can attach to EC2 instances. In this section, you'll create a new EBS volume that you can later attach to an instance.

**Create a basic gp3 volume**

The following command creates a 100 GiB General Purpose SSD (gp3) volume in the specified Availability Zone. The gp3 volume type provides a baseline performance of 3,000 IOPS and 125 MiB/s throughput.

```bash
aws ec2 create-volume \
    --volume-type gp3 \
    --size 100 \
    --region us-east-1 \
    --availability-zone us-east-1a
```

The command returns details about the newly created volume, including its ID, size, type, and state:

```json
{
    "AvailabilityZone": "us-east-1a",
    "Tags": [],
    "Encrypted": false,
    "VolumeType": "gp3",
    "VolumeId": "vol-abcd1234efgh5678i",
    "State": "creating",
    "Iops": 3000,
    "SnapshotId": "",
    "CreateTime": "2025-01-13T10:15:30.000Z",
    "Size": 100,
    "Throughput": 125
}
```

When you create a volume, it starts in the `creating` state and transitions to the `available` state when it's ready to use. Make note of the `VolumeId` as you'll need it for subsequent commands.

**Create a volume with custom performance settings**

If you need higher performance than the gp3 baseline provides, you can specify custom IOPS and throughput values. The following command creates a gp3 volume with 4,000 IOPS and 250 MiB/s throughput:

```bash
aws ec2 create-volume \
    --volume-type gp3 \
    --size 100 \
    --iops 4000 \
    --throughput 250 \
    --region us-east-1 \
    --availability-zone us-east-1a
```

This command returns similar output to the previous one, but with the specified IOPS and throughput values:

```json
{
    "AvailabilityZone": "us-east-1a",
    "Tags": [],
    "Encrypted": false,
    "VolumeType": "gp3",
    "VolumeId": "vol-abcd1234efgh5678j",
    "State": "creating",
    "Iops": 4000,
    "SnapshotId": "",
    "CreateTime": "2025-01-13T10:20:45.000Z",
    "Size": 100,
    "Throughput": 250
}
```

**Create an encrypted volume**

For sensitive data, you should create encrypted volumes. The following command creates an encrypted gp3 volume using the default AWS managed key for EBS:

```bash
aws ec2 create-volume \
    --volume-type gp3 \
    --size 100 \
    --encrypted \
    --region us-east-1 \
    --availability-zone us-east-1a
```

The response shows that the volume is encrypted:

```json
{
    "AvailabilityZone": "us-east-1a",
    "Tags": [],
    "Encrypted": true,
    "VolumeType": "gp3",
    "VolumeId": "vol-abcd1234efgh5678k",
    "State": "creating",
    "Iops": 3000,
    "SnapshotId": "",
    "CreateTime": "2025-01-13T10:25:15.000Z",
    "Size": 100,
    "Throughput": 125,
    "KmsKeyId": "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
}
```

**Create a volume with tags**

Tags help you organize and manage your AWS resources. The following command creates a volume with tags for Name and Environment:

```bash
aws ec2 create-volume \
    --volume-type gp3 \
    --size 100 \
    --region us-east-1 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=MyDataVolume},{Key=Environment,Value=Production}]'
```

The response includes the tags you specified:

```json
{
    "AvailabilityZone": "us-east-1a",
    "Tags": [
        {
            "Key": "Name",
            "Value": "MyDataVolume"
        },
        {
            "Key": "Environment",
            "Value": "Production"
        }
    ],
    "Encrypted": false,
    "VolumeType": "gp3",
    "VolumeId": "vol-abcd1234efgh5678l",
    "State": "creating",
    "Iops": 3000,
    "SnapshotId": "",
    "CreateTime": "2025-01-13T10:30:00.000Z",
    "Size": 100,
    "Throughput": 125
}
```

## Check volume status

Before you can use a volume, it must be in the `available` state. This section shows you how to check the status of your volumes.

**Check a specific volume's status**

To check the status of a specific volume, use the `describe-volumes` command with the volume ID:

```bash
aws ec2 describe-volumes \
    --region us-east-1 \
    --volume-ids vol-abcd1234efgh5678i
```

The command returns detailed information about the volume:

```json
{
    "Volumes": [
        {
            "AvailabilityZone": "us-east-1a",
            "Attachments": [],
            "Encrypted": false,
            "VolumeType": "gp3",
            "VolumeId": "vol-abcd1234efgh5678i",
            "State": "available",
            "Iops": 3000,
            "SnapshotId": "",
            "CreateTime": "2025-01-13T10:15:30.000Z",
            "Size": 100,
            "Throughput": 125
        }
    ]
}
```

The `State` field shows that the volume is now `available`, which means it's ready to be attached to an instance.

**Filter volumes by state**

You can also list all volumes in a specific state, such as `available`:

```bash
aws ec2 describe-volumes \
    --region us-east-1 \
    --filters Name=status,Values=available
```

This command returns information about all available volumes in your account in the current region.

## Create an EC2 instance (optional)

If you don't have an EC2 instance available for attaching your volume, you can create one using the following command. Make sure to use a subnet in the same Availability Zone as the volume that you want to attach.

```bash
# Get the latest Amazon Linux 2 AMI
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --region us-east-1 \
    --output text)

# Create the instance
aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "t2.micro" \
    --subnet-id "subnet-01234567890abcdef" \
    --security-group-ids "sg-abcdef01234567890" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EBSTutorialInstance}]' \
    --query "Instances[0].InstanceId" \
    --region us-east-1 \
    --output text

```

Wait for the instance to be in the `running` state before proceeding:

```bash
aws ec2 wait instance-running --instance-ids i-abcd1234efgh5678m --region us-east-1
```

## Attach a volume to an EC2 instance

Once your volume is in the `available` state, you can attach it to an EC2 instance in the same Availability Zone. This section shows you how to attach a volume and verify the attachment.

**Attach the volume to an instance**

To attach a volume to an instance, you need the volume ID, instance ID, and a device name. The following command attaches a volume to an instance as `/dev/sdf`:

```bash
aws ec2 attach-volume \
    --volume-id vol-abcd1234efgh5678i \
    --instance-id i-abcd1234efgh5678m \
    --region us-east-1 \
    --device /dev/sdf
```

The command returns information about the attachment:

```json
{
    "AttachTime": "2025-01-13T10:45:30.000Z",
    "InstanceId": "i-abcd1234efgh5678m",
    "VolumeId": "vol-abcd1234efgh5678i",
    "State": "attaching",
    "Device": "/dev/sdf"
}
```

The `State` field shows that the volume is in the process of being attached. It will change to `attached` when the process is complete.

**Verify the attachment**

To verify that the volume is attached to the instance, you can describe the volume again:

```bash
aws ec2 describe-volumes \
    --region us-east-1 \
    --volume-ids vol-abcd1234efgh5678i
```

The response now includes attachment information:

```json
{
    "Volumes": [
        {
            "AvailabilityZone": "us-east-1a",
            "Attachments": [
                {
                    "AttachTime": "2025-01-13T10:45:30.000Z",
                    "InstanceId": "i-abcd1234efgh5678m",
                    "VolumeId": "vol-abcd1234efgh5678i",
                    "State": "attached",
                    "Device": "/dev/sdf",
                    "DeleteOnTermination": false
                }
            ],
            "Encrypted": false,
            "VolumeType": "gp3",
            "VolumeId": "vol-abcd1234efgh5678i",
            "State": "in-use",
            "Iops": 3000,
            "SnapshotId": "",
            "CreateTime": "2025-01-13T10:15:30.000Z",
            "Size": 100,
            "Throughput": 125
        }
    ]
}
```

The `State` field now shows `in-use`, and the `Attachments` array contains information about the attachment.

**List volumes attached to a specific instance**

You can also list all volumes attached to a specific instance:

```bash
aws ec2 describe-volumes \
    --region us-east-1 \
    --filters Name=attachment.instance-id,Values=i-abcd1234efgh5678m
```

This command returns information about all volumes attached to the specified instance.

## Modify a volume (optional)

You can modify the size, IOPS, or throughput of an existing EBS volume without detaching it from an instance. This section shows you how to modify a volume's attributes.

**Increase volume size and performance**

The following command increases a volume's size to 200 GiB and changes its type to io2 with 10,000 IOPS:

```bash
aws ec2 modify-volume \
    --volume-id vol-abcd1234efgh5678i \
    --size 200 \
    --volume-type io2 \
    --region us-east-1 \
    --iops 10000
```

The command returns information about the modification:

```json
{
    "VolumeModification": {
        "VolumeId": "vol-abcd1234efgh5678i",
        "ModificationState": "modifying",
        "TargetSize": 200,
        "TargetIops": 10000,
        "TargetVolumeType": "io2",
        "OriginalSize": 100,
        "OriginalIops": 3000,
        "OriginalVolumeType": "gp3",
        "Progress": 0,
        "StartTime": "2025-01-13T11:00:00.000Z"
    }
}
```

The `ModificationState` field shows that the volume is being modified. The modification process can take some time to complete, especially for larger volumes.

## Clean up resources

When you're finished with your EBS volumes, you should clean them up to avoid incurring additional charges. This section shows you how to detach and delete volumes.

**Detach a volume**

Before you can delete a volume, you must detach it from any instances:

```bash
aws ec2 detach-volume \
    --region us-east-1 \
    --volume-id vol-abcd1234efgh5678i
```

The command returns information about the detachment:

```json
{
    "AttachTime": "2025-01-13T10:45:30.000Z",
    "InstanceId": "i-abcd1234efgh5678m",
    "VolumeId": "vol-abcd1234efgh5678i",
    "State": "detaching",
    "Device": "/dev/sdf"
}
```

The `State` field shows that the volume is in the process of being detached. You should wait until the volume is fully detached before deleting it.

**Delete a volume**

Once a volume is detached and in the `available` state, you can delete it:

```bash
aws ec2 delete-volume \
    --region us-east-1 \
    --volume-id vol-abcd1234efgh5678i
```

This command doesn't return any output if successful. You can verify that the volume has been deleted by trying to describe it:

```bash
aws ec2 describe-volumes \
    --region us-east-1 \
    --volume-ids vol-abcd1234efgh5678i
```

If the volume has been deleted, you'll receive an error message indicating that the volume doesn't exist.

**Terminate the EC2 instance (if created for this tutorial)**

If you created an EC2 instance specifically for this tutorial, you should terminate it to avoid ongoing charges:

```bash
aws ec2 terminate-instances \
    --region us-east-1 \
    --instance-ids i-abcd1234efgh5678m
```

Wait for the instance to terminate:

```bash
aws ec2 wait instance-terminated \
    --region us-east-1 \
    --instance-ids i-abcd1234efgh5678m
```

## Troubleshooting

Here are some common issues you might encounter when working with EBS volumes and how to resolve them:

**Volume stuck in "creating" state**

If a volume remains in the `creating` state for an extended period:
- Check your AWS service health dashboard for any EBS issues in your region
- Try creating the volume in a different Availability Zone
- Contact AWS Support if the issue persists

**Permission errors**

If you receive permission errors:
- Verify that your IAM user or role has the necessary permissions
- Check for any resource-based policies that might be restricting access
- Ensure you're operating in the correct AWS account and region

**Availability Zone mismatch**

If you can't attach a volume to an instance:
- Verify that the volume and instance are in the same Availability Zone
- You cannot attach a volume to an instance in a different Availability Zone

**Volume limit exceeded**

If you receive a "volume limit exceeded" error:
- Check your current EBS volume limits in the EC2 console
- Request a limit increase through the Service Quotas console if needed


## Going to production

This tutorial is designed to help you learn how to use the EBS API through the AWS CLI. When implementing EBS volumes in a production environment, consider the following additional best practices:

### Security considerations

1. **IAM permissions**: Implement least privilege access by creating specific IAM policies that grant only the permissions needed for each role or user.

2. **KMS key management**: For sensitive data, create and manage your own customer managed keys (CMKs) instead of using the default AWS managed key.

3. **Encryption**: Enable default encryption for all EBS volumes in your account.

4. **Monitoring**: Set up CloudTrail to monitor API calls related to your EBS volumes.

### Architecture best practices

1. **Backup strategy**: Implement regular snapshots of your volumes to protect against data loss.

2. **Multi-AZ resilience**: Design your application to span multiple Availability Zones for higher availability.

3. **Performance monitoring**: Use CloudWatch to monitor volume performance metrics and set up alarms for potential issues.

4. **Automation**: Use infrastructure as code tools like AWS CloudFormation or Terraform to manage your volumes consistently.

5. **Cost optimization**: Implement lifecycle policies to manage snapshots and consider using gp3 volumes instead of gp2 for better price-performance.

For more information on building production-ready systems on AWS, refer to:
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
- [EBS Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSPerformance.html)

## Next steps

Now that you've learned how to create and manage EBS volumes using the AWS CLI, you can explore other EBS features:

1. **Snapshots** - [Create point-in-time backups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSSnapshots.html) of your EBS volumes.
2. **Volume initialization** - [Improve performance](https://docs.aws.amazon.com/ebs/latest/userguide/initalize-volume.html) when creating volumes from snapshots.
3. **Multi-Attach** - [Attach a single volume to multiple instances](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-volumes-multi.html) (for io1 and io2 volumes only).
4. **Volume metrics** - [Monitor your volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using_cloudwatch_ebs.html) using Amazon CloudWatch.
5. **Data lifecycle management** - [Automate snapshot creation and deletion](https://docs.aws.amazon.com/ebs/latest/userguide/dlm-overview.html) using Amazon Data Lifecycle Manager.

For more information about available AWS CLI commands for EBS, see the [AWS CLI Command Reference for EC2](https://docs.aws.amazon.com/cli/latest/reference/ec2/index.html).
