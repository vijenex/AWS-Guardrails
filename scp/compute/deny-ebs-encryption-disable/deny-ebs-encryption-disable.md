# deny-ebs-encryption-disable

## What this does
Blocks the `ec2:DisableEbsEncryptionByDefault` action, which would turn off the account-level EBS default encryption setting. Once encryption by default is enabled and this SCP is attached, it cannot be disabled.

## Why you need this
AWS EBS encryption by default (`ec2:EnableEbsEncryptionByDefault`) ensures that all new EBS volumes, snapshots, and attached volumes are automatically encrypted with the default KMS key. This is a one-way switch — enabling it is free and has no performance impact (AES-256 encryption is done in hardware).

Without this SCP, a user with EC2 permissions can disable EBS encryption by default, allowing unencrypted volumes to be created. This is often done by developers who run into encryption-related issues and take the path of least resistance rather than fixing the underlying problem.

CIS AWS Foundations Benchmark 2.2.1 requires EBS encryption at rest.

## When to apply this
Apply to all OUs immediately. Enable `EbsEncryptionByDefault` in all accounts first, then apply this SCP to lock it in.

## Prerequisites
Enable EBS encryption by default in all accounts before applying this SCP:
```bash
aws ec2 enable-ebs-encryption-by-default --region REPLACE_WITH_YOUR_REGION
```
Verify:
```bash
aws ec2 get-ebs-encryption-by-default --region REPLACE_WITH_YOUR_REGION
# Should return: {"EbsEncryptionByDefault": true}
```

## How to apply
```bash
aws organizations create-policy \
  --name "deny-ebs-encryption-disable" \
  --description "Prevent disabling default EBS encryption" \
  --content file://deny-ebs-encryption-disable.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to disable EBS encryption — expect AccessDenied
aws ec2 disable-ebs-encryption-by-default --region REPLACE_WITH_YOUR_REGION
```

## Exceptions and customisation
No exceptions. There is no legitimate reason to disable EBS encryption by default in a production environment.

Pair this with [deny-unencrypted-ebs-volumes](../deny-unencrypted-ebs-volumes/) to also block attaching or snapshotting unencrypted volumes.

## References
- [CIS AWS Foundations Benchmark v2 — 2.2.1](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS — EBS encryption by default](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html#encryption-by-default)
- [PCI-DSS requirement 3.5 — Protect stored account data](https://www.pcisecuritystandards.org/)
