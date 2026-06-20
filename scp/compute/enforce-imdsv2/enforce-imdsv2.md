# enforce-imdsv2

## What this does
Blocks launch of EC2 instances that do not require IMDSv2 (token-based metadata access). Also caps the hop limit at 2 to prevent containers from reaching IMDS across network hops, and denies post-launch modification of metadata options to downgrade back to v1.

## Why you need this
IMDSv1 allows any process on an instance — including web application code — to read `http://169.254.169.254/latest/meta-data/iam/security-credentials/` without any token. An SSRF vulnerability (Server-Side Request Forgery) in any web app running on the instance is all an attacker needs to steal the instance's IAM credentials with full role permissions.

This attack pattern has been used in multiple high-profile breaches:
- **Capital One (2019)** — SSRF via misconfigured WAF hit IMDS and extracted IAM credentials, enabling S3 data exfiltration of 100 million records.
- Multiple Kubernetes and container escape incidents where container workloads reached the host IMDS endpoint.

IMDSv2 requires a PUT request with a session token before any metadata can be read, making SSRF attacks ineffective against the metadata service.

## When to apply this
Apply to all OUs. There is no legitimate reason to run IMDSv1 in a modern AWS environment — all AWS SDKs and the AWS CLI have supported IMDSv2 since 2019.

## Prerequisites
- Verify your AMIs and applications use the AWS SDK (v3+ for JavaScript, boto3 1.9.220+ for Python, AWS CLI v2). Legacy SDKs that hardcode IMDSv1 HTTP calls must be updated first.
- Check current instances: `aws ec2 describe-instances --query 'Reservations[].Instances[?MetadataOptions.HttpTokens==\`optional\`].InstanceId'`

## How to apply
```bash
aws organizations create-policy \
  --name "enforce-imdsv2" \
  --description "Require IMDSv2 and cap hop limit on all EC2 instances" \
  --content file://enforce-imdsv2.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to launch instance with IMDSv1 — expect AccessDenied
aws ec2 run-instances \
  --image-id ami-REPLACE_WITH_YOUR_AMI \
  --instance-type t3.micro \
  --metadata-options HttpTokens=optional \
  --count 1

# Attempt to launch with IMDSv2 — expect success
aws ec2 run-instances \
  --image-id ami-REPLACE_WITH_YOUR_AMI \
  --instance-type t3.micro \
  --metadata-options HttpTokens=required,HttpPutResponseHopLimit=2 \
  --count 1
```

## Exceptions and customisation
- **Hop limit**: 2 is appropriate for most workloads. Container-heavy environments (ECS on EC2) may need `3` if containers are double-NAT'd. Do not set above `3`.
- The `DenyModifyingMetadataOptions` statement prevents post-launch downgrade. Remove it only if you have operational tooling that legitimately modifies metadata options (rare).
- Existing running instances are not affected by this SCP — use AWS Config rule `ec2-imdsv2-check` to find and remediate them.

## References
- [AWS IMDSv2 migration guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)
- [Capital One breach report — SSRF via IMDS](https://krebsonsecurity.com/2019/07/what-we-can-learn-from-the-capital-one-hack/)
- [CIS AWS Foundations Benchmark — 5.6](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS re:Inforce 2022 — IAT306 EC2 security hardening](https://reinforce.awsevents.com/)
