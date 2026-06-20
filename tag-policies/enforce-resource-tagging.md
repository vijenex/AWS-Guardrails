# Tag Policy: enforce-resource-tagging

## What this does
An **AWS Organizations Tag Policy** that enforces consistent capitalisation and allowed values for three core tags — `Environment`, `Owner`, and `CostCenter` — across the most common AWS resource types.

| Tag | Enforced | Allowed Values |
|-----|----------|----------------|
| `Environment` | EC2, EBS, RDS, S3, Lambda, ECS, EKS, ALB | `production`, `staging`, `development`, `sandbox`, `shared` |
| `Owner` | EC2, RDS, S3, Lambda | Any value (key existence enforced) |
| `CostCenter` | EC2, RDS, S3, Lambda, ALB | Any value (key existence enforced) |

Tag policies enforce **exact-match** capitalisation of the tag key and constrain allowed values. They do NOT automatically apply tags — they flag or block resources with non-compliant tags depending on your org settings.

## Why you need this
Without enforced tag standards:
- Cost Explorer shows "untagged" resources with no owner — impossible to chargeback.
- Incident response asks "who owns this EC2 instance?" — no answer.
- `Environment: Prod`, `Environment: PROD`, `Environment: production` are treated as three different values in Cost Explorer, breaking every cost allocation report.

Tag policies solve the taxonomy consistency problem. Combined with Config rules, they form the basis of a complete tagging governance framework.

## Security impact if you don't apply this
- **Cost attribution failure**: Untagged resources cannot be allocated to teams, leading to budget overruns and unaccountable spend.
- **Incident response delays**: Without an `Owner` tag, identifying who to contact during a security incident takes hours.
- **Compliance gaps**: SOC 2 and ISO 27001 require evidence of asset inventory. Inconsistent tags mean your inventory is incomplete.

## ⚠️ Disclaimer
> **Vijenex is not responsible for any accidental policy applied directly in production.**
>
> Tag policies in enforcement mode (`@@operators_allowed_for_child_policies: ["@@none"]`) prevent tagging operations that don't conform. Existing resources are not retroactively deleted — but new tag operations that violate the policy will fail. Test in reporting mode first.

## Testing ladder
1. **Sandbox**: Attach to a sandbox OU. Attempt to tag an EC2 instance with `Environment: PRODUCTION` (wrong case) — it should fail. Attempt `Environment: production` — should succeed.
2. **Non-production**: Attach to dev/staging. Run AWS Config rule `required-tags` to identify untagged resources.
3. **Production**: Enable enforcement. Run a tagging sweep with AWS Resource Tagging API first to remediate existing resources.

## Prerequisites
- Enable Tag Policies in your org: `aws organizations enable-policy-type --root-id r-XXXX --policy-type TAG_POLICY`
- Audit existing resource tags in all target accounts before enforcement. Use AWS Resource Groups Tagging API:
  ```bash
  aws resourcegroupstaggingapi get-resources --tag-filters Key=Environment --query 'ResourceTagMappingList[].Tags'
  ```
- Agree on the allowed value set for `Environment` for your organisation and update the `@@assign` list.

## How to apply
```bash
# Enable Tag Policies in your org (one-time)
aws organizations enable-policy-type \
  --root-id r-REPLACE_ORG_ROOT \
  --policy-type TAG_POLICY

# Create the policy
aws organizations create-policy \
  --name "enforce-resource-tagging" \
  --content file://enforce-resource-tagging.json \
  --type TAG_POLICY

# Attach to OU or root
aws organizations attach-policy \
  --policy-id <POLICY_ID> \
  --target-id ou-REPLACE_TARGET_OU
```

## How to test
```bash
# Check tag compliance across accounts (requires Organization Tag Policies feature)
aws organizations describe-effective-policy \
  --policy-type TAG_POLICY \
  --target-id ACCOUNT_ID

# List non-compliant resources
aws resourcegroupstaggingapi get-compliance-summary \
  --target-id-filters TargetIds=ACCOUNT_ID,TargetIdType=ACCOUNT

# Get resources missing required tags
aws resourcegroupstaggingapi get-resources \
  --resource-type-filters ec2:instance \
  --tag-filters Key=Environment
```

## Exceptions and customization
- Add more allowed `Environment` values to match your org's naming (e.g., `uat`, `qa`, `dr`).
- Add `Project` or `Application` tags by duplicating the `Owner` block structure.
- For `@@operators_allowed_for_child_policies: ["@@append"]` — child OUs can extend the allowed values list rather than being locked to this parent's set.
- Consider adding the `ManagedBy` tag to distinguish resources managed by Terraform/CDK from manually created ones.

## References
- [AWS Organizations Tag Policies documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_tag-policies.html)
- [AWS Resource Groups Tagging API](https://docs.aws.amazon.com/resourcegroupstagging/latest/APIReference/Welcome.html)
- [AWS Config rule: required-tags](https://docs.aws.amazon.com/config/latest/developerguide/required-tags.html)
