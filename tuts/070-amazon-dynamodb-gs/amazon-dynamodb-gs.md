# Getting started with DynamoDB using the AWS CLI

This tutorial guides you through the basic operations of Amazon DynamoDB using the AWS Command Line Interface (AWS CLI). You'll learn how to create a table, write data to it, read data from it, update data, query data, and finally delete the table.

## Prerequisites

Before you begin this tutorial, you need to:

1. **Set up an AWS account** - If you don't have an AWS account, sign up at [https://aws.amazon.com](https://aws.amazon.com).

2. **Install and configure the AWS CLI** - Follow the instructions in the [AWS CLI User Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) to install the AWS CLI and configure it with your credentials.

3. **Understand DynamoDB basics** - Familiarize yourself with basic DynamoDB concepts like tables, items, and primary keys. For more information, see [Core components of Amazon DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html).

### Pricing considerations

This tutorial uses AWS Free Tier eligible services. If you are within the AWS Free Tier limits, you won't incur charges for completing this tutorial. If you've exceeded the Free Tier limits, you'll incur the standard DynamoDB usage fees from the time you create the table until you delete it. The costs for this tutorial are minimal because:

- We use on-demand capacity mode, which charges only for the actual reads and writes you perform
- We create a small table with just a few items
- We delete the table at the end of the tutorial

