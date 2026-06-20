# deny-admin-access-policies

## What this does
Blocks attaching AWS-managed `AdministratorAccess`, `PowerUserAccess`, and any `*FullAccess*` or `*Administrator*` managed policies to users, roles, or groups. Custom policies with similar permissions are not blocked by this SCP — use IAM Access Analyzer and permission boundary policies for those.

## Why you need this
`AdministratorAccess` grants `Action: * / Resource: *` — every AWS API call across every service. In the wrong hands (compromised credential, misconfigured role, new developer experiment) it enables complete account takeover: deleting security controls, creating backdoor users, exfiltrating all data, destroying infrastructure.

The most common misconfiguration that leads to privilege escalation is attaching `AdministratorAccess` as a quick fix ("I'll narrow it down later") — and it never gets narrowed down.

## Security impact if you don't apply this
- Any IAM user, role, or group can be granted full admin access by anyone with `iam:AttachRolePolicy`.
- A compromised developer credential with `iam:AttachRolePolicy` can escalate itself to full admin in one API call.
- Shadow admin roles accumulate over time, widening the blast radius of any future credential compromise.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: If your CI/CD automation or bootstrap processes currently attach `AdministratorAccess` to roles, applying this SCP will break those processes.

**Step 1 — Sandbox**: Inventory all principals with `AdministratorAccess` attached (`aws iam list-entities-for-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess`). Apply and verify they retain their existing permissions but no new attachments are possible.

**Step 2 — Non-production**: Replace any CI/CD role that uses `AdministratorAccess` with a scoped permissions policy. Apply and run full CI/CD pipeline to verify no breakage.

**Step 3 — Production**: Apply during a deployment freeze. Monitor IAM CloudTrail for `AccessDenied` on `AttachRolePolicy` for 48h.

**Vijenex is not responsible for CI/CD pipeline failures resulting from applying this policy without completing the testing ladder.**

## Prerequisites
- Audit current `AdministratorAccess` usage: `aws iam list-entities-for-policy --policy-arn arn:aws:iam::aws:policy/AdministratorAccess`
- Replace broad policies with least-privilege alternatives before applying.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-admin-access-policies" \
  --description "Block attaching AdministratorAccess and FullAccess managed policies" \
  --content file://deny-admin-access-policies.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt to attach AdministratorAccess — expect AccessDenied
aws iam attach-role-policy \
  --role-name REPLACE_WITH_ANY_ROLE \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Attempt to attach S3FullAccess — expect AccessDenied
aws iam attach-role-policy \
  --role-name REPLACE_WITH_ANY_ROLE \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
```

## Exceptions and customisation
- This policy does not block principals that **already have** `AdministratorAccess` from using it — it only blocks new attachments.
- For the organization management account, where Control Tower bootstrapping uses `AdministratorAccess`, apply this SCP to child OUs only.
- Do not add exceptions for specific roles using `StringNotLike` — this creates a permanent wide exception. Instead, exclude the management OU from this policy.

## References
- [AWS IAM — Managed policies best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [MITRE ATT&CK — T1098.001 Account Manipulation: Additional Cloud Credentials](https://attack.mitre.org/techniques/T1098/001/)
- [AWS Well-Architected — Least privilege access](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/permissions-management.html)
- [CIS AWS Foundations Benchmark — 1.16](https://www.cisecurity.org/benchmark/amazon_web_services)
