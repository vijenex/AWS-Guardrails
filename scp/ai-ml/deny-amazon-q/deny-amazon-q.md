# deny-amazon-q

## What this does
Blocks Amazon Q Business, Amazon Q Developer (formerly CodeWhisperer), and the Amazon Q IDE plugin from operating in the OU. An optional exception allows specifically named SSO roles to access Q if your organization has an approved pilot group.

## Why you need this
Amazon Q indexes and processes your AWS environment data, CloudWatch logs, source code, and documentation to provide answers. Without governance:
- Source code is transmitted to AWS AI services before it has been reviewed for IP and data classification compliance.
- The IDE plugin can read files from a developer's local project — including files containing secrets — and send context to the service.
- Engineers may unknowingly use the tool against production account context, exposing sensitive infrastructure topology.

Many organizations require a formal AI tool approval process before allowing tools like Q to operate in regulated or production environments.

## When to apply this
- Apply to production, PCI-DSS, HIPAA, and financial-services OUs where AI coding assistant usage requires a security and legal review.
- Use the exception pattern to allow access for an approved pilot SSO role.
- Do **not** apply in innovation/sandbox accounts where you want engineers to freely experiment.

## Prerequisites
- If you want to allow an exception group, create the SSO Permission Set named `AmazonQ-Approved-Access` before attaching this policy.
- To fully block (no exceptions), remove the `Condition` block from `DenyAmazonQServices`.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-amazon-q" \
  --description "Block Amazon Q and Q Developer except for approved SSO roles" \
  --content file://deny-amazon-q.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to use Q — expect AccessDenied
aws q list-applications --region us-east-1

# Verify IDE plugin calls are blocked by checking CloudTrail for
# UserAgent containing "AmazonQ-For-IDE" with Deny decision
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  | jq '.Events[] | select(.CloudTrailEvent | contains("AmazonQ-For-IDE"))'
```

## Exceptions and customisation
- Replace `AWSReservedSSO_AmazonQ-Approved-Access_*` with the exact name of your approved SSO Permission Set.
- To block with zero exceptions, use:
  ```json
  { "Sid": "DenyAmazonQServices", "Effect": "Deny",
    "Action": ["q:*","qdeveloper:*","codewhisperer:*"], "Resource": "*" }
  ```
- The `DenyAmazonQIDEPlugin` statement blocks any API call (not just Q APIs) originating from the Q IDE plugin user agent. This is a belt-and-suspenders control.

## References
- [Amazon Q Developer documentation](https://docs.aws.amazon.com/amazonq/latest/qdeveloper-ug/what-is.html)
- [Amazon Q security best practices](https://docs.aws.amazon.com/amazonq/latest/qbusiness-ug/security-best-practices.html)
- [NIST AI RMF — AI tool governance](https://airc.nist.gov/RMF_Overview)
