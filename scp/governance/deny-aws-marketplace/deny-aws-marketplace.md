# deny-aws-marketplace

## What this does
Blocks all AWS Marketplace API actions. No one in the OU can subscribe to, purchase, or manage Marketplace software listings.

## Why you need this
AWS Marketplace allows purchasing third-party software directly billed to your AWS account. Without governance:
- Engineers subscribe to paid Marketplace listings without procurement approval.
- Software licenses are acquired outside of legal/vendor review processes.
- BYOL (Bring Your Own License) products create compliance issues if license tracking is centralized.
- Marketplace charges are embedded in AWS bills and can be missed during cost review.
- Security-unreviewed software can be deployed via Marketplace without proper vetting.

Organizations typically centralize Marketplace procurement through a single purchasing account or through AWS Organizations' Marketplace governance controls.

## Security impact if you don't apply this
- Unvetted third-party software can be deployed from Marketplace listings.
- Software with known vulnerabilities or backdoors can enter the environment through subscriptions.
- Shadow IT procurement bypasses security review processes.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: If any existing workloads rely on software running from Marketplace subscriptions (e.g., a Marketplace AMI, a Marketplace SaaS product), applying this will block subscription management. The existing running software continues to work, but subscription renewals or changes may be blocked.

**Step 1 — Sandbox**: Apply and verify `aws-marketplace:DescribeListings` returns `AccessDenied`.

**Step 2 — Non-production**: Inventory Marketplace subscriptions (`AWS Console → AWS Marketplace → Manage subscriptions`). Document any active subscriptions before applying.

**Step 3 — Production**: Apply to production OUs where procurement should be controlled. Keep one designated procurement account excluded from this SCP for purchasing.

**Vijenex is not responsible for procurement disruptions from applying this policy.**

## Prerequisites
Designate a procurement account (or the management account) for Marketplace purchases and exclude it from this SCP.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-aws-marketplace" \
  --description "Block all AWS Marketplace actions" \
  --content file://deny-aws-marketplace.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Attempt any Marketplace action — expect AccessDenied
aws marketplace-catalog list-entities \
  --catalog AWSMarketplace \
  --entity-type AmiProduct \
  --region us-east-1
```

## Exceptions and customisation
If your organization uses a specific Marketplace product in a workload OU, you can allow only `DescribeProduct` (read-only):
```json
"Action": ["aws-marketplace:Subscribe","aws-marketplace:Unsubscribe","aws-marketplace:AcceptAgreementApprovalRequest"]
```
(block transactional actions but allow reads)

## References
- [AWS Marketplace governance overview](https://docs.aws.amazon.com/marketplace/latest/buyerguide/govcloud-access.html)
- [AWS Organizations — Marketplace management](https://docs.aws.amazon.com/marketplace/latest/buyerguide/private-marketplace.html)
