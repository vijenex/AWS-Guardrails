# RCP: deny-cross-org-assume-role

## What this does
A **Resource Control Policy (RCP)** that prevents principals from outside your AWS Organization from assuming any IAM role. AWS services are excluded via `aws:PrincipalIsAWSService`, so service-linked roles and service integrations continue to function.

## Why you need this
An IAM role with a trust policy that accidentally allows `"Principal": "*"` or `"Principal": {"AWS": "arn:aws:iam::*:root"}` can be assumed by any AWS account in the world. Without an RCP, this misconfiguration immediately becomes an external access path.

This RCP acts as a backstop: even if a role's trust policy is too permissive, only principals from within your organization can use it.

## ⚠️ Disclaimer
> **WARNING**: This blocks ALL `sts:AssumeRole` from outside your org. If you have legitimate third-party integrations (monitoring tools, MSPs, consulting partners) that assume roles in your accounts, you must add them as exceptions BEFORE applying.

## Prerequisites
- Replace `REPLACE_WITH_YOUR_ORG_ID` with your actual org ID.
- Audit all cross-account role trust policies: `aws iam get-role --role-name ROLE | jq '.Role.AssumeRolePolicyDocument'`
- Document all legitimate external role assumptions before applying.

## How to apply
```bash
aws organizations create-policy \
  --name "deny-cross-org-assume-role-rcp" \
  --content file://deny-cross-org-assume-role.json \
  --type RESOURCE_CONTROL_POLICY

aws organizations attach-policy \
  --policy-id <ID> \
  --target-id r-REPLACE_ORG_ROOT
```

## Testing
```bash
# From an account OUTSIDE the org — expect AccessDenied
aws sts assume-role \
  --role-arn arn:aws:iam::REPLACE_ACCOUNT:role/SomeRole \
  --role-session-name test
```

## References
- [AWS Resource Control Policies documentation](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_rcps.html)
- [AWS — Preventing cross-account access](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_deny-requested-region.html)
