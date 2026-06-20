# s3-hardening

## What this does
Four combined S3 security controls:
1. **Block static website hosting** — `s3:PutBucketWebsite` is denied for all buckets
2. **Require bucket owner enforcement** — new buckets must be created with `BucketOwnerEnforced` object ownership (disabling ACLs)
3. **Lock public access block settings** — `s3:PutBucketPublicAccessBlock` is blocked, preventing weakening of public access settings
4. **Block S3 writes from Chatbot** — prevents files being written to S3 via Slack/Teams Chatbot integrations

## Why you need this
S3 misconfiguration is the #1 cause of AWS data breaches. Each of these controls addresses a specific misconfiguration vector:

**Static website hosting**: An S3 static website URL bypasses bucket policies and can serve any content publicly. It's frequently used by attackers to exfiltrate data through a "legitimate" S3 endpoint. It also creates phishing pages and enables open redirects.

**ACL-based ownership**: S3 ACLs are a legacy access control model that can override bucket policies. `BucketOwnerEnforced` disables ACLs entirely, ensuring only bucket policies control access. Without it, cross-account object uploads can leave objects owned by the uploader, not the bucket owner.

**Public access block**: S3's "Block Public Access" is a safety net that overrides any bucket policy or ACL that would make data public. If this can be modified, an attacker can re-expose any bucket.

**Chatbot writes**: Files written to S3 via Chatbot bypass normal CI/CD review and are hard to audit. Chatbot Slack integrations should not have S3 write permissions.

## Security impact if you don't apply this
- S3 static website endpoints are not blocked by Block Public Access — a bucket can be made public via the website endpoint even with "block public access" enabled.
- Without `BucketOwnerEnforced`, cross-account object uploads can result in data the bucket owner cannot access or delete.
- Block Public Access being disabled → public bucket policies and public ACLs become effective → data exposure.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: `DenyS3PublicAccessBlockModification` prevents both enabling AND disabling Block Public Access on individual buckets. It must be applied only after all buckets have Block Public Access enabled at the account level.

**Step 1 — Sandbox**: Enable S3 Block Public Access at the account level (`aws s3control put-public-access-block --account-id ACCOUNT --public-access-block-configuration BlockPublicAcls=true,...`). Apply SCP. Verify `PutBucketPublicAccessBlock` returns `AccessDenied`. Verify bucket creation without `BucketOwnerEnforced` returns `AccessDenied`.

**Step 2 — Non-production**: Enable account-level Block Public Access in all accounts. Inventory buckets with static website hosting (`aws s3api list-buckets | jq '.Buckets[].Name' | xargs -I{} sh -c 'aws s3api get-bucket-website --bucket {} 2>/dev/null && echo {}'`). Remove website configurations. Apply.

**Step 3 — Production**: Apply after completing all inventory and remediation. Monitor S3 bucket creation CloudTrail events for 24h.

**Vijenex is not responsible for S3 operation failures from applying this policy without completing the prerequisites.**

## Prerequisites
Enable S3 Block Public Access at the account level for all accounts:
```bash
aws s3control put-public-access-block \
  --account-id REPLACE_WITH_YOUR_ACCOUNT_ID \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

## How to apply
```bash
aws organizations create-policy \
  --name "s3-hardening" \
  --description "S3 security baseline: block website hosting, require owner enforcement, lock public access" \
  --content file://s3-hardening.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to enable S3 website hosting — expect AccessDenied
aws s3api put-bucket-website \
  --bucket REPLACE_YOUR_BUCKET \
  --website-configuration '{"IndexDocument":{"Suffix":"index.html"}}'

# Attempt to create bucket without BucketOwnerEnforced — expect AccessDenied
aws s3api create-bucket --bucket test-no-ownership --region us-east-1
# (no --object-ownership flag = no BucketOwnerEnforced)

# Create with BucketOwnerEnforced — expect success
aws s3api create-bucket \
  --bucket test-with-ownership \
  --object-ownership BucketOwnerEnforced \
  --region us-east-1
```

## Exceptions and customisation
- If you have a legitimate S3 static website use case (e.g., a CDN origin), deliver it via CloudFront with an S3 origin instead — this avoids S3 website endpoints and is architecturally superior.
- The `DenyS3PublicAccessBlockModification` blocks the bucket-level setting. Account-level Block Public Access (set via `s3control`) is not affected.
- To allow a specific automation role to modify public access block settings (e.g., a remediation Lambda), use `StringNotLike` on `aws:PrincipalArn` — but only do this for a tightly scoped role with no other permissions.

## References
- [AWS S3 Block Public Access](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- [AWS S3 Object Ownership](https://docs.aws.amazon.com/AmazonS3/latest/userguide/about-object-ownership.html)
- [CIS AWS Foundations Benchmark — 2.1.5 (Block Public Access)](https://www.cisecurity.org/benchmark/amazon_web_services)
- [AWS Security Blog — Preventing S3 data exposure](https://aws.amazon.com/blogs/security/)
