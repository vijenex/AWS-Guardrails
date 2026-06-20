# secrets-manager-hardening

## What this does
Requires all new Secrets Manager secrets to include an `Email` owner tag (for ownership notification) and an `Owner` tag. Prevents removing the `Email` tag from any secret after creation. The `Email` value should be the responsible team's on-call or distribution list.

## Why you need this
Secrets Manager is one of the most sensitive services in AWS — it stores database passwords, API keys, private keys, and OAuth tokens. Without ownership tracking:
- Secrets become orphaned after team changes, no one knows whether they are still in use or can be rotated.
- When a secret needs to be rotated urgently (post-breach), there is no way to find the owner quickly.
- Old unused secrets with broad permissions continue to represent an attack surface indefinitely.

Requiring an `Email` tag at creation time creates an ownership record that persists as long as the secret exists.

## Security impact if you don't apply this
- Orphaned secrets with no owner → credentials that are never rotated → persistent attack surface.
- No way to notify the right team when a secret is compromised or needs rotation.
- Compliance frameworks (SOC 2 CC6.1, ISO 27001 A.9.4) require access credential lifecycle management.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: After applying this policy, any automation that creates secrets without the required tags will fail. This commonly affects:
> - AWS CloudFormation stacks that create `AWS::SecretsManager::Secret` without tags
> - Terraform `aws_secretsmanager_secret` resources without tag blocks
> - Lambda functions that programmatically create secrets

**Step 1 — Sandbox**: Apply and verify that `secretsmanager:CreateSecret` without tags returns `AccessDenied`. Verify that creation with `Email` and `Owner` tags succeeds.

**Step 2 — Non-production**: Audit all automation creating secrets. Add required tags. Apply.

**Step 3 — Production**: Apply and monitor `secretsmanager:CreateSecret` CloudTrail events for `AccessDenied` for 48h.

**Vijenex is not responsible for secret creation failures from applying this policy without the testing ladder.**

## Prerequisites
- Define your tag taxonomy: what are valid `Owner` values? Who should the `Email` be?
- Update all IaC and automation that creates secrets to include these tags.

## How to apply
```bash
# Optionally customize the tag key names (currently "Email" and "Owner")
aws organizations create-policy \
  --name "secrets-manager-hardening" \
  --description "Require owner tags on Secrets Manager secrets" \
  --content file://secrets-manager-hardening.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Create secret WITHOUT tags — expect AccessDenied
aws secretsmanager create-secret \
  --name test-no-tags \
  --secret-string "testvalue"

# Create WITH required tags — expect success
aws secretsmanager create-secret \
  --name test-with-tags \
  --secret-string "testvalue" \
  --tags '[{"Key":"Email","Value":"platform-team@example.com"},{"Key":"Owner","Value":"platform-team"}]'

# Attempt to remove Email tag — expect AccessDenied
aws secretsmanager untag-resource \
  --secret-id test-with-tags \
  --tag-keys "Email"
```

## Exceptions and customisation
- Change `Email` and `Owner` to whatever tag keys your organization uses for ownership tracking.
- Consider adding `aws:RequestTag/Team` and `aws:RequestTag/Service` as additional required tags for larger organizations.
- The `DenyRemovingOwnerEmailTag` statement uses `ForAnyValue:StringEquals` — this correctly matches even when multiple tags are being removed at once.

## References
- [AWS Secrets Manager tagging](https://docs.aws.amazon.com/secretsmanager/latest/userguide/tagging.html)
- [AWS Secrets Manager secret rotation](https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets.html)
- [SOC 2 CC6.1 — Logical access](https://www.aicpa.org/resources/article/soc-2-criteria)
- [NIST SP 800-57 — Key management lifecycle](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)
