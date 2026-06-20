# deny-chatbot-iam

## What this does
Blocks all IAM API actions (`iam:*`) when the request originates from AWS Chatbot (Slack or Microsoft Teams integration). The `aws:ChatbotSourceArn` condition key identifies calls routed through Chatbot.

## Why you need this
AWS Chatbot allows users to run AWS CLI commands and invoke Lambda functions via Slack messages. If Chatbot is configured with a role that has IAM permissions, a Slack message like `/aws iam create-user --user-name backdoor` creates a real IAM user. This:
- Bypasses normal CI/CD governance for IAM changes
- Creates an audit trail in Slack instead of standard IAM access logs
- Can be triggered by anyone in the Slack channel, not just people with direct AWS console access
- Is difficult to detect because the caller in CloudTrail shows as the Chatbot role, not the Slack user

Chatbot is useful for read-only operations and notifications. IAM mutations should only happen through approved tooling with proper review processes.

## Security impact if you don't apply this
- Any Slack channel member with access to a Chatbot integration can modify IAM resources if the Chatbot role has IAM permissions.
- IAM changes via Chatbot are harder to tie to a specific human identity in audit logs.
- Compromised Slack accounts can be used to modify IAM in AWS accounts.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: If any operational runbook involves IAM commands via Chatbot (e.g., `iam:GetRole`, `iam:ListUsers` for diagnostics), those will also be blocked. Review all Chatbot configurations before applying.

**Step 1 — Sandbox**: Send an IAM read command via Chatbot (e.g., `aws iam list-users`) and verify it returns `AccessDenied`.

**Step 2 — Non-production**: Check all Chatbot channel configurations for IAM-related commands in runbooks. Update runbooks to use the AWS Console or CLI directly.

**Step 3 — Production**: Apply and notify all teams using Chatbot. Monitor Chatbot-originated CloudTrail events for `AccessDenied` on `iam:*` for 48h.

**Vijenex is not responsible for Chatbot operational disruptions from applying this policy without the testing ladder.**

## Prerequisites
- Inventory all Chatbot integrations: AWS Console → AWS Chatbot → Configured clients
- Review which roles Chatbot uses and what IAM permissions they have

## How to apply
```bash
aws organizations create-policy \
  --name "deny-chatbot-iam" \
  --description "Block IAM actions via AWS Chatbot" \
  --content file://deny-chatbot-iam.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
In your Slack channel with AWS Chatbot configured:
```
@aws iam list-users
```
Expected: `AccessDenied` error returned in Slack.

Check CloudTrail:
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventSource,AttributeValue=iam.amazonaws.com \
  | jq '.Events[] | select(.CloudTrailEvent | contains("chatbot"))'
```

## Exceptions and customisation
- To allow read-only IAM via Chatbot, change `iam:*` to specific write actions only:
  ```json
  "Action": ["iam:Create*","iam:Delete*","iam:Update*","iam:Put*","iam:Attach*","iam:Detach*"]
  ```
- No exceptions for specific Chatbot channels — the condition applies to all `aws:ChatbotSourceArn` origins.

## References
- [AWS Chatbot security considerations](https://docs.aws.amazon.com/chatbot/latest/adminguide/security.html)
- [AWS — aws:ChatbotSourceArn condition key](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html)
- [MITRE ATT&CK — T1098 Account Manipulation](https://attack.mitre.org/techniques/T1098/)
