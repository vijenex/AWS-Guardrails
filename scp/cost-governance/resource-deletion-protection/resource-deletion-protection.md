# resource-deletion-protection

## What this does
Blocks deletion of critical production infrastructure across 12 AWS service categories: ECS clusters/services, OpenSearch domains, Redshift clusters, load balancers, Route 53 hosted zones, DynamoDB tables, RDS instances/clusters/snapshots, ElastiCache clusters, S3 buckets, EKS clusters, critical EC2 resources (instances, volumes, VPCs), and IAM principals.

This is a hard stop — no one can delete these resources from accounts in this OU without first detaching the SCP.

## Why you need this
Cloud ransomware and destructive attacks increasingly target infrastructure deletion rather than data exfiltration. Compromised cloud credentials with delete permissions enable:
- Deleting all RDS databases and backups → instant data loss
- Terminating all EC2 instances → complete service outage
- Deleting IAM roles → breaking application authentication
- Deleting Route 53 hosted zones → DNS blackout for all services

The 2022 Okta breach and multiple public cloud incidents involved attackers deleting resources as a destructive final step after exfiltration. This policy eliminates that attack path entirely.

Even without an attacker, accidental deletion is common:
- `terraform destroy` run against the wrong workspace
- `aws ec2 terminate-instances` with an incorrect `--instance-ids` argument
- A junior engineer cleaning up dev resources accidentally targeting prod

## Security impact if you don't apply this
- A single compromised admin credential can wipe your entire production database infrastructure in minutes.
- Insider threats can cause irreversible destruction without triggering preventive controls.
- DR and backup-only recovery from infrastructure deletion takes hours to days — far beyond most RTO targets.

## ⚠️ Disclaimer and Testing Ladder
> **CRITICAL WARNING**: This is the highest-impact SCP in this library. After applying it, NO ONE in the OU can delete any of the listed resources via API, CLI, console, or automation — including:
> - Terraform destroy (for managed resources)
> - CloudFormation stack deletion (if it tries to delete listed resources)
> - Automated cleanup Lambda functions
> - CI/CD pipeline teardown jobs
> - Your own emergency incident response procedures if they involve resource deletion

**This policy MUST only be applied to production OUs where resource deletion should require extraordinary access (detaching the SCP first).**

**Step 1 — Sandbox**: Apply and verify that `ec2:TerminateInstances`, `rds:DeleteDBInstance`, and `s3:DeleteBucket` return `AccessDenied`.

**Step 2 — Non-production**: Identify all automation that deletes resources (CI/CD teardown, cost-saving scripts, temporary environment cleanup). Build an alternative workflow: detach the SCP → perform deletion → reattach SCP (management account action). Apply only to production-isolated OUs in non-prod.

**Step 3 — Production**: Apply. Communicate to all teams that production resource deletion now requires a management-account SCP detachment as part of any change request. Document the break-glass procedure for emergency resource deletion.

**Vijenex is not responsible for any inability to delete resources after applying this policy. This is intentional behavior — ensure your operational processes account for it before applying.**

## Prerequisites
1. Document your emergency/break-glass procedure for production resource deletion (e.g., detaching the SCP from the management account using a break-glass IAM role).
2. Update all CI/CD pipelines and automated cleanup scripts to not target production OUs.
3. Test Terraform plan/apply workflows to confirm they do not include destroy operations for these resource types.

## How to apply
```bash
aws organizations create-policy \
  --name "resource-deletion-protection" \
  --description "Block deletion of critical production infrastructure resources" \
  --content file://resource-deletion-protection.json \
  --type SERVICE_CONTROL_POLICY

# Apply ONLY to production OUs
aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id <PRODUCTION_OU_ID>
```

## How to test
```bash
# Attempt to terminate an EC2 instance — expect AccessDenied
aws ec2 terminate-instances --instance-ids i-REPLACE_INSTANCE_ID

# Attempt to delete an RDS instance — expect AccessDenied
aws rds delete-db-instance \
  --db-instance-identifier REPLACE_DB_ID \
  --skip-final-snapshot

# Attempt to delete an S3 bucket — expect AccessDenied
aws s3api delete-bucket --bucket REPLACE_BUCKET_NAME
```

## Emergency resource deletion procedure
When production resource deletion is genuinely required:
1. Create a change request ticket with business justification.
2. Management account admin temporarily detaches this SCP from the target OU.
3. Execute the deletion with full CloudTrail logging active.
4. Management account admin reattaches the SCP within 1 hour.
5. Close the change request ticket with evidence of reattachment.

## Exceptions and customisation
This policy has **no conditional exceptions** — there are no principal ARN exclusions. This is intentional: the only way to delete resources is the break-glass procedure above.

If you need exceptions for specific automation roles (e.g., AWS Backup restore jobs that need to delete old snapshots), do it via a sub-OU with a less restrictive policy rather than adding `StringNotLike` conditions here.

**Do not add exception conditions** — every exception is a potential attack path.

## References
- [MITRE ATT&CK — T1485 Data Destruction](https://attack.mitre.org/techniques/T1485/)
- [MITRE ATT&CK — T1561 Disk Wipe](https://attack.mitre.org/techniques/T1561/)
- [AWS — Protecting production resources with SCPs](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples_general.html)
- [AWS re:Invent 2023 — Cloud ransomware defense strategies](https://reinvent.awsevents.com/)
