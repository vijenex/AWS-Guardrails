# deny-ssm-unprivileged-roles

## What this does
Blocks SSM Session Manager, SSM Send Command, and the underlying SSM Messages and EC2 Messages APIs for roles that are read-only or unprivileged (e.g., `ReadOnly-Access`, `ViewOnly-Access`, `CostExplorer-ViewOnly` SSO permission sets). These roles cannot start interactive sessions or run commands on EC2 instances.

## Why you need this
AWS SSM Session Manager provides interactive shell access to EC2 instances. AWS IAM policies might grant `ssm:StartSession` to a broad role for convenience, but:
- A read-only role that can start an SSM session is not actually read-only — it can run any command on the instance as root/admin.
- Developers or analysts with read-only AWS Console access can pivot to full OS-level access via SSM.
- SSM sessions bypass all network controls — there is no VPN, SSH key, or security group involved.

This policy customizes the block list to match the unprivileged SSO roles in your environment. Update the `ArnLike` list to match your actual read-only permission sets.

## Security impact if you don't apply this
- "Read-only" users can actually run arbitrary commands on all EC2 instances if SSM permissions are not properly scoped.
- Analysts with cost or read-only access can pivot to administrative OS access.
- SSM sessions are audited in CloudTrail but not blocked — detection after the fact is insufficient for production.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: This policy requires you to edit the `ArnLike` list to match the **exact names of your SSO permission sets**. The placeholder names (`ReadOnly-Access`, `ViewOnly-Access`, `CostExplorer-ViewOnly`) are examples — they must match your organization's IAM Identity Center permission set names.

**Step 1 — Sandbox**: Replace placeholder role names with your actual read-only SSO role ARN patterns. Apply. Verify that a read-only role user cannot start an SSM session. Verify that a privileged role user can.

**Step 2 — Non-production**: Verify no legitimate operational automation uses read-only roles for SSM commands (this should be zero).

**Step 3 — Production**: Apply. Notify read-only role users that SSM shell access is now blocked. Monitor SSM CloudTrail events for `AccessDenied`.

**Vijenex is not responsible for operational disruptions from applying this policy with incorrect role names.**

## Prerequisites
Identify your unprivileged SSO permission set names:
```bash
aws sso-admin list-permission-sets-provisioned-to-account \
  --instance-arn REPLACE_WITH_YOUR_SSO_INSTANCE_ARN \
  --account-id REPLACE_WITH_ACCOUNT_ID
```
List the resulting permission set names and update the `ArnLike` condition to match.

## How to apply
```bash
# IMPORTANT: Edit the JSON first — replace placeholder role names with your actual SSO role patterns
aws organizations create-policy \
  --name "deny-ssm-unprivileged-roles" \
  --description "Block SSM session access for read-only SSO roles" \
  --content file://deny-ssm-unprivileged-roles.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# As a read-only role user — expect AccessDenied
aws ssm start-session --target i-REPLACE_INSTANCE_ID

# As a privileged role user — expect success (opens session)
aws ssm start-session --target i-REPLACE_INSTANCE_ID
```

## Exceptions and customisation
- **Pattern format**: SSO roles follow the pattern `AWSReservedSSO_<PermissionSetName>_<RandomSuffix>`. The `*` wildcard at the end matches any suffix. Use `ArnLike` (not `ArnEquals`) with the wildcard suffix.
- **Blocking all non-privileged roles**: to be more aggressive, reverse the logic — use `ArnNotLike` to block everyone except specifically named privileged roles. This requires less maintenance as you only whitelist, not blacklist.
- **Send Command**: `ssm:SendCommand` allows running scripts on instances — ensure it is blocked alongside `StartSession`.

## References
- [AWS SSM Session Manager security](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-security-considerations.html)
- [AWS — IAM Identity Center permission sets](https://docs.aws.amazon.com/singlesignon/latest/userguide/permissionsetsconcept.html)
- [NIST SP 800-190 — Principle of least privilege for container/compute access](https://csrc.nist.gov/publications/detail/sp/800-190/final)
