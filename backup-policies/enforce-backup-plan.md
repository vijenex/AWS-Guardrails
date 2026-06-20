# Backup Policy: enforce-backup-plan

## What this does
An **AWS Organizations Backup Policy** that deploys a standardised AWS Backup plan to all accounts in the attached scope. It creates two backup rules:

- **Daily backup** at 5:00 AM UTC, retained for **35 days** — covers point-in-time recovery within the last month.
- **Weekly backup** every Sunday at 5:00 AM UTC, retained for **90 days** — covers longer recovery windows.

Resources selected for backup: EC2 instances, EBS volumes, RDS databases, RDS clusters, EFS file systems, DynamoDB tables, and EBS volumes tagged with `Environment: production` or `Environment: prod`.

## Why you need this
Without a backup policy enforced at the org level:
- Individual teams can skip backups or configure inconsistent retention.
- Ransomware, accidental deletion, or a failed migration leaves you without a recovery path.
- Compliance requirements (SOC 2, HIPAA, PCI-DSS, ISO 27001) mandate documented, tested backup procedures for production data.

An org-level backup policy ensures the baseline is applied everywhere without relying on individual account owners.

## Security impact if you don't apply this
- **Ransomware** encrypts your data — no backup means permanent loss or paying the ransom.
- **Accidental `terraform destroy`** on a production database with no backup = data loss.
- **Compliance failure** for regulated workloads (HIPAA, PCI, SOC 2 all require backup and recovery testing).
- Mean Recovery Time Objective (RTO) spikes from hours to "impossible."

## ⚠️ Disclaimer
> **Vijenex is not responsible for any accidental policy applied directly in production.**
>
> Backup policies create AWS Backup plans in every account in the attached scope. This will incur **AWS Backup storage costs**. Validate your cost estimate before broad deployment. Test in sandbox first.

## Testing ladder
1. **Sandbox**: Attach to a sandbox OU. Verify AWS Backup plans are created in the target account. Run an on-demand backup of a test EC2 instance. Verify the backup job completes and the recovery point appears.
2. **Non-production**: Apply to dev/staging OUs. Validate backup jobs run nightly. Test restore of an RDS snapshot.
3. **Production**: Apply during a maintenance window. Monitor backup job success rates in AWS Backup console. Set up CloudWatch alarms for backup job failures (`aws/backup` namespace).

## Prerequisites
- Replace `REPLACE_WITH_YOUR_PRIMARY_REGION` with your primary region (e.g., `ap-south-1`).
- Enable Backup Policies in your org: `aws organizations enable-policy-type --root-id r-XXXX --policy-type BACKUP_POLICY`
- The `AWSBackupDefaultServiceRole` IAM service role must exist in each account. It is created automatically when you first open AWS Backup console, or you can create it via CloudFormation StackSets.
- Tag production resources with `Environment: production` or `Environment: prod` for automatic inclusion.

## How to apply
```bash
# Enable Backup Policies in your org (one-time)
aws organizations enable-policy-type \
  --root-id r-REPLACE_ORG_ROOT \
  --policy-type BACKUP_POLICY

# Create the backup policy
aws organizations create-policy \
  --name "enforce-backup-plan" \
  --content file://enforce-backup-plan.json \
  --type BACKUP_POLICY

# Attach to OU or root
aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id ou-REPLACE_TARGET_OU
```

## How to test
```bash
# Verify backup plans are created in a target account
aws backup list-backup-plans

# Run an on-demand backup of a tagged resource
aws backup start-backup-job \
  --backup-vault-name Default \
  --resource-arn arn:aws:ec2:REGION:ACCOUNT:instance/INSTANCE_ID \
  --iam-role-arn arn:aws:iam::ACCOUNT:role/service-role/AWSBackupDefaultServiceRole

# Check job status
aws backup list-backup-jobs --by-state RUNNING
```

## Exceptions and customization
- Add `copy_actions` to replicate backups to a secondary region for disaster recovery.
- Add a `MonthlyBackupRule` with `delete_after_days: 365` for annual compliance.
- Modify `tag_value` to include your own environment naming convention.
- Use `@@append` operator instead of `@@assign` to allow child OUs to add additional backup rules without overriding this baseline.

## References
- [AWS Organizations Backup Policies documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_backup.html)
- [AWS Backup developer guide](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html)
- [CIS AWS Foundations Benchmark — Backup controls](https://www.cisecurity.org/benchmark/amazon_web_services)
