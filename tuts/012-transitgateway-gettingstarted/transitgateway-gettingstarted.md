# Getting started with Amazon VPC Transit Gateway using the AWS CLI

This tutorial guides you through creating and configuring an Amazon VPC Transit Gateway using the AWS Command Line Interface (AWS CLI). You'll learn how to connect two VPCs using a transit gateway, allowing resources in each VPC to communicate with each other.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

2. Two VPCs in the same AWS Region with non-overlapping CIDR blocks. For example, one VPC with CIDR block 10.1.0.0/16 and another with 10.2.0.0/16.

3. At least one subnet in each VPC. Transit Gateway needs subnets to establish attachments.

4. One EC2 instance in each VPC that you can use to test connectivity.

5. Security groups configured to allow ICMP traffic between instances. For more information, see [Configure security group rules](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-security-group-rules.html).

6. [Sufficient permissions](https://docs.aws.amazon.com/vpc/latest/tgw/transit-gateway-authentication-access-control.html) to create and manage transit gateways in your AWS account.

### Cost considerations

The resources created in this tutorial will incur costs in your AWS account. The estimated cost for running the resources for one hour is approximately $0.15 (not including data transfer costs):

- Transit Gateway: $0.05 per hour
- Transit Gateway Attachments: $0.05 per attachment hour (2 attachments = $0.10)

Remember to delete all resources after completing the tutorial to avoid ongoing charges.

## Create a transit gateway

A transit gateway serves as a network transit hub that you can use to interconnect your VPCs and on-premises networks. In this step, you'll create a transit gateway with default settings.

The following command creates a transit gateway with DNS support and default route table association and propagation enabled:

```bash
aws ec2 create-transit-gateway \
  --description "My Transit Gateway" \
  --options DnsSupport=enable,VpnEcmpSupport=enable,DefaultRouteTableAssociation=enable,DefaultRouteTablePropagation=enable,MulticastSupport=disable,AutoAcceptSharedAttachments=disable
```

The command returns information about your new transit gateway, including its ID. Make note of the transit gateway ID (tgw-xxxxxxxxxxxxxxxxx) as you'll need it in subsequent steps.

Example output:

```json
{
    "TransitGateway": {
        "TransitGatewayId": "tgw-0262a0e521abcd123",
        "TransitGatewayArn": "arn:aws:ec2:us-west-2:123456789012:transit-gateway/tgw-0262a0e521abcd123",
        "State": "pending",
        "OwnerId": "123456789012",
        "Description": "My Transit Gateway",
        "CreationTime": "2025-06-03T19:02:12.000Z",
        "Options": {
            "AmazonSideAsn": 64512,
            "AutoAcceptSharedAttachments": "disable",
            "DefaultRouteTableAssociation": "enable",
            "AssociationDefaultRouteTableId": "tgw-rtb-018774adf3abcd123",
            "DefaultRouteTablePropagation": "enable",
            "PropagationDefaultRouteTableId": "tgw-rtb-018774adf3abcd123",
            "VpnEcmpSupport": "enable",
            "DnsSupport": "enable",
            "MulticastSupport": "disable"
        }
    }
}
```

When you first create a transit gateway, its state is `pending`. You need to wait until the state changes to `available` before you can attach VPCs to it. Use the following command to check the status:

```bash
aws ec2 describe-transit-gateways \
  --transit-gateway-ids tgw-0262a0e521abcd123 \
  --query 'TransitGateways[0].State'
```

This command returns the current state of your transit gateway. Continue checking until it returns `"available"`.

## Attach your VPCs to your transit gateway

Once your transit gateway is available, you can create attachments to connect your VPCs to it. You'll create one attachment for each VPC.

First, create an attachment for your first VPC:

```bash
aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id tgw-0262a0e521abcd123 \
  --vpc-id vpc-0123456789abcdef0 \
  --subnet-ids subnet-0123456789abcdef0
```

Example output:

```json
{
    "TransitGatewayVpcAttachment": {
        "TransitGatewayAttachmentId": "tgw-attach-0a34fe6b4fabcd123",
        "TransitGatewayId": "tgw-0262a0e521abcd123",
        "VpcId": "vpc-0123456789abcdef0",
        "VpcOwnerId": "123456789012",
        "State": "pending",
        "SubnetIds": [
            "subnet-0123456789abcdef0"
        ],
        "CreationTime": "2025-06-03T19:33:46.000Z",
        "Options": {
            "DnsSupport": "enable",
            "Ipv6Support": "disable"
        }
    }
}
```

Now, create an attachment for your second VPC:

```bash
aws ec2 create-transit-gateway-vpc-attachment \
  --transit-gateway-id tgw-0262a0e521abcd123 \
  --vpc-id vpc-0123456789abcdef1 \
  --subnet-ids subnet-0123456789abcdef1
```

Similar to the transit gateway itself, the attachments start in the `pending` state. You need to wait until both attachments are in the `available` state before proceeding. Use the following command to check their status:

```bash
aws ec2 describe-transit-gateway-vpc-attachments \
  --filters Name=transit-gateway-id,Values=tgw-0262a0e521abcd123
```

This command returns information about all attachments for your transit gateway. Check the `State` field for each attachment and wait until both show as `available`.

## Add routes between the transit gateway and your VPCs

Now that your VPCs are attached to the transit gateway, you need to configure routes to enable traffic flow between them. You'll add routes to each VPC's route table that direct traffic destined for the other VPC through the transit gateway.

First, identify the route tables for each VPC:

```bash
aws ec2 describe-route-tables \
  --filters Name=vpc-id,Values=vpc-0123456789abcdef0
```

```bash
aws ec2 describe-route-tables \
  --filters Name=vpc-id,Values=vpc-0123456789abcdef1
```

Make note of the route table IDs (rtb-xxxxxxxxxxxxxxxxx) for each VPC.

Now, add a route in the first VPC's route table to direct traffic to the second VPC through the transit gateway:

```bash
aws ec2 create-route \
  --route-table-id rtb-0123456789abcdef0 \
  --destination-cidr-block 10.2.0.0/16 \
  --transit-gateway-id tgw-0262a0e521abcd123
```

Replace `10.2.0.0/16` with the actual CIDR block of your second VPC.

Next, add a route in the second VPC's route table to direct traffic to the first VPC through the transit gateway:

```bash
aws ec2 create-route \
  --route-table-id rtb-0123456789abcdef1 \
  --destination-cidr-block 10.1.0.0/16 \
  --transit-gateway-id tgw-0262a0e521abcd123
```

Replace `10.1.0.0/16` with the actual CIDR block of your first VPC.

## Test the transit gateway

Now that you've set up the transit gateway and configured the routes, you can test connectivity between your VPCs. You'll connect to an EC2 instance in one VPC and ping an instance in the other VPC.

1. Connect to your EC2 instance in the first VPC using SSH or EC2 Instance Connect.

2. Once connected, ping the private IP address of the EC2 instance in the second VPC:

```bash
ping 10.2.0.100
```

Replace `10.2.0.100` with the actual private IP address of your EC2 instance in the second VPC.

If the ping is successful, you'll see output similar to this:

```
PING 10.2.0.100 (10.2.0.100) 56(84) bytes of data.
64 bytes from 10.2.0.100: icmp_seq=1 ttl=255 time=1.23 ms
64 bytes from 10.2.0.100: icmp_seq=2 ttl=255 time=1.45 ms
64 bytes from 10.2.0.100: icmp_seq=3 ttl=255 time=1.19 ms
```

This confirms that your transit gateway is correctly routing traffic between your VPCs.

## Clean up resources

When you no longer need the transit gateway and its attachments, you should delete them to avoid incurring charges. You must delete the attachments before you can delete the transit gateway.

First, delete the routes you created:

```bash
aws ec2 delete-route \
  --route-table-id rtb-0123456789abcdef0 \
  --destination-cidr-block 10.2.0.0/16
```

```bash
aws ec2 delete-route \
  --route-table-id rtb-0123456789abcdef1 \
  --destination-cidr-block 10.1.0.0/16
```

Next, delete the VPC attachments:

```bash
aws ec2 delete-transit-gateway-vpc-attachment \
  --transit-gateway-attachment-id tgw-attach-0a34fe6b4fabcd123
```

```bash
aws ec2 delete-transit-gateway-vpc-attachment \
  --transit-gateway-attachment-id tgw-attach-0b45fe6c5fabcd123
```

Wait until both attachments are completely deleted before proceeding. You can check their status using the following command:

```bash
aws ec2 describe-transit-gateway-vpc-attachments \
  --transit-gateway-attachment-ids tgw-attach-0a34fe6b4fabcd123
```

The attachment is fully deleted when the command returns no results or an error indicating the attachment ID cannot be found. Repeat this check for both attachments.

Once the attachments are completely deleted, you can delete the transit gateway:

```bash
aws ec2 delete-transit-gateway \
  --transit-gateway-id tgw-0262a0e521abcd123
```

Before attempting to delete the transit gateway, you can verify that all attachments have been removed:

```bash
aws ec2 describe-transit-gateway-attachments \
  --filters Name=transit-gateway-id,Values=tgw-0262a0e521abcd123
```

If this command returns any attachments, wait until they are fully deleted before attempting to delete the transit gateway.

The transit gateway will enter the `deleting` state. You can monitor its deletion status with:

```bash
aws ec2 describe-transit-gateways \
  --transit-gateway-ids tgw-0262a0e521abcd123
```

Once it's fully deleted, you'll stop incurring charges for it.

## Going to production

This tutorial demonstrates the basic functionality of Amazon VPC Transit Gateway for educational purposes. For production deployments, consider the following additional best practices:

### High availability
- Use multiple subnets across different Availability Zones for transit gateway attachments to ensure high availability.
- Consider your bandwidth requirements and service quotas when planning your transit gateway deployment.

### Security
- Implement least-privilege IAM policies for managing transit gateway resources.
- Use VPC Flow Logs to monitor traffic flowing through your transit gateway.
- Configure security groups and network ACLs with precise rules to control traffic between VPCs.

### Scalability
- For environments with many VPCs, consider implementing a hub-and-spoke architecture with centralized route management.
- Use infrastructure as code tools like AWS CloudFormation or Terraform to manage your transit gateway configuration at scale.

For more information on building production-ready architectures, refer to:
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Transit Gateway Design Best Practices](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-best-design-practices.html)
- [Centralized Network Architecture Considerations](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/centralized-network-architecture-considerations.html)

## Next steps

Now that you've learned how to create and use a transit gateway to connect VPCs, you might want to explore more advanced configurations:

- [Connect your transit gateway to a VPN](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-vpn-attachments.html)
- [Connect your transit gateway to AWS Direct Connect](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-dcg-attachments.html)
- [Create transit gateway peering attachments](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-peering.html)
- [Configure multicast on your transit gateway](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-multicast-overview.html)
- [Centralize outbound internet traffic](https://docs.aws.amazon.com/vpc/latest/tgw/transit-gateway-nat-igw.html)

## Security Considerations

This tutorial demonstrates basic AWS CLI usage for educational purposes. For production environments:
- Follow the [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- Implement least privilege access principles
- Enable appropriate logging and monitoring
- Review and apply security best practices specific to each service used

**Important:** This tutorial does not provide security guidance. Consult AWS security documentation and your security team for production deployments.