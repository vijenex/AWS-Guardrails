# Declarative Policy: enforce-imdsv2-declarative

## What this does
An **EC2 Declarative Policy** (AWS Organizations) that enforces IMDSv2 (token-based Instance Metadata Service) account-wide and restricts the metadata HTTP hop limit to 1. Unlike an SCP (which prevents API calls), a declarative policy enforces a configuration baseline directly on all existing and new EC2 instances — it functions like a permanent config override.

**What gets enforced:**
- `httpTokensState: required` — IMDSv1 (credential-free, unprotected HTTP GET to 169.254.169.254) is disabled on all instances.
- `httpPutResponseHopLimit: 1` — Limits metadata token requests to originate from within the instance itself (TTL = 1 hop). Prevents container escape attacks where a container-level SSRF reaches the host metadata service.

## Why you need this
IMDSv1 is trivially abusable via SSRF: any web application with a GET-to-arbitrary-URL vulnerability can be used to fetch AWS credentials from `http://169.254.169.254/latest/meta-data/iam/security-credentials/ROLE`. IMDSv2 requires a PUT request with a session token, which eliminates reflective SSRF as an attack path.

The hop limit of 1 closes an additional vector where containers running on the host EC2 instance can query the metadata service to steal the EC2 instance role credentials.

> **Difference from SCP version**: The `enforce-imdsv2` SCP (in `scp/compute/`) blocks the API call `ec2:RunInstances` if `ec2:MetadataHttpTokens != required`. This declarative policy enforces the setting on all instances regardless of how they were launched — including instances that existed before the SCP was applied.

## Security impact if you don't apply this
- **SSRF-to-credential-theft**: Any SSRF vulnerability in your applications can lead to AWS credential exfiltration via IMDSv1.
- **Container credential theft**: Containers with network access to 169.254.169.254 can steal the host EC2 instance role.
- Attackers can pivot from a compromised web app to full AWS account access in seconds.
- Referenced in MITRE ATT&CK: **T1552.005** (Unsecured Credentials: Cloud Instance Metadata API).

## ⚠️ Disclaimer
> **Vijenex is not responsible for any accidental policy applied directly in production.**
>
> EC2 Declarative Policies are applied at the AWS Organizations level and immediately affect all instances in the attached scope. Test before attaching at a wide scope. Applications using IMDSv1 SDKs (old versions of AWS SDK for Java v1, Python boto2, etc.) may break.

## Testing ladder
1. **Sandbox**: Apply to a single test OU. Launch an EC2 instance. Try `curl http://169.254.169.254/latest/meta-data/iam/security-credentials/` — expect 401. Try `curl -H "X-aws-ec2-metadata-token: TOKEN" http://169.254.169.254/latest/meta-data/` — expect success.
2. **Non-production**: Apply to dev/staging OUs. Monitor CloudWatch for application errors related to credential retrieval.
3. **Production**: Apply during a low-traffic window. Monitor EC2 instance health and application metrics for 24 hours.

## Prerequisites
- AWS Organizations with **Declarative Policies** enabled for EC2.
- Policy type must be enabled: `aws organizations enable-policy-type --root-id r-XXXX --policy-type DECLARATIVE_POLICY_EC2`
- Audit all running instances and confirm they support IMDSv2 (all modern AMIs do; very old custom AMIs may not).
- Audit all applications for IMDSv1 SDK usage: `grep -r "169.254.169.254" .` in application code.

## How to apply
```bash
# Enable Declarative Policies in your org (one-time)
aws organizations enable-policy-type \
  --root-id r-REPLACE_ORG_ROOT \
  --policy-type DECLARATIVE_POLICY_EC2

# Create the policy
aws organizations create-policy \
  --name "enforce-imdsv2-declarative" \
  --content file://enforce-imdsv2-declarative.json \
  --type DECLARATIVE_POLICY_EC2

# Attach to OU or root
aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id ou-REPLACE_TARGET_OU
```

## How to test
```bash
# On a running EC2 instance in the target OU:

# IMDSv1 — should return 401 (Unauthorized)
curl -s -o /dev/null -w "%{http_code}" http://169.254.169.254/latest/meta-data/

# IMDSv2 — should return 200 and list metadata keys
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/
```

## Exceptions and customization
- If specific instance types require IMDSv1 (legacy OS, old SDKs), target this policy to an OU that excludes those accounts.
- `instanceMetadataTags` is set to allow both `disabled` and `enabled` — you can restrict it to `disabled` only if you don't use metadata tag lookups.
- The hop limit of 1 may need to be 2 if you use ECS on EC2 (container→host→IMDS = 2 hops). Update `allowedRange.max` and `default` accordingly.

## References
- [AWS EC2 Declarative Policies documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_declarative.html)
- [IMDSv2 — how it works](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)
- [AWS blog: Protect against SSRF with IMDSv2](https://aws.amazon.com/blogs/security/defense-in-depth-open-firewalls-reverse-proxies-ssrf-vulnerabilities-ec2-instance-metadata-service/)
- MITRE ATT&CK: T1552.005 — Unsecured Credentials: Cloud Instance Metadata API
