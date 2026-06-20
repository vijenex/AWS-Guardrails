# deny-s3-public-access-modification

## What this does
Restricts `s3:PutBucketPublicAccessBlock` to a single designated remediation role (`S3PublicAccessRemediationRole`). All other principals — including admins — cannot modify the public access block settings on any S3 bucket. The remediation role is intended for an automated Lambda that enforces public access block on any non-compliant bucket.

## Why you need this
This is a more targeted version of [s3-hardening](../s3-hardening/) for environments that need a remediation automation role to correct non-compliant buckets. Instead of blocking `PutBucketPublicAccessBlock` entirely, it channels all modifications through a single audited role.

The use case: you have a Lambda or EventBridge-triggered automation that detects buckets where `BlockPublicAccess` is disabled (e.g., from a legacy migration) and re-enables it. This SCP ensures only that automation can make the change — manual "fixes" via console or CLI by engineers are blocked.

## Security impact if you don't apply this
Same as [s3-hardening](../s3-hardening/) — without this, any engineer with S3 permissions can disable Block Public Access on any bucket, potentially exposing data publicly.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: After applying this policy, no human can disable or modify S3 Block Public Access except via the remediation role. Ensure the remediation role exists and functions before applying.

**Step 1 — Sandbox**: Create the `S3PublicAccessRemediationRole` role. Apply SCP. Verify that `PutBucketPublicAccessBlock` from a regular admin returns `AccessDenied` but succeeds when called with the remediation role.

**Step 2 — Non-production**: Deploy and test the remediation Lambda end-to-end before applying.

**Step 3 — Production**: Apply. Monitor for legitimate use cases that need `PutBucketPublicAccessBlock` — they should all be channeled through the remediation role.

**Vijenex is not responsible for operational impact from applying this policy.**

## Prerequisites
1. Create the `S3PublicAccessRemediationRole` IAM role.
2. Optionally build a Lambda function using this role that ensures Block Public Access is always enabled.

## How to apply
```bash
# Edit role name if yours differs from "S3PublicAccessRemediationRole"
aws organizations create-policy \
  --name "deny-s3-public-access-modification" \
  --description "Restrict S3 public access block changes to remediation role only" \
  --content file://deny-s3-public-access-modification.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# As a regular admin — expect AccessDenied
aws s3api put-public-access-block \
  --bucket REPLACE_YOUR_BUCKET \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# As the remediation role (assume it first) — expect success
aws sts assume-role --role-arn arn:aws:iam::REPLACE_ACCOUNT:role/S3PublicAccessRemediationRole \
  --role-session-name test-session
# (use temporary credentials to call PutBucketPublicAccessBlock)
```

## Exceptions and customisation
Replace `S3PublicAccessRemediationRole` with whatever you name your remediation role. Keep it a single role — multiple exception roles defeat the purpose of the control.

## References
- [AWS S3 Block Public Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- [AWS Config rule — s3-bucket-public-access-prohibited](https://docs.aws.amazon.com/config/latest/developerguide/s3-bucket-public-access-prohibited.html)
