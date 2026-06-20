# enforce-golden-ami

## What this does
Blocks `ec2:RunInstances` unless the specified AMI ID is in an explicitly approved list. Any AMI not on the list — community, personal experiments, or unlisted AWS-owned — is denied.

## Why you need this
Configuration drift begins with the first unapproved AMI. An approved "golden AMI" program ensures that:
- All instances share a known-good baseline (OS version, security agents, hardening settings, logging config).
- Security patches are centrally applied to the golden AMI and propagate to new instances automatically.
- Supply chain risks are eliminated — only AMIs that passed your internal build and scan pipeline are launchable.

Without this control, developers inevitably launch from whatever AMI is convenient, leading to a heterogeneous fleet with varying patch levels and missing security tooling.

## When to apply this
- Apply to production and pre-production OUs where fleet consistency is required.
- Maintain this policy as part of your AMI lifecycle process: add new AMI IDs when a new golden image is released, remove expired ones.
- In developer OUs with more autonomy, use [deny-community-amis](../deny-community-amis/) instead for a softer control.

## Prerequisites
1. Establish a golden AMI build pipeline (EC2 Image Builder, Packer, or equivalent).
2. All approved AMI IDs must be added to the `ec2:ImageId` list before attaching this policy.
3. Regularly update this policy — if the AMI list goes stale, new instances cannot be launched.

## How to apply
```bash
# Edit the JSON — replace REPLACE_WITH_APPROVED_AMI_ID_* with your actual AMI IDs
# Then:
aws organizations create-policy \
  --name "enforce-golden-ami" \
  --description "Restrict EC2 launches to approved golden AMI IDs" \
  --content file://enforce-golden-ami.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Launch from a non-approved AMI — expect AccessDenied
aws ec2 run-instances \
  --image-id ami-00000000000000000 \
  --instance-type t3.micro --count 1

# Launch from an approved AMI — expect success
aws ec2 run-instances \
  --image-id REPLACE_WITH_APPROVED_AMI_ID_1 \
  --instance-type t3.micro --count 1
```

## Exceptions and customisation
- **AMI rotation**: When you release a new golden AMI, update the policy first (add new ID), then remove the old ID after all instances using the old AMI have been replaced.
- **Automation roles**: Services like AWS Backup restore and Auto Scaling may use AMIs referenced in launch templates — ensure all referenced AMIs are on the approved list before applying.
- **Region-specific AMIs**: AMI IDs are region-specific. If you operate in multiple regions, you will need a separate approved list per region, or use a different matching strategy (e.g., AMI tag-based enforcement via AWS Config).

## References
- [AWS EC2 Image Builder](https://docs.aws.amazon.com/imagebuilder/latest/userguide/what-is-image-builder.html)
- [AWS Whitepaper — EC2 AMI security best practices](https://docs.aws.amazon.com/whitepapers/latest/ec2-security/ec2-security.html)
- [CIS AMI hardening benchmarks](https://www.cisecurity.org/cis-hardened-images/)
