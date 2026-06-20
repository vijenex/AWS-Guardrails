# deny-unencrypted-ebs-volumes

## What this does
Blocks attaching an unencrypted EBS volume to an EC2 instance, and blocks creating snapshots of unencrypted volumes. All EBS volumes that are attached or snapshotted must have `ec2:Encrypted = true`.

## Why you need this
An unencrypted EBS volume stores data in plaintext on the underlying physical storage. If the underlying hardware is decommissioned, reallocated, or accessed by AWS support under a legal order, the data is readable without any key material.

More practically: EBS snapshots can be shared cross-account or made public. An unencrypted snapshot of a database volume exposes your entire dataset to anyone who can access the snapshot. Public unencrypted snapshots are a common source of data breaches — AWS publicly disclosed that misconfigured public snapshots exposed data for hundreds of organizations.

Encryption at rest is a baseline requirement in PCI-DSS, HIPAA, SOC 2, and most enterprise security frameworks.

## Security impact if you don't apply this
- **Data at rest exposure**: unencrypted EBS volumes can be accessed by AWS personnel under legal process, or via physical media if hardware is decommissioned insecurely.
- **Snapshot leakage**: any snapshot of an unencrypted volume is itself unencrypted and can be copied cross-account, shared publicly, or made world-readable by accident.
- **Compliance failure**: PCI-DSS requirement 3.5, HIPAA §164.312(a)(2)(iv), and CIS 2.2.1 all require encryption at rest for stored data.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: Applying this policy in an account that has existing unencrypted volumes will block future attach and snapshot operations for those volumes. It does NOT terminate running instances, but it will prevent reattaching a detached unencrypted volume.

**Required testing sequence — do not skip steps:**

**Step 1 — Sandbox**
```bash
# In a sandbox account with no production data:
aws organizations attach-policy --policy-id <ID> --target-id <SANDBOX_OU>
# Attempt to attach an unencrypted volume — verify AccessDenied
# Verify existing running instances are unaffected
```

**Step 2 — Non-production**
```bash
# Inventory unencrypted volumes in non-prod BEFORE applying:
aws ec2 describe-volumes \
  --filters "Name=encrypted,Values=false" \
  --query 'Volumes[*].{ID:VolumeId,State:State}' --output table
# Encrypt or replace all listed volumes, then apply
```

**Step 3 — Production**
```bash
# Same inventory check in production — do NOT proceed with any unencrypted volumes
# Apply during a maintenance window, notify on-call team
# Monitor CloudTrail for AccessDenied events in the 24h after applying
```

**Vijenex is not responsible for any operational impact resulting from applying this policy to accounts without completing the testing ladder above.**

## Prerequisites
1. Enable EBS encryption by default in all target accounts (see [deny-ebs-encryption-disable](../deny-ebs-encryption-disable/)).
2. Inventory and encrypt all existing unencrypted volumes using the EBS "Encrypt in-place" workflow or by creating encrypted snapshots and restoring.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-unencrypted-ebs-volumes" \
  --description "Block attaching or snapshotting unencrypted EBS volumes" \
  --content file://deny-unencrypted-ebs-volumes.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Create an unencrypted volume (this will succeed — creation is not blocked)
aws ec2 create-volume --size 1 --availability-zone REPLACE_WITH_AZ --no-encrypted

# Attempt to attach it — expect AccessDenied
aws ec2 attach-volume --volume-id vol-REPLACE --instance-id i-REPLACE --device /dev/sdf
```

## Exceptions and customisation
No exceptions recommended. If a specific application has a hard dependency on unencrypted volumes (rare, legacy), isolate it in a dedicated OU without this SCP, document the exception, and set a remediation deadline.

## References
- [AWS EBS encryption at rest](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html)
- [CIS AWS Foundations Benchmark — 2.2.1](https://www.cisecurity.org/benchmark/amazon_web_services)
- [PCI-DSS v4.0 — Requirement 3.5](https://www.pcisecuritystandards.org/)
- [AWS — Public snapshot exposure notifications](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/sharingamis-intro.html)
