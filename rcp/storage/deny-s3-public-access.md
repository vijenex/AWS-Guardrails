# RCP: deny-s3-public-access

## What this does
A **Resource Control Policy (RCP)** that prevents any principal from modifying S3 bucket public access block settings unless they are inside your AWS Organization. Unlike SCPs (which restrict IAM principals in your org), RCPs restrict who can take actions *on* your resources — including cross-account and public access.

## Why you need this
SCPs only constrain principals *within* your organization. An external AWS account can still call APIs on your S3 buckets if the bucket policy grants them access. RCPs fill this gap: they attach to resources and restrict actions regardless of where the caller comes from.

This specific policy prevents anyone outside your org from disabling Block Public Access on your S3 buckets — eliminating cross-account misconfiguration vectors.

## When to apply this
Apply at the organization root level. RCPs apply to all resources within the organization.

## Prerequisites
- RCPs require AWS Organizations with **resource control policies** feature enabled.
- Replace `REPLACE_WITH_YOUR_ORG_ID` with your actual org ID (format: `o-xxxxxxxxxx`).

## How to apply
```bash
# Enable RCPs in your org (one-time)
aws organizations enable-policy-type \
  --root-id r-REPLACE \
  --policy-type RESOURCE_CONTROL_POLICY

# Create and attach
aws organizations create-policy \
  --name "deny-s3-public-access-rcp" \
  --content file://deny-s3-public-access.json \
  --type RESOURCE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <ID> \
  --target-id r-REPLACE_ORG_ROOT
```

## References
- [AWS Resource Control Policies documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html)
- [AWS — RCP vs SCP comparison](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_vs_rcps.html)
