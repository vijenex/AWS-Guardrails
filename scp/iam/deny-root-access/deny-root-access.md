# deny-root-access

## What this does
Blocks all API actions and access key creation by the AWS root user across every account in the organizational unit. Any call where `aws:PrincipalArn` matches the root ARN pattern is unconditionally denied.

## Why you need this
The root user bypasses IAM permission boundaries and cannot be restricted by SCPs once it is actively operating — it is the single most dangerous credential in any AWS account. CISA Advisory AA21-243A and AWS Well-Architected Framework both recommend treating root as a break-glass identity used only for the handful of tasks that explicitly require it (account recovery, billing settings, Support plan changes). Routine API access via root has led to account-level compromise in multiple public incidents.

## When to apply this
Apply to every OU except the management (root) account OU. The management account is explicitly excluded from SCP enforcement by AWS; apply equivalent IAM policies and monitoring there instead.

Do **not** remove or weaken this policy as a shortcut to fix broken automation. Fix the automation to use an IAM role instead.

## Prerequisites
- AWS Organizations with SCPs enabled.
- Existing automation and CI/CD pipelines must be using IAM roles, not root credentials. Audit with `aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=root` before applying.

## How to apply
```bash
# Create the policy
aws organizations create-policy \
  --name "deny-root-access" \
  --description "Deny all root user API activity" \
  --content file://deny-root-access.json \
  --type SERVICE_CONTROL_POLICY

# Attach to target OU (replace OU_ID)
aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt any API call as root — it should be denied with AccessDenied
aws sts get-caller-identity   # run this while logged in as root

# Verify in CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GetCallerIdentity \
  | jq '.Events[] | select(.Username == "root")'
```
Expected: `An error occurred (AccessDenied)` for all root API calls.

## Exceptions and customisation
There are **no** exceptions in this policy. Root is always blocked.

The handful of actions that require root (closing an account, changing the Support plan, enabling/disabling certain billing features) must be performed via the AWS Console with MFA, which bypasses the API restriction check — the SCP only applies to API calls, not console login itself.

Do not add `StringNotEquals` exception conditions for specific roles here — that pattern is fragile under role assumption chains.

## References
- [AWS — Tasks that require root credentials](https://docs.aws.amazon.com/accounts/latest/reference/root-user-tasks.html)
- [CIS AWS Foundations Benchmark v2 — 1.7](https://www.cisecurity.org/benchmark/amazon_web_services)
- [CISA Advisory AA21-243A](https://www.cisa.gov/news-events/cybersecurity-advisories/aa21-243a)
- [AWS Well-Architected — SEC 02](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_identities_enforce_mechanisms.html)
