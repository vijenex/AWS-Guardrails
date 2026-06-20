# deny-iam-access-keys

## What this does
Blocks creation of new IAM access key pairs and blocks reactivating existing deactivated access keys. All programmatic access must use IAM roles with temporary credentials (STS `AssumeRole`) instead of static long-lived access keys.

## Why you need this
IAM access keys are the single most common source of AWS credential exposure. They are:
- Committed to git repositories (GitHub secret scanning found 6 million+ exposed keys in 2023)
- Hardcoded in application config files, Docker images, and CI/CD pipelines
- Valid indefinitely unless explicitly rotated or deleted
- Impossible to scope to a single IP or source without additional controls

Once an access key is leaked, an attacker has persistent programmatic access to your AWS account from anywhere in the world until you notice and rotate it. The average dwell time between key exposure and discovery is weeks.

IAM roles with temporary credentials (maximum 12h lifetime) eliminate this attack surface entirely — a leaked temporary token expires automatically.

## Security impact if you don't apply this
- Static access keys that leak via git, S3 public buckets, or misconfigured apps give attackers persistent access.
- Key rotation policies are rarely enforced without tooling — CIS requires rotation every 90 days, but most keys are years old in practice.
- A single leaked access key with broad permissions can lead to full account compromise.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: This is a high-impact policy. Any service, CI/CD pipeline, or application currently using IAM access keys will lose the ability to create new keys. Existing keys continue to work — but they cannot be replaced when rotated or compromised.

**Step 1 — Sandbox**: Apply and verify `aws iam create-access-key --user-name REPLACE` returns `AccessDenied`.

**Step 2 — Non-production**: Audit all existing access keys (`aws iam list-users | jq '.Users[].UserName' | xargs -I{} aws iam list-access-keys --user-name {}`). Migrate every service to role-based access. Verify CI/CD pipelines use OIDC federation (GitHub Actions → OIDC, Jenkins → EC2 role). Apply only after migration is complete.

**Step 3 — Production**: Apply only after non-prod has been clean for at least one full release cycle. Keep emergency break-glass procedure documented for access key creation in the management account (excluded from this SCP).

**Vijenex is not responsible for service disruptions from applying this policy before completing the migration to role-based access.**

## Prerequisites
Migrate all access key users to role-based access:
- CI/CD: use OIDC or assume-role chaining
- Applications: use EC2 instance profiles, ECS task roles, Lambda execution roles
- Scripts: use AWS CLI profiles with `credential_process` or SSO

## How to apply
```bash
aws organizations create-policy \
  --name "deny-iam-access-keys" \
  --description "Block IAM access key creation and activation" \
  --content file://deny-iam-access-keys.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Create a test IAM user
aws iam create-user --user-name test-key-user

# Attempt to create access key — expect AccessDenied
aws iam create-access-key --user-name test-key-user
```

## Exceptions and customisation
- **Break-glass exception**: if you need an exception for a specific automation role, use `StringNotLike` on `aws:PrincipalArn` with the exact role ARN. Keep exceptions to an absolute minimum and document them.
- **Existing keys**: this SCP does not deactivate or delete existing keys. Use AWS Config rule `iam-user-no-policies-check` and `access-keys-rotated` to find and remediate them.
- Do not apply to the management account OU — keep a documented break-glass user with keys there for account recovery.

## References
- [AWS — IAM best practices: use roles, not access keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#use-roles-with-aws-services)
- [GitHub — Secret scanning for AWS keys](https://docs.github.com/en/code-security/secret-scanning/about-secret-scanning)
- [CIS AWS Foundations Benchmark — 1.4 (key rotation), 1.20 (avoid access keys)](https://www.cisecurity.org/benchmark/amazon_web_services)
- [NIST SP 800-63B — Memorized secrets lifecycle](https://pages.nist.gov/800-63-3/sp800-63b.html)
