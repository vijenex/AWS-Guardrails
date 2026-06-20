# protect-controltower

## What this does
Locks all AWS Control Tower managed resources — CT-named CloudTrail trails, Config rules and recorders, IAM roles (`aws-controltower-*`, `*AWSControlTower*`, `stacksets-exec-*`), Lambda functions, SNS topics, CloudWatch log groups, audit S3 buckets, and EventBridge rules — from modification by anyone except the `AWSControlTowerExecution` role.

## Why you need this
AWS Control Tower installs and manages a set of security baseline resources in every enrolled account (CloudTrail, Config, GuardDuty, Lambda lifecycle hooks, SNS notifications). These are your central governance infrastructure.

If a team member with IAM permissions modifies or deletes these resources:
- CloudTrail stops logging → forensic gap
- Config stops evaluating → compliance drift goes undetected
- SNS security notifications stop → alert pipeline breaks silently

Control Tower does not protect its own resources by default — it relies on SCPs to do so. This policy is the standard way to lock CT infrastructure from member account modification.

## Security impact if you don't apply this
- Any member account admin can delete `aws-controltower` CloudTrail trails and Log Groups.
- Config rule modifications are possible without this protection, causing compliance gaps.
- Silent breakage of the security notification pipeline (SNS) goes undetected until a security review.

## ⚠️ Disclaimer and Testing Ladder
This policy should be applied to **all accounts enrolled in Control Tower**. It is a standard CT best practice.

**Step 1 — Sandbox**: Apply and verify that `cloudtrail:DeleteTrail` on a CT trail returns `AccessDenied`.

**Step 2 — Non-production**: Verify that the Control Tower account vending process (`AWSControlTowerExecution` role) still functions normally after applying.

**Step 3 — Production**: Apply across the organization. This is standard Control Tower hardening — low operational risk.

**Vijenex is not responsible for CT governance gaps from not applying this policy.**

## Prerequisites
- AWS Control Tower must be set up in your management account.
- The `AWSControlTowerExecution` role must exist in each account (CT creates it automatically during enrollment).

## How to apply
```bash
aws organizations create-policy \
  --name "protect-controltower" \
  --description "Protect Control Tower managed resources from modification" \
  --content file://protect-controltower.json \
  --type SERVICE_CONTROL_POLICY

# Attach to the root or the top-level OU (below management account)
aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <ROOT_OR_TOP_OU_ID>
```

## How to test
```bash
# Attempt to delete a CT CloudTrail trail — expect AccessDenied
aws cloudtrail delete-trail --name aws-controltower-BaselineCloudTrail

# Attempt to modify CT Config recorder — expect AccessDenied
aws configservice delete-configuration-recorder \
  --configuration-recorder-name aws-controltower-BaselineConfigRecorder
```

## Exceptions and customisation
This policy is intentionally narrow: it only protects resources with `aws-controltower-*` names or the CT management tags. Your own Config rules and CloudTrail trails are not affected.

## References
- [AWS Control Tower — SCP guardrails documentation](https://docs.aws.amazon.com/controltower/latest/userguide/guardrails.html)
- [AWS — Protecting Control Tower resources with SCPs](https://docs.aws.amazon.com/controltower/latest/userguide/scp-ct.html)
- [AWS Control Tower security best practices](https://docs.aws.amazon.com/controltower/latest/userguide/security.html)
