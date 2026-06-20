# restrict-regions

## What this does
Blocks creating infrastructure resources (compute, storage, databases, networking, AI/ML, serverless, and more) in any AWS region not in the approved list. Replace `REPLACE_WITH_YOUR_PRIMARY_REGION` and `REPLACE_WITH_YOUR_SECONDARY_REGION` with your actual approved region codes (e.g., `ap-south-1`, `us-east-1`).

## Why you need this
Without a region restriction, anyone with AWS permissions can create resources in any of AWS's 30+ regions. This creates:

1. **Data residency violations**: your data may be stored in regions that violate your legal or contractual obligations (GDPR, data sovereignty laws, customer contracts).
2. **Compliance scope creep**: your audit and compliance controls only cover known regions. Resources in unenforced regions are invisible to centralized security monitoring.
3. **Cost sprawl**: forgotten resources in unexpected regions continue incurring charges indefinitely.
4. **Incident response blind spots**: if an attacker creates infrastructure in an unmonitored region, you may not detect it for weeks.

## Security impact if you don't apply this
- Attackers who compromise credentials commonly create crypto-mining infrastructure in less-monitored regions (us-west-1, eu-west-3) to avoid detection by region-scoped alerts.
- GDPR Article 46 and similar laws require data to remain in approved jurisdictions — uncontrolled region usage creates automatic violations.
- GuardDuty, Security Hub, and CloudWatch alarms must be enabled per-region — regions outside your approved list likely have no monitoring at all.

## ⚠️ Disclaimer and Testing Ladder
> **WARNING**: This is one of the most impactful SCPs. It will immediately block any user from creating resources in unapproved regions. Any existing automation targeting unapproved regions will fail.

**Step 1 — Sandbox**: Fill in your region list (minimum 1 region). Apply to sandbox OU. Attempt to create an EC2 instance in a blocked region — expect `AccessDenied`. Attempt in an approved region — expect success.

**Step 2 — Non-production**: Run a full infrastructure discovery first:
```bash
# List all regions with active resources (requires Resource Explorer or manual per-region audit)
aws ec2 describe-regions --query 'Regions[*].RegionName' --output text | \
  tr '\t' '\n' | xargs -I{} sh -c 'COUNT=$(aws ec2 describe-instances --region {} --query "length(Reservations)" --output text 2>/dev/null); [ "$COUNT" -gt "0" ] && echo "{}: $COUNT instances"'
```
Migrate any resources in unapproved regions before applying.

**Step 3 — Production**: Apply during a change freeze. Validate for 48h. Keep a list of approved regions in your runbook for quick reference.

**Vijenex is not responsible for infrastructure failures from applying this policy before completing the regional resource audit.**

## Prerequisites
1. Audit all active regions with resources: use AWS Resource Explorer or the per-service discovery commands above.
2. Migrate or decommission all resources outside the approved region list.
3. Update all IaC (Terraform, CDK, CloudFormation) to target only approved regions.

## How to apply
```bash
# Edit the JSON file and replace the placeholder region values, then:
aws organizations create-policy \
  --name "restrict-regions" \
  --description "Block resource creation outside approved AWS regions" \
  --content file://restrict-regions.json \
  --type SERVICE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <OU_ID>
```

## How to test
```bash
# Create an EC2 instance in a BLOCKED region — expect AccessDenied
aws ec2 run-instances \
  --image-id ami-00000000000000000 \
  --instance-type t3.micro \
  --count 1 \
  --region eu-central-1    # Replace with a region NOT in your approved list

# Create in an APPROVED region — expect success
aws ec2 run-instances \
  --image-id ami-REPLACE_YOUR_AMI \
  --instance-type t3.micro \
  --count 1 \
  --region REPLACE_WITH_YOUR_PRIMARY_REGION
```

## Exceptions and customisation
- **Global services** (IAM, Route 53, CloudFront, WAF v1, STS, S3 bucket creation) use `us-east-1` as their API endpoint even when the resource is global. If you exclude `us-east-1`, these API calls may be affected. Test thoroughly.
- **Per-OU approved lists**: different OUs can have different approved region sets. A marketing team may only need one region; a global platform may need five.
- **Adding a new region**: update the policy JSON to add the new region code, test in non-prod, then apply the update to the SCP.

## References
- [AWS — AWS Regions and endpoints](https://docs.aws.amazon.com/general/latest/gr/rande.html)
- [GDPR — Chapter V data transfers to third countries](https://gdpr.eu/chapter-5-transfer-of-personal-data-to-third-countries/)
- [AWS Well-Architected — Reduce attack surface](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/reducing-attack-surface.html)
- [CIS AWS Foundations Benchmark — region restriction recommendations](https://www.cisecurity.org/benchmark/amazon_web_services)
