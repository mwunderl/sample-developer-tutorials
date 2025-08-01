# Working with VPC peering connections using the AWS CLI

This tutorial guides you through the process of creating and configuring VPC peering connections using the AWS Command Line Interface (AWS CLI). VPC peering enables direct network connectivity between two VPCs, allowing resources in each VPC to communicate with each other as if they were on the same network.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI installed and configured with appropriate credentials. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Permissions to create and manage VPC resources in your AWS account.
3. Basic understanding of VPC networking concepts.
4. Two existing VPCs with non-overlapping CIDR blocks. If you don't have existing VPCs, you can create them as shown in the first section of this tutorial.

### Cost considerations

The resources used in this tutorial have the following cost implications:

- VPCs, subnets, route tables, and VPC peering connections within the same region are free of charge.
- If you create VPC peering connections between different regions, you will incur data transfer charges for traffic that flows across the peering connection.
- Any EC2 instances or other resources you launch within these VPCs will incur standard charges.
- Data transfer between instances in different Availability Zones will incur standard EC2 data transfer charges, even when using VPC peering.

For the most up-to-date pricing information, refer to the [Amazon VPC Pricing](https://aws.amazon.com/vpc/pricing/) page.

## Create VPCs for peering

If you don't already have VPCs to use for this tutorial, you can create them using the AWS CLI. The VPCs must have non-overlapping CIDR blocks to establish a peering connection.

**Create the first VPC**

The following command creates a VPC with a CIDR block of 10.0.0.0/16:

```bash
VPC1_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=VPC1}]" \
  --query 'Vpc.VpcId' \
  --output text)

echo "VPC1 created with ID: $VPC1_ID"
```

After running this command, the VPC ID is stored in the `VPC1_ID` variable and displayed in the terminal. This VPC will be the requester in our peering connection.

**Create a subnet in the first VPC**

Now, let's create a subnet within the first VPC:

```bash
SUBNET1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC1_ID \
  --cidr-block 10.0.1.0/24 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=VPC1-Subnet}]" \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Subnet created in VPC1 with ID: $SUBNET1_ID"
```

This command creates a subnet with CIDR block 10.0.1.0/24 within the first VPC. The subnet ID is stored in the `SUBNET1_ID` variable.

**Create the second VPC**

Next, create the second VPC with a different CIDR block:

```bash
VPC2_ID=$(aws ec2 create-vpc \
  --cidr-block 172.16.0.0/16 \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=VPC2}]" \
  --query 'Vpc.VpcId' \
  --output text)

echo "VPC2 created with ID: $VPC2_ID"
```

This command creates a second VPC with CIDR block 172.16.0.0/16. The VPC ID is stored in the `VPC2_ID` variable. This VPC will be the accepter in our peering connection.

**Create a subnet in the second VPC**

Create a subnet within the second VPC:

```bash
SUBNET2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC2_ID \
  --cidr-block 172.16.1.0/24 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=VPC2-Subnet}]" \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Subnet created in VPC2 with ID: $SUBNET2_ID"
```

This command creates a subnet with CIDR block 172.16.1.0/24 within the second VPC. The subnet ID is stored in the `SUBNET2_ID` variable.

## Create a VPC peering connection

After creating the VPCs and subnets (or if you're using existing VPCs), you can establish a VPC peering connection between them.

**Create the peering connection**

The following command creates a VPC peering connection from the first VPC to the second VPC:

```bash
PEERING_ID=$(aws ec2 create-vpc-peering-connection \
  --vpc-id $VPC1_ID \
  --peer-vpc-id $VPC2_ID \
  --tag-specifications "ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=VPC1-VPC2-Peering}]" \
  --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
  --output text)

echo "VPC Peering Connection created with ID: $PEERING_ID"
```

This command initiates a peering connection request from VPC1 to VPC2. The peering connection ID is stored in the `PEERING_ID` variable. The peering connection is in the `pending-acceptance` state until it's accepted by the owner of the accepter VPC.

## Accept the VPC peering connection

For the peering connection to become active, it must be accepted by the owner of the accepter VPC. In this tutorial, since we're using the same AWS account for both VPCs, we can accept the request ourselves.

**Accept the peering request**

Use the following command to accept the VPC peering connection:

```bash
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id $PEERING_ID
```

After running this command, the VPC peering connection status changes from `pending-acceptance` to `active`. The VPCs are now peered, but you still need to configure route tables to enable traffic flow between them.

## Update route tables

To enable traffic between the peered VPCs, you need to update the route tables for both VPCs to route traffic destined for the peer VPC through the peering connection.

**Create a route table for the first VPC**

First, create a route table for VPC1:

```bash
RTB1_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC1_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=VPC1-RouteTable}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

echo "Route table created for VPC1 with ID: $RTB1_ID"
```

This command creates a new route table for VPC1 and stores its ID in the `RTB1_ID` variable.

**Create a route from VPC1 to VPC2**

Add a route to the VPC1 route table that directs traffic destined for VPC2's CIDR block through the peering connection:

```bash
aws ec2 create-route \
  --route-table-id $RTB1_ID \
  --destination-cidr-block 172.16.0.0/16 \
  --vpc-peering-connection-id $PEERING_ID
```

This command creates a route in VPC1's route table that sends traffic destined for VPC2's CIDR block (172.16.0.0/16) through the VPC peering connection.

**Associate the route table with the subnet in VPC1**

Associate the route table with the subnet in VPC1:

```bash
RTB1_ASSOC_ID=$(aws ec2 associate-route-table \
  --route-table-id $RTB1_ID \
  --subnet-id $SUBNET1_ID \
  --query 'AssociationId' \
  --output text)

echo "Route table associated with subnet in VPC1"
```

This command associates the route table with the subnet in VPC1, enabling the subnet to use the routes defined in the route table.

**Create a route table for the second VPC**

Now, create a route table for VPC2:

```bash
RTB2_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC2_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=VPC2-RouteTable}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)

echo "Route table created for VPC2 with ID: $RTB2_ID"
```

This command creates a new route table for VPC2 and stores its ID in the `RTB2_ID` variable.

**Create a route from VPC2 to VPC1**

Add a route to the VPC2 route table that directs traffic destined for VPC1's CIDR block through the peering connection:

```bash
aws ec2 create-route \
  --route-table-id $RTB2_ID \
  --destination-cidr-block 10.0.0.0/16 \
  --vpc-peering-connection-id $PEERING_ID
```

This command creates a route in VPC2's route table that sends traffic destined for VPC1's CIDR block (10.0.0.0/16) through the VPC peering connection.

**Associate the route table with the subnet in VPC2**

Associate the route table with the subnet in VPC2:

```bash
RTB2_ASSOC_ID=$(aws ec2 associate-route-table \
  --route-table-id $RTB2_ID \
  --subnet-id $SUBNET2_ID \
  --query 'AssociationId' \
  --output text)

echo "Route table associated with subnet in VPC2"
```

This command associates the route table with the subnet in VPC2, enabling the subnet to use the routes defined in the route table.

## Verify the VPC peering connection

After setting up the VPC peering connection and configuring the route tables, you should verify that the connection is active and properly configured.

**Check the peering connection status**

Use the following command to check the status of the VPC peering connection:

```bash
aws ec2 describe-vpc-peering-connections \
  --vpc-peering-connection-ids $PEERING_ID
```

The output should show the status as "active", indicating that the peering connection is established and working. You should also see details about both the requester and accepter VPCs.

## Clean up resources

When you no longer need the VPC peering connection and associated resources, you should clean them up to avoid incurring unnecessary charges.

**Delete the VPC peering connection**

To delete the VPC peering connection:

```bash
aws ec2 delete-vpc-peering-connection \
  --vpc-peering-connection-id $PEERING_ID

echo "VPC Peering Connection deleted"
```

This command deletes the VPC peering connection. Once deleted, traffic can no longer flow between the VPCs through this connection.

**Delete route tables and their associations**

Before deleting the route tables, you need to disassociate them from the subnets:

```bash
aws ec2 disassociate-route-table \
  --association-id $RTB2_ASSOC_ID

aws ec2 disassociate-route-table \
  --association-id $RTB1_ASSOC_ID
```

These commands disassociate the route tables from their respective subnets. After disassociating, you can delete the route tables:

```bash
aws ec2 delete-route-table \
  --route-table-id $RTB2_ID

aws ec2 delete-route-table \
  --route-table-id $RTB1_ID
```

These commands delete the route tables you created for VPC1 and VPC2.

**Delete subnets**

If you created subnets specifically for this tutorial, you can delete them:

```bash
aws ec2 delete-subnet \
  --subnet-id $SUBNET2_ID

aws ec2 delete-subnet \
  --subnet-id $SUBNET1_ID
```

These commands delete the subnets you created in VPC1 and VPC2.

**Delete VPCs**

If you created VPCs specifically for this tutorial, you can delete them:

```bash
aws ec2 delete-vpc \
  --vpc-id $VPC2_ID

aws ec2 delete-vpc \
  --vpc-id $VPC1_ID
```

These commands delete the VPCs you created for this tutorial. Note that you can only delete a VPC after all its resources (subnets, route tables, etc.) have been deleted.

## Going to production

This tutorial demonstrates the basic steps to create and configure a VPC peering connection for educational purposes. When implementing VPC peering in a production environment, consider the following additional best practices:

### Security considerations

1. **Configure security groups**: Restrict traffic between peered VPCs by configuring security groups that allow only necessary traffic. For more information, see [Security groups for your VPC](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html).

2. **Implement network ACLs**: Use network ACLs as an additional layer of security at the subnet level. For more information, see [Network ACLs](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html).

3. **Enable VPC Flow Logs**: Monitor traffic between peered VPCs by enabling VPC Flow Logs. For more information, see [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html).

4. **Use more specific routes**: Instead of routing entire VPC CIDR blocks, consider creating more specific routes to limit communication to only necessary subnets.

### Architecture considerations

1. **VPC peering limitations**: VPC peering does not support transitive peering, meaning if VPC A is peered with VPC B, and VPC B is peered with VPC C, VPC A cannot communicate with VPC C through VPC B.

2. **Scaling beyond two VPCs**: For complex networks involving multiple VPCs, consider using AWS Transit Gateway instead of creating multiple peering connections. For more information, see [AWS Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html).

3. **High availability**: For critical applications, consider implementing redundant networking paths and monitoring for the VPC peering connection.

4. **DNS resolution**: Enable DNS resolution for VPC peering connections to resolve DNS hostnames to private IP addresses across peered VPCs. For more information, see [Enable DNS resolution for a VPC peering connection](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-dns.html).

For comprehensive guidance on building secure and scalable architectures on AWS, refer to the [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/).

## Next steps

Now that you've learned how to create and configure VPC peering connections using the AWS CLI, you can explore more advanced networking scenarios:

1. [Create a VPC peering connection between VPCs in different regions](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-regions.html) to connect resources across AWS regions.
2. [Enable DNS resolution for VPC peering connections](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-dns.html) to resolve DNS hostnames to private IP addresses across peered VPCs.
3. [Update security groups to reference peer security groups](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-security-groups.html) for more granular control over traffic between peered VPCs.
4. [Explore Transit Gateway](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html) for connecting multiple VPCs and on-premises networks through a central hub.
5. [Learn about VPC endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html) to privately connect your VPC to supported AWS services without requiring an internet gateway.