For current pricing information, see [Amazon DynamoDB Pricing](https://aws.amazon.com/dynamodb/pricing/).

## Create a table in DynamoDB

The first step is to create a DynamoDB table. In this example, we'll create a `Music` table with a composite primary key consisting of an `Artist` (partition key) and `SongTitle` (sort key).

A partition key determines the partition where DynamoDB stores the data, while a sort key allows you to organize items within a partition. Together, they form a unique identifier for each item in the table.

Run the following command to create the table:

```bash
aws dynamodb create-table \
    --table-name Music \
    --attribute-definitions \
        AttributeName=Artist,AttributeType=S \
        AttributeName=SongTitle,AttributeType=S \
    --key-schema AttributeName=Artist,KeyType=HASH AttributeName=SongTitle,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --table-class STANDARD
```

This command creates a table with the following characteristics:
- Table name: `Music`
- Partition key: `Artist` (string type)
- Sort key: `SongTitle` (string type)
- Billing mode: On-demand (PAY_PER_REQUEST)
- Table class: Standard

After running the command, DynamoDB returns information about the table being created. The table status will initially be `CREATING`:

```json
{
    "TableDescription": {
        "AttributeDefinitions": [
            {
                "AttributeName": "Artist",
                "AttributeType": "S"
            },
            {
                "AttributeName": "SongTitle",
                "AttributeType": "S"
            }
        ],
        "TableName": "Music",
        "KeySchema": [
            {
                "AttributeName": "Artist",
                "KeyType": "HASH"
            },
            {
                "AttributeName": "SongTitle",
                "KeyType": "RANGE"
            }
        ],
        "TableStatus": "CREATING",
        "CreationDateTime": 1673600000.000,
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-east-1:123456789012:table/Music",
        "TableId": "abcd1234-abcd-1234-abcd-abcd1234abcd",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST"
        },
        "TableClassSummary": {
            "TableClass": "STANDARD"
        },
        "DeletionProtectionEnabled": false
    }
}
```

You need to wait until the table is in the `ACTIVE` state before you can use it. You can check the status with the following command:

```bash
aws dynamodb describe-table --table-name Music --query "Table.TableStatus" --output text
```

Once the table is active, it's considered a best practice to enable point-in-time recovery:

```bash
aws dynamodb update-continuous-backups \
    --table-name Music \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

Enabling point-in-time recovery allows you to restore your table to any point in time within the last 35 days, protecting you from accidental writes or deletes.

## Write data to a DynamoDB table

Now that you have created a table, you can add items to it. In DynamoDB, an item is a collection of attributes, each with its own name and value.

Let's add some items to the `Music` table:

```bash
aws dynamodb put-item \
    --table-name Music \
    --item \
        '{"Artist": {"S": "No One You Know"}, "SongTitle": {"S": "Call Me Today"}, "AlbumTitle": {"S": "Somewhat Famous"}, "Awards": {"N": "1"}}'
```

This command adds an item with the following attributes:
- `Artist`: "No One You Know" (string type)
- `SongTitle`: "Call Me Today" (string type)
- `AlbumTitle`: "Somewhat Famous" (string type)
- `Awards`: 1 (number type)

Notice the syntax for specifying attribute values in DynamoDB. Each attribute value includes a data type descriptor (`S` for string, `N` for number).

Let's add a few more items to our table:

```bash
aws dynamodb put-item \
    --table-name Music \
    --item \
        '{"Artist": {"S": "No One You Know"}, "SongTitle": {"S": "Howdy"}, "AlbumTitle": {"S": "Somewhat Famous"}, "Awards": {"N": "2"}}'

aws dynamodb put-item \
    --table-name Music \
    --item \
        '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "Happy Day"}, "AlbumTitle": {"S": "Songs About Life"}, "Awards": {"N": "10"}}'

aws dynamodb put-item \
    --table-name Music \
    --item \
        '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "PartiQL Rocks"}, "AlbumTitle": {"S": "Another Album Title"}, "Awards": {"N": "8"}}'
```

Notice that we've added items for two different artists, with multiple songs for each artist. This will allow us to demonstrate querying capabilities later.

## Read data from a DynamoDB table

After adding items to your table, you can retrieve them using the `get-item` command. To retrieve an item, you need to specify its primary key (both partition key and sort key in this case).

Let's retrieve the "Happy Day" song by "Acme Band":

```bash
aws dynamodb get-item --consistent-read \
    --table-name Music \
    --key '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "Happy Day"}}'
```

The `--consistent-read` parameter ensures that the operation uses strongly consistent reads. By default, DynamoDB uses eventually consistent reads, which might not reflect the most recent write operations.

The output shows all attributes of the retrieved item:

```json
{
    "Item": {
        "AlbumTitle": {
            "S": "Songs About Life"
        },
        "Awards": {
            "N": "10"
        },
        "Artist": {
            "S": "Acme Band"
        },
        "SongTitle": {
            "S": "Happy Day"
        }
    }
}
```

## Update data in a DynamoDB table

You can update existing items in your DynamoDB table using the `update-item` command. This allows you to modify attribute values, add new attributes, or remove existing ones.

Let's update the `AlbumTitle` attribute of the "Happy Day" song:

```bash
aws dynamodb update-item \
    --table-name Music \
    --key '{"Artist": {"S": "Acme Band"}, "SongTitle": {"S": "Happy Day"}}' \
    --update-expression "SET AlbumTitle = :newval" \
    --expression-attribute-values '{":newval": {"S": "Updated Album Title"}}' \
    --return-values ALL_NEW
```

This command:
- Identifies the item using its primary key
- Uses the `SET` action to update the `AlbumTitle` attribute
- Uses an expression attribute value `:newval` to specify the new value
- Returns all attributes of the item after the update (`--return-values ALL_NEW`)

The output shows the updated item:

```json
{
    "Attributes": {
        "AlbumTitle": {
            "S": "Updated Album Title"
        },
        "Awards": {
            "N": "10"
        },
        "Artist": {
            "S": "Acme Band"
        },
        "SongTitle": {
            "S": "Happy Day"
        }
    }
}
```

## Query data in a DynamoDB table

Querying allows you to efficiently retrieve items that share the same partition key. This is one of the most powerful features of DynamoDB, as it provides fast, efficient access to items based on their primary key attributes.

Let's query all songs by "Acme Band":

```bash
aws dynamodb query \
    --table-name Music \
    --key-condition-expression "Artist = :name" \
    --expression-attribute-values '{":name": {"S": "Acme Band"}}'
```

This command:
- Specifies the table to query
- Uses a key condition expression to filter items by the partition key
- Uses an expression attribute value to specify the artist name

The output shows all songs by "Acme Band":

```json
{
    "Items": [
        {
            "AlbumTitle": {
                "S": "Updated Album Title"
            },
            "Awards": {
                "N": "10"
            },
            "Artist": {
                "S": "Acme Band"
            },
            "SongTitle": {
                "S": "Happy Day"
            }
        },
        {
            "AlbumTitle": {
                "S": "Another Album Title"
            },
            "Awards": {
                "N": "8"
            },
            "Artist": {
                "S": "Acme Band"
            },
            "SongTitle": {
                "S": "PartiQL Rocks"
            }
        }
    ],
    "Count": 2,
    "ScannedCount": 2,
    "ConsumedCapacity": null
}
```

The query returns both songs by "Acme Band" that we added earlier. Notice that the `AlbumTitle` for "Happy Day" reflects our update from the previous step.

## Delete your DynamoDB table

When you're done with the tutorial, you can delete the table to avoid incurring charges. This step is optional but recommended if you don't plan to use the table anymore.

```bash
aws dynamodb delete-table --table-name Music
```

This command initiates the deletion of the table. DynamoDB returns information about the table, with the `TableStatus` set to `DELETING`:

```json
{
    "TableDescription": {
        "TableName": "Music",
        "TableStatus": "DELETING",
        "ProvisionedThroughput": {
            "NumberOfDecreasesToday": 0,
            "ReadCapacityUnits": 0,
            "WriteCapacityUnits": 0
        },
        "TableSizeBytes": 0,
        "ItemCount": 0,
        "TableArn": "arn:aws:dynamodb:us-east-1:123456789012:table/Music",
        "TableId": "abcd1234-abcd-1234-abcd-abcd1234abcd",
        "BillingModeSummary": {
            "BillingMode": "PAY_PER_REQUEST",
            "LastUpdateToPayPerRequestDateTime": 1673600000.000
        },
        "TableClassSummary": {
            "TableClass": "STANDARD"
        },
        "DeletionProtectionEnabled": false
    }
}
```

The deletion process happens asynchronously, and it might take a few minutes to complete. You can check if the table has been deleted by trying to describe it:

```bash
aws dynamodb describe-table --table-name Music
```

If the table has been deleted, you'll receive a `ResourceNotFoundException` error.

## Going to production

This tutorial is designed to teach you the basics of working with DynamoDB using the AWS CLI. When moving to a production environment, consider the following best practices:

1. **Capacity planning**: While we used on-demand capacity mode for simplicity, you should evaluate whether provisioned capacity with auto-scaling might be more cost-effective for your production workload.

2. **Security**: Implement the principle of least privilege by creating IAM policies that grant only the permissions needed for your application to interact with DynamoDB.

3. **Backup strategy**: Although we enabled point-in-time recovery, you should also consider implementing scheduled backups for long-term retention.

4. **Data modeling**: The simple schema we used might not be optimal for complex applications. Consider your access patterns carefully when designing your schema.

5. **Monitoring and alerting**: Set up CloudWatch alarms to monitor your DynamoDB table's performance and consumption metrics.

6. **Cost optimization**: Implement TTL (Time to Live) for items that should expire, use appropriate table class (Standard vs. Standard-IA), and consider using DynamoDB Accelerator (DAX) for caching.

For more information on building production-ready applications with DynamoDB, see:
- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Serverless Applications Lens](https://docs.aws.amazon.com/wellarchitected/latest/serverless-applications-lens/welcome.html)

## Next steps

Now that you've learned the basics of working with DynamoDB using the AWS CLI, you can explore more advanced features:

- Learn about [DynamoDB secondary indexes](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/SecondaryIndexes.html) to enable efficient access patterns beyond the primary key
- Explore [DynamoDB Streams](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html) to capture changes to your table in real-time
- Try [DynamoDB transactions](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/transactions.html) for coordinating multiple operations
- Implement [DynamoDB fine-grained access control](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/specifying-conditions.html) using IAM policies
- Use [PartiQL for DynamoDB](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ql-reference.html), a SQL-compatible query language
