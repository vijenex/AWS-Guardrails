# deny-community-amis

## What this does
Blocks `ec2:RunInstances` when the source AMI is a community (public marketplace/shared) AMI. Only AWS-owned AMIs (Amazon Linux, Windows Server, etc.) and private AMIs owned by your account or approved accounts are allowed.

## Why you need this
The AWS community AMI catalog contains hundreds of thousands of images — the vast majority are legitimate, but there is no vetting process. Malicious actors have published AMIs that appear to be standard images (Ubuntu, CentOS, etc.) but contain:
- Cryptomining software activated on first launch
- Backdoor accounts with hardcoded credentials
- Pre-installed reverse shells that call back to attacker infrastructure
- Modified system binaries designed to persist through standard patching

AWS Security Blog documented community AMI abuse in 2022 where cryptominers were embedded in AMIs with names like "ubuntu-22.04-clean". There is no SLA or audit trail for who published a community AMI.

## When to apply this
- Apply to all production OUs.
- Apply to developer OUs where developers might grab a convenient community AMI without realizing the risk.
- Use alongside [enforce-golden-ami](../enforce-golden-ami/) for defense in depth: this blocks community AMIs, the golden AMI policy restricts to an approved list.

## Prerequisites
- Maintain a private AMI catalog in your AWS account or an AMI sharing account. Developers must use only approved AMIs.
- Use EC2 Image Builder or HashiCorp Packer to build hardened private AMIs from AWS-owned base images.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-community-amis" \
  --description "Block EC2 launches using community (public) AMIs" \
  --content file://deny-community-amis.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Find a community AMI ID for testing
COMMUNITY_AMI=$(aws ec2 describe-images \
  --filters "Name=image-type,Values=machine" "Name=is-public,Values=true" \
  --query 'Images[0].ImageId' --output text \
  --owners community)

# Attempt to launch it — expect AccessDenied
aws ec2 run-instances \
  --image-id $COMMUNITY_AMI \
  --instance-type t3.micro \
  --count 1

# Launch from your private AMI — expect success
aws ec2 run-instances \
  --image-id ami-REPLACE_WITH_YOUR_PRIVATE_AMI \
  --instance-type t3.micro \
  --count 1
```

## Exceptions and customisation
- AWS-owned public AMIs (Amazon Linux, Windows) are **not** community AMIs — they have `ec2:ImageType = "machine"` and owner `amazon`. This policy only blocks `community` type.
- If you use AMIs shared from a partner account (ISV AMIs), they arrive as `private` type AMIs (shared to your account) — they are not blocked.
- To restrict even further to specific approved AMI IDs, use [enforce-golden-ami](../enforce-golden-ami/).

## References
- [AWS Security Blog — Malicious AMIs in the community catalog](https://aws.amazon.com/blogs/security/)
- [CIS AWS Foundations Benchmark — EC2 image governance](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS EC2 Image Builder](https://docs.aws.amazon.com/imagebuilder/latest/userguide/what-is-image-builder.html)
