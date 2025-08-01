# Setting up Amazon Simple Email Service (SES) using the AWS CLI

This tutorial guides you through setting up Amazon Simple Email Service (SES) using the AWS Command Line Interface (AWS CLI). You'll learn how to verify email addresses and domains, check your sending limits, and send test emails.

## Prerequisites

Before you begin this tutorial, make sure you have the following:

1. The AWS CLI. If you need to install it, follow the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
2. Configured your AWS CLI with appropriate credentials. Run `aws configure` if you haven't set up your credentials yet.
3. An email address that you own and can access.
4. [Sufficient permissions](https://docs.aws.amazon.com/ses/latest/dg/control-user-access.html) to create and manage SES resources in your AWS account.

### Cost Information

This tutorial uses Amazon SES features that are either free or extremely low cost:

- Email and domain verification: Free
- API calls for checking status: Free
- Sending test emails: $0.10 per 1,000 emails (when sent from EC2) or $0.12 per 1,000 emails (when sent from outside AWS)

The total cost of completing this tutorial is effectively $0.00, as you'll only send one test email. Amazon SES also offers a free tier that includes 62,000 free outbound messages per month when sending from Amazon EC2 or AWS Elastic Beanstalk, and 1,000 free outbound messages per month when sending from outside AWS.

## Verify an email address

Before you can send emails with Amazon SES, you need to verify at least one email address to prove that you own it. This is a security measure to prevent unauthorized use.

**Verify your sender email address**

Run the following command to start the verification process for your email address:

```bash
aws ses verify-email-identity --email-address your-email@example.com
```

After running this command, Amazon SES sends a verification email to the specified address. You must click the verification link in that email to complete the process.

**Check verification status**

You can check the status of your verified email addresses using the following command:

```bash
aws ses list-identities --identity-type EmailAddress
```

This command lists all email addresses that you've attempted to verify. To see the verification status of specific email addresses, use:

```bash
aws ses get-identity-verification-attributes --identities "your-email@example.com"
```

The output will show whether the email address has been successfully verified:

```json
{
    "VerificationAttributes": {
        "your-email@example.com": {
            "VerificationStatus": "Success"
        }
    }
}
```

If the status shows "Pending", check your email inbox and click the verification link.

## Verify a domain (optional)

For production use, it's recommended to verify an entire domain rather than individual email addresses. This allows you to send from any address at that domain.

**Verify your domain**

To verify a domain, run:

```bash
aws ses verify-domain-identity --domain example.com
```

The command returns a verification token that you need to add as a TXT record to your domain's DNS settings:

```json
{
    "VerificationToken": "eoEmxw+YaYhb3h3YJJnSWgdD/rMdbnX83hHXW+VXsho="
}
```

Add this token as a TXT record to `_amazonses.example.com` in your domain's DNS settings.

**Set up DKIM for your domain**

DKIM (DomainKeys Identified Mail) adds an additional layer of authentication to your emails. To set up DKIM for your domain:

```bash
aws ses verify-domain-dkim --domain example.com
```

This command returns three CNAME records that you need to add to your domain's DNS settings:

```json
{
    "DkimTokens": [
        "q7abcdefghijklmnopqrst",
        "r7uvwxyzabcdefghijklm",
        "s7nopqrstuvwxyzabcdefg"
    ]
}
```

For each token, add a CNAME record with:
- Name: `<token>._domainkey.example.com`
- Value: `<token>.dkim.amazonses.com`

**Check domain verification status**

To check the verification status of your domains:

```bash
aws ses list-identities --identity-type Domain
```

To see the verification status of a specific domain:

```bash
aws ses get-identity-verification-attributes --identities "example.com"
```

Domain verification can take up to 72 hours to complete, depending on your DNS provider.

## Check your sending limits

New SES accounts are placed in the sandbox environment, which has certain limitations. You can check your current sending limits with:

```bash
aws ses get-send-quota
```

The output shows:
- Your maximum send rate (emails per second)
- Your maximum 24-hour send quota
- How many emails you've sent in the last 24 hours

```json
{
    "Max24HourSend": 200.0,
    "MaxSendRate": 1.0,
    "SentLast24Hours": 0.0
}
```

In the sandbox environment, you can only send to verified email addresses or domains. For production use, you'll need to request to be moved out of the sandbox.

## Send a test email

Once you have verified at least one email address, you can send a test email.

**Send an email to a verified address**

In the sandbox environment, both the sender AND recipient email addresses must be verified. Run the following command to send a test email:

```bash
aws ses send-email \
    --from "your-verified-email@example.com" \
    --destination "ToAddresses=recipient-verified-email@example.com" \
    --message "Subject={Data=Test Email,Charset=UTF-8},Body={Text={Data=This is a test email sent from Amazon SES using the AWS CLI,Charset=UTF-8}}"
```

If successful, the command returns a message ID, confirming that your email was accepted for delivery:

```json
{
    "MessageId": "010001866e78b830-21a5d789-9c86-4bfc-a27f-0a3e65d08a9a-000000"
}
```

If you receive an error stating that the email address is not verified, make sure both the sender and recipient addresses have been verified in your account.

## Clean up resources

If you no longer need the email addresses or domains you've verified, you can remove them from your SES account.

**Delete an email identity**

To delete a verified email address:

```bash
aws ses delete-identity --identity "your-email@example.com"
```

**Delete a domain identity**

To delete a verified domain:

```bash
aws ses delete-identity --identity "example.com"
```

Deleting identities helps keep your SES account organized and makes it easier to manage your verified senders.

## Going to production

This tutorial is designed to help you learn how the Amazon SES API works, not to build a production-ready email sending system. When moving to production, consider the following best practices:

### Security considerations

1. **Implement comprehensive email authentication**: Beyond DKIM, also set up SPF and DMARC records for your domain to prevent email spoofing.

2. **Use IAM roles with least privilege**: Create specific IAM roles for email sending with only the necessary permissions.

3. **Protect sensitive information**: Never send sensitive data via email without proper encryption.

### Scalability considerations

1. **Request production access**: Move out of the SES sandbox to remove recipient verification requirements and increase sending limits.

2. **Set up bounce and complaint handling**: Configure SNS notifications to automatically process bounces and complaints.

3. **Use configuration sets**: Track and manage different email workloads separately.

4. **Consider dedicated IPs**: For high-volume senders, dedicated IPs provide better deliverability control.

For more information on building production-ready email systems with SES, refer to:

- [Amazon SES Best Practices](https://docs.aws.amazon.com/ses/latest/dg/best-practices.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

## Next steps

Now that you've set up Amazon SES using the AWS CLI, you can explore more advanced features:

1. **Request production access** - [Move out of the SES sandbox](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html) to remove sending limitations.
2. **Configure SMTP settings** - [Send emails using SMTP](https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp.html) from your applications.
3. **Set up event notifications** - [Track bounces and complaints](https://docs.aws.amazon.com/ses/latest/dg/monitor-sending-activity.html) to maintain a good sender reputation.
4. **Create templates** - [Use email templates](https://docs.aws.amazon.com/ses/latest/dg/send-personalized-email-api.html) for consistent messaging.
5. **Implement sending authorization** - [Allow other accounts to send from your identities](https://docs.aws.amazon.com/ses/latest/dg/sending-authorization.html).

For more information about available AWS CLI commands for SES, see the [AWS CLI Command Reference for SES](https://docs.aws.amazon.com/cli/latest/reference/ses/index.html).
